`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.09.2026 
// Design Name: 
// Module Name: multicycle_controller
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


module multicycle_controller(

    input Clk,
    input Reset,

    input [6:0] opcode,
    input [2:0] funct3,

    input Zero,
    input Less,
    input LessU,


    // Datapath register enables

    output reg IRWrite,
    output reg AWrite,
    output reg BWrite,
    output reg ALUOutWrite,
    output reg MDRWrite,

    output reg PCWrite,
    output reg RegWrite,

    output reg MemRead,
    output reg MemWrite,


    // ALU control

    output reg [1:0] ALUSrcA,
    output reg [1:0] ALUSrcB,
    output reg [1:0] ALUOp,


    // PC MUX

    output reg [1:0] PCSource,


    // Writeback MUX

    output reg [1:0] WriteBackSel

);


//
// OPCODES
//

localparam OP_RTYPE  = 7'b0110011;
localparam OP_ITYPE  = 7'b0010011;
localparam OP_LOAD   = 7'b0000011;
localparam OP_STORE  = 7'b0100011;
localparam OP_BRANCH = 7'b1100011;
localparam OP_LUI    = 7'b0110111;
localparam OP_AUIPC  = 7'b0010111;
localparam OP_JAL    = 7'b1101111;
localparam OP_JALR   = 7'b1100111;



//
// FSM STATES
//

localparam S_FETCH          = 5'd0;
localparam S_DECODE         = 5'd1;

localparam S_EXEC_R         = 5'd2;
localparam S_EXEC_I         = 5'd3;
localparam S_WB_ALU         = 5'd4;

localparam S_MEM_ADDR       = 5'd5;
localparam S_MEM_READ       = 5'd6;
localparam S_MEM_WRITE      = 5'd7;
localparam S_WB_LOAD        = 5'd8;

localparam S_BRANCH_TARGET  = 5'd9;
localparam S_BRANCH_COMPARE = 5'd10;

localparam S_JAL_CALC       = 5'd11;
localparam S_JAL_WRITE      = 5'd12;

localparam S_JALR_CALC      = 5'd13;
localparam S_JALR_WRITE     = 5'd14;

localparam S_LUI            = 5'd15;
localparam S_AUIPC          = 5'd16;



reg [4:0] state;
reg [4:0] next_state;



//
// STATE REGISTER
//

always @(posedge Clk or negedge Reset) begin

    if(!Reset)
        state <= S_FETCH;

    else
        state <= next_state;

end



//
// NEXT STATE LOGIC
//

always @(*) begin

    next_state = S_FETCH;

    case(state)

        //------------------------------------------------
        // FETCH
        //------------------------------------------------

        S_FETCH:
            next_state = S_DECODE;


        //------------------------------------------------
        // DECODE
        //------------------------------------------------

        S_DECODE: begin

            case(opcode)

                OP_RTYPE:
                    next_state = S_EXEC_R;

                OP_ITYPE:
                    next_state = S_EXEC_I;

                OP_LOAD,
                OP_STORE:
                    next_state = S_MEM_ADDR;

                OP_BRANCH:
                    next_state = S_BRANCH_TARGET;

                OP_JAL:
                    next_state = S_JAL_CALC;

                OP_JALR:
                    next_state = S_JALR_CALC;

                OP_LUI:
                    next_state = S_LUI;

                OP_AUIPC:
                    next_state = S_AUIPC;

                default:
                    next_state = S_FETCH;

            endcase

        end


        //------------------------------------------------
        // R-TYPE EXECUTE
        //------------------------------------------------

        S_EXEC_R:
            next_state = S_WB_ALU;


        //------------------------------------------------
        // I-TYPE EXECUTE
        //------------------------------------------------

        S_EXEC_I:
            next_state = S_WB_ALU;


        //------------------------------------------------
        // ALU WRITEBACK
        //------------------------------------------------

        S_WB_ALU:
            next_state = S_FETCH;


        //------------------------------------------------
        // MEMORY ADDRESS
        //------------------------------------------------

        S_MEM_ADDR: begin

            if(opcode == OP_LOAD)
                next_state = S_MEM_READ;

            else
                next_state = S_MEM_WRITE;

        end


        //------------------------------------------------
        // MEMORY READ
        //------------------------------------------------

        S_MEM_READ:
            next_state = S_WB_LOAD;


        //------------------------------------------------
        // MEMORY WRITE
        //------------------------------------------------

        S_MEM_WRITE:
            next_state = S_FETCH;


        //------------------------------------------------
        // LOAD WRITEBACK
        //------------------------------------------------

        S_WB_LOAD:
            next_state = S_FETCH;


        //------------------------------------------------
        // BRANCH TARGET
        //------------------------------------------------

        S_BRANCH_TARGET:
            next_state = S_BRANCH_COMPARE;


        //------------------------------------------------
        // BRANCH COMPARE
        //------------------------------------------------

        S_BRANCH_COMPARE:
            next_state = S_FETCH;


        //------------------------------------------------
        // JAL
        //------------------------------------------------

        S_JAL_CALC:
            next_state = S_JAL_WRITE;

        S_JAL_WRITE:
            next_state = S_FETCH;


        //------------------------------------------------
        // JALR
        //------------------------------------------------

        S_JALR_CALC:
            next_state = S_JALR_WRITE;

        S_JALR_WRITE:
            next_state = S_FETCH;


        //------------------------------------------------
        // LUI
        //------------------------------------------------

        S_LUI:
            next_state = S_WB_ALU;


        //------------------------------------------------
        // AUIPC
        //------------------------------------------------

        S_AUIPC:
            next_state = S_WB_ALU;


        default:
            next_state = S_FETCH;

    endcase

end



//
// OUTPUT CONTROL LOGIC
//

always @(*) begin

    //------------------------------------------------
    // DEFAULT VALUES
    //------------------------------------------------

    IRWrite     = 1'b0;
    AWrite      = 1'b0;
    BWrite      = 1'b0;
    ALUOutWrite = 1'b0;
    MDRWrite    = 1'b0;

    PCWrite     = 1'b0;
    RegWrite    = 1'b0;

    MemRead     = 1'b0;
    MemWrite    = 1'b0;

    ALUSrcA     = 2'b00;
    ALUSrcB     = 2'b00;

    ALUOp       = 2'b00;

    PCSource    = 2'b00;

    WriteBackSel = 2'b00;



    case(state)

        //------------------------------------------------
        // FETCH
        //
        // IR <= InstructionMemory[PC]
        // PC_old <= PC
        // PC <= PC + 4
        //------------------------------------------------

        S_FETCH: begin

            IRWrite = 1'b1;
            PCWrite = 1'b1;

            // ALU A = PC
            ALUSrcA = 2'b01;

            // ALU B = 4
            ALUSrcB = 2'b10;

            // ADD
            ALUOp = 2'b00;

            // PC = ALU Result
            PCSource = 2'b00;

        end


        //------------------------------------------------
        // DECODE
        //
        // A <= Register[rs1]
        // B <= Register[rs2]
        //------------------------------------------------

        S_DECODE: begin

            AWrite = 1'b1;
            BWrite = 1'b1;

        end


        //------------------------------------------------
        // R-TYPE EXECUTE
        //
        // ALUOut <= A operation B
        //------------------------------------------------

        S_EXEC_R: begin

            ALUOutWrite = 1'b1;

            ALUSrcA = 2'b00; // A
            ALUSrcB = 2'b00; // B

            ALUOp = 2'b10;

        end


        //------------------------------------------------
        // I-TYPE EXECUTE
        //
        // ALUOut <= A operation Immediate
        //------------------------------------------------

        S_EXEC_I: begin

            ALUOutWrite = 1'b1;

            ALUSrcA = 2'b00; // A
            ALUSrcB = 2'b01; // Immediate

            ALUOp = 2'b11;

        end


        //------------------------------------------------
        // ALU WRITEBACK
        //
        // rd <= ALUOut
        //------------------------------------------------

        S_WB_ALU: begin

            RegWrite = 1'b1;

            WriteBackSel = 2'b00;

        end


        //------------------------------------------------
        // MEMORY ADDRESS
        //
        // ALUOut <= A + Immediate
        //------------------------------------------------

        S_MEM_ADDR: begin

            ALUOutWrite = 1'b1;

            ALUSrcA = 2'b00; // A
            ALUSrcB = 2'b01; // Immediate

            ALUOp = 2'b00; // ADD

        end


        //------------------------------------------------
        // MEMORY READ
        //
        // MDR <= Memory[ALUOut]
        //------------------------------------------------

        S_MEM_READ: begin

            MemRead  = 1'b1;
            MDRWrite = 1'b1;

        end


        //------------------------------------------------
        // MEMORY WRITE
        //
        // Memory[ALUOut] <= B
        //------------------------------------------------

        S_MEM_WRITE: begin

            MemWrite = 1'b1;

        end


        //------------------------------------------------
        // LOAD WRITEBACK
        //
        // rd <= MDR
        //------------------------------------------------

        S_WB_LOAD: begin

            RegWrite = 1'b1;

            WriteBackSel = 2'b01;

        end


        //------------------------------------------------
        // BRANCH TARGET
        //
        // ALUOut <= PC_old + Immediate
        //------------------------------------------------

        S_BRANCH_TARGET: begin

            ALUOutWrite = 1'b1;

            ALUSrcA = 2'b10; // PC_old
            ALUSrcB = 2'b01; // Immediate

            ALUOp = 2'b00;

        end


        //------------------------------------------------
        // BRANCH COMPARE
        //------------------------------------------------

        S_BRANCH_COMPARE: begin

            ALUSrcA = 2'b00; // A
            ALUSrcB = 2'b00; // B

            ALUOp = 2'b01;   // SUB

            PCSource = 2'b01; // ALUOut = branch target


            case(funct3)

                // BEQ
                3'b000:
                    PCWrite = Zero;

                // BNE
                3'b001:
                    PCWrite = ~Zero;

                // BLT
                3'b100:
                    PCWrite = Less;

                // BGE
                3'b101:
                    PCWrite = ~Less;

                // BLTU
                3'b110:
                    PCWrite = LessU;

                // BGEU
                3'b111:
                    PCWrite = ~LessU;

                default:
                    PCWrite = 1'b0;

            endcase

        end


        //------------------------------------------------
        // JAL CALCULATION
        //
        // ALUOut <= PC_old + Immediate
        //------------------------------------------------

        S_JAL_CALC: begin

            ALUOutWrite = 1'b1;

            ALUSrcA = 2'b10; // PC_old
            ALUSrcB = 2'b01; // Immediate

            ALUOp = 2'b00;

        end


        //------------------------------------------------
        // JAL WRITE
        //
        // rd <= PC
        // PC <= ALUOut
        //------------------------------------------------

        S_JAL_WRITE: begin

            PCWrite = 1'b1;
            PCSource = 2'b01;

            RegWrite = 1'b1;
            WriteBackSel = 2'b10;

        end


        //------------------------------------------------
        // JALR CALCULATION
        //
        // ALUOut <= A + Immediate
        //------------------------------------------------

        S_JALR_CALC: begin

            ALUOutWrite = 1'b1;

            ALUSrcA = 2'b00; // A
            ALUSrcB = 2'b01; // Immediate

            ALUOp = 2'b00;

        end


        //------------------------------------------------
        // JALR WRITE
        //
        // rd <= PC
        // PC <= (ALUOut & ~1)
        //------------------------------------------------

        S_JALR_WRITE: begin

            PCWrite = 1'b1;

            PCSource = 2'b10;

            RegWrite = 1'b1;
            WriteBackSel = 2'b10;

        end


        //------------------------------------------------
        // LUI
        //
        // ALUOut <= 0 + Immediate
        //------------------------------------------------

        S_LUI: begin

            ALUOutWrite = 1'b1;

            ALUSrcA = 2'b11; // ZERO
            ALUSrcB = 2'b01; // Immediate

            ALUOp = 2'b00;

        end


        //------------------------------------------------
        // AUIPC
        //
        // ALUOut <= PC_old + Immediate
        //------------------------------------------------

        S_AUIPC: begin

            ALUOutWrite = 1'b1;

            ALUSrcA = 2'b10; // PC_old
            ALUSrcB = 2'b01; // Immediate

            ALUOp = 2'b00;

        end


        default: begin
        end

    endcase

end

endmodule
