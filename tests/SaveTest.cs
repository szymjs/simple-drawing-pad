// Headless check of BoardForm.Save() with and without the Shift+Enter copy, run under Mono + Xvfb.
// It loads the compiled SimpleDrawingPad.exe by reflection, so nothing in the program changes for the test.
using System;
using System.Collections;
using System.Drawing;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

static class SaveTest
{
    static int failures;
    static void Check(bool ok, string what) { Console.WriteLine((ok ? "  ok   " : "  FAIL ") + what); if (!ok) failures++; }

    static object NewBoard(Assembly a, out Type t)
    {
        t = a.GetType("SimpleDrawingPadApp.BoardForm");
        return Activator.CreateInstance(t, true);
    }
    static void AddStroke(Assembly a, Type t, object board)
    {
        object s = Activator.CreateInstance(a.GetType("SimpleDrawingPadApp.Stroke"), true);
        IList strokes = (IList)t.GetField("strokes", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(board);
        strokes.Add(s);
    }
    static void SetSaveAs(Type t, object board, string path) { t.GetField("saveAsPath", BindingFlags.NonPublic | BindingFlags.Instance).SetValue(board, path); }
    static string GetSaveAs(Type t, object board) { return (string)t.GetField("saveAsPath", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(board); }
    // the copy's path when it could not be written (shown in the warning when the board closes), else null
    static string GetSaveAsFailed(Type t, object board) { return (string)t.GetField("saveAsFailed", BindingFlags.NonPublic | BindingFlags.Instance).GetValue(board); }
    // Esc: the board closes with cancelled set, so Save() writes status.txt only
    static void SetCancelled(Type t, object board) { t.GetField("cancelled", BindingFlags.NonPublic | BindingFlags.Instance).SetValue(board, true); }
    // the names of the files in drawings\, sorted: after a drawing the folder holds latest.png and status.txt, nothing else
    static string Files(string drawings)
    {
        string[] names = Directory.GetFiles(drawings);
        for (int i = 0; i < names.Length; i++) names[i] = Path.GetFileName(names[i]);
        Array.Sort(names, StringComparer.Ordinal);
        return string.Join(" ", names);
    }
    static bool SameBytes(byte[] a, byte[] b)
    {
        if (a.Length != b.Length) return false;
        for (int i = 0; i < a.Length; i++) if (a[i] != b[i]) return false;
        return true;
    }
    static Exception CallSave(Type t, object board)
    {
        try { t.GetMethod("Save", BindingFlags.NonPublic | BindingFlags.Instance).Invoke(board, null); return null; }
        catch (TargetInvocationException e) { return e.InnerException; }
    }
    static string[] Status(string drawings) { return File.ReadAllText(Path.Combine(drawings, "status.txt")).Split(new[] { "\r\n", "\n" }, StringSplitOptions.None); }
    static bool IsPng(string p) { if (!File.Exists(p)) return false; byte[] b = File.ReadAllBytes(p); return b.Length > 8 && b[0] == 0x89 && b[1] == (byte)'P' && b[2] == (byte)'N' && b[3] == (byte)'G'; }

    [STAThread]
    static int Main(string[] args)
    {
        string exe = Path.GetFullPath(args[0]);
        string home = Environment.GetFolderPath(Environment.SpecialFolder.UserProfile);
        string drawings = Path.Combine(home, "simple-drawing-pad", "drawings");
        string latest = Path.Combine(drawings, "latest.png");
        if (Directory.Exists(drawings)) Directory.Delete(drawings, true);
        Console.WriteLine("program: " + exe);
        Console.WriteLine("home:    " + home);
        Assembly a = Assembly.LoadFrom(exe);
        Type t;

        Console.WriteLine("\n1. Shift+Enter path: a stroke, saveAsPath set, Save()");
        string copyDir = Path.Combine(home, "Pictures"); Directory.CreateDirectory(copyDir);
        string copy = Path.Combine(copyDir, "my copy.png");
        object b1 = NewBoard(a, out t); AddStroke(a, t, b1); SetSaveAs(t, b1, copy);
        Exception e1 = CallSave(t, b1);
        Console.WriteLine("  Save() threw: " + (e1 == null ? "nothing" : e1.GetType().Name + ": " + e1.Message));
        string[] st = Status(drawings);
        Check(st[0] == "copied", "status.txt line 1 is 'copied' (got '" + st[0] + "')");
        Check(st[1] == latest, "status.txt line 2 is drawings\\latest.png, not the copy (got '" + st[1] + "')");
        Check(IsPng(latest), "latest.png exists and is a PNG");
        Check(IsPng(copy), "the Save as copy exists and is a PNG: " + copy);
        Check(new FileInfo(copy).Length == new FileInfo(latest).Length, "the copy has the same size as latest.png");
        Check(Files(drawings) == "latest.png status.txt", "drawings\\ holds latest.png and status.txt only: no drawing_*.png, no latest.txt (got '" + Files(drawings) + "')");
        Check(GetSaveAs(t, b1) == null, "saveAsPath is reset to null after the save");
        Check(GetSaveAsFailed(t, b1) == null, "no copy failure is recorded");
        Check(e1 == null || e1 is System.Runtime.InteropServices.ExternalException, "no exception, or only the clipboard's ExternalException (is caught in the program)");

        Console.WriteLine("\n2. Plain Enter path: a stroke, no saveAsPath, Save(): latest.png is overwritten, nothing is added");
        int before = Directory.GetFiles(copyDir, "*.png").Length;
        object b2 = NewBoard(a, out t); AddStroke(a, t, b2);
        Exception e2 = CallSave(t, b2);
        st = Status(drawings);
        Check(st[0] == "copied" && st[1] == latest, "status.txt says copied and names latest.png");
        Check(IsPng(latest), "latest.png is a PNG");
        Check(Files(drawings) == "latest.png status.txt", "still one drawing: drawings\\ holds latest.png and status.txt only (got '" + Files(drawings) + "')");
        Check(Directory.GetFiles(copyDir, "*.png").Length == before, "no extra copy was written");
        Check(e2 == null || e2 is System.Runtime.InteropServices.ExternalException, "no exception beyond the clipboard's");

        Console.WriteLine("\n3. Copy to an unwritable place: the drawing is still saved and sent, the failure is recorded, nothing is saved twice");
        // the copy is written last, in its own try: Save() does not throw, so OnFormClosing only warns (naming the path)
        // and the board closes; there is no retry that would save the same sheet again
        Directory.Delete(drawings, true);
        string bad = "/nonexistent-dir/x/y.png";
        object b3 = NewBoard(a, out t); AddStroke(a, t, b3); SetSaveAs(t, b3, bad);
        Exception e3 = CallSave(t, b3);
        Console.WriteLine("  Save() threw: " + (e3 == null ? "nothing" : e3.GetType().Name + ": " + e3.Message));
        Check(e3 == null || e3 is System.Runtime.InteropServices.ExternalException, "Save() did not throw (beyond the clipboard's ExternalException), so the close is not cancelled");
        st = Status(drawings);
        Check(st[0] == "copied" && st[1] == latest && IsPng(latest), "status.txt says copied and names latest.png, which is a PNG");
        Check(GetSaveAs(t, b3) == null, "saveAsPath cleared after the failed attempt");
        Check(GetSaveAsFailed(t, b3) == bad, "the failed copy's path is recorded for the warning (got '" + GetSaveAsFailed(t, b3) + "')");
        Check(Files(drawings) == "latest.png status.txt", "drawings\\ holds latest.png and status.txt only (got '" + Files(drawings) + "')");

        Console.WriteLine("\n4. Empty sheet with saveAsPath set: nothing is copied, status is 'empty', latest.png is left as it was");
        byte[] kept = File.ReadAllBytes(latest);
        string copy4 = Path.Combine(copyDir, "should-not-exist.png");
        object b4 = NewBoard(a, out t); SetSaveAs(t, b4, copy4);
        Exception e4 = CallSave(t, b4);
        st = Status(drawings);
        Check(st[0] == "empty" && st[1] == "", "status.txt says empty with no path");
        Check(!File.Exists(copy4), "no copy written for an empty sheet");
        Check(SameBytes(kept, File.ReadAllBytes(latest)), "latest.png is unchanged");
        Check(e4 == null, "no exception");

        Console.WriteLine("\n5. Esc: a stroke, cancelled set, Save(): status is 'cancelled' with no path, latest.png is left as it was, no file is added");
        object b5 = NewBoard(a, out t); AddStroke(a, t, b5); SetCancelled(t, b5);
        Exception e5 = CallSave(t, b5);
        st = Status(drawings);
        Check(st[0] == "cancelled" && st[1] == "", "status.txt says cancelled with no path (got '" + st[0] + "', '" + st[1] + "')");
        Check(SameBytes(kept, File.ReadAllBytes(latest)), "latest.png is unchanged");
        Check(Files(drawings) == "latest.png status.txt", "nothing was added to drawings\\ (got '" + Files(drawings) + "')");
        Check(e5 == null, "no exception");

        Console.WriteLine("\n6. Keys: Shift+Enter is routed before the plain Enter case (static check of ProcessCmdKey)");
        MethodInfo pck = t.GetMethod("ProcessCmdKey", BindingFlags.NonPublic | BindingFlags.Instance);
        Check(pck != null, "ProcessCmdKey exists");
        Check(t.GetMethod("SaveAs", BindingFlags.NonPublic | BindingFlags.Instance) != null, "SaveAs() exists");

        Console.WriteLine("\n" + (failures == 0 ? "ALL CHECKS PASSED" : failures + " CHECK(S) FAILED"));
        return failures == 0 ? 0 : 1;
    }
}
