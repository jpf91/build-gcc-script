module main;
import scriptlike;


// Standard PATH + build compiler
string basePathEnv;
string gccVersion;
Path installDir;
Path sourceConfig;
Path resultBase;
Path gdcRepo;
string fullGCCVersion;
string dmdFE;
string baseArgs;
string pkgVersion;
string gitName;

void main(string[] args)
{
    scriptlikeEcho = true;
    setupVariables(args);

    build();
}

void build()
{    
    /**
     * x86_64-unknown-linux host
     */
    // BUILD => x86_64-unknown-linux-gnu target compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/x86_64/linux-ml.json";
        toolchain.host = "x86_64-unknown-linux-gnu";
        toolchain.target = "x86_64-unknown-linux-gnu";
        toolchain.installNativeGDMD = false;
        toolchain.installCompiler = true;
        toolchain.archivePostfix = "sysrooted";
        toolchain.archiveNative = true;
        toolchain.extraArgs = "--type=cross --target-strip=strip " ~ defaultHostArgs(toolchain.host);
        toolchain.extraPaths = [];
        toolchain.build();
    }
    // BUILD => arm-unknown-linux-gnueabihf target compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/arm-ml/linux-ml.json";
        toolchain.host = "x86_64-unknown-linux-gnu";
        toolchain.target = "arm-unknown-linux-gnueabihf";
        toolchain.installNativeGDMD = false;
        toolchain.installCompiler = true;
        toolchain.archiveNative = false;
        toolchain.extraArgs = defaultHostArgs(toolchain.host);
        toolchain.extraPaths = [];
        toolchain.build();
    }
    // BUILD => x86_64-unknown-linux-gnu native compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/x86_64/linux-ml.json";
        toolchain.host = "x86_64-unknown-linux-gnu";
        toolchain.target = "x86_64-unknown-linux-gnu";
        toolchain.installNativeGDMD = true;
        toolchain.installCompiler = false;
        toolchain.archiveNative = true;
        toolchain.extraArgs = "--host-strip=strip --variable=HOST_TOOLS: --variable=TARGET_TOOLS:";
        toolchain.extraPaths = [hostCompilerBinPath2(toolchain.host)];
        toolchain.build();
    }


    /**
     * i686-unknown-linux-gnu host
     */
    // i686-unknown-linux-gnu => i686-unknown-linux-gnu native compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/i686/linux.json";
        toolchain.host = "i686-unknown-linux-gnu";
        toolchain.target = "i686-unknown-linux-gnu";
        toolchain.installNativeGDMD = true;
        toolchain.installCompiler = false;
        toolchain.archiveNative = true;
        toolchain.extraArgs = "--host-strip=x86_64_host-unknown-linux-gnu-strip --target-gcc='multi-wrapper x86_64-unknown-linux-gnu-gcc -m32'";
        toolchain.extraPaths = [hostCompilerBinPath("x86_64-unknown-linux-gnu"), targetCompilerBinPath("x86_64-unknown-linux-gnu")];
        toolchain.build();
    }
    
    /**
     * x86_64-w64-mingw32 host
     */
    // x86_64-w64-mingw32 => x86_64-unknown-linux-gnu canadian compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/x86_64/linux-ml.json";
        toolchain.host = "x86_64-w64-mingw32";
        toolchain.target = "x86_64-unknown-linux-gnu";
        toolchain.installNativeGDMD = false;
        toolchain.installCompiler = false;
        toolchain.archiveNative = false;
        toolchain.extraArgs = "--target-strip=strip " ~ defaultHostArgs(toolchain.host);
        toolchain.extraPaths = [hostCompilerBinPath(toolchain.host), targetCompilerBinPath(toolchain.target)];
        toolchain.build();
    }
    // x86_64-w64-mingw32 => arm-unknown-linux-gnueabihf canadian compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/arm-ml/linux-ml.json";
        toolchain.host = "x86_64-w64-mingw32";
        toolchain.target = "arm-unknown-linux-gnueabihf";
        toolchain.installNativeGDMD = false;
        toolchain.installCompiler = false;
        toolchain.archiveNative = false;
        toolchain.extraArgs = defaultHostArgs(toolchain.host);
        toolchain.extraPaths = [hostCompilerBinPath(toolchain.host), targetCompilerBinPath(toolchain.target)];
        toolchain.build();
    }
    
    /**
     * i686-w64-mingw32 host
     */
    // i686-w64-mingw32 => x86_64-unknown-linux-gnu canadian compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/x86_64/linux-ml.json";
        toolchain.host = "i686-w64-mingw32";
        toolchain.target = "x86_64-unknown-linux-gnu";
        toolchain.installNativeGDMD = false;
        toolchain.installCompiler = false;
        toolchain.archiveNative = false;
        toolchain.extraArgs = "--target-strip=strip " ~ defaultHostArgs(toolchain.host);
        toolchain.extraPaths = [hostCompilerBinPath(toolchain.host), targetCompilerBinPath(toolchain.target)];
        toolchain.build();
    }
    // i686-w64-mingw32 => arm-unknown-linux-gnueabihf canadian compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/arm-ml/linux-ml.json";
        toolchain.host = "i686-w64-mingw32";
        toolchain.target = "arm-unknown-linux-gnueabihf";
        toolchain.installNativeGDMD = false;
        toolchain.installCompiler = false;
        toolchain.archiveNative = false;
        toolchain.extraArgs = defaultHostArgs(toolchain.host);
        toolchain.extraPaths = [hostCompilerBinPath(toolchain.host), targetCompilerBinPath(toolchain.target)];
        toolchain.build();
    }

    /**
     * arm-unknown-linux-gnueabi host
     */
    // arm-unknown-linux-gnueabi => arm-unknown-linux-gnueabi native compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/arm/linux.json";
        toolchain.host = "arm-unknown-linux-gnueabi";
        toolchain.target = "arm-unknown-linux-gnueabi";
        toolchain.installNativeGDMD = true;
        toolchain.installCompiler = false;
        toolchain.archiveNative = true;
        toolchain.extraArgs = "--target-gcc='multi-wrapper arm-unknown-linux-gnueabihf -mfloat-abi=soft' --host-strip=arm-unknown-linux-gnueabihf-strip --target-strip=arm-unknown-linux-gnueabihf-strip";
        toolchain.extraPaths = [hostCompilerBinPath("arm-unknown-linux-gnueabihf"), targetCompilerBinPath("arm-unknown-linux-gnueabihf")];
        toolchain.build();
    }
    // arm-unknown-linux-gnueabihf => arm-unknown-linux-gnueabihf native compiler
    {
        ToolchainConfig toolchain;
        toolchain.buildConfig = "configs/armhf/linux.json";
        toolchain.host = "arm-unknown-linux-gnueabihf";
        toolchain.target = "arm-unknown-linux-gnueabihf";
        toolchain.installNativeGDMD = true;
        toolchain.installCompiler = false;
        toolchain.archiveNative = true;
        toolchain.extraArgs = "--target-gcc='multi-wrapper arm-unknown-linux-gnueabihf'";
        toolchain.extraPaths = [hostCompilerBinPath("arm-unknown-linux-gnueabihf"), targetCompilerBinPath("arm-unknown-linux-gnueabihf")];
        toolchain.build();
    }
}

