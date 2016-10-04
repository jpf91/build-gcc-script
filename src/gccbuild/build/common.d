module gccbuild.build.common;

import gccbuild, scriptlike;

/**
 * type is used to lookup arguments for the command in the component
 */
void runBuildCommand(string baseCommand, BuildCommand args, string type, string[string] extraVars = string[string].init)
{
    string argString = "";
    string[string] extraEnv;

    if(auto argPtr = type in args.args)
        argString = *argPtr;
    if(auto envPtr = type in args.env)
        extraEnv = *envPtr;

    auto scriptVars = buildVariables.dup;
    foreach(key, val; extraVars)
        scriptVars[key] = val;

    auto cmd = baseCommand ~ " " ~ substituteVars(argString, scriptVars);

    runCollectLog(cmd);
}

string substituteVars(string text, string[string] vars)
{
    auto result = appender!string();

    auto remain = text;
    while(!remain.empty)
    {
        auto parts = remain.findSplit("${");
        result ~= parts[0];
        remain = parts[2];

        if(parts)
        {
            parts = remain.findSplit("}");
            failEnforcec(cast(bool)parts, "Can't find closing } in macro:", text);
            auto val = parts[0] in vars;
            failEnforce(val != null, "Couldn't find replacement value for ", parts[0], " in ", text);
            result ~= *val;
            remain = parts[2];
        }
    }

    return result.data;
}

/**
 * 1) Delete old directory
 * 2) Create directory
 * 3) chdir into directory
 */
auto prepareBuildDir(MainConfig.Component component)
{
    component.buildFolder.tryRmdirRecurse();
    component.buildFolder.tryMkdirRecurse();
    return component.buildFolder.pushCWD();
}

auto pushCWD(Path dir, bool autoPop = true)
{
    auto saveDir = getcwd();
    dir.chdir();
    return RefCounted!(RestoreCWD)(saveDir, autoPop);
}

struct RestoreCWD
{
private:
    Path saveDir;
    bool autoPop;

public:
    ~this()
    {
        if(autoPop)
            saveDir.chdir();
    }
    
    void popCWD()
    {
        saveDir.chdir();
    }
}

string updatePathVar(Path additional)
{
    auto oldPath = environment["PATH"];
    auto newPath = oldPath ~ ":" ~ additional.toString();
    environment["PATH"] = newPath;
    yap("Updated path: ", oldPath, " => ", newPath);
    return oldPath;
}

void restorePathVar(string val)
{
    yap("Restore path: ", val);
    environment["PATH"] = val;
}