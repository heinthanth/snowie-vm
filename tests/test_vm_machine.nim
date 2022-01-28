import unittest
import vm/[machine,instructions]

suite "test vm/machine.nim":
  test "create a virtual machine":
    let vm = newSnowieVM(@[0'u8, 0, 0, 0])
    check(vm.program == @[0'u8, 0, 0, 0])
    check(vm.specRegisters.pc == 0)
    for register in vm.registers: check(register == 0)
  test "simple program with just HLT":
    var vm = newSnowieVM(@[u8(OP_HLT), 0, 0, 0])
    check(vm.run() == VM_EXIT_SUCCESS)
    check(vm.specRegisters.pc == 1)