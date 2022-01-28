import instructions

type
  SpecRegister = object
    pc*: uint

  SnowieVM* = object
    registers*: array[32, uint8]  ## 32 generic registers
    specRegisters*: SpecRegister  ## special registers
    program*: seq[uint8]          ## user program

  SnowieVmExitCode* = enum
    VM_EXIT_SUCCESS,              ## success
    VM_EXIT_FAILURE,              ## generic error
    VM_EXIT_ILGL_OP               ## illegal opcode

proc newSnowieVM*(program: seq[uint8]): SnowieVM =
  SnowieVM(program: program)

proc getInstruction(this: var SnowieVM): SnowieOpCode =
  result = op(this.program[this.specRegisters.pc])
  inc(this.specRegisters.pc)

proc run*(this: var SnowieVM): SnowieVmExitCode =
  while true:
    if this.specRegisters.pc >= (uint)this.program.len():
      break
    case this.getInstruction():
    of OP_HLT: return VM_EXIT_SUCCESS
    else: return VM_EXIT_SUCCESS
  # should not reach here ( run proc should exit via HLT instruction )
  return VM_EXIT_FAILURE