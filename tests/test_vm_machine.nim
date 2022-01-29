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
  test "simple program: 'HALT'":
    # HLT $0
    var vm = newSnowieVM(@[u8(OP_HALT), 0, 0, 0])
    vm.registers[0] = 125
    check(vm.run() == VM_EXIT_SUCCESS)
    check(vm.specRegisters.exitCode == 125)
    check(vm.specRegisters.pc == 2)

  test "simple program: 'LOAD'":
    var vm = newSnowieVM()
    # LOAD $0 #500
    # HALT $0
    vm.program = @[u8(OP_LOAD), 0, 1, 244, u8(OP_HALT), 0, 0, 0]
    check(vm.run() == VM_EXIT_SUCCESS)
    check(vm.registers[0] == 500)
    check(vm.specRegisters.pc == 6)
    check(vm.specRegisters.exitCode == 500)

  test "simple program: 'ADD'":
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

  test "simple program: 'SUB'":
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
  test "simple program: 'MUL'":
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
  test "simple program: 'DIV'":
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
  test "simple program: 'MOD'":
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