void setupVariables(string[] args)
{
    gccVersion = args[1];
    basePathEnv = environment["PATH"];
    installDir = Path("/home/build/share/cache/install/");
    sourceConfig = Path("/home/build/share/configs/sources-${gccVersion}.json");
    resultBase = Path("/home/build/share/result") ~ gccVersion;
    fullGCCVersion = args[2]; // TODO: read from source config
    gitName = args[3];
    dmdFE = "2.068.2";
    gdcRepo = Path("/home/build/share/GDC");
    string date = strip(runCollect("date +%Y%m%d"));
    pkgVersion = mixin(interp!"--variable=PKGVERSION:\"gdcproject.org ${date}-${gitName}\"");
    baseArgs = mixin(interp!"--force-extract --num-cpus=4 --gdc-src=${gdcRepo} --mirrors=configs/mirrors.json '${pkgVersion}'");
    sourceConfig = Path(mixin(interp!"configs/sources-${gccVersion}.json"));
}

struct ToolchainConfig
{
    // Main configuration file to build compiler
    string buildConfig;
    
    // Host triplet to build for
    string host;
    
    // Target triplet
    string target;
    
    // Install a GDMD for a native compiler (search LD, AR in PATH)
    bool installNativeGDMD;
    
    // Install this compiler locally to be used as a requiredTargetCompiler
    bool installCompiler;
    
