
`timescale 1ns / 1ps

module instrmem(
    input [31:0] address,
    output reg [31:0] data,
    input instrmem_flush,
    input instrmem_stall,
    input clk,
    input rst
);
    (* ram_style = "block" *) reg [31:0] mem_loc [0:8191];

    integer i;
    initial begin
        for (i = 0; i < 8192; i = i + 1)
            mem_loc[i] = 32'h00000013;   
        $readmemh("test_instr.mem", mem_loc);      
    end

    always @(posedge clk) begin
        if (rst || instrmem_flush) begin
            data <= 32'h00000013; // NOP
        end else if (!instrmem_stall) begin
            data <= mem_loc[address[31:2]]; 
        end
    end



endmodule

