module alu(
    input      [3:0]  alu_ctrl,
    input      [31:0] a,
    input      [31:0] b,
    output reg [31:0] alu_result,
    output reg        t_branch
);  

    always @(*) begin
        case (alu_ctrl)
            4'b0000: alu_result = a + b;
            4'b1000: alu_result = a - b;
            4'b0111: alu_result = a & b;
            4'b0110: alu_result = a | b;
            4'b0100: alu_result = a ^ b;
            4'b0001: alu_result = a << b[4:0];
            4'b0101: alu_result = a >> b[4:0];
            4'b1101: alu_result = $signed(a) >>> b[4:0];
            4'b0010: alu_result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'b0011: alu_result = (a < b) ? 32'd1 : 32'd0;
            default: alu_result = 32'd0;
        endcase
    end
    
    always @(*) begin
        case (alu_ctrl) 
            4'b1010: t_branch = (a == b);                
            4'b1011: t_branch = (a != b);                
            4'b1100: t_branch = ($signed(a) < $signed(b)); 
            4'b1101: t_branch = ($signed(a) >= $signed(b));
            4'b1110: t_branch = (a < b);                 
            4'b1111: t_branch = (a >= b);                
            default: t_branch = 1'b0;
       endcase
    end
      
      
     
endmodule