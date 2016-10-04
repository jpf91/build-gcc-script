module gccbuild.log;

import scriptlike;

private File logFile;

void writelnLog(T...)(T args)
{
    if(!logFile.isOpen)
        return;

    logFile.writeln(args);
}

void writeLogCMD(string text)
{
    if(!logFile.isOpen)
        return;

    foreach(line; text.lineSplitter())
        logFile.writeln("           ", line);
    logFile.flush();
}

void intializeLog(Path path)
{
    void echoLogger(string text)
    {
        if(!logFile.isOpen)
            return;

        logFile.writeln("       ", text);
        logFile.flush();
    }

    scriptlikeEcho = true;
    scriptlikeCustomEcho = &echoLogger;
    logFile = File(path.toString(), "w");
}

private SysTime startTime;

void startSectionLog(string text)
{
    if(!logFile.isOpen)
        return;

    startTime = Clock.currTime;
    static bool first = true;
    
    if (first)
        first = false;
    else
    {
        logFile.writeln();
        logFile.writeln();
    }

    logFile.writeln("==> ", text);
}

void endSectionLog()
{
    endSectionLog(Clock.currTime - startTime);
}

void endSectionLog(Duration dur)
{
    if(logFile.isOpen)
        logFile.writefln(":   (%s)", dur);
}

void closeLog()
{
    logFile.close();
}

string runCollectLog(string command)
{
    auto result = tryRunCollectLog(command);
    if(result.status != 0)
        throw new ErrorLevelException(result.status, command, result.output);
    return result.output;
}

auto tryRunCollectLog(string command)
{
    auto result = tryRunCollect(command);
    result.output.writeLogCMD();
    return result;
}