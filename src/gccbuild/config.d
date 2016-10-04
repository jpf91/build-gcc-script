module gccbuild.config;

import gccbuild, scriptlike, painlessjson, std.json;

BuildMode mode = BuildMode.all;
Path buildConfig, sourceConfig, logFilePath;
string buildTriplet = "x86_64-pc-linux-gnu";
Path mirrorFile = "mirrors.json";
bool verifyCachedSources = true;
bool forceDownload = false;
bool forceExtract = false;
size_t numCPUs = 1;
Path cacheDir;
string[string] buildVariables;
string[string] cmdVariables;
bool skipStripLibraries = false;
bool skipStripBinaries = false;
bool keepBuildFiles = false;
string hostStripCMD;
string[] patchDirsCMD;

@property string hostStrip()
{
    if(!hostStripCMD.empty)
        return hostStripCMD;
    else
        return build.host ~ "-strip";
}

@property Path[] patchDirectories()
{
    Path[] result;
    result ~= mainPatchDir;
    foreach(dir; build.localPatchDirs)
    {
        // Make sure relative Paths are relative to the build config specifying them
        auto path = Path(dir);
        if(!path.isAbsolute)
            path = path.absolutePath(buildConfig.dirName);
        result ~= path;
    }
    foreach(dir; patchDirsCMD)
        result ~= Path(dir);

    return result;
}

struct CMDBuildOverwrites
{
    string host, target;
    string gccFile, gccSuburl, gccMD5;
}

CMDBuildOverwrites cmdOverwrites;

@property Path sysrootDirStage1()
{
    return toolchainDirStage1 ~ "sysroot";
}

@property Path binDirStage1()
{
    return toolchainDirStage1 ~ "bin";
}

@property Path toolchainDirStage1()
{
    return installDir ~ "stage1";
}

@property Path sysrootDir()
{
    return toolchainDir ~ "sysroot";
}

@property Path binDir()
{
    return toolchainDir ~ "bin";
}

@property Path toolchainDir()
{
    return installDir ~ build.target;
}

@property Path hostlibDir()
{
    return installDir ~ "host";
}

@property Path mainPatchDir()
{
    return cacheDir ~ "patches";
}

@property Path installDir()
{
    return cacheDir ~ "install";
}

@property Path extractDir()
{
    return cacheDir ~ "src";
}

@property Path buildDir()
{
    return cacheDir ~ "build";
}

@property Path downloadDir()
{
    return cacheDir ~ "download";
}

MainConfig build;
string[][string] mirrors;

void setDefaultPaths()
{
    cacheDir = Path("cache").absolutePath;
    logFilePath = Path("build.log").absolutePath;
}

void loadMirrors()
{
    startSectionLog("Loading mirror information");
    try
        mirrors = fromJSON!(typeof(mirrors))(mirrorFile.readText().parseJSON());
    catch(Exception e)
        failc("Couldn't load mirror file ", mirrorFile, ": ", e);
    endSectionLog();
}

void loadSourceConfig(Path file)
{
    startSectionLog("Loading build sources configuration");
    try
        build = fromJSON!MainConfig(file.readText().parseJSON());
    catch(Exception e)
        failc("Couldn't load build sources configuration ", file, ": ", e);
    endSectionLog();
}

void loadBuildConfig(Path file)
{
    startSectionLog("Loading build configuration");
    BuildConfig commands;
    try
        commands = fromJSON!BuildConfig(file.readText().parseJSON());
    catch(Exception e)
        failc("Couldn't load build configuration ", file, ": ", e);

    build.include(commands);
    build.include(cmdOverwrites);

    if (build.target == build.host)
    {
        if (build.host == buildTriplet)
            build.type = ToolchainType.native;
        else
            build.type = ToolchainType.cross_native;
    }
    else
    {
        if (build.host == buildTriplet)
            build.type = ToolchainType.cross;
        else
            build.type = ToolchainType.canadian;
    }
    endSectionLog();
}

void setupBuildVariables()
{
    startSectionLog("Setting build variables");

    buildVariables["NUM_CPU"] = to!string(numCPUs);
    buildVariables["BUILD"] = buildTriplet;
    buildVariables["HOST"] = build.host;
    buildVariables["TARGET"] = build.target;
    buildVariables["ARCH"] = build.arch;
    buildVariables["DIR_GMP_INSTALL"] = (hostlibDir ~ build.gmp.baseDirName).toString();
    buildVariables["DIR_MPFR_INSTALL"] = (hostlibDir ~ build.mpfr.baseDirName).toString();
    buildVariables["DIR_MPC_INSTALL"] = (hostlibDir ~ build.mpc.baseDirName).toString();
    buildVariables["DIR_TOOLCHAIN"] = toolchainDir.toString();
    buildVariables["DIR_SYSROOT"] = sysrootDir.toString();
    buildVariables["DIR_SYSROOT_PREFIX"] = build.sysrootPrefix;
    buildVariables["DIR_SYSROOT_WITH_PREFIX"] = (sysrootDir ~ build.relativeSysrootPrefix).toString();
    buildVariables["DIR_TOOLCHAIN_STAGE1"] = toolchainDirStage1.toString();
    buildVariables["DIR_SYSROOT_STAGE1"] = sysrootDirStage1.toString();
    buildVariables["DIR_SYSROOT_STAGE1_WITH_PREFIX"] = (sysrootDirStage1 ~ build.relativeSysrootPrefix).toString();
    buildVariables["TARGET_GCC"] = build.target ~ "-gcc";

    // overwrite from build.json
    foreach(key, val; build.constants)
    {
        buildVariables[key] = val;
    }
    // overwrites from cmd
    foreach(key, val; cmdVariables)
    {
        buildVariables[key] = val;
    }

    foreach(key, val; buildVariables)
    {
        yap(key, "=", val);
    }
    endSectionLog();
}

