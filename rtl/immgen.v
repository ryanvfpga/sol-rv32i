`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11.09.2026 00:03:50
// Design Name: 
// Module Name: immgen
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

module immgen(
    
    input [31:0]instr,
    input [2:0]imm_ctrl,
    output reg [31:0]imm
    );
    
    always @(*)begin 
        case(imm_ctrl)
            3'b000: imm = {{20{instr[31]}}, instr[31:20]}; 
            3'b001: imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; 
            3'b010: imm = { instr[31:12], 12'b0 }; 
            3'b011: imm = {{19{instr[31]}},instr[31],instr[7],instr[30:25],instr[11:8], 1'b0};     
            3'b100: imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
          
         endcase   
      end     
endmodule