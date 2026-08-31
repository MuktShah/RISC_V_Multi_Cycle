`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mukt Shah
// 
// Create Date: 30.08.2026
// Design Name: 
// Module Name: tb_processor
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



module tb_processor();


 

    reg Clk;
    reg Reset;


    // ============================================================
    // DEBUG WIRES
    // ============================================================

    wire [4:0] debug_state;


    // PC
    wire [31:0] debug_PC;
    wire [31:0] debug_PC_old;
    wire [31:0] debug_PC_next;


    // Instruction
    wire [31:0] debug_instruction;
    wire [31:0] debug_IR;


    // Register file
    wire [31:0] debug_read_data1;
    wire [31:0] debug_read_data2;

    wire [31:0] debug_A;
    wire [31:0] debug_B;


    // Immediate
    wire [31:0] debug_immediate;


    // ALU
    wire [31:0] debug_ALU_A;
    wire [31:0] debug_ALU_B;

    wire [3:0] debug_ALUControl;

    wire [31:0] debug_ALU_result;
    wire [31:0] debug_ALUOut;

    wire debug_Zero;
    wire debug_Less;
    wire debug_LessU;


    // Memory
    wire [31:0] debug_mem_read_data;
    wire [31:0] debug_MDR;


    // Writeback
    wire [31:0] debug_writeback_data;


    // Control Signals
    wire debug_IRWrite;
    wire debug_AWrite;
    wire debug_BWrite;

    wire debug_ALUOutWrite;
    wire debug_MDRWrite;

    wire debug_PCWrite;
    wire debug_RegWrite;

    wire debug_MemRead;
    wire debug_MemWrite;

    wire [1:0] debug_ALUSrcA;
    wire [1:0] debug_ALUSrcB;
    wire [1:0] debug_ALUOp;

    wire [1:0] debug_PCSource;
    wire [1:0] debug_WriteBackSel;


    // ============================================================
    // DUT
    // ============================================================

    processor dut (

        .Clk(Clk),
        .Reset(Reset),

        // FSM
        .debug_state(debug_state),

        // PC
        .debug_PC(debug_PC),
        .debug_PC_old(debug_PC_old),
        .debug_PC_next(debug_PC_next),

        // Instruction
        .debug_instruction(debug_instruction),
        .debug_IR(debug_IR),

        // Register File
        .debug_read_data1(debug_read_data1),
        .debug_read_data2(debug_read_data2),

        .debug_A(debug_A),
        .debug_B(debug_B),

        // Immediate
        .debug_immediate(debug_immediate),

        // ALU
        .debug_ALU_A(debug_ALU_A),
        .debug_ALU_B(debug_ALU_B),

        .debug_ALUControl(debug_ALUControl),

        .debug_ALU_result(debug_ALU_result),
        .debug_ALUOut(debug_ALUOut),

        .debug_Zero(debug_Zero),
        .debug_Less(debug_Less),
        .debug_LessU(debug_LessU),

        // Memory
        .debug_mem_read_data(debug_mem_read_data),
        .debug_MDR(debug_MDR),

        // Writeback
        .debug_writeback_data(debug_writeback_data),

        // Control
        .debug_IRWrite(debug_IRWrite),
        .debug_AWrite(debug_AWrite),
        .debug_BWrite(debug_BWrite),

        .debug_ALUOutWrite(debug_ALUOutWrite),
        .debug_MDRWrite(debug_MDRWrite),

        .debug_PCWrite(debug_PCWrite),
        .debug_RegWrite(debug_RegWrite),

        .debug_MemRead(debug_MemRead),
        .debug_MemWrite(debug_MemWrite),

        .debug_ALUSrcA(debug_ALUSrcA),
        .debug_ALUSrcB(debug_ALUSrcB),

        .debug_ALUOp(debug_ALUOp),

        .debug_PCSource(debug_PCSource),

        .debug_WriteBackSel(debug_WriteBackSel)

    );


    // ============================================================
    // CLOCK GENERATION
    // ============================================================

    initial begin

        Clk = 1'b0;

        forever #5 Clk = ~Clk;

    end


    // ============================================================
    // RESET
    // ============================================================

    initial begin

        Reset = 1'b0;

        #20;

        Reset = 1'b1;

    end


    // ============================================================
    // SIMULATION END
    // ============================================================

    initial begin

        #1000;

        $finish;

    end


endmodule
