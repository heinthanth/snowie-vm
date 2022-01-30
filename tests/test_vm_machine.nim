import unittest
import vm/[machine, instructions]

suite "vm/machine.nim - general test":
    test "create a virtual machine":
        # LOAD $0 #0
        var vm = newSnowieVM(@[0'u8, 0, 0, 0])
        check(vm.program == @[0'u8, 0, 0, 0])
        for register in vm.registers: check(register == 0)

    test "program: illegal instruction":
        # IGL
        var vm = newSnowieVM(@[200'u8, 0, 0, 0])
        check(vm.run() == VM_EXIT_ILLEGAL)
        check(vm.specRegisters.pc == 1)

    test "program: incomplete instructions":
        # LOAD $0 256
        var vm = newSnowieVM(@[0'u8, 0, 1, 0])
        check(vm.run() == VM_EXIT_ILGLSEQ)
        check(vm.specRegisters.pc == 4)

suite "vm/machine.nim - opcode test":
    test "opcode test: 'HALT'":
        # HLT $0
        var vm = newSnowieVM(@[u8(OP_HALT), 0, 0, 0])
        vm.registers[0] = 125
        check(vm.run() == VM_EXIT_SUCCESS)
        check(vm.specRegisters.exitCode == 125)
        check(vm.specRegisters.pc == 2)

    test "opcode test: 'LOAD'":
        var vm = newSnowieVM()
        # LOAD $0 #500
        # HALT $0
        vm.program = @[u8(OP_LOAD), 0, 1, 244, u8(OP_HALT), 0, 0, 0]
        check(vm.run() == VM_EXIT_SUCCESS)
        check(vm.registers[0] == 500)
        check(vm.specRegisters.pc == 6)
        check(vm.specRegisters.exitCode == 500)

    test "opcode test: 'ADD'":
        var vm = newSnowieVM()
        # LOAD $0 #500
        # LOAD $1 #500
        # ADD $0 $1 $2
        # HALT $2
        vm.program = @[
          u8(OP_LOAD), 0, 1, 244, u8(OP_LOAD), 1, 1, 244,
          u8(OP_ADD), 0, 1, 2, u8(OP_HALT), 2, 0, 0]
        check(vm.run() == VM_EXIT_SUCCESS)
        check(vm.registers[2] == 1000)
        check(vm.specRegisters.exitCode == 1000)
        check(vm.specRegisters.pc == 14)

    test "opcode test: 'SUB'":
        var vm = newSnowieVM()
        # LOAD $0 #500
        # LOAD $1 #500
        # SUB $0 $1 $2
        # HALT $2
        vm.program = @[
          u8(OP_LOAD), 0, 1, 244, u8(OP_LOAD), 1, 1, 244,
          u8(OP_SUB), 0, 1, 2, u8(OP_HALT), 2, 0, 0]
        check(vm.run() == VM_EXIT_SUCCESS)
        check(vm.registers[2] == 0)
        check(vm.specRegisters.exitCode == 0)
        check(vm.specRegisters.pc == 14)

    test "opcode test: 'MUL'":
        var vm = newSnowieVM()
        # LOAD $0 #500
        # LOAD $1 #500
        # MUL $0 $1 $2
        # HALT $2
        vm.program = @[
          u8(OP_LOAD), 0, 1, 244, u8(OP_LOAD), 1, 1, 244,
          u8(OP_MUL), 0, 1, 2, u8(OP_HALT), 2, 0, 0]
        check(vm.run() == VM_EXIT_SUCCESS)
        check(vm.registers[2] == 250000)
        check(vm.specRegisters.exitCode == 250000)
        check(vm.specRegisters.pc == 14)

    test "opcode test: 'DIV'":
        var vm = newSnowieVM()
        # LOAD $0 #229
        # LOAD $1 #64
        # DIV $0 $1 $2
        # HALT $2
        vm.program = @[
          u8(OP_LOAD), 0, 0, 229, u8(OP_LOAD), 1, 0, 64,
          u8(OP_DIV), 0, 1, 2, u8(OP_HALT), 2, 0, 0]
        check(vm.run() == VM_EXIT_SUCCESS)
        check(vm.registers[2] == 3)
        check(vm.specRegisters.exitCode == 3)
        check(vm.specRegisters.reminder == 37)
        check(vm.specRegisters.pc == 14)

    test "opcode test: 'MOD'":
        var vm = newSnowieVM()
        # LOAD $0 #229
        # LOAD $1 #64
        # DIV $0 $1 $2
        # HALT $2
        vm.program = @[
          u8(OP_LOAD), 0, 0, 229, u8(OP_LOAD), 1, 0, 64,
          u8(OP_MOD), 0, 1, 2, u8(OP_HALT), 2, 0, 0]
        check(vm.run() == VM_EXIT_SUCCESS)
        check(vm.registers[2] == 37)
        check(vm.specRegisters.exitCode == 37)
        check(vm.specRegisters.pc == 14)

    test "opcode test: 'JMP'":
        var vm = newSnowieVM()
        # LOAD $0 #8
        # JMP $0
        vm.program = @[u8(OP_LOAD), 0, 0, 8, u8(OP_JMP), 0, 0, 0]
        check(vm.execOneStep() == VM_CONT_EXECUTE)
        check(vm.execOneStep() == VM_CONT_EXECUTE)
        check(vm.specRegisters.pc == 8)
        check(vm.execOneStep() == VM_EXIT_ILGLSEQ)

    test "opcode test: 'FJMP'":
        var vm = newSnowieVM()
        # LOAD $0 20
        vm.program = @[u8(OP_LOAD), 0, 0, 20, u8(OP_FJMP), 0, 0, 0]
        check(vm.execOneStep() == VM_CONT_EXECUTE)
        check(vm.execOneStep() == VM_CONT_EXECUTE)
        check(vm.specRegisters.pc == 26)
        check(vm.execOneStep() == VM_EXIT_ILGLSEQ)

    test "opcode test: 'RJMP'":
        var vm = newSnowieVM()
        # LOAD $0 20
        vm.program = @[u8(OP_LOAD), 0, 0, 20, u8(OP_RJMP), 0, 0, 0]
        check(vm.execOneStep() == VM_CONT_EXECUTE)
        check(vm.execOneStep() == VM_CONT_EXECUTE)
        check(vm.specRegisters.pc == high(uint) - 13)
        check(vm.execOneStep() == VM_EXIT_ILGLSEQ)

    test "opcode test: 'EQ'":
        var vm = newSnowieVM()
        vm.registers[0] = 8
        vm.registers[1] = 8
        vm.program = @[u8(OP_EQ), 0, 1, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 8
        vm.registers[1] = 10
        discard vm.execOneStep()
        check(not vm.specRegisters.zero)

    test "opcode test: 'NE'":
        var vm = newSnowieVM()
        vm.registers[0] = 8
        vm.registers[1] = 10
        vm.program = @[u8(OP_NE), 0, 1, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 8
        vm.registers[1] = 8
        discard vm.execOneStep()
        check(not vm.specRegisters.zero)

    test "opcode test: 'LT'":
        var vm = newSnowieVM()
        vm.registers[0] = 4
        vm.registers[1] = 8
        vm.program = @[u8(OP_LT), 0, 1, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 8
        vm.registers[1] = 8
        discard vm.execOneStep()
        check(not vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 16
        vm.registers[1] = 8
        discard vm.execOneStep()
        check(not vm.specRegisters.zero)

    test "opcode test: 'GT'":
        var vm = newSnowieVM()
        vm.registers[0] = 8
        vm.registers[1] = 4
        vm.program = @[u8(OP_GT), 0, 1, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 8
        vm.registers[1] = 8
        discard vm.execOneStep()
        check(not vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 8
        vm.registers[1] = 16
        discard vm.execOneStep()
        check(not vm.specRegisters.zero)

    test "opcode test: 'LE'":
        var vm = newSnowieVM()
        vm.registers[0] = 4
        vm.registers[1] = 8
        vm.program = @[u8(OP_LE), 0, 1, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 8
        vm.registers[1] = 8
        discard vm.execOneStep()
        check(vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 16
        vm.registers[1] = 8
        discard vm.execOneStep()
        check(not vm.specRegisters.zero)

    test "opcode test: 'GE'":
        var vm = newSnowieVM()
        vm.registers[0] = 8
        vm.registers[1] = 4
        vm.program = @[u8(OP_GE), 0, 1, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 8
        vm.registers[1] = 8
        discard vm.execOneStep()
        check(vm.specRegisters.zero)
        vm.specRegisters.pc = 0
        vm.registers[0] = 8
        vm.registers[1] = 16
        discard vm.execOneStep()
        check(not vm.specRegisters.zero)

    test "opcode test: 'JZ'":
        var vm = newSnowieVM()
        vm.registers[0] = 20
        vm.specRegisters.zero = true
        vm.program = @[u8(OP_JZ), 0, 0, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 20)
        vm.specRegisters.pc = 0
        vm.specRegisters.zero = false
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 2)

    test "opcode test: 'JNZ'":
        var vm = newSnowieVM()
        vm.registers[0] = 20
        vm.program = @[u8(OP_JNZ), 0, 0, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 20)
        vm.specRegisters.pc = 0
        vm.specRegisters.zero = true
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 2)

    test "opcode test: 'FJZ'":
        var vm = newSnowieVM()
        vm.registers[0] = 20
        vm.specRegisters.zero = true
        vm.program = @[u8(OP_FJZ), 0, 0, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 22)
        vm.specRegisters.pc = 0
        vm.specRegisters.zero = false
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 2)

    test "opcode test: 'RJZ'":
        var vm = newSnowieVM()
        vm.registers[0] = 20
        vm.specRegisters.zero = true
        vm.program = @[u8(OP_RJZ), 0, 0, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.pc == high(uint) - 17)
        vm.specRegisters.pc = 0
        vm.specRegisters.zero = false
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 2)

    test "opcode test: 'FJNZ'":
        var vm = newSnowieVM()
        vm.registers[0] = 20
        vm.program = @[u8(OP_FJNZ), 0, 0, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 22)
        vm.specRegisters.pc = 0
        vm.specRegisters.zero = true
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 2)

    test "opcode test: 'RJNZ'":
        var vm = newSnowieVM()
        vm.registers[0] = 20
        vm.program = @[u8(OP_RJNZ), 0, 0, 0]
        discard vm.execOneStep()
        check(vm.specRegisters.pc == high(uint) - 17)
        vm.specRegisters.pc = 0
        vm.specRegisters.zero = true
        discard vm.execOneStep()
        check(vm.specRegisters.pc == 2)
