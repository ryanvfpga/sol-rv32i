`timescale 1ns / 1ps

module cpu(
    input clk, rst,
    input  [2:0]  dbg_sel,
    output [3:0] dbg_out
    );

    wire [31:0] instruction;
    wire [2:0] reg_ctrl;
    wire [6:0] alu_ctrl;
    wire [2:0] imm_ctrl;
    wire mem_write;
    wire pc_ctrl;
    wire  jump_ctrl;
    wire jalr_ctrl;
    wire branch_ctrl;
    wire [31:0] temp_dbg_out;
    
    assign dbg_out[0] = ^temp_dbg_out[7:0];
    assign dbg_out[1] = ^temp_dbg_out[15:8];
    assign dbg_out[2] = ^temp_dbg_out[23:16];
    assign dbg_out[3] = ^temp_dbg_out[31:24];
 
 
    datapath dp (.clk(clk), .rst(rst), .instruction(instruction), .reg_ctrl(reg_ctrl), .alu_ctrl(alu_ctrl), .imm_ctrl(imm_ctrl), .mem_write(mem_write), .pc_ctrl(pc_ctrl), .jump_ctrl(jump_ctrl), .jalr_ctrl(jalr_ctrl), .branch_ctrl(branch_ctrl), .dbg_sel(dbg_sel), .dbg_out(temp_dbg_out));
    control cu (.instr(instruction), .reg_ctrl(reg_ctrl), .alu_ctrl(alu_ctrl), .imm_ctrl(imm_ctrl), .mem_write(mem_write), .pc_ctrl(pc_ctrl), .jump_ctrl(jump_ctrl), .jalr_ctrl(jalr_ctrl), .branch_ctrl(branch_ctrl));
    
endmodule