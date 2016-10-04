import gccbuild, scriptlike;

void main(string[] args)
{
    auto startTime = Clock.currTime;
    setDefaultPaths();
    if(!handleArguments(args))
        return;

    intializeLog(logFilePath);
    loadSourceConfig(sourceConfig);
    loadBuildConfig(buildConfig);
    setupBuildVariables();
    dumpConfiguration();
    loadMirrors();

    buildToolchain();

    auto dur = Clock.currTime - startTime;
    cleanupToolchain(dur);
    writeln("Total execution time: ", dur.durationToString());
}

bool handleArguments(string[] args)
{

    void setBuildVariable(string opt, string val)
    {
        auto parts = findSplit(val, ":");
        failEnforcec(cast(bool)parts, "Invalid format for build variable: ", val, " usage: --variable=key:val");
        cmdVariables[parts[0]] = parts[2];
    }

    auto helpInformation = getopt(
        args,
        "build", "Build machine triplet", &buildTriplet,
        "host", "Overwrite host machine triplet", &cmdOverwrites.host,
        "target", "Overwrite target machine triplet", &cmdOverwrites.target,
        "mirrors", "File containing mirror urls", (string opt, string val) {mirrorFile = Path(val);},
        "cache", "Path to cache folder", (string opt, string val) {cacheDir = Path(val);},
        "verify-cached-sources", "Verify cached source files", &verifyCachedSources,
        "force-download", "Download even if sources exist", &forceDownload,
        "force-extract", "Extract even if sources already extracted", &forceExtract,
        "num-cpus", "Number of CPUs to use", &numCPUs,
        "skip-target-strip", "Do not strip target libraries", &skipStripLibraries,
        "skip-host-strip", "Do not strip host executables", &skipStripBinaries,
        "keep-build-files", "Do not delete objects after build", &keepBuildFiles,
        "variable", "Set build variable (--variable=key:val)", &setBuildVariable,
        "gcc-file", "Overwrite gcc source filename", &cmdOverwrites.gccFile,
        "gcc-suburl", "Overwrite gcc suburl", &cmdOverwrites.gccSuburl,
        "gcc-md5", "Overwrite gcc file md5", &cmdOverwrites.gccMD5,
        "host-strip", "Command to strip binaries for host", &hostStripCMD
        );

    bool printHelp = false;
    if (!helpInformation.helpWanted)
    {
        switch(args.length)
        {
            case 3:
                buildConfig = Path(args[2]);
                sourceConfig = Path(args[1]);
                mode = BuildMode.all;
                failEnforcec(buildConfig.exists, "Invalid path for build settings file: ", buildConfig);
                failEnforcec(sourceConfig.exists, "Invalid path for sources file: ", sourceConfig);
                break;
            case 4:
                buildConfig = Path(args[3]);
                sourceConfig = Path(args[2]);
                mode = to!BuildMode(args[1]);
                failEnforcec(buildConfig.exists, "Invalid path for build settings file: ", buildConfig);
                failEnforcec(sourceConfig.exists, "Invalid path for sources file: ", sourceConfig);
                break;
            default:
                printHelp = true;
        }
    }

    if (helpInformation.helpWanted || printHelp)
    {
        writeln("gcc-build-script: Build GCC toolchains");
        writeln("Usage: gcc-build-script [command] source.json toolchain.json [options]");
        
        size_t lenShort, lenLong;
        foreach(it; helpInformation.options)
        {
            lenShort = max(lenShort, it.optShort.length);
            lenLong = max(lenLong, it.optLong.length);
        }
        size_t lenBoth = lenShort + lenLong + 3;
        
        writeln("");
        writeln("Commands:");
        writefln("    %-*s%s", lenBoth, "all:", "Perform all steps (default)");
        writefln("    %-*s%s", lenBoth, "download:", "Download sources");
        writefln("    %-*s%s", lenBoth, "extract:", "Extract sources");
        writefln("    %-*s%s", lenBoth, "patch:", "Patch extracted sources");
        writeln("");
        writeln("Options:");
        
        
        foreach(it; helpInformation.options)
        {
            writefln("    %-*s %-*s%s%s", lenShort, it.optShort,
                lenLong, it.optLong,
                it.required ? "  Required: " : "  ", it.help);
        }
        
        return false;
    }

    failEnforcec(mirrorFile.exists, "Mirror file ", mirrorFile, " does not exist");
    failEnforcec(cacheDir.exists, "Cache dir ", cacheDir, " does not exist");

    return true;
}