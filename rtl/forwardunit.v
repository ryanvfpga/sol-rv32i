`timescale 1ns / 1ps

module forwardunit(
    input mem_reg_write,
    input ex_reg_write, 
    input [4:0] mem_rd,
    input [4:0] ex_rd,
    input [4:0] rs1, 
    input [4:0] rs2,
    output reg [1:0] forward_1,
    output reg [1:0] forward_2
    );

    always @(*) begin
        if (ex_reg_write && (ex_rd != 5'd0) && (ex_rd == rs1)) begin
            forward_1 = 2'b01;
        end else if (mem_reg_write && (mem_rd != 5'd0) && (mem_rd == rs1)) begin
            forward_1 = 2'b10;
        end else begin
            forward_1 = 2'b00; 
        end

        if (ex_reg_write && (ex_rd != 5'd0) && (ex_rd == rs2)) begin
            forward_2 = 2'b01; 
        end else if (mem_reg_write && (mem_rd != 5'd0) && (mem_rd == rs2)) begin
            forward_2 = 2'b10; 
        end else begin
            forward_2 = 2'b00; 
        end
    end

endmodule