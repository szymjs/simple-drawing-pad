// drawing-board: a pop-up drawing window for Windows. While the window is active, the WHOLE tablet
// surface draws into it (Wintab), regardless of how the tablet is mapped to the monitors. That is for regular
// (opaque) tablets; pen displays and touch screens use the normal pointer and draw where the pen is.
// Closing the window saves the sheet as PNG (and copies it to the clipboard) for Claude to read.
//
// Usage:  DrawingBoard.exe          open the board now, exit after closing it
//         DrawingBoard.exe --tray   stay in the notification area; a shortcut (default Ctrl+Alt+D, changeable from
//                                   the tray menu, kept in %APPDATA%\drawing-board\hotkey.txt) opens the board
// Output: <Pictures>\drawing-board\drawing_yyyyMMdd_HHmmss.png (+ latest.png, latest.txt); Esc: ...\cancelled\
//         <Pictures> is the Pictures known folder (it may be redirected).
//         Every close writes <Pictures>\drawing-board\status.txt (UTF-8): sent | cancelled | empty, PNG path, local time.
// Build:  build.ps1 (uses the C# compiler that ships with Windows / .NET Framework 4)
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace DrawingBoardApp
{
    static class Wintab
    {
        public const uint WTI_DEFCONTEXT = 3, WTI_DEVICES = 100, DVC_HWCAPS = 2, DVC_NPRESSURE = 15, HWC_INTEGRATED = 0x0001;
        public const uint CXO_MESSAGES = 0x0004;
        public const uint PK_STATUS = 0x0002, PK_CURSOR = 0x0020, PK_BUTTONS = 0x0040, PK_X = 0x0080, PK_Y = 0x0100, PK_NORMAL_PRESSURE = 0x0400;
        public const int WT_PACKET = 0x7FF0, WT_PROXIMITY = 0x7FF5;

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        public struct LOGCONTEXT
        {
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 40)] public string lcName;
            public uint lcOptions, lcStatus, lcLocks, lcMsgBase, lcDevice, lcPktRate, lcPktData, lcPktMode, lcMoveMask, lcBtnDnMask, lcBtnUpMask;
            public int lcInOrgX, lcInOrgY, lcInOrgZ, lcInExtX, lcInExtY, lcInExtZ;
            public int lcOutOrgX, lcOutOrgY, lcOutOrgZ, lcOutExtX, lcOutExtY, lcOutExtZ;
            public int lcSensX, lcSensY, lcSensZ, lcSysMode, lcSysOrgX, lcSysOrgY, lcSysExtX, lcSysExtY, lcSysSensX, lcSysSensY;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct AXIS { public int axMin, axMax; public uint axUnits; public int axResolution; }

        // field order follows the PK_* bit order
        [StructLayout(LayoutKind.Sequential)]
        public struct PACKET { public uint pkStatus, pkCursor, pkButtons; public int pkX, pkY; public uint pkNormalPressure; }

        [DllImport("Wintab32.dll", CharSet = CharSet.Unicode)] public static extern uint WTInfoW(uint cat, uint idx, ref LOGCONTEXT ctx);
        [DllImport("Wintab32.dll", CharSet = CharSet.Unicode)] public static extern uint WTInfoW(uint cat, uint idx, ref AXIS axis);
        [DllImport("Wintab32.dll", CharSet = CharSet.Unicode)] public static extern uint WTInfoW(uint cat, uint idx, ref uint value);
        [DllImport("Wintab32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr WTOpenW(IntPtr hWnd, ref LOGCONTEXT ctx, bool enable);
        [DllImport("Wintab32.dll")] public static extern bool WTClose(IntPtr hCtx);
        [DllImport("Wintab32.dll")] public static extern bool WTEnable(IntPtr hCtx, bool enable);
        [DllImport("Wintab32.dll")] public static extern bool WTOverlap(IntPtr hCtx, bool toTop);
        [DllImport("Wintab32.dll")] public static extern bool WTPacket(IntPtr hCtx, uint serial, ref PACKET pkt);
        [DllImport("Wintab32.dll")] public static extern bool WTQueueSizeSet(IntPtr hCtx, int size);
    }

    static class Native
    {
        [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
        [DllImport("user32.dll")] public static extern bool ClipCursor(ref RECT r);
        [DllImport("user32.dll")] public static extern bool ClipCursor(IntPtr none);
        [DllImport("user32.dll")] public static extern bool RegisterHotKey(IntPtr hWnd, int id, uint mods, uint vk);
        [DllImport("user32.dll")] public static extern bool UnregisterHotKey(IntPtr hWnd, int id);
        [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
        [DllImport("shcore.dll")] public static extern int SetProcessDpiAwareness(int value);
        public const int WM_HOTKEY = 0x0312;
        public const uint MOD_ALT = 0x1, MOD_CONTROL = 0x2, MOD_SHIFT = 0x4;
    }

    // English by default; Polish when Windows' display language is Polish
    static class Loc
    {
        static readonly bool Pl = System.Globalization.CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "pl";
        public static string T(string en, string pl) { return Pl ? pl : en; }
    }

    class Stroke
    {
        public Color Color; public float Width; public bool Eraser;
        public List<PointF> Pts = new List<PointF>(); public List<float> Pr = new List<float>();
    }

    class BoardForm : Form
    {
        public const int SheetW = 1600, SheetH = 1000;
        readonly Bitmap sheet = new Bitmap(SheetW, SheetH, PixelFormat.Format32bppArgb);
        readonly List<Stroke> strokes = new List<Stroke>();
        readonly Panel bar = new Panel();
        readonly Label status = new Label();
        readonly ToolTip hint = new ToolTip();
        Stroke cur;
        Color color = Color.FromArgb(29, 29, 31);
        // 5 thickness levels (keys 1-5); the eraser uses the same level, 8x wider
        static readonly float[] Levels = { 1f, 2f, 4f, 7f, 12f };
        int level = 3;
        float width { get { return Levels[level - 1]; } }
        bool eraserMode, sideEraser, tipEraser, hover, cancelled;
        bool Erasing { get { return eraserMode || sideEraser || tipEraser; } }
        Graphics sheetG;
        Rectangle lastCursorRect = Rectangle.Empty;
        PointF penAt;
        IntPtr ctx = IntPtr.Zero;
        int maxPressure = 1023;
        public string SavedPath;

        public BoardForm()
        {
            Text = "drawing-board";
            KeyPreview = true;
            DoubleBuffered = true;
            BackColor = Color.FromArgb(247, 247, 244);
            StartPosition = FormStartPosition.Manual;
            Screen scr = Screen.FromPoint(Cursor.Position);
            Rectangle wa = scr.WorkingArea;
            int w = Math.Min(wa.Width - 80, 1600), h = Math.Min(wa.Height - 80, (int)(w * 10.0 / 16.0) + 60);
            Bounds = new Rectangle(wa.Left + (wa.Width - w) / 2, wa.Top + (wa.Height - h) / 2, w, h);
            sheetG = Graphics.FromImage(sheet);
            sheetG.SmoothingMode = SmoothingMode.AntiAlias;
            sheetG.Clear(Color.White);
            BuildBar();
        }

        void BuildBar()
        {
            bar.Dock = DockStyle.Top; bar.Height = 48; bar.BackColor = Color.White;
            Controls.Add(bar);
            int x = 10;
            for (int i = 0; i < 5; i++)
            {
                int n = i + 1;
                x = AddButton(n.ToString(), x, delegate { SetLevel(n); });
            }
            x += 10;
            for (int i = 0; i < Palette.Length; i++)
            {
                int ci = i;
                Button b = new Button(); b.BackColor = Palette[i]; b.FlatStyle = FlatStyle.Flat; b.Size = new Size(30, 30); b.Location = new Point(x, 9);
                b.Text = PaletteKeys[i]; b.ForeColor = Color.White; b.TabStop = false;
                b.Click += delegate { SetColor(ci); };
                bar.Controls.Add(b); x += 36;
            }
            x += 10;
            x = AddButton(Loc.T("Backspace undo", "Backspace cofnij"), x, delegate { Undo(); });
            x = AddButton(Loc.T("Space eraser", "Spacja gumka"), x, delegate { ToggleEraser(); });
            x = AddButton(Loc.T("Delete clear", "Delete wyczyść"), x, delegate { ClearAll(); });
            x += 10;
            x = AddButton(Loc.T("Enter: send", "Enter: wyślij"), x, delegate { Close(); });
            x = AddButton(Loc.T("Esc: cancel", "Esc: anuluj"), x, delegate { cancelled = true; Close(); });
            status.AutoSize = true; status.Location = new Point(x + 12, 15); status.ForeColor = Color.DimGray;
            hint.ShowAlways = true;   // in tablet mode the cursor is kept on the sheet, so the tooltip shows when the board is inactive
            bar.Controls.Add(status);
            UpdateStatus();
        }

        int AddButton(string text, int x, EventHandler onClick)
        {
            // GrowAndShrink: the digit buttons would otherwise keep the 75 px default width and push the status off the bar
            Button b = new Button(); b.Text = text; b.AutoSize = true; b.AutoSizeMode = AutoSizeMode.GrowAndShrink; b.MinimumSize = new Size(30, 30); b.Location = new Point(x, 9);
            b.FlatStyle = FlatStyle.System; b.Click += onClick; b.TabStop = false;
            bar.Controls.Add(b);
            return x + b.PreferredSize.Width + 6;
        }

        // short text so nothing is cut off at 125-150% scaling; the explanation is in the tooltip
        void UpdateStatus()
        {
            status.Text = string.Format(Loc.T("{0} | width {1}/5 | {2}", "{0} | grubość {1}/5 | {2}"),
                Erasing ? Loc.T("ERASER", "GUMKA") : ctx != IntPtr.Zero ? "tablet" : Loc.T("mouse", "mysz"),
                level, PaletteNames[colorIndex]);
            hint.SetToolTip(status, ctx != IntPtr.Zero
                ? Loc.T("Tablet mode: while this window is active, the whole tablet draws on this sheet. Pen back end or a side button = eraser.",
                        "Tryb tabletu: gdy to okno jest aktywne, cały tablet rysuje na tym arkuszu. Tył pióra lub boczny przycisk = gumka.")
                : Loc.T("Mouse mode: draws where the mouse, pen or finger is (no Wintab tablet driver, or a pen display / touch screen).",
                        "Tryb myszy: rysuje tam, gdzie jest mysz, pióro lub palec (brak sterownika Wintab albo ekran z piórem / dotykowy)."));
            if (hover) InvalidateCursor();   // the circle may have grown (eraser, width)
        }

        // keys 6 7 8 9 0: black, orange, light blue, red, grey
        static readonly Color[] Palette = { Color.FromArgb(29, 29, 31), Color.FromArgb(234, 138, 0), Color.FromArgb(77, 171, 247), Color.FromArgb(214, 40, 40), Color.FromArgb(128, 128, 128) };
        static readonly string[] PaletteNames = {
            Loc.T("black", "czarny"), Loc.T("orange", "pomarańczowy"), Loc.T("light blue", "jasnoniebieski"), Loc.T("red", "czerwony"), Loc.T("grey", "szary") };
        static readonly string[] PaletteKeys = { "6", "7", "8", "9", "0" };
        int colorIndex;
        void SetLevel(int l) { level = Math.Max(1, Math.Min(5, l)); UpdateStatus(); }   // 1-5, applies to pen and eraser alike
        void SetColor(int i) { colorIndex = i; color = Palette[i]; eraserMode = false; UpdateStatus(); }
        void ToggleEraser() { eraserMode = !eraserMode; UpdateStatus(); }

        // ---------- sheet <-> screen
        Rectangle SheetRect()
        {
            Rectangle area = new Rectangle(0, bar.Height, ClientSize.Width, ClientSize.Height - bar.Height);
            float s = Math.Min((float)area.Width / SheetW, (float)area.Height / SheetH);
            int w = (int)(SheetW * s), h = (int)(SheetH * s);
            return new Rectangle(area.Left + (area.Width - w) / 2, area.Top + (area.Height - h) / 2, w, h);
        }

        // ---------- Wintab
        protected override void OnHandleCreated(EventArgs e)
        {
            base.OnHandleCreated(e);
            try
            {
                Wintab.LOGCONTEXT lc = new Wintab.LOGCONTEXT();
                if (Wintab.WTInfoW(Wintab.WTI_DEFCONTEXT, 0, ref lc) == 0) return;
                // pen display / tablet PC: the pen already points at the screen, so keep the normal pointer (mouse mode)
                uint caps = 0;
                if (Wintab.WTInfoW(Wintab.WTI_DEVICES, Wintab.DVC_HWCAPS, ref caps) != 0 && (caps & Wintab.HWC_INTEGRATED) != 0) return;
                Wintab.AXIS ax = new Wintab.AXIS();
                if (Wintab.WTInfoW(Wintab.WTI_DEVICES, Wintab.DVC_NPRESSURE, ref ax) != 0 && ax.axMax > 0) maxPressure = ax.axMax;
                lc.lcName = "drawing-board";
                lc.lcOptions |= Wintab.CXO_MESSAGES;
                lc.lcPktData = Wintab.PK_STATUS | Wintab.PK_CURSOR | Wintab.PK_BUTTONS | Wintab.PK_X | Wintab.PK_Y | Wintab.PK_NORMAL_PRESSURE;
                lc.lcPktMode = 0;
                lc.lcMoveMask = lc.lcPktData;
                lc.lcBtnUpMask = lc.lcBtnDnMask;
                // whole tablet -> whole sheet, origin top-left; the tablet area is letterboxed to the sheet's 16:10
                // (longer axis shrunk, centred) so circles stay round
                if (lc.lcInExtX > 0 && lc.lcInExtY > 0)
                {
                    if ((long)lc.lcInExtX * SheetH > (long)lc.lcInExtY * SheetW)
                    { int w = (int)((long)lc.lcInExtY * SheetW / SheetH); lc.lcInOrgX += (lc.lcInExtX - w) / 2; lc.lcInExtX = w; }
                    else
                    { int h = (int)((long)lc.lcInExtX * SheetH / SheetW); lc.lcInOrgY += (lc.lcInExtY - h) / 2; lc.lcInExtY = h; }
                }
                lc.lcOutOrgX = 0; lc.lcOutExtX = SheetW;
                lc.lcOutOrgY = 0; lc.lcOutExtY = -SheetH;
                ctx = Wintab.WTOpenW(Handle, ref lc, true);
                if (ctx != IntPtr.Zero) Wintab.WTQueueSizeSet(ctx, 256);
            }
            catch (DllNotFoundException) { ctx = IntPtr.Zero; }
            catch (EntryPointNotFoundException) { ctx = IntPtr.Zero; }
            UpdateStatus();
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == Wintab.WT_PACKET && ctx != IntPtr.Zero)
            {
                Wintab.PACKET p = new Wintab.PACKET();
                if (Wintab.WTPacket(m.LParam, (uint)m.WParam.ToInt64(), ref p)) OnPen(p);
                return;
            }
            base.WndProc(ref m);
        }

        void OnPen(Wintab.PACKET p)
        {
            float x = Math.Max(0, Math.Min(SheetW, p.pkX));
            float y = p.pkY < 0 ? -p.pkY : p.pkY;
            y = Math.Max(0, Math.Min(SheetH, y));
            float pr = Math.Min(1f, (float)p.pkNormalPressure / maxPressure);
            bool tip = (p.pkCursor % 3) == 2;                           // back end of the pen
            bool side = (p.pkButtons & 0x6) != 0;                       // either side button held = eraser
            if (side != sideEraser || tip != tipEraser) { sideEraser = side; tipEraser = tip; UpdateStatus(); }
            penAt = new PointF(x, y); hover = true;
            if (pr > 0.01f)
            {
                if (cur == null) StartStroke(penAt, pr, tip || side);
                else AddPoint(penAt, pr);
            }
            else cur = null;
            InvalidateCursor();
        }

        // ---------- repaint only what changed (repainting the whole sheet per pen packet made it lag)
        Rectangle SheetToScreen(RectangleF s)
        {
            Rectangle r = SheetRect(); float k = (float)r.Width / SheetW;
            return Rectangle.FromLTRB((int)Math.Floor(r.Left + s.Left * k) - 2, (int)Math.Floor(r.Top + s.Top * k) - 2,
                                      (int)Math.Ceiling(r.Left + s.Right * k) + 2, (int)Math.Ceiling(r.Top + s.Bottom * k) + 2);
        }
        float CursorRadius() { return Math.Max(3f, (Erasing ? width * EraserFactor : width * 2.35f) / 2f); }
        void InvalidateCursor()
        {
            float rad = CursorRadius() + 12;
            Rectangle now = SheetToScreen(new RectangleF(penAt.X - rad, penAt.Y - rad, rad * 2, rad * 2));
            Invalidate(lastCursorRect); Invalidate(now); lastCursorRect = now;
        }
        void InvalidateSegment(Stroke s, int i)
        {
            PointF a = s.Pts[i == 0 ? 0 : i - 1], b = s.Pts[i];
            float m = SegWidth(s, i) / 2 + 2;
            Invalidate(SheetToScreen(RectangleF.FromLTRB(Math.Min(a.X, b.X) - m, Math.Min(a.Y, b.Y) - m, Math.Max(a.X, b.X) + m, Math.Max(a.Y, b.Y) + m)));
        }

        // ---------- mouse fallback (no Wintab)
        PointF ToSheet(Point pt)
        {
            Rectangle r = SheetRect();
            return new PointF(Math.Max(0, Math.Min(SheetW, (pt.X - r.Left) * (float)SheetW / r.Width)),
                              Math.Max(0, Math.Min(SheetH, (pt.Y - r.Top) * (float)SheetH / r.Height)));
        }
        protected override void OnMouseDown(MouseEventArgs e) { if (ctx == IntPtr.Zero && e.Button == MouseButtons.Left) StartStroke(ToSheet(e.Location), 0.55f, false); }
        protected override void OnMouseMove(MouseEventArgs e) { if (ctx == IntPtr.Zero && cur != null) AddPoint(ToSheet(e.Location), 0.55f); }
        protected override void OnMouseUp(MouseEventArgs e) { if (ctx == IntPtr.Zero) cur = null; }

        // ---------- drawing
        void StartStroke(PointF pt, float pr, bool eraserTip)
        {
            cur = new Stroke();
            cur.Color = color; cur.Width = width; cur.Eraser = eraserMode || eraserTip;
            cur.Pts.Add(pt); cur.Pr.Add(pr);
            strokes.Add(cur);
            DrawSegment(sheetG, cur, 0);
            InvalidateSegment(cur, 0);
        }
        void AddPoint(PointF pt, float pr)
        {
            PointF last = cur.Pts[cur.Pts.Count - 1];
            if (Math.Abs(last.X - pt.X) + Math.Abs(last.Y - pt.Y) < 0.5f) return;
            cur.Pts.Add(pt); cur.Pr.Add(pr);
            DrawSegment(sheetG, cur, cur.Pts.Count - 1);
            InvalidateSegment(cur, cur.Pts.Count - 1);
        }
        const float EraserFactor = 8f;
        static float SegWidth(Stroke s, int i) { return s.Eraser ? s.Width * EraserFactor : Math.Max(1.4f, s.Width * 2.35f * (s.Pr[i] * 1.4f + 0.2f)); }
        static void DrawSegment(Graphics g, Stroke s, int i)
        {
            Color c = s.Eraser ? Color.White : s.Color;
            float w = SegWidth(s, i);
            if (i == 0) { using (Brush b = new SolidBrush(c)) g.FillEllipse(b, s.Pts[0].X - w / 2, s.Pts[0].Y - w / 2, w, w); return; }
            using (Pen pen = new Pen(c, w))
            {
                pen.StartCap = LineCap.Round; pen.EndCap = LineCap.Round; pen.LineJoin = LineJoin.Round;
                g.DrawLine(pen, s.Pts[i - 1], s.Pts[i]);
            }
        }
        void Redraw()
        {
            sheetG.Clear(Color.White);
            foreach (Stroke s in strokes) for (int i = 0; i < s.Pts.Count; i++) DrawSegment(sheetG, s, i);
            Invalidate();
        }
        List<Stroke> cleared;
        void ClearAll() { if (strokes.Count == 0) return; cleared = new List<Stroke>(strokes); strokes.Clear(); cur = null; Redraw(); }
        void Undo()
        {
            if (strokes.Count == 0 && cleared != null) { strokes.AddRange(cleared); cleared = null; Redraw(); return; } // Ctrl+Z also brings back a cleared sheet
            if (strokes.Count > 0) { strokes.RemoveAt(strokes.Count - 1); cur = null; Redraw(); }
        }
        protected override void OnPaint(PaintEventArgs e)
        {
            Rectangle r = SheetRect();
            Rectangle clip = Rectangle.Intersect(e.ClipRectangle, r);
            if (clip.Width > 0 && clip.Height > 0)
            {
                float k = (float)SheetW / r.Width;
                RectangleF src = new RectangleF((clip.Left - r.Left) * k, (clip.Top - r.Top) * k, clip.Width * k, clip.Height * k);
                e.Graphics.InterpolationMode = InterpolationMode.HighQualityBilinear;
                e.Graphics.PixelOffsetMode = PixelOffsetMode.Half;
                e.Graphics.DrawImage(sheet, clip, src, GraphicsUnit.Pixel);
                e.Graphics.PixelOffsetMode = PixelOffsetMode.Default;
            }
            e.Graphics.DrawRectangle(Pens.LightGray, r);
            if (hover && ctx != IntPtr.Zero)
            {
                // circle = the real size of the line (blue) or of the eraser (red), seen before touching the tablet
                float sx = r.Left + penAt.X * r.Width / SheetW, sy = r.Top + penAt.Y * r.Height / SheetH;
                float rad = CursorRadius() * r.Width / SheetW;
                e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                using (Pen p = new Pen(Erasing ? Color.FromArgb(214, 40, 40) : Color.FromArgb(55, 138, 221), 1.5f))
                {
                    e.Graphics.DrawEllipse(p, sx - rad, sy - rad, rad * 2, rad * 2);
                    e.Graphics.DrawLine(p, sx - 4, sy, sx + 4, sy);
                    e.Graphics.DrawLine(p, sx, sy - 4, sx, sy + 4);
                }
            }
        }
        protected override void OnResize(EventArgs e) { base.OnResize(e); Invalidate(); Reclip(); }
        protected override void OnMove(EventArgs e) { base.OnMove(e); Reclip(); }
        // no clip inside the system move/size loop (it would fight a title-bar or border drag); re-clip once at the end
        bool inMoveSize;
        protected override void OnResizeBegin(EventArgs e) { base.OnResizeBegin(e); inMoveSize = true; Native.ClipCursor(IntPtr.Zero); }
        protected override void OnResizeEnd(EventArgs e) { base.OnResizeEnd(e); inMoveSize = false; Reclip(); }
        // the clip follows the sheet (tablet mode, active window only); a minimized board frees the cursor
        void Reclip()
        {
            if (inMoveSize || ctx == IntPtr.Zero || Form.ActiveForm != this) return;
            if (WindowState == FormWindowState.Minimized) Native.ClipCursor(IntPtr.Zero); else ClipToWindow();
        }

        // ---------- focus: whole tablet only while this window is active
        void ClipToWindow()
        {
            Rectangle r = RectangleToScreen(SheetRect()); // only the sheet: a pen tap can never hit the toolbar
            Native.RECT rc = new Native.RECT(); rc.Left = r.Left; rc.Top = r.Top; rc.Right = r.Right; rc.Bottom = r.Bottom;
            Native.ClipCursor(ref rc);
        }
        protected override void OnActivated(EventArgs e)
        {
            base.OnActivated(e);
            if (ctx != IntPtr.Zero) { Wintab.WTEnable(ctx, true); Wintab.WTOverlap(ctx, true); ClipToWindow(); }
        }
        protected override void OnDeactivate(EventArgs e)
        {
            base.OnDeactivate(e);
            Native.ClipCursor(IntPtr.Zero);
            if (ctx != IntPtr.Zero) { Wintab.WTEnable(ctx, false); cur = null; hover = false; Invalidate(); }
        }
        // keys are handled before any button sees them (Enter would otherwise click a focused button,
        // and the arrow keys sent by the numpad with Num Lock off would move focus)
        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            Keys k = keyData & Keys.KeyCode;
            bool ctrl = (keyData & Keys.Control) != 0, shift = (keyData & Keys.Shift) != 0;
            if (ctrl && k == Keys.Z) { Undo(); return true; }
            if (!ctrl)
            {
                // numpad with Num Lock on (NumPadN), top-row digits (DN), or numpad with Num Lock off (End, Down, ...)
                switch (k)
                {
                    case Keys.NumPad1: case Keys.D1: case Keys.End: SetLevel(1); return true;
                    case Keys.NumPad2: case Keys.D2: case Keys.Down: SetLevel(2); return true;
                    case Keys.NumPad3: case Keys.D3: case Keys.Next: SetLevel(3); return true;
                    case Keys.NumPad4: case Keys.D4: case Keys.Left: SetLevel(4); return true;
                    case Keys.NumPad5: case Keys.D5: case Keys.Clear: SetLevel(5); return true;
                    case Keys.NumPad6: case Keys.D6: case Keys.Right: SetColor(0); return true;   // black
                    case Keys.NumPad7: case Keys.D7: case Keys.Home: SetColor(1); return true;    // orange
                    case Keys.NumPad8: case Keys.D8: case Keys.Up: SetColor(2); return true;      // light blue
                    case Keys.NumPad9: case Keys.D9: case Keys.Prior: SetColor(3); return true;   // red
                    case Keys.NumPad0: case Keys.D0: case Keys.Insert: SetColor(4); return true;  // grey
                    case Keys.Back: Undo(); return true;                                          // Backspace: undo
                    case Keys.Delete: case Keys.Decimal: ClearAll(); return true;                 // Delete: clear (Backspace brings it back)
                    case Keys.Space: case Keys.E: ToggleEraser(); return true;                    // Space (or E): eraser on/off
                    case Keys.Enter: Close(); return true;                                        // Enter: done, send to Claude
                    case Keys.Escape: cancelled = true; Close(); return true;                     // Esc: close without sending
                }
            }
            return base.ProcessCmdKey(ref msg, keyData);
        }

        // ---------- closing sends the drawing
        protected override void OnFormClosing(FormClosingEventArgs e)
        {
            Native.ClipCursor(IntPtr.Zero);
            try { Save(); }
            catch (Exception ex)
            {
                // keep the board (and its Wintab context) open so nothing is lost, unless the user chooses to close anyway
                if (strokes.Count > 0)
                    e.Cancel = MessageBox.Show(this, string.Format(Loc.T("The drawing could not be saved:\n{0}\n\nClose the board anyway? The drawing will be lost.",
                        "Nie udało się zapisać rysunku:\n{0}\n\nZamknąć tablicę mimo to? Rysunek przepadnie."), ex.Message),
                        "drawing-board", MessageBoxButtons.YesNo, MessageBoxIcon.Error, MessageBoxDefaultButton.Button2) != DialogResult.Yes;
                cancelled = false;
            }
            if (!e.Cancel && ctx != IntPtr.Zero) { Wintab.WTClose(ctx); ctx = IntPtr.Zero; }
            base.OnFormClosing(e);
        }
        protected override void Dispose(bool disposing)
        {
            base.Dispose(disposing);
            if (disposing) { if (sheetG != null) sheetG.Dispose(); sheet.Dispose(); hint.Dispose(); }
        }
        // <Pictures>\drawing-board, where <Pictures> is the Pictures known folder (it may be redirected)
        static string OutDir()
        {
            string pics = Environment.GetFolderPath(Environment.SpecialFolder.MyPictures, Environment.SpecialFolderOption.Create);
            if (pics.Length == 0) pics = Path.Combine(Environment.GetEnvironmentVariable("USERPROFILE"), "Pictures");
            return Path.Combine(pics, "drawing-board");
        }
        // Enter / close: PNG + latest.png + latest.txt + clipboard. Esc: PNG in cancelled\ only (latest.* untouched),
        // so a stray Esc never loses a drawing. Every close ends with status.txt (sent | cancelled | empty, PNG path,
        // local time) for Claude to wait on. Throws when saving fails.
        void Save()
        {
            DateTime now = DateTime.Now;
            string dir = OutDir(), file = "", state = strokes.Count == 0 ? "empty" : cancelled ? "cancelled" : "sent";
            Directory.CreateDirectory(dir);
            if (state != "empty")
            {
                string to = cancelled ? Path.Combine(dir, "cancelled") : dir;
                Directory.CreateDirectory(to);
                file = Path.Combine(to, "drawing_" + now.ToString("yyyyMMdd_HHmmss") + ".png");
                sheet.Save(file, ImageFormat.Png);
            }
            if (state == "sent")
            {
                try { File.Copy(file, Path.Combine(dir, "latest.png"), true); } catch (Exception) { }   // a convenience copy; latest.txt names the real file
                File.WriteAllText(Path.Combine(dir, "latest.txt"), file + Environment.NewLine + now.ToString("o") + Environment.NewLine);
                try { Clipboard.SetImage(sheet); } catch (ExternalException) { }
                SavedPath = file;
            }
            File.WriteAllText(Path.Combine(dir, "status.txt"), state + Environment.NewLine + file + Environment.NewLine + now.ToString("o") + Environment.NewLine);
        }
    }

    // --tray mode: hidden window that owns the hotkey and the notification icon
    class TrayContext : ApplicationContext
    {
        readonly NotifyIcon icon = new NotifyIcon();
        readonly HotkeyWindow hk;
        readonly MenuItem drawItem;
        BoardForm open;
        Keys hotkey;

        // the shortcut is stored as text ("Ctrl+Alt+D") in %APPDATA%\drawing-board\hotkey.txt
        static readonly string ConfigFile = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), "drawing-board", "hotkey.txt");
        const Keys DefaultHotkey = Keys.Control | Keys.Alt | Keys.D;

        public TrayContext()
        {
            icon.Icon = SystemIcons.Application;
            ContextMenu menu = new ContextMenu();
            drawItem = menu.MenuItems.Add(Loc.T("Draw", "Rysuj"), delegate { OpenBoard(); });
            menu.MenuItems.Add(Loc.T("Change shortcut…", "Zmień skrót…"), delegate { ChangeHotkey(); });
            menu.MenuItems.Add(Loc.T("Exit", "Zakończ"), delegate { Exit(); });
            icon.ContextMenu = menu;
            icon.DoubleClick += delegate { OpenBoard(); };
            icon.Visible = true;
            hk = new HotkeyWindow(OpenBoard);
            Keys saved = DefaultHotkey;
            try { if (File.Exists(ConfigFile)) saved = Hotkeys.Parse(File.ReadAllText(ConfigFile)); } catch (Exception) { saved = DefaultHotkey; }
            if (!Apply(saved))
                icon.ShowBalloonTip(5000, "drawing-board", string.Format(Loc.T(
                    "The shortcut {0} is taken by another program. Right-click this icon and choose \"Change shortcut\".",
                    "Skrót {0} jest zajęty przez inny program. Kliknij ikonę prawym przyciskiem i wybierz „Zmień skrót”."), Hotkeys.Format(saved)), ToolTipIcon.Warning);
        }

        // registers the shortcut system-wide; false if another program already owns it
        bool Apply(Keys k)
        {
            Native.UnregisterHotKey(hk.Handle, 1);
            hotkey = k;   // kept even if registering fails, so the menu, tooltip and dialog show the wanted shortcut
            uint mods = 0;
            if ((k & Keys.Control) != 0) mods |= Native.MOD_CONTROL;
            if ((k & Keys.Alt) != 0) mods |= Native.MOD_ALT;
            if ((k & Keys.Shift) != 0) mods |= Native.MOD_SHIFT;
            bool ok = Native.RegisterHotKey(hk.Handle, 1, mods, (uint)(k & Keys.KeyCode));
            string name = Hotkeys.Format(hotkey);
            drawItem.Text = Loc.T("Draw", "Rysuj") + " (" + name + ")";
            icon.Text = "drawing-board (" + name + ")";
            return ok;
        }

        void ChangeHotkey()
        {
            Keys old = hotkey;
            Native.UnregisterHotKey(hk.Handle, 1);   // so the current shortcut can be pressed in the dialog too
            using (HotkeyDialog d = new HotkeyDialog(hotkey))
            {
                if (d.ShowDialog() != DialogResult.OK || (d.Chosen & Keys.KeyCode) == Keys.None) { Apply(old); return; }
                if (!Apply(d.Chosen))
                {
                    Apply(old);
                    MessageBox.Show(string.Format(Loc.T("The shortcut {0} is taken by another program. Choose a different one.",
                        "Skrót {0} jest zajęty przez inny program. Wybierz inny."), Hotkeys.Format(d.Chosen)), "drawing-board", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                    return;
                }
                Directory.CreateDirectory(Path.GetDirectoryName(ConfigFile));
                File.WriteAllText(ConfigFile, Hotkeys.Format(hotkey));
            }
        }
        void OpenBoard()
        {
            if (open != null && !open.IsDisposed)
            {
                if (open.WindowState == FormWindowState.Minimized) open.WindowState = FormWindowState.Normal;
                open.Activate(); return;
            }
            open = new BoardForm();
            open.Show(); open.Activate();
        }
        // an open board is closed first, so its drawing is saved; the helper keeps running if the board stays open
        void Exit()
        {
            if (open != null && !open.IsDisposed) { open.Close(); if (!open.IsDisposed) return; }
            ExitThread();
        }
        protected override void ExitThreadCore()
        {
            Native.UnregisterHotKey(hk.Handle, 1);
            icon.Visible = false; icon.Dispose(); hk.DestroyHandle();
            base.ExitThreadCore();
        }
    }

    // "Ctrl+Alt+D" <-> Keys
    static class Hotkeys
    {
        public static string Format(Keys k)
        {
            string s = "";
            if ((k & Keys.Control) != 0) s += "Ctrl+";
            if ((k & Keys.Alt) != 0) s += "Alt+";
            if ((k & Keys.Shift) != 0) s += "Shift+";
            Keys code = k & Keys.KeyCode;
            string name = code.ToString();
            if (code >= Keys.D0 && code <= Keys.D9) name = name.Substring(1);
            return s + name;
        }
        public static Keys Parse(string text)
        {
            Keys k = Keys.None;
            foreach (string raw in text.Trim().Split('+'))
            {
                string p = raw.Trim();
                if (p.Length == 0) continue;
                string low = p.ToLowerInvariant();
                if (low == "ctrl" || low == "control") k |= Keys.Control;
                else if (low == "alt") k |= Keys.Alt;
                else if (low == "shift") k |= Keys.Shift;
                else if (p.Length == 1 && char.IsDigit(p[0])) k |= (Keys)Enum.Parse(typeof(Keys), "D" + p);
                else k |= (Keys)Enum.Parse(typeof(Keys), p, true);
            }
            if ((k & Keys.KeyCode) == Keys.None || (k & (Keys.Control | Keys.Alt)) == 0) throw new FormatException("need Ctrl or Alt and a key");
            return k;
        }
    }

    // small window: press the new combination, OK saves it
    class HotkeyDialog : Form
    {
        public Keys Chosen;
        readonly Label shown = new Label();
        readonly Button ok = new Button();
        public HotkeyDialog(Keys current)
        {
            Text = Loc.T("drawing-board: shortcut", "drawing-board: skrót");
            FormBorderStyle = FormBorderStyle.FixedDialog; MaximizeBox = false; MinimizeBox = false;
            StartPosition = FormStartPosition.CenterScreen; KeyPreview = true; ClientSize = new Size(380, 150);
            Label info = new Label(); info.Text = Loc.T("Press the new key combination (Ctrl and/or Alt + a key):", "Naciśnij nową kombinację klawiszy (Ctrl i/lub Alt + klawisz):");
            info.AutoSize = true; info.Location = new Point(14, 14); Controls.Add(info);
            shown.Font = new Font(Font.FontFamily, 16f, FontStyle.Bold); shown.AutoSize = true; shown.Location = new Point(14, 44);
            Chosen = current; shown.Text = Hotkeys.Format(current); Controls.Add(shown);
            ok.Text = "OK"; ok.DialogResult = DialogResult.OK; ok.Location = new Point(200, 105); ok.TabStop = false; Controls.Add(ok);
            Button cancel = new Button(); cancel.Text = Loc.T("Cancel", "Anuluj"); cancel.DialogResult = DialogResult.Cancel; cancel.Location = new Point(285, 105); cancel.TabStop = false; Controls.Add(cancel);
            AcceptButton = ok; CancelButton = cancel;
        }
        protected override bool ProcessCmdKey(ref Message msg, Keys keyData)
        {
            Keys code = keyData & Keys.KeyCode;
            bool isModifier = code == Keys.ControlKey || code == Keys.Menu || code == Keys.ShiftKey || code == Keys.LWin || code == Keys.RWin;
            bool hasMod = (keyData & (Keys.Control | Keys.Alt)) != 0;
            if (!isModifier && hasMod) { Chosen = keyData & (Keys.KeyCode | Keys.Control | Keys.Alt | Keys.Shift); shown.Text = Hotkeys.Format(Chosen); return true; }
            return base.ProcessCmdKey(ref msg, keyData);
        }
    }

    class HotkeyWindow : NativeWindow
    {
        readonly MethodInvoker onHotkey;
        public HotkeyWindow(MethodInvoker onHotkey) { this.onHotkey = onHotkey; CreateHandle(new CreateParams()); }
        protected override void WndProc(ref Message m)
        {
            if (m.Msg == Native.WM_HOTKEY) onHotkey();
            base.WndProc(ref m);
        }
    }

    static class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try { Native.SetProcessDpiAwareness(2); } catch (Exception) { try { Native.SetProcessDPIAware(); } catch (Exception) { } }
            Application.EnableVisualStyles();
            if (args.Length > 0 && args[0] == "--tray") Application.Run(new TrayContext());
            else Application.Run(new BoardForm());
        }
    }
}
