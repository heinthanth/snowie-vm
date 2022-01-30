import instructions

type
    SpecRegister = object
        pc*: uint         ## program counter
        exitCode*: int    ## program exit code used in HALT
        zero*: bool       ## zero status - logical operations
        reminder*: uint32 ## reminder o' last DIV instruction

    SnowieVM* = object
        registers*: array[32, int32] ## 32 generic registers
        specRegisters*: SpecRegister ## special registers
        program*: seq[uint8]         ## user program

    SnowieVmStatus* = enum
        VM_EXIT_SUCCESS, ## 0 - success
        VM_CONT_EXECUTE  ## 1 - not exit ... continue next instruction
        VM_EXIT_FAILURE, ## 2 - generic error
        VM_EXIT_ILLEGAL  ## 3 - illegal opcode
        VM_EXIT_ILGLSEQ  ## 4 - invalid program

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
    of OP_ADD:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.registers[this.getNext8bitsOperand()] = a + b
    of OP_SUB:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.registers[this.getNext8bitsOperand()] = a - b
    of OP_MUL:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.registers[this.getNext8bitsOperand()] = a * b
    of OP_DIV:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.registers[this.getNext8bitsOperand()] = a div b
        # "mod" is more cpu expansive than "and"
        this.specRegisters.reminder = uint32(a and b - 1) # a % b == a & b - 1
    of OP_MOD:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.registers[this.getNext8bitsOperand()] = a and b - 1 # a % b == a & b - 1
    of OP_JMP:
        let targetJmp = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.pc = uint(targetJmp)
    of OP_FJMP:
        let amount = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.pc += uint(amount)
    of OP_RJMP:
        let amount = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.pc -= uint(amount)
    of OP_EQ:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.zero = a == b
    of OP_NE:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.zero = a != b
    of OP_LT:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.zero = a < b
    of OP_GT:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.zero = a > b
    of OP_LE:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.zero = a <= b
    of OP_GE:
        let a = this.registers[this.getNext8bitsOperand()]
        let b = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.zero = a >= b
    of OP_JZ:
        let targetJmp = this.registers[this.getNext8bitsOperand()]
        if this.specRegisters.zero: this.specRegisters.pc = uint(targetJmp)
    of OP_JNZ:
        let targetJmp = this.registers[this.getNext8bitsOperand()]
        if not this.specRegisters.zero: this.specRegisters.pc = uint(targetJmp)
    of OP_FJZ:
        let amount = this.registers[this.getNext8bitsOperand()]
        if this.specRegisters.zero: this.specRegisters.pc += uint(amount)
    of OP_RJZ:
        let amount = this.registers[this.getNext8bitsOperand()]
        if this.specRegisters.zero: this.specRegisters.pc -= uint(amount)
    of OP_FJNZ:
        let amount = this.registers[this.getNext8bitsOperand()]
        if not this.specRegisters.zero: this.specRegisters.pc += uint(amount)
    of OP_RJNZ:
        let amount = this.registers[this.getNext8bitsOperand()]
        if not this.specRegisters.zero: this.specRegisters.pc -= uint(amount)
    of OP_HALT:
        let exitCode = this.registers[this.getNext8bitsOperand()]
        this.specRegisters.exitCode = int(exitCode)
        return VM_EXIT_SUCCESS
    else:
        return VM_EXIT_ILLEGAL
    # need more instructions
    return VM_CONT_EXECUTE

## execute one step ( instruction )
proc execOneStep*(this: var SnowieVM): SnowieVmStatus = this.executeInstruction()

## execute the whole program
proc run*(this: var SnowieVM): SnowieVmStatus =
    result = VM_CONT_EXECUTE
    while result == VM_CONT_EXECUTE: result = this.execOneStep()
