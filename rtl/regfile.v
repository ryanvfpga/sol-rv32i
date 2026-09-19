module regfile(
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] rd,
    input [31:0] write_data_in,
    input reg_write,
    input clk,
    output [31:0] rs1_read_o,
    output [31:0] rs2_read_o
    );
    
    reg [31:0]regs [0:31];
    
    assign rs1_read_o = (rs1==0)?0:regs[rs1];
    assign rs2_read_o = (rs2==0)?0:regs[rs2];
    
    always @(negedge clk)
        if(reg_write && rd != 0)
            regs[rd] <= write_data_in;
    
 
endmodule