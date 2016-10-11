module gccbuild.config;

import gccbuild, scriptlike, painlessjson, std.json;

BuildMode mode = BuildMode.all;
Path buildConfig, sourceConfig, logFilePath;
string buildTriplet = "x86_64-unknown-linux-gnu";
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
string gdcSourcePath;

@property string hostStrip()
{
    if (!hostStripCMD.empty)
        return hostStripCMD;
    else if (build.type == ToolchainType.native)
        return "strip";
    else
        return build.host ~ "-strip";
}

Path[] patchDirectories;

struct CMDBuildOverwrites
{
    string host, target;
    string gccFile, gccSuburl, gccMD5;
    Nullable!ToolchainType type;
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

@property Path sysrootDirWithPrefix()
{
    return sysrootDir ~ build.relativeSysrootPrefix;
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
    catch (Exception e)
        failc("Couldn't load mirror file ", mirrorFile, ": ", e);
    endSectionLog();
}

void loadSourceConfig(Path file)
{
    startSectionLog("Loading build sources configuration");
    try
        build = fromJSON!MainConfig(file.readText().parseJSON());
    catch (Exception e)
        failc("Couldn't load build sources configuration ", file, ": ", e);
    endSectionLog();
}

void loadBuildConfig(Path file)
{
    startSectionLog("Loading build configuration");
    BuildConfig commands;
    try
        commands = fromJSON!BuildConfig(file.readText().parseJSON());
    catch (Exception e)
        failc("Couldn't load build configuration ", file, ": ", e);

    build.include(commands);
    build.include(cmdOverwrites);

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
    buildVariables["DIR_SYSROOT_WITH_PREFIX"] = sysrootDirWithPrefix.toString();
    buildVariables["DIR_TOOLCHAIN_STAGE1"] = toolchainDirStage1.toString();
    buildVariables["DIR_SYSROOT_STAGE1"] = sysrootDirStage1.toString();
    buildVariables["DIR_SYSROOT_STAGE1_WITH_PREFIX"] = (
        sysrootDirStage1 ~ build.relativeSysrootPrefix).toString();
    buildVariables["TARGET_GCC"] = build.target ~ "-gcc";

    // overwrite from build.json
    static void addConstants(string[string] cst)
    {
        foreach (key, val; cst)
        {
            buildVariables[key] = val;
        }
    }

    addConstants(build.constants);
    final switch (build.type)
    {
    case ToolchainType.cross:
        addConstants(build.constantsCross);
        break;
    case ToolchainType.native:
        addConstants(build.constantsNative);
        break;
    case ToolchainType.cross_native:
        addConstants(build.constantsCrossNative);
        break;
    case ToolchainType.canadian:
        addConstants(build.constantsCanadian);
        break;
    }

    // overwrites from cmd
    foreach (key, val; cmdVariables)
    {
        buildVariables[key] = val;
    }

    foreach (key, val; buildVariables)
    {
        yap(key, "=", val);
    }
    endSectionLog();

    // Setup patch directories
    startSectionLog("Setting patch directories");

    static void addConfPatchDirs(string[] dirs)
    {
        foreach (dir; dirs)
        {
            // Make sure relative Paths are relative to the build config specifying them
            auto path = Path(dir);
            if (!path.isAbsolute)
                path = path.absolutePath(buildConfig.dirName);
            patchDirectories ~= path;
        }
    }

    patchDirectories ~= mainPatchDir;
    addConfPatchDirs(build.localPatchDirs);
    final switch (build.type)
    {
    case ToolchainType.cross:
        addConfPatchDirs(build.localPatchDirsCross);
        break;
    case ToolchainType.native:
        addConfPatchDirs(build.localPatchDirsNative);
        break;
    case ToolchainType.cross_native:
        addConfPatchDirs(build.localPatchDirsCrossNative);
        break;
    case ToolchainType.canadian:
        addConfPatchDirs(build.localPatchDirsCanadian);
        break;
    }
    foreach (dir; patchDirsCMD)
        patchDirectories ~= Path(dir);

    endSectionLog();
}

void dumpConfiguration()
{
    startSection("Dumping configuration");
    writeBulletPoint(mixin(interp!"Type: ${build.type}     Target type: ${build.targetType}"));
    writeBulletPoint(mixin(interp!"Build: ${buildTriplet}"));
    writeBulletPoint(mixin(interp!"Host: ${build.host}"));
    writeBulletPoint(mixin(interp!"Target: ${build.target}"));
    if (build.targetType == HostType.linux)
        writeBulletPoint(mixin(interp!"Kernel ARCH: ${build.arch}"));
    endSection();
}

auto namedFields(T, A...)(ref T instance)
{
    static string generateMixin(string[] fields)
    {
        string result = "return only(";
        foreach (i, entry; fields)
        {
            if (i != 0)
                result ~= ", ";
            result ~= "tuple!(\"name\", \"value\")(\"" ~ entry ~ "\", cast(Component)instance." ~ entry ~ ")";
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
    @SerializedName("constants_native") string[string] constantsNative;
    @SerializedName("constants_cross") string[string] constantsCross;
    @SerializedName("constants_cross_native") string[string] constantsCrossNative;
    @SerializedName("constants_canadian") string[string] constantsCanadian;

    @SerializedName("sysroot_prefix") string sysrootPrefix = "/";
    @SerializedName("patch_dirs") string[] localPatchDirs;
    @SerializedName("patch_dirs_native") string[] localPatchDirsNative;
    @SerializedName("patch_dirs_cross") string[] localPatchDirsCross;
    @SerializedName("patch_dirs_cross_native") string[] localPatchDirsCrossNative;
    @SerializedName("patch_dirs_canadian") string[] localPatchDirsCanadian;

    string type = "";

    BuildCommand gmp, mpfr, mpc, linux, binutils, w32api, gcc;
    GlibcBuildCommand glibc;
    CleanupCommand cleanup;
    @SerializedName("gcc_stage1") BuildCommand gccStage1;
}

struct MainConfig
{
    @SerializeIgnore string host;
    @SerializeIgnore string target;
    @SerializeIgnore string arch;
    @SerializeIgnore string[string] constants;
    @SerializeIgnore string[string] constantsNative;
    @SerializeIgnore string[string] constantsCross;
    @SerializeIgnore string[string] constantsCrossNative;
    @SerializeIgnore string[string] constantsCanadian;

    @SerializeIgnore MultilibEntry[] multilibs;
    @SerializeIgnore string sysrootPrefix;
    @property string relativeSysrootPrefix()
    {
        return sysrootPrefix.relativePath("/");
    }

    @SerializeIgnore ToolchainType type;
    @SerializeIgnore string[] localPatchDirs;
    @SerializeIgnore string[] localPatchDirsNative;
    @SerializeIgnore string[] localPatchDirsCross;
    @SerializeIgnore string[] localPatchDirsCrossNative;
    @SerializeIgnore string[] localPatchDirsCanadian;

    Component mpc, mpfr, gmp, binutils, linux, w32api;
    GCCComponent gcc;
    GlibcComponent glibc;
    // This is a special component: only a addon for glibc, don't build individually
    @SerializedName("glibc_ports") Component glibcPorts;

    @SerializeIgnore CleanupCommand cleanup;

    @property HostType targetType()
    {
        if (target.toLower().canFind("mingw"))
            return HostType.mingw;
        else
            return HostType.linux;
    }

    @property componentRange()
    {
        return this.namedFields!(MainConfig, "mpc", "mpfr", "gmp", "glibc",
            "binutils", "linux", "w32api", "gcc");
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
        constantsNative = config.constantsNative;
        constantsCross = config.constantsCross;
        constantsCrossNative = config.constantsCrossNative;
        constantsCanadian = config.constantsCanadian;
        sysrootPrefix = config.sysrootPrefix;
        localPatchDirs = config.localPatchDirs;
        localPatchDirsNative = config.localPatchDirsNative;
        localPatchDirsCross = config.localPatchDirsCross;
        localPatchDirsCrossNative = config.localPatchDirsCrossNative;
        localPatchDirsCanadian = config.localPatchDirsCanadian;
        cleanup = config.cleanup;

        void trySet(Component comp, BuildCommand com)
        {
            if (comp)
                comp._mainBuildCommand = com;
        }

        trySet(mpc, config.mpc);
        trySet(mpfr, config.mpfr);
        trySet(gmp, config.gmp);
        trySet(glibc, config.glibc);
        trySet(binutils, config.binutils);
        trySet(linux, config.linux);
        trySet(w32api, config.w32api);
        if (gcc)
        {
            gcc._mainBuildCommand = config.gcc;
            gcc._stage1BuildCommand = config.gccStage1;
        }
    }

    void include(CMDBuildOverwrites overwrite)
    {
        void overwriteIfSet(ref string oldVal, string newVal)
        {
            if (!newVal.empty)
                oldVal = newVal;
        }

        overwriteIfSet(host, cmdOverwrites.host);
        overwriteIfSet(target, cmdOverwrites.target);
        overwriteIfSet(gcc.file, cmdOverwrites.gccFile);
        overwriteIfSet(gcc.suburl, cmdOverwrites.gccSuburl);
        overwriteIfSet(gcc.md5, cmdOverwrites.gccMD5);

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

        if (!overwrite.type.isNull)
            type = overwrite.type;
    }
}

class Component
{
private:
    BuildCommand _mainBuildCommand;

public:

    string file, url, md5;
    // Total url is url | mirror ~ suburl | mirror ~ filename
    string suburl;

    @property BuildCommand mainBuildCommand()
    {
        return _mainBuildCommand;
    }

    @SerializeIgnore bool wasExtracted = false;

    @property Path localFile()
    {
        return downloadDir ~this.file;
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

// Whether this component is specified in config file
@property bool isInConfig(Component c)
{
    return c !is null && c.mainBuildCommand !is null;
}

@property bool hasBuildCommands(Component c)
{
    return c.isInConfig && c.mainBuildCommand.matchesBuildType;
}

class GlibcComponent : Component
{
public:
    override @property GlibcBuildCommand mainBuildCommand()
    {
        return cast(GlibcBuildCommand) _mainBuildCommand;
    }
}

class GCCComponent : Component
{
private:
    BuildCommand _stage1BuildCommand;

public:
    @property BuildCommand stage1BuildCommand()
    {
        return _stage1BuildCommand;
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

class BuildCommand
{
    string[] commands;
    string[] variants;
}

@property bool matchesBuildType(BuildCommand cmd)
{
    if (!cmd)
        return false;

    if (cmd.variants.empty)
        return true;

    foreach (variant; cmd.variants)
    {
        if (variant == to!string(build.type))
            return true;
    }
    return false;
}

class GlibcBuildCommand : BuildCommand
{
    @SerializedName("multi_commands") string[][] multiCommands;
}

class CleanupCommand : BuildCommand
{
    @SerializedName("strip_target") string[] stripTarget;
    @SerializedName("strip_host") string[] stripHost;
    string[] remove;
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
