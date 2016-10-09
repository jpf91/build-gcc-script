module gccbuild.build.linux;

import scriptlike, gccbuild;

void installLinuxHeaders()
{
    auto comp = build.linux;
    if (!comp.mainBuildCommand.matchesBuildType)
        return;

    startSection("Installing linux headers");

    comp.buildFolder.tryRmdirRecurse();
    runCollectLog(
        "cp -R --reflink=auto " ~ comp.sourceFolder.toString() ~ " " ~ comp.buildFolder.toString());
    auto saveCWD = comp.buildFolder.pushCWD();

    runBuildCommands(comp.mainBuildCommand.commands);

    if (!keepBuildFiles)
        rmdirRecurse(comp.buildFolder);
    endSection();
}
