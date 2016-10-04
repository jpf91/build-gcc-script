module gccbuild.console;

import consoled, scriptlike, gccbuild;

private SysTime startTime;

void startSection(string text, bool log = true)
{
    startTime = Clock.currTime;
    static bool first = true;

    if (first)
        first = false;
    else
        writeln();

    writec(FontStyle.bold, Fg.green, "==> ", Fg.initial, text);
    resetFontStyle();
    writecln();

    if(log)
        startSectionLog(text);
}

void endSection(bool log = true)
{
    auto dur = Clock.currTime - startTime;
    writefln("%*s", consoled.width, "(" ~ dur.durationToString() ~ ")");
    if(log)
        endSectionLog(dur);
}

private void writeError(string text)
{
    enum prefix = "==> ERROR: ";
    writec(FontStyle.bold, Fg.red, prefix, Fg.initial, text);
    resetFontStyle();
    writecln();
    writelnLog(prefix, text);
}

static SysTime bulletStartTime;

void writeBulletPoint(string text)
{
    bulletStartTime = Clock.currTime;
    enum prefix = "  -> ";
    writec(FontStyle.bold, Fg.blue, prefix, Fg.initial, text);
    resetFontStyle();
    writecln();
    writelnLog(prefix, text);
}

void endBulletPoint()
{
    writelnLog("  :  (", Clock.currTime - bulletStartTime, ")");
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

// Duration formatting

string durationToString(Duration dur) nothrow
{
    auto _hnsecs = dur.total!"hnsecs";
    static void appUnitVal(string units)(ref string res, long val) nothrow
    {
        immutable plural = val != 1;
        string unit;
        static if (units == "seconds")
            unit = plural ? "secs" : "sec";
        else static if (units == "msecs")
            unit = "ms";
        else static if (units == "usecs")
            unit = "us";
        else
            unit = plural ? units : units[0 .. $-1];
        res ~= to!string(val);
        res ~= " ";
        res ~= unit;
    }
    
    if (_hnsecs == 0) return "0 hnsecs";
    
    template TT(T...) { alias T TT; }
    alias units = TT!("weeks", "days", "hours", "minutes", "seconds", "msecs", "usecs");
    
    long hnsecs = _hnsecs; string res; uint pos;
    size_t written = 0;
    foreach (unit; units)
    {
        if (auto val = splitUnitsFromHNSecs!unit(hnsecs))
        {
            if(written != 0)
                res ~= ", ";
            appUnitVal!unit(res, val);
            if(++written == 2)
                break;
        }
        if (hnsecs == 0) break;
    }
    if (hnsecs != 0 && written < 2)
    {
        res ~= ", ";
        appUnitVal!"hnsecs"(res, hnsecs);
    }
    return res;
}

long splitUnitsFromHNSecs(string units)(ref long hnsecs) @safe pure nothrow @nogc
    if(units == "weeks" ||
        units == "days" ||
        units == "hours" ||
        units == "minutes" ||
        units == "seconds" ||
        units == "msecs" ||
        units == "usecs" ||
        units == "hnsecs")
{
    immutable value = convert!("hnsecs", units)(hnsecs);
    hnsecs -= convert!(units, "hnsecs")(value);
    
    return value;
}