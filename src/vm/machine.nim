import instructions

type
  SpecRegister = object
    pc*: uint                     ## program counter
    exitCode*: int                ## program exit code used in HALT
    reminder*: uint32             ## reminder o' last DIV instruction

  SnowieVM* = object
    registers*: array[32, int32] ## 32 generic registers
    specRegisters*: SpecRegister  ## special registers
    program*: seq[uint8]          ## user program

  SnowieVmStatus* = enum
    VM_EXIT_SUCCESS,              ## 0 - success
    VM_CONT_EXECUTE               ## 1 - not exit ... continue next instruction
    VM_EXIT_FAILURE,              ## 2 - generic error
    VM_EXIT_ILLEGAL               ## 3 - illegal opcode
    VM_EXIT_ILGLSEQ               ## 4 - invalid program

## create new vm
proc newSnowieVM*(): SnowieVM = SnowieVM()

## create new vm with given program
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

## main execution proc, map opcode to respective action
proc executeInstruction(this: var SnowieVM): SnowieVmStatus =
  if this.specRegisters.pc >= (uint)this.program.len():
    return VM_EXIT_ILGLSEQ
  case this.getInstruction():
  of OP_LOAD:
    let register = this.getNext8bitsOperand()
    let numberOperand = this.getNext16bitsOperand()
    this.registers[register] = int32(numberOperand)
    return VM_CONT_EXECUTE
  of OP_ADD:
    let a = this.registers[this.getNext8bitsOperand()]
    let b = this.registers[this.getNext8bitsOperand()]
    this.registers[this.getNext8bitsOperand()] = a + b
    return VM_CONT_EXECUTE
  of OP_SUB:
    let a = this.registers[this.getNext8bitsOperand()]
    let b = this.registers[this.getNext8bitsOperand()]
    this.registers[this.getNext8bitsOperand()] = a - b
    return VM_CONT_EXECUTE
  of OP_MUL:
    let a = this.registers[this.getNext8bitsOperand()]
    let b = this.registers[this.getNext8bitsOperand()]
    this.registers[this.getNext8bitsOperand()] = a * b
    return VM_CONT_EXECUTE
  of OP_DIV:
    let a = this.registers[this.getNext8bitsOperand()]
    let b = this.registers[this.getNext8bitsOperand()]
    this.registers[this.getNext8bitsOperand()] = a div b
    # "mod" is more cpu expansive than "and"
    this.specRegisters.reminder = uint32(a and b - 1) # a % b == a & b - 1
    return VM_CONT_EXECUTE
  of OP_MOD:
    let a = this.registers[this.getNext8bitsOperand()]
    let b = this.registers[this.getNext8bitsOperand()]
    this.registers[this.getNext8bitsOperand()] = a and b - 1 # a % b == a & b - 1
    return VM_CONT_EXECUTE
  of OP_HALT:
    let exitCode = this.registers[this.getNext8bitsOperand()]
    this.specRegisters.exitCode = int(exitCode)
    return VM_EXIT_SUCCESS
  else: return VM_EXIT_ILLEGAL

## execute one step ( instruction )
proc execOneStep*(this: var SnowieVM): SnowieVmStatus = this.executeInstruction()

## execute the whole program
proc run*(this: var SnowieVM): SnowieVmStatus =
  result = VM_CONT_EXECUTE
  while result == VM_CONT_EXECUTE: result = this.execOneStep()
