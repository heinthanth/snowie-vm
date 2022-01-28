import unittest
import vm/[machine,instructions]

suite "test vm/machine.nim":
  test "create a virtual machine":
    var vm = newSnowieVM(@[0'u8, 0, 0, 0])
    check(vm.program == @[0'u8, 0, 0, 0])
    for register in vm.registers: check(register == 0)
  test "simple program with HALT":
    var vm = newSnowieVM(@[u8(OP_HALT), 0, 0, 0])
    vm.registers[0] = 125
    check(vm.run() == VM_EXIT_SUCCESS)
    check(vm.specRegisters.exitCode == 125)
    check(vm.specRegisters.pc == 2)
  test "simple program with LOAD":
    var vm = newSnowieVM(@[
      u8(OP_LOAD), 0, 1, 244, # LOAD $0 #500
      u8(OP_HALT), 0, 0, 0])   # HALT
    check(vm.run() == VM_EXIT_SUCCESS)
    check(vm.registers[0] == 500)
    check(vm.specRegisters.pc == 6)
    check(vm.specRegisters.exitCode == 500)
