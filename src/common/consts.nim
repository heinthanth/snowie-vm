import strutils

when
    defined(NimblePkgVersion) and not defined(version):
    const NimblePkgVersion* {.strdefine.} = ""
    const version = NimblePkgVersion
else:
    const version {.strdefine.} = "0.1.0"

when version.strip() != "":
    const versionList = version.strip().split(".", 3)
else:
    const versionList = @["0", "1", "0"]

const
    SNOWIE_VERSION_MAJOR* = versionList[0]
    SNOWIE_VERSION_MINOR* = versionList[1]
    SNOWIE_VERSION_PATCH* = versionList[2]
    SNOWIE_VERSION_STRING* = version.strip()
    SNOWIE_PLATFORM_OS* = hostOS
    SNOWIE_PLATFORM_ARCH* = hostCPU

var
    SNOWIE_STDIN* = stdin
    SNOWIE_STDOUT* = stdout
    SNOWIE_STDERR* = stderr