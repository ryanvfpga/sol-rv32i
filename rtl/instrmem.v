
`timescale 1ns / 1ps

module instrmem(
    input [31:0] address,
    output reg [31:0] data,
    input instrmem_flush,
    input instrmem_stall,
    input clk,
    input rst
);
    reg [31:0] mem_loc [0:1023];

    always @(posedge clk)
        if (rst || instrmem_flush) begin
            data <= 32'h00000013; // NOP
        end else if (!instrmem_stall) begin
            data <= mem_loc[address[31:2]]; 
        end
endmodule
