`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Mukt Shah
// 
// Create Date: 30.08.2026 
// Design Name: 
// Module Name: data_memory
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


module data_memory(

    input Clk,

    input MemRead,
    input MemWrite,

    input [2:0] funct3,

    input [31:0] address,
    input [31:0] write_data,

    output reg [31:0] read_data

);

//
// 1024 bytes = 1 KB
//

reg [7:0] memory [0:1023];

wire [9:0] addr;

assign addr = address[9:0];


//
// COMBINATIONAL READ
//

always @(*) begin

    read_data = 32'd0;

    if(MemRead) begin

        case(funct3)

            //--------------------------------
            // LB
            //--------------------------------

            3'b000:
                read_data =
                    {{24{memory[addr][7]}},
                     memory[addr]};


            //--------------------------------
            // LH
            //--------------------------------

            3'b001:
                read_data =
                    {{16{memory[addr][7]}},
                     memory[addr+1],
                     memory[addr]};


            //--------------------------------
            // LW
            //--------------------------------

            3'b010:
                read_data =
                    {memory[addr+3],
                     memory[addr+2],
                     memory[addr+1],
                     memory[addr]};


            //--------------------------------
            // LBU
            //--------------------------------

            3'b100:
                read_data =
                    {24'd0,
                     memory[addr]};


            //--------------------------------
            // LHU
            //--------------------------------

            3'b101:
                read_data =
                    {16'd0,
                     memory[addr+1],
                     memory[addr]};


            default:
                read_data = 32'd0;

        endcase

    end

end



//
// SEQUENTIAL WRITE
//

always @(posedge Clk) begin

    if(MemWrite) begin

        case(funct3)

            //--------------------------------
            // SB
            //--------------------------------

            3'b000:
                memory[addr] <= write_data[7:0];


            //--------------------------------
            // SH
            //--------------------------------

            3'b001: begin

                memory[addr]   <= write_data[7:0];
                memory[addr+1] <= write_data[15:8];

            end


            //--------------------------------
            // SW
            //--------------------------------

            3'b010: begin

                memory[addr]   <= write_data[7:0];
                memory[addr+1] <= write_data[15:8];
                memory[addr+2] <= write_data[23:16];
                memory[addr+3] <= write_data[31:24];

            end

        endcase

    end

end

endmodule