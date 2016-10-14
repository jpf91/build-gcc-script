module main;
import std.stdio, std.process;

int main(string[] args)
{
    if (args.length < 2)
        return 1;

    auto app = args[1];
    foreach (arg; args[2 .. $])
    {
        switch (arg)
        {
        case "--print-multi-lib":
        case "-print-multi-lib":
            writeln(".;");
            return 0;
        case "--print-multi-os-dir":
        case "--print-multi-os-directory":
        case "-print-multi-os-directory":
            writeln("../lib");
            return 0;
        case "--print-multi-dir":
        case "--print-multi-directory":
        case "-print-multi-directory":
            writeln(".");
            return 0;
        default:
            break;
        }
    }

    return spawnProcess(args[1 .. $]).wait();
}
