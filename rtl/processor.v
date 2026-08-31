`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mukt Shah
// 
// Create Date: 30.08.2026 04:01:35
// Design Name: 
// Module Name: processor
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module processor(

    input Clk,
    input Reset,

    // ============================================================
    // DEBUG OUTPUTS
    // ============================================================

    // FSM
    output [4:0] debug_state,

    // PC
    output [31:0] debug_PC,
    output [31:0] debug_PC_old,
    output [31:0] debug_PC_next,

    // Instruction
    output [31:0] debug_instruction,
    output [31:0] debug_IR,

    // Register File
    output [31:0] debug_read_data1,
    output [31:0] debug_read_data2,
    output [31:0] debug_A,
    output [31:0] debug_B,

    // Immediate
    output [31:0] debug_immediate,

    // ALU
    output [31:0] debug_ALU_A,
    output [31:0] debug_ALU_B,
    output [3:0]  debug_ALUControl,
    output [31:0] debug_ALU_result,
    output [31:0] debug_ALUOut,

    output debug_Zero,
    output debug_Less,
    output debug_LessU,

    // Memory
    output [31:0] debug_mem_read_data,
    output [31:0] debug_MDR,

    // Writeback
    output [31:0] debug_writeback_data,

    // Control Signals
    output debug_IRWrite,
    output debug_AWrite,
    output debug_BWrite,
    output debug_ALUOutWrite,
    output debug_MDRWrite,

    output debug_PCWrite,
    output debug_RegWrite,

    output debug_MemRead,
    output debug_MemWrite,

    output [1:0] debug_ALUSrcA,
    output [1:0] debug_ALUSrcB,
    output [1:0] debug_ALUOp,

    output [1:0] debug_PCSource,
    output [1:0] debug_WriteBackSel

);


//
// ============================================================
// PC
// ============================================================
//

wire [31:0] PC_current;
wire [31:0] PC_next;

wire PCWrite;

PC pc_module(

    .Clk(Clk),
    .Reset(Reset),

    .PCWrite(PCWrite),

    .next_PC(PC_next),

    .PC_out(PC_current)

);


//
// ============================================================
// PC_old REGISTER
//
// Stores the address of the instruction currently being executed.
// ============================================================
//

reg [31:0] PC_old;


//
// ============================================================
// INSTRUCTION MEMORY
// ============================================================
//

wire [31:0] instruction;

instruction_mem imem(

    .read_addr(PC_current),
    .instruction(instruction)

);


//
// ============================================================
// INSTRUCTION REGISTER (IR)
// ============================================================
//

reg [31:0] IR;

wire IRWrite;

always @(posedge Clk or negedge Reset) begin

    if(!Reset)
        IR <= 32'd0;

    else if(IRWrite)
        IR <= instruction;

end


//
// ============================================================
// PC_old REGISTER UPDATE
// ============================================================
//

always @(posedge Clk or negedge Reset) begin

    if(!Reset)
        PC_old <= 32'd0;

    else if(IRWrite)
        PC_old <= PC_current;

end


//
// ============================================================
// REGISTER FILE
// ============================================================
//

wire [31:0] read_data1;
wire [31:0] read_data2;

wire [31:0] writeback_data;

wire RegWrite;

register_file regfile(

    .Clk(Clk),
    .Reset(Reset),

    .read_reg1(IR[19:15]),
    .read_reg2(IR[24:20]),

    .write_reg(IR[11:7]),

    .data(writeback_data),

    .RegWrite(RegWrite),

    .read_data1(read_data1),
    .read_data2(read_data2)

);


//
// ============================================================
// A AND B TEMPORARY REGISTERS
// ============================================================
//

reg [31:0] A_reg;
reg [31:0] B_reg;

wire AWrite;
wire BWrite;

always @(posedge Clk or negedge Reset) begin

    if(!Reset) begin

        A_reg <= 32'd0;
        B_reg <= 32'd0;

    end

    else begin

        if(AWrite)
            A_reg <= read_data1;

        if(BWrite)
            B_reg <= read_data2;

    end

end


//
// ============================================================
// IMMEDIATE GENERATOR
// ============================================================
//

wire [31:0] immediate;

imm_gen imm_generator(

    .instruction(IR),

    .immediate(immediate)

);


//
// ============================================================
// ALU INPUT MUX A
//
// 00 = A_reg
// 01 = PC_current
// 10 = PC_old
// 11 = 0
// ============================================================
//

wire [1:0] ALUSrcA;
reg [31:0] ALU_input_A;

always @(*) begin

    case(ALUSrcA)

        2'b00: ALU_input_A = A_reg;
        2'b01: ALU_input_A = PC_current;
        2'b10: ALU_input_A = PC_old;
        2'b11: ALU_input_A = 32'd0;

        default: ALU_input_A = 32'd0;

    endcase

end


//
// ============================================================
// ALU INPUT MUX B
//
// 00 = B_reg
// 01 = Immediate
// 10 = 4
// 11 = 0
// ============================================================
//

wire [1:0] ALUSrcB;
reg [31:0] ALU_input_B;

always @(*) begin

    case(ALUSrcB)

        2'b00: ALU_input_B = B_reg;
        2'b01: ALU_input_B = immediate;
        2'b10: ALU_input_B = 32'd4;
        2'b11: ALU_input_B = 32'd0;

        default: ALU_input_B = 32'd0;

    endcase

end


//
// ============================================================
// ALU CONTROL
// ============================================================
//

wire [1:0] ALUOp;
wire [3:0] ALUControl;

ALU_control_unit alu_control(

    .ALUOp(ALUOp),
    .funct3(IR[14:12]),
    .funct7_5(IR[30]),

    .ALUControl(ALUControl)

);


//
// ============================================================
// ALU
// ============================================================
//

wire [31:0] ALU_result;

wire Zero;
wire Less;
wire LessU;

ALU alu(

    .A(ALU_input_A),
    .B(ALU_input_B),

    .ALUControl(ALUControl),

    .Result(ALU_result),

    .Zero(Zero),
    .Less(Less),
    .LessU(LessU)

);


//
// ============================================================
// ALUOut REGISTER
// ============================================================
//

reg [31:0] ALUOut;

wire ALUOutWrite;

always @(posedge Clk or negedge Reset) begin

    if(!Reset)
        ALUOut <= 32'd0;

    else if(ALUOutWrite)
        ALUOut <= ALU_result;

end


//
// ============================================================
// DATA MEMORY
// ============================================================
//

wire MemRead;
wire MemWrite;

wire [31:0] memory_read_data;

data_memory dmem(

    .Clk(Clk),

    .MemRead(MemRead),
    .MemWrite(MemWrite),

    .funct3(IR[14:12]),

    .address(ALUOut),

    .write_data(B_reg),

    .read_data(memory_read_data)

);


//
// ============================================================
// MEMORY DATA REGISTER (MDR)
// ============================================================
//

reg [31:0] MDR;

wire MDRWrite;

always @(posedge Clk or negedge Reset) begin

    if(!Reset)
        MDR <= 32'd0;

    else if(MDRWrite)
        MDR <= memory_read_data;

end


//
// ============================================================
// WRITEBACK MUX
//
// 00 = ALUOut
// 01 = MDR
// 10 = PC_current
//
// NOTE:
// For JAL/JALR, PC_current already points to PC_old + 4.
// ============================================================
//

wire [1:0] WriteBackSel;

reg [31:0] writeback_mux_output;

always @(*) begin

    case(WriteBackSel)

        2'b00:
            writeback_mux_output = ALUOut;

        2'b01:
            writeback_mux_output = MDR;

        2'b10:
            writeback_mux_output = PC_current;

        default:
            writeback_mux_output = 32'd0;

    endcase

end

assign writeback_data = writeback_mux_output;


//
// ============================================================
// PC MUX
//
// 00 = ALU_result       (FETCH: PC + 4)
// 01 = ALUOut           (Branch / JAL target)
// 10 = ALUOut & ~1      (JALR target)
// ============================================================
//

wire [1:0] PCSource;

reg [31:0] PC_mux_output;

always @(*) begin

    case(PCSource)

        2'b00:
            PC_mux_output = ALU_result;

        2'b01:
            PC_mux_output = ALUOut;

        2'b10:
            PC_mux_output = {ALUOut[31:1], 1'b0};

        default:
            PC_mux_output = ALU_result;

    endcase

end

assign PC_next = PC_mux_output;


//
// ============================================================
// MULTICYCLE CONTROLLER
// ============================================================
//

multicycle_controller controller(

    .Clk(Clk),
    .Reset(Reset),

    .opcode(IR[6:0]),
    .funct3(IR[14:12]),

    .Zero(Zero),
    .Less(Less),
    .LessU(LessU),

    .IRWrite(IRWrite),

    .AWrite(AWrite),
    .BWrite(BWrite),

    .ALUOutWrite(ALUOutWrite),

    .MDRWrite(MDRWrite),

    .PCWrite(PCWrite),

    .RegWrite(RegWrite),

    .MemRead(MemRead),
    .MemWrite(MemWrite),

    .ALUSrcA(ALUSrcA),
    .ALUSrcB(ALUSrcB),

    .ALUOp(ALUOp),

    .PCSource(PCSource),

    .WriteBackSel(WriteBackSel)

);


//
// ============================================================
// DEBUG SIGNAL CONNECTIONS
// ============================================================
//

// FSM
assign debug_state = controller.state;


// PC
assign debug_PC      = PC_current;
assign debug_PC_old  = PC_old;
assign debug_PC_next = PC_next;


// Instruction
assign debug_instruction = instruction;
assign debug_IR          = IR;


// Register File
assign debug_read_data1 = read_data1;
assign debug_read_data2 = read_data2;

assign debug_A = A_reg;
assign debug_B = B_reg;


// Immediate
assign debug_immediate = immediate;


// ALU
assign debug_ALU_A       = ALU_input_A;
assign debug_ALU_B       = ALU_input_B;

assign debug_ALUControl  = ALUControl;

assign debug_ALU_result  = ALU_result;

assign debug_ALUOut      = ALUOut;

assign debug_Zero        = Zero;
assign debug_Less        = Less;
assign debug_LessU       = LessU;


// Memory
assign debug_mem_read_data = memory_read_data;
assign debug_MDR           = MDR;


// Writeback
assign debug_writeback_data = writeback_data;


// Control signals
assign debug_IRWrite     = IRWrite;
assign debug_AWrite      = AWrite;
assign debug_BWrite      = BWrite;

assign debug_ALUOutWrite = ALUOutWrite;
assign debug_MDRWrite    = MDRWrite;

assign debug_PCWrite     = PCWrite;
assign debug_RegWrite    = RegWrite;

assign debug_MemRead     = MemRead;
assign debug_MemWrite    = MemWrite;

assign debug_ALUSrcA     = ALUSrcA;
assign debug_ALUSrcB     = ALUSrcB;

assign debug_ALUOp       = ALUOp;

assign debug_PCSource    = PCSource;

assign debug_WriteBackSel = WriteBackSel;

endmodule