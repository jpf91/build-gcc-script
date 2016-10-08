module gccbuild.main;

import scriptlike, gccbuild;

void buildToolchain()
{
    final switch (mode)
    {
    case BuildMode.all:
        downloadSources();
        extractSources();
        patchSources();
        buildHostLibs();

        startSectionLog("Removing old toolchain directory");
        toolchainDir.tryRmdirRecurse();
        endSectionLog();

        final switch (build.type)
        {
        case ToolchainType.cross:
        case ToolchainType.canadian:
            installLinuxHeaders();
            buildBinutils();

            /**
                     * In a canadian build we don't have to boostrap a stage 1 compiler
                     * as we already have a working $BUILD => $TARGET compiler to compile
                     * the C library
                     */
            if (build.type != ToolchainType.canadian)
            {
                startSectionLog("Creating stage1 directory from toolchain directory");
                toolchainDirStage1.tryRmdirRecurse();
                runCollectLog(
                    "cp -R --reflink=auto " ~ toolchainDir.toString() ~ " " ~ toolchainDirStage1.toString());
                endSectionLog();

                buildStage1GCC();
                detectMultilib();
            }
            else
            {
                /**
                         * We have to ask the $BUILD => $TARGET compiler for supported multilibs,
                         * and this must match with the final GCCs multilib configuration / paths!
                         */
                detectMultilib(build.target ~ "-gcc");
            }
            buildGlibc();
            buildFinalGCC();
            break;
        case ToolchainType.native:
            toolchainDirStage1.tryRmdirRecurse();
            if (build.linux.isInConfig)
                installLinuxHeaders();
            if (build.binutils.isInConfig)
                buildBinutils();
            if (build.glibc.isInConfig)
            {
                buildStage1GCC();
                detectMultilib();
                buildGlibc();
                // For now we do not copy stage1 binutils or glibc to the final toolchain,
                // just use it when building final GCC
                buildFinalGCC();
            }
            else
            {
                buildFinalGCC();
                // Just print the multilib of the final compiler for debugging
                detectMultilib((binDir ~ (build.target ~ "-gcc")).toString());
            }
            break;
        case ToolchainType.cross_native:
            //if binutils ...
            //if stage1
            // buildStage1GCC
            //if glibc...
            // detectMultilib(system-compiler);
            // buildGlibc

            /**
                     * Can't run the built compiler, detect multilib from $BUILD => $TARGET compiler.
                     * For debugging only, but this must match the final compiler multilib configuration,
                     * otherwise the built toolchain will not work correctly.
                     */
            detectMultilib(build.target ~ "-gcc");
            buildFinalGCC();
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
