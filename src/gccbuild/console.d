module gccbuild.console;

import consoled, scriptlike;

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
}

private void writeError(string text)
{
    writec(FontStyle.bold, Fg.red, "==> ERROR: ", Fg.initial, text);
    resetFontStyle();
    writecln();
}

void writeBulletPoint(string text)
{
    writec(FontStyle.bold, Fg.blue, "  -> ", Fg.initial, text);
    resetFontStyle();
    writecln();
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