    // Postfix to use when generating the result archive
    string archivePostfix;
    
    // Whether the archive name should be for a native compiler
    bool archiveNative;
    
    // extra arguments to pass to gcc-build-script
    string extraArgs;
    
    // extra directories to add to PATH
    string[] extraPaths;
    
    
    void build()
    {
        // Setup filename
        auto isMinGWHost = host.canFind("mingw");

        string fileName = mixin(interp!"gdc-${fullGCCVersion}+${dmdFE}");
        if (!archiveNative)
            fileName ~= "-" ~ target;
        if (!archivePostfix.empty)
            fileName ~= "_" ~ archivePostfix;
        if (isMinGWHost)
            fileName ~= ".7z";
        else
            fileName ~= ".tar.xz";
        
        // Some variables
        auto targetDir = installDir ~ target;
        auto targetKeepPath = targetCompilerPath(target);
        auto resultDir = resultBase ~ host;
        auto resultFile = resultDir ~ fileName;
        
        string gdmd = "gdmd";
        if (installNativeGDMD)
            gdmd ~= "_native";
        if (isMinGWHost)
            gdmd ~= ".exe";
        
        // Setup PATH
        string path = basePathEnv;
        // Always add build compiler PATH
        if(!extraPaths.canFind(hostCompilerBinPath("x86_64-unknown-linux-gnu")))
            path ~= ":" ~ hostCompilerBinPath("x86_64-unknown-linux-gnu");
        foreach(entry; extraPaths)
        {
            path ~= ":" ~ entry;
        }
        environment["PATH"] = path;
        yapFunc("Setting path to ", path);
        
        
        
        // Build the compiler
        run(mixin(interp!"gcc-build-script ${sourceConfig} ${buildConfig} ${baseArgs} ${extraArgs}"));
        
        // Install GDMD & create archive
        pushd("cache/install");
        tryMkdirRecurse(resultDir);
        tryRemove(resultFile);
        run(mixin(interp!"install-gdmd ${targetDir} ${gccVersion} ${host} ${gdmd}"));
        if (isMinGWHost)
            run(mixin(interp!"7zr a '${resultFile}' ${target}"));
        else
            run(mixin(interp!"tar -cf - '${target}' | xz -9 -c - > '${resultFile}'"));
        
        if (installCompiler)
        {
            tryRmdirRecurse(targetKeepPath);
            run(mixin(interp!"mv ${target} ${targetKeepPath}"));
        }
        else
        {
            tryRmdirRecurse(target);
        }
        popd();
    }
}

string defaultHostArgs(string host)
{
    auto parts = host.findSplit("-");
    string hostPrefix = mixin(interp!"${parts[0]}_host-${parts[2]}");
    return mixin(interp!"--host-strip=${hostPrefix}-strip --variable=HOST_TOOLPREFIX:${hostPrefix} --host=${host}");
}

string hostCompilerBinPath(string host)
{
    return mixin(interp!"/home/build/share/host-toolchains/${host}/xbin");
}
string hostCompilerBinPath2(string host)
{
    return mixin(interp!"/home/build/share/host-toolchains/${host}/bin");
}
string targetCompilerPath(string target)
{
    return mixin(interp!"/home/build/share/target-toolchains/${target}");
}
string targetCompilerBinPath(string target)
{
    return targetCompilerPath(target) ~ "/bin";
}

// Helper functions
void pushd(string dir)
{
    pushd(Path(dir));
}

string[] dirStack;

void pushd(Path dir)
{
    dirStack ~= ".".absolutePath();
    yapFunc(dir.toString());
    chdir(dir.toString());
}

void popd()
{
    if (dirStack.length > 0)
    {
        auto ndir = dirStack[$ - 1];
        dirStack = dirStack[0 .. $ - 1];
        yapFunc(ndir);
        chdir(ndir);
    }
}