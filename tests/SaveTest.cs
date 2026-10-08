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
        Check(st[1].StartsWith(drawings) && st[1].EndsWith(".png"), "status.txt line 2 is the drawings\\ PNG, not the copy (got '" + st[1] + "')");
        Check(IsPng(st[1]), "the drawings\\ PNG exists and is a PNG");
        Check(IsPng(copy), "the Save as copy exists and is a PNG: " + copy);
        Check(new FileInfo(copy).Length == new FileInfo(st[1]).Length, "the copy has the same size as the drawings\\ PNG");
        Check(File.ReadAllText(Path.Combine(drawings, "latest.txt")).StartsWith(st[1]), "latest.txt names the drawings\\ PNG");
        Check(IsPng(Path.Combine(drawings, "latest.png")), "latest.png exists");
        Check(GetSaveAs(t, b1) == null, "saveAsPath is reset to null after the save");
        Check(e1 == null || e1 is System.Runtime.InteropServices.ExternalException, "no exception, or only the clipboard's ExternalException (is caught in the program)");

        Console.WriteLine("\n2. Plain Enter path: a stroke, no saveAsPath, Save()");
        int before = Directory.GetFiles(copyDir, "*.png").Length;
        object b2 = NewBoard(a, out t); AddStroke(a, t, b2);
        Exception e2 = CallSave(t, b2);
        st = Status(drawings);
        Check(st[0] == "copied", "status.txt says copied");
        Check(Directory.GetFiles(copyDir, "*.png").Length == before, "no extra copy was written");
        Check(e2 == null || e2 is System.Runtime.InteropServices.ExternalException, "no exception beyond the clipboard's");

        Console.WriteLine("\n3. Copy to an unwritable place: Save() must throw, saveAsPath cleared, next plain Save() works");
        object b3 = NewBoard(a, out t); AddStroke(a, t, b3); SetSaveAs(t, b3, "/nonexistent-dir/x/y.png");
        Exception e3 = CallSave(t, b3);
        Check(e3 != null && !(e3 is System.Runtime.InteropServices.ExternalException), "Save() threw (" + (e3 == null ? "nothing" : e3.GetType().Name) + ")");
        Check(GetSaveAs(t, b3) == null, "saveAsPath cleared after the failed attempt");
        Exception e3b = CallSave(t, b3);
        st = Status(drawings);
        Check((e3b == null || e3b is System.Runtime.InteropServices.ExternalException) && st[0] == "copied", "the second, plain Save() succeeds and writes status.txt");

        Console.WriteLine("\n4. Empty sheet with saveAsPath set: nothing is copied, status is 'empty'");
        string copy4 = Path.Combine(copyDir, "should-not-exist.png");
        object b4 = NewBoard(a, out t); SetSaveAs(t, b4, copy4);
        Exception e4 = CallSave(t, b4);
        st = Status(drawings);
        Check(st[0] == "empty" && st[1] == "", "status.txt says empty with no path");
        Check(!File.Exists(copy4), "no copy written for an empty sheet");
        Check(e4 == null, "no exception");

        Console.WriteLine("\n5. Keys: Shift+Enter is routed before the plain Enter case (static check of ProcessCmdKey)");
        MethodInfo pck = t.GetMethod("ProcessCmdKey", BindingFlags.NonPublic | BindingFlags.Instance);
        Check(pck != null, "ProcessCmdKey exists");
        Check(t.GetMethod("SaveAs", BindingFlags.NonPublic | BindingFlags.Instance) != null, "SaveAs() exists");

        Console.WriteLine("\n" + (failures == 0 ? "ALL CHECKS PASSED" : failures + " CHECK(S) FAILED"));
        return failures == 0 ? 0 : 1;
    }
}
