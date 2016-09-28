module gccbuild.log;

import scriptlike;

File logFile;

void writeLogCMD(string text)
{
    foreach(line; text.lineSplitter())
        logFile.writeln("           ", line);
    logFile.flush();
}

void intializeLog(Path path)
{
    void echoLogger(string text)
    {
        logFile.writeln("       ", text);
        logFile.flush();
    }

    scriptlikeEcho = true;
    scriptlikeCustomEcho = &echoLogger;
    logFile = File(path.toString(), "w");
}

void startSectionLog(string text)
{
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