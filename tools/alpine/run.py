"""Run focused Alpine probes, keeping commands and logs for every result."""
import argparse
import json
import pathlib
import platform
import subprocess
import sys

parser = argparse.ArgumentParser()
parser.add_argument("nim")
parser.add_argument("--output", default="/tmp/audit/full")
parser.add_argument("--foreign", default="skip")
parser.add_argument("--only", default="")
args = parser.parse_args()
output = pathlib.Path(args.output)
output.mkdir(parents=True, exist_ok=True)
results = []
report = {"architecture": platform.machine(), "results": results}


def run(name, command, expected=False):
    """Run one command and save its full output and status."""
    logfile = output / (name + ".log")
    with logfile.open("w") as stream:
        try:
            result = subprocess.run(command, stdout=stream,
                                    stderr=subprocess.STDOUT, timeout=180)
            code = result.returncode
        except subprocess.TimeoutExpired:
            code = 124
    passed = code != 0 and code != 124 if expected else code == 0
    results.append({"name": name, "command": command, "exitcode": code,
                    "expected_failure": expected, "passed": passed,
                    "log": logfile.name})
    (output / "results.json").write_text(json.dumps(report, indent=2) + "\n")
    print(("PASS " if passed else "FAIL ") + name, flush=True)
    return passed


sources = sorted(pathlib.Path("tools/alpine/probes").glob("*.nim"))
sources += [pathlib.Path("tests/stdlib/talpineabi.nim"),
            pathlib.Path("tests/stdlib/talpine.nim"),
            pathlib.Path("tests/stdlib/tgetaddrinfo.nim"),
            pathlib.Path("tests/stdlib/tposixscalars.nim"),
            pathlib.Path("tests/stdlib/tssl.nim")]
if args.only:
    names = args.only.split(",")
    sources = [source for source in sources if source.stem in names]
plugin = str(output.resolve() / "plugin.so")
run("build-plugin", ["gcc", "-shared", "-fPIC", "tools/alpine/plugin.c",
                     "-o", plugin])
for source in sources:
    flags = ["-d:ssl"] if source.stem == "tssl" else []
    run(source.stem + "-check",
        [args.nim, "check", "--hints:off", *flags, str(source)])
    for compiler in ("gcc", "clang"):
        for backend in ("c", "cpp"):
            for memory in ("orc", "refc"):
                name = "-".join((source.stem, compiler, backend, memory))
                binary = str(output.resolve() / name)
                command = [args.nim, backend, "--hints:off", "--cc:" + compiler,
                           "--mm:" + memory, "--out:" + binary,
                           "--nimcache:" + str(output / ("cache-" + name))]
                if backend == "c":
                    command += ["--passC:-Werror=implicit-function-declaration",
                                "--passC:-Werror=incompatible-pointer-types"]
                if source.stem == "tencodingsstatic":
                    command += ["--passL:-static"]
                command += flags
                command.append(str(source))
                expected = source.stem == "talpinestdioassign"
                compiled = run(name + "-compile", command, expected)
                if compiled and not expected:
                    execute = [binary]
                    if source.stem == "talpinedns":
                        execute = [sys.executable, "tools/alpine/dns.py", binary]
                    elif source.stem == "talpinedynamic":
                        execute += [plugin, args.foreign]
                    run(name + "-run", execute)
if not args.only:
    for source in ("talpineregex", "staticload"):
        binary = str(output.resolve() / (source + "-static"))
        filename = ("tools/alpine/staticload.nim" if source == "staticload"
                    else "tools/alpine/probes/talpineregex.nim")
        flags = (["--dynlibOverride:pcre", "--passL:-lpcre", "-d:musl"]
                 if source == "talpineregex" else [])
        if run(source + "-static-compile",
               [args.nim, "c", "--hints:off", "--passL:-static",
                "--out:" + binary, *flags, filename]):
            run(source + "-static-run", [binary, plugin])
for compiler in ("gcc", "clang"):
    binary = str(output.resolve() / ("contracts-" + compiler))
    if run("contracts-" + compiler + "-compile",
           [compiler, "-Werror=implicit-function-declaration",
            "-Werror=incompatible-pointer-types", "tools/alpine/contracts.c",
            "-lm", "-o", binary]):
        run("contracts-" + compiler + "-run", [binary])
control = str(output.resolve() / "sanitizer-control")
sanitizers = ["-fsanitize=address,undefined", "-fno-sanitize-recover=all"]
if run("sanitizer-control-compile",
       ["clang", *sanitizers, "tools/alpine/sanitize.c", "-o", control]):
    run("sanitizer-control-run", [control])
for source in ("talpinestreams", "talpinestacks"):
    binary = str(output.resolve() / (source + "-sanitized"))
    command = [args.nim, "c", "--cc:clang", "--hints:off",
               "--out:" + binary, "--passC:" + " ".join(sanitizers),
               "--passL:-fsanitize=address,undefined",
               "tools/alpine/probes/" + source + ".nim"]
    if run(source + "-sanitized-compile", command):
        run(source + "-sanitized-run", [binary])
failures = [result["name"] for result in results if not result["passed"]]
print(json.dumps({"checks": len(results), "failures": failures}), flush=True)
sys.exit(bool(failures))