void dumpConfiguration()
{
    startSection("Dumping configuration");
    writeBulletPoint(mixin(interp!"Type: ${build.type}     Target type: ${build.targetType}"));
    writeBulletPoint(mixin(interp!"Build: ${buildTriplet}"));
    writeBulletPoint(mixin(interp!"Host: ${build.host}"));
    writeBulletPoint(mixin(interp!"Target: ${build.target}"));
    if(build.targetType == HostType.linux)
        writeBulletPoint(mixin(interp!"Kernel ARCH: ${build.arch}"));
    endSection();
}

auto namedFields(T, A...)(T instance)
{
    static string generateMixin(string[] fields)
    {
        string result = "return only(";
        foreach(i, entry; fields)
        {
            if (i != 0)
                result ~= ", ";
            result ~= "tuple!(\"name\", \"value\")(\"" ~ entry ~ "\", &instance." ~ entry ~ ")";
        }
        result ~= ");";
        return result;
    }
    
    mixin(generateMixin([A]));
}

struct BuildConfig
{
    string host, target, arch;
    string[string] constants;

    @SerializedName("sysroot_prefix") string sysrootPrefix = "/";
    @SerializedName("patch_dirs") string[] localPatchDirs;

    @SerializeIgnore ToolchainType type;

    BuildCommand gmp, mpfr, mpc, linux, binutils, glibc, w32api, gcc;
    @SerializedName("gcc_stage1") BuildCommand gccStage1;
}

struct MainConfig
{
    static struct Component
    {
        string file, url, md5;
        // Total url is url | mirror ~ suburl | mirror ~ filename
        string suburl;

        @SerializeIgnore BuildCommand[string] commands;
        @SerializeIgnore bool wasExtracted = false;

        // Whether this component is specified in config file
        @property bool isInConfig()
        {
            return commands["main"].args.length != 0;
        }

        @property Path localFile()
        {
            return downloadDir ~ this.file;
        }

        @property Path baseDirName()
        {
            return Path(file.stripExt.stripExt);
        }

        Path getSourceFile(Path relFile)
        {
            return sourceFolder ~ relFile;
        }

        @property Path configureFile()
        {
            return getSourceFile(Path("configure"));
        }

        @property Path sourceFolder()
        {
            return extractDir ~ baseDirName;
        }

        @property Path buildFolder()
        {
            return buildDir ~ baseDirName;
        }
    }

    @SerializeIgnore string host;
    @SerializeIgnore string target;
    @SerializeIgnore string arch;
    @SerializeIgnore string[string] constants;
    @SerializeIgnore MultilibEntry[] multilibs;
    @SerializeIgnore string sysrootPrefix;
    @property string relativeSysrootPrefix()
    {
        return sysrootPrefix.relativePath("/");
    }

    @SerializeIgnore ToolchainType type;
    @SerializeIgnore string[] localPatchDirs;

    Component mpc, mpfr, gmp, glibc, binutils, linux, w32api, gcc;
    // This is a special component: only a addon for glibc, don't build individually
    @SerializedName("glibc_ports") Component glibcPorts;

    @property HostType targetType()
    {
        if(target.toLower().canFind("mingw"))
            return HostType.mingw;
        else
            return HostType.linux;
    }

    @property componentRange()
    {
        return this.namedFields!(MainConfig, "mpc", "mpfr", "gmp", "glibc", "binutils", "linux", "w32api", "gcc");
    }

    @property configuredComponents()
    {
        return this.componentRange.filter!(a => a.value.isInConfig);
    }

    void include(BuildConfig config)
    {
        host = config.host;
        target = config.target;
        arch = config.arch;
        constants = config.constants;
        type = config.type;
        sysrootPrefix = config.sysrootPrefix;
        localPatchDirs = config.localPatchDirs;
        
        mpc.commands["main"] = config.mpc;
        mpfr.commands["main"] = config.mpfr;
        gmp.commands["main"] = config.gmp;
        glibc.commands["main"] = config.glibc;
        binutils.commands["main"] = config.binutils;
        linux.commands["main"] = config.linux;
        w32api.commands["main"] = config.w32api;
        gcc.commands["main"] = config.gcc;
        gcc.commands["stage1"] = config.gccStage1;
    }

    void include(CMDBuildOverwrites overwrite)
    {
        void overwriteIfSet(ref string oldVal, string newVal)
        {
            if(!newVal.empty)
                oldVal = newVal;
        }

        overwriteIfSet(host, cmdOverwrites.host);
        overwriteIfSet(target, cmdOverwrites.target);
        overwriteIfSet(gcc.file, cmdOverwrites.gccFile);
        overwriteIfSet(gcc.suburl, cmdOverwrites.gccSuburl);
        overwriteIfSet(gcc.md5, cmdOverwrites.gccMD5);
    }
}

enum ToolchainType
{
    native,
    cross,
    cross_native,
    canadian
}

enum HostType
{
    mingw,
    linux
}

enum BuildMode
{
    all,
    download,
    extract,
    patch
}

struct BuildCommand
{
    alias KeyValue = string[string];
    KeyValue args;
    KeyValue[string] env;
}

struct MultilibEntry
{
    string gccFolder;
    string args;
    string osFolder;
    
    @property bool isDefaultLib()
    {
        return gccFolder == ".";
    }
}