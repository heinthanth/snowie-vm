type
  SnowieOpCode* = enum
    OP_HLT,
    OP_IGL

  SnowieInstruction* = object
    opcode*: SnowieOpCode

## helper to convert uint8 to SnowieOpCode
proc op*(n: uint8): SnowieOpCode =
  if n >= 0 and n <= uint8(high(SnowieOpCode)): SnowieOpCode(n) else: OP_IGL

## helper to convert opcode to uint8
proc u8*(opcode: SnowieOpCode): uint8 = uint8(opcode)

## create a new instruction with given SnowieOpCode
proc newSnowieInstruction*(opcode: SnowieOpCode): SnowieInstruction =
  SnowieInstruction(opcode: opcode)

## create a new instruction with given uint8
proc newSnowieInstruction*(opcode: uint8): SnowieInstruction =
  SnowieInstruction(opcode: op(opcode))

## convert int