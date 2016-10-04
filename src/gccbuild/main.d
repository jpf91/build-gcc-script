module gccbuild.main;

import scriptlike, gccbuild;

void buildToolchain()
{
    final switch(mode)
    {
        case BuildMode.all:
            final switch(build.type)
            {
                case ToolchainType.cross:
                case ToolchainType.canadian:
                    downloadSources();
                    extractSources();
                    patchSources();
                    buildHostLibs();

                    startSectionLog("Removing old toolchain directory");
                    toolchainDir.tryRmdirRecurse();
                    endSectionLog();

                    installLinuxHeaders();
                    buildBinutils();

                    startSectionLog("Creating stage1 directory from toolchain directory");
                    toolchainDirStage1.tryRmdirRecurse();
                    runCollectLog("cp -R --reflink=auto " ~ toolchainDir.toString() ~ " " ~ toolchainDirStage1.toString());
                    endSectionLog();

                    buildStage1GCC();
                    detectMultilib();
                    buildGlibc();
                    buildFinalGCC();
                    break;
                case ToolchainType.native:
                    failc("Support for native toolchains not implemented");
                    break;
                case ToolchainType.cross_native:
                    failc("Support for cross-native toolchains not implemented");
                    break;
            }
            break;
        case BuildMode.download:
            downloadSources();
            break;
        case BuildMode.extract:
            extractSources();
            break;
        case BuildMode.patch:
            break;
    }
}