`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mukt Shah
// 
// Create Date: 30.08.2026 
// Design Name: 
// Module Name: PC
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



module PC(

    input Clk,
    input Reset,

    input PCWrite,

    input [31:0] next_PC,

    output reg [31:0] PC_out

);

always @(posedge Clk or negedge Reset) begin

    if(!Reset)
        PC_out <= 32'd0;

    else if(PCWrite)
        PC_out <= next_PC;

end

endmodule