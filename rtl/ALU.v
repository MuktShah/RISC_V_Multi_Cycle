`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mukt Shah
// 
// Create Date: 30.08.2026 
// Design Name: 
// Module Name: ALU
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


module ALU(
    input [31:0] A,
    input [31:0] B,
    input [3:0] ALUControl,
    
    output reg [31:0] Result,
    output Zero,
    output Less,
    output LessU
    );
    
always@(*) begin
    case(ALUControl)
        4'b0000: Result = A & B; //AND
        4'b0001: Result = A | B; //OR
        4'b0010: Result = A + B; //ADD
        4'b0110: Result = A - B; //SUB
        4'b0011: Result = A ^ B; //XOR
        4'b0100: Result = A << B[4:0];// SLL
        4'b0101: Result = A >> B[4:0];// SRL
        4'b1101: Result = $signed(A) >>> B[4:0];//SRA
        4'b0111: Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;// SLT
        4'b1000: Result = (A < B) ? 32'd1 : 32'd0; //SLTU
        default: Result = 32'd0;
    endcase
end
assign Zero = (Result ==32'd0);
assign Less = ($signed(A) < $signed(B));
assign LessU = (A < B);
endmodule
