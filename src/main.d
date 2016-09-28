import gccbuild, scriptlike;

void main(string[] args)
{
    if(!handleArguments(args))
        return;

    intializeLog(Path("log.txt"));
    loadBuildConfig(buildConfig);
    loadMirrors();

    final switch(mode)
    {
        case BuildMode.all:
            downloadSources();
            break;
        case BuildMode.download:
            downloadSources();
            break;
        case BuildMode.extract:
            break;
        case BuildMode.patch:
            break;
    }
}

bool handleArguments(string[] args)
{
    auto helpInformation = getopt(
        args,
        "build", "Build machine triplet", &buildTriplet,
        "mirrors", "File containing mirror urls", (string opt, string val) {mirrorFile = Path(val);},
        "cache", "Path to cache folder", (string opt, string val) {cacheDir = Path(val);},
        "verify-cached-sources", "Verify cached source files", &verifyCachedSources,
        "fd|force-download", "Download even if sources exist", &forceDownload,
        "force-extract", "Extract even if sources already extracted", &forceExtract,
        );

    bool printHelp = false;
    if (!helpInformation.helpWanted)
    {
        switch(args.length)
        {
            case 2:
                buildConfig = Path(args[1]);
                mode = BuildMode.all;
                failEnforcec(buildConfig.exists, "Invalid path for build settings file: ", buildConfig);
                break;
            case 3:
                buildConfig = Path(args[2]);
                mode = to!BuildMode(args[1]);
                failEnforcec(buildConfig.exists, "Invalid path for build settings file: ", buildConfig);
                break;
            default:
                printHelp = true;
        }
    }

    if (helpInformation.helpWanted || printHelp)
    {
        writeln("gcc-build-script: Build GCC toolchains");
        writeln("Usage: gcc-build-script [command] source.json [options]");
        
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