`timescale 1ns / 1ps

module cpu(
    input clk, rst,
    output [31:0] instr
    );
    
   
    
    wire [31:0] instruction;
    wire [2:0] reg_ctrl;
    wire [6:0] alu_ctrl;
    wire [2:0] imm_ctrl;
    wire mem_write;
    wire pc_ctrl;
    wire  jump_ctrl;
    wire jalr_ctrl;
     assign instr = instruction;
 
    datapath dp (.clk(clk), .rst(rst), .instruction(instruction), .reg_ctrl(reg_ctrl), .alu_ctrl(alu_ctrl), .imm_ctrl(imm_ctrl), .mem_write(mem_write), .pc_ctrl(pc_ctrl), .jump_ctrl(jump_ctrl), .jalr_ctrl(jalr_ctrl));
    control cu (.instr(instruction), .reg_ctrl(reg_ctrl), .alu_ctrl(alu_ctrl), .imm_ctrl(imm_ctrl), .mem_write(mem_write), .pc_ctrl(pc_ctrl), .jump_ctrl(jump_ctrl), .jalr_ctrl(jalr_ctrl));
    
endmodule
