//****************Instruction Decode Macro Definations********************
//op represents 31-26, func represents 5-0, 
//rs represents 25-21, rt represents 20-16

//R-type instructions, the same op, different funcs
`define OP_SPECIAL				6'b000000

`define FUNC_ADD				6'b100000
`define FUNC_ADDU				6'b100001
`define FUNC_SUB				6'b100010
`define FUNC_SUBU				6'b100011
`define FUNC_AND				6'b100100
`define FUNC_OR					6'b100101
`define FUNC_XOR				6'b100110
`define FUNC_NOR				6'b100111
`define FUNC_SLT				6'b101010
`define FUNC_SLTU				6'b101011
`define FUNC_SLL				6'b000000
`define FUNC_SRL				6'b000010
`define FUNC_SRA				6'b000011
`define FUNC_SLLV				6'b000100
`define FUNC_SRLV				6'b000110
`define FUNC_SRAV				6'b000111
`define FUNC_MULT				6'b011000
`define FUNC_MULTU				6'b011001
`define FUNC_DIV				6'b011010
`define FUNC_DIVU				6'b011011
`define FUNC_JR					6'b001000
`define FUNC_JALR				6'b001001
`define FUNC_MOVZ				6'b001010
`define FUNC_MOVN				6'b001011
`define FUNC_SYSCALL			6'b001100
`define FUNC_BREAK				6'b001101
`define FUNC_MFHI				6'b010000
`define FUNC_MTHI				6'b010001
`define FUNC_MFLO				6'b010010
`define FUNC_MTLO				6'b010011

//common J-type and I-type instructions, different ops
`define OP_J					6'b000010
`define OP_JAL					6'b000011
`define OP_BEQ					6'b000100
`define OP_BNE					6'b000101
`define OP_BLEZ					6'b000110
`define OP_BGTZ					6'b000111
`define OP_ADDI					6'b001000
`define OP_ADDIU				6'b001001
`define OP_SLTI					6'b001010
`define OP_SLTIU				6'b001011
`define OP_ANDI					6'b001100
`define OP_ORI					6'b001101
`define OP_XORI					6'b001110
`define OP_LUI					6'b001111
`define OP_LB					6'b100000
`define OP_LH					6'b100001
`define OP_LW					6'b100011
`define OP_LBU					6'b100100
`define OP_LHU					6'b100101
`define OP_SB					6'b101000
`define OP_SH					6'b101001						
`define OP_SW					6'b101011

//special branch instructions, op is 000001, different rts
`define OP_REGIMM				6'b000001

`define RT_BLTZ					5'b00000
`define RT_BGEZ					5'b00001
`define RT_BLTZAL				5'b10000
`define RT_BGEZAL				5'b10001

//CP0 instructions
`define OP_COP0					6'b010000

`define FUNC_TLBP				6'b001000
`define FUNC_TLBR				6'b000001
`define FUNC_TLBWI				6'b000010
`define FUNC_TLBWR				6'b000110
`define FUNC_ERET				6'b011000
`define RS_MFC0					5'b00000
`define RS_MTC0					5'b00100

//****************ALU Operations Macro Definations********************
`define ALU_NOP                 5'b00000
`define ALU_MOV					5'b00001
`define ALU_ADD					5'b00010
`define ALU_SUB					5'b00011
`define ALU_DIV					5'b00100
`define ALU_AND					5'b00101
`define ALU_OR                  5'b00110
`define ALU_XOR					5'b00111
`define ALU_NOR					5'b01000
`define ALU_SLL					5'b01001
`define ALU_SRL					5'b01010
`define ALU_SRA					5'b01011
`define ALU_SB					5'b01100
`define ALU_SH					5'b01101
`define	ALU_SW					5'b01110
`define ALU_LBU					5'b01111
`define ALU_LHU					5'b10000
`define ALU_LB					5'b10001
`define ALU_LH					5'b10010
`define ALU_LW					5'b10011
`define ALU_MULT				5'b10100
`define ALU_BAJ					5'b10101 //branch and jump alu operations
`define ALU_SLT					5'b10110

//***************MEM Operations Macro Definations**********************
`define MEM_NOP					4'b0000
`define MEM_SB					4'b0001
`define MEM_SH					4'b0010
`define	MEM_SW					4'b0011
`define MEM_LBU					4'b0100
`define MEM_LHU					4'b0101
`define MEM_LB					4'b0110
`define MEM_LH					4'b0111
`define MEM_LW					4'b1000

//**************CP0 Registers****************
`define CAUSE  					5'b01101
`define EPC						5'b01110
`define STATUS 					5'b01100
`define BADVADDR				5'b01000
`define EBASE					5'b01111
