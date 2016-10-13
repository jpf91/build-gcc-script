module gccbuild.build.gcc;

import scriptlike, gccbuild;

void buildStage1GCC()
{
    auto comp = build.gcc;
    if (!comp.stage1BuildCommand.matchesBuildType)
        return;
    startSection("Building stage 1 gcc");
    auto saveCWD = comp.prepareBuildDir();
    auto oldPath = updatePathVar(binDirStage1);

    runBuildCommands(comp.stage1BuildCommand.commands, ["CONFIGURE" : comp.configureFile.toString()]);
    restorePathVar(oldPath);
    if (!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}

void detectMultilib()
{
    auto oldPath = updatePathVar(binDirStage1);
    detectMultilib(build.target ~ "-gcc");
    restorePathVar(oldPath);
}

void detectMultilib(string compiler)
{
    startSection("Detecting available multilibs");

    auto output = runCollectLog(compiler ~ " --print-multi-lib");
    foreach (line; output.lineSplitter)
    {
        MultilibEntry entry;
        auto parts = line.findSplit(";");
        failEnforcec(cast(bool) parts, "Invalid format returned from --print-multi-lib",
            line);
        entry.gccFolder = parts[0];
        entry.args = parts[2].splitter("@").filter!(a => !a.empty).map!(a => "-" ~ a).join(" ");

        auto output2 = runCollectLog(compiler ~ " --print-multi-os-dir " ~ entry.args);
        entry.osFolder = output2.strip();
        build.multilibs ~= entry;
    }

    if (build.multilibs.length == 1 && build.multilibs[0].isDefaultLib)
        writeBulletPoint("No multilib support detected");
    else
    {
        foreach (lib; build.multilibs)
        {
            writeBulletPoint(
                "args='" ~ lib.args ~ "' osDir='" ~ lib.osFolder ~ "' gccDir='" ~ lib.gccFolder
                ~ "'");
        }
    }
    endSection();
}

void buildFinalGCC()
{
    auto comp = build.gcc;
    if (!comp.mainBuildCommand.matchesBuildType)
        return;
    startSection("Building final gcc");
    auto saveCWD = comp.prepareBuildDir();

    // Native builds need the newly build binutils in PATH
    string oldPath;
    if(build.type == ToolchainType.native || build.type == ToolchainType.cross)
        oldPath = updatePathVar(binDir);

    runBuildCommands(comp.mainBuildCommand.commands, ["CONFIGURE" : comp.configureFile.toString()]);

    if(build.type == ToolchainType.native || build.type == ToolchainType.cross)
        restorePathVar(oldPath);

    if (!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}
