module gccbuild.console;

import consoled, scriptlike, gccbuild;

void startSection(string text)
{
    static bool first = true;

    if (first)
        first = false;
    else
        writeln();

    writec(FontStyle.bold, Fg.green, "==> ", Fg.initial, text);
    resetFontStyle();
    writecln();

    startSectionLog(text);
}

private void writeError(string text)
{
    enum prefix = "==> ERROR: ";
    writec(FontStyle.bold, Fg.red, prefix, Fg.initial, text);
    resetFontStyle();
    writecln();
    logFile.writeln(prefix, text);
}

void writeBulletPoint(string text)
{
    enum prefix = "  -> ";
    writec(FontStyle.bold, Fg.blue, prefix, Fg.initial, text);
    resetFontStyle();
    writecln();
    logFile.writeln(prefix, text);
}

void failc(T...)(T args)
{
    writeError(text(args));
    SilentFail();
}

void failEnforcec(T...)(bool cond, T args)
{
    if(!cond)
        failc(args);
}

class SilentFail : Exception
{
    private this()
    {
        super(null);
    }

    private static Fail opCall(string file=__FILE__, int line=__LINE__)
    {
        throw cast(SilentFail) cast(void*) SilentFail.classinfo.init;
    }

    override void toString(scope void delegate(in char[]) sink) const
    {
    }
}
