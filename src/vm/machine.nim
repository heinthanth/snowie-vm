import instructions

type
  SpecRegister = object
    pc*: uint                     ## program counter
    exitCode*: int                ## program exit code used in HALT

  SnowieVM* = object
    registers*: array[32, uint32] ## 32 generic registers
    specRegisters*: SpecRegister  ## special registers
    program*: seq[uint8]          ## user program

  SnowieVmExitCode* = enum
    VM_EXIT_SUCCESS,              ## 0 - success
    VM_EXIT_FAILURE,              ## 1 - generic error
    VM_EXIT_ILLEGAL               ## 2 - illegal opcode

proc newSnowieVM*(program: seq[uint8]): SnowieVM =
  SnowieVM(program: program)

proc getInstruction(this: var SnowieVM): SnowieOpCode =
  result = op(this.program[this.specRegisters.pc])
  inc(this.specRegisters.pc)

proc getNext8bitsOperand(this: var SnowieVM): uint8 =
  result = this.program[this.specRegisters.pc]
  inc(this.specRegisters.pc)

proc getNext16bitsOperand(this: var SnowieVM): uint16 =
  result = (uint16(this.program[this.specRegisters.pc]) shl 8) or
    this.program[this.specRegisters.pc + 1]
  this.specRegisters.pc += 2

proc run*(this: var SnowieVM): SnowieVmExitCode =
  while true:
    # run out of instructions
    if this.specRegisters.pc >= (uint)this.program.len():
      break
    case this.getInstruction():
    of OP_LOAD:
      let register = this.getNext8bitsOperand()
      let numberOperand = this.getNext16bitsOperand()
      this.registers[register] = numberOperand
      continue
    of OP_HALT:
      let exitCode = this.registers[this.getNext8bitsOperand()]
      this.specRegisters.exitCode = int(exitCode)
      return VM_EXIT_SUCCESS
    else: return VM_EXIT_ILLEGAL
  # should not reach here ( run proc should exit via HALT instruction )
  return VM_EXIT_FAILURE