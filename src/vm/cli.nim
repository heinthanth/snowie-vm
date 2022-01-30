import machine, ../common/consts
import noise, os, strutils, times, strformat

type
    REPL* = object
        vm: SnowieVM

    ReplStatus* = enum
        REPL_EXIT
        REPL_CONTINUE

proc newREPL*(): REPL = REPL()

proc runBuiltinCommands(this: var REPL, cmd: string): ReplStatus =
    case cmd.strip()
    of ".quit", ".exit":
        return REPL_EXIT
    of ".clear", ".cls":
        when defined(windows):
            discard execShellCmd("cls")
        elif defined(macosx):
            discard execShellCmd("clear")
            SNOWIE_STDOUT.write("\ec\e[3J")
            SNOWIE_STDOUT.flushFile()
        else:
            discard execShellCmd("clear")
            SNOWIE_STDOUT.write("\ec")
            SNOWIE_STDOUT.flushFile()
        return REPL_CONTINUE
    else:
        SNOWIE_STDOUT.writeLine("invalid command")
        return REPL_CONTINUE

proc introduceVM() =
    const ascii = [
        ",d88~~\\ 888b    |   ,88~-_   Y88b         / 888 888~~",
        "8888    |Y88b   |  d888   \\   Y88b       /  888 888___",
        "`Y88b   | Y88b  | 88888    |   Y88b  e  /   888 888",
        " `Y88b, |  Y88b | 88888    |    Y88bd8b/    888 888",
        "   8888 |   Y88b|  Y888   /      Y88Y8Y     888 888",
        "\\__88P' |    Y888   `88_-~        Y  Y      888 888___"].join("\n")
    let currentYear = now().year
    const versionString =
        fmt"SnowieVM v{SNOWIE_VERSION_STRING} ( {SNOWIE_PLATFORM_OS} / {SNOWIE_PLATFORM_ARCH} )"
    SNOWIE_STDOUT.writeLine("\n", ascii, "\n")
    SNOWIE_STDOUT.writeLine("$#$#" % [versionString,
        when not defined(release): " ( debug )" else: ""])
    SNOWIE_STDOUT.writeLine(
        "(c) 2021$# Hein Thant Maung Maung. Licensed under BSD-2-CLAUSE.\n" %
        [if currentYear == 2021: "" else: " - " & $currentYear])

proc run*(this: var REPL) =
    introduceVM()

    var
        linenoise = Noise.init()
        shouldExit: bool
        linenoiseOk: bool

    linenoise.setPrompt("snowie > ")
    while true:
        while true:
            linenoiseOk = linenoise.readLine()
            if not linenoiseOk:
                break # something went wrong
            let currentLine = linenoise.getLine()
            # skip new lines
            if currentLine.len <= 0: continue

            # reset shouldExit status
            shouldExit = false
            linenoise.historyAdd(currentLine)

            case this.runBuiltinCommands(currentLine)
            of REPL_CONTINUE:
                continue
            of REPL_EXIT:
                shouldExit = true
                break

        # re-ask again for Ctrl-C
        case linenoise.getKeyType():
        of ktCtrlD:
            break
        of ktCtrlC:
            # break if ^C is pressed again
            if shouldExit: break
            SNOWIE_STDOUT.writeLine(
                "\nWanna exit? Press ^C again or ^D or use .exit command.\n")
            shouldExit = true
        elif shouldExit: break
        elif not linenoiseOk:
            SNOWIE_STDERR.writeLine(
                "\nSomething went wrong while reading input.\n")
            return
        else: continue # don't know - I think should not reachable

    # last message
    SNOWIE_STDOUT.writeLine("\nThanks! See u later!\n")
