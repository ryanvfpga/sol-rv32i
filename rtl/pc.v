module pc(
    input clk,
    input pc_write,
    input [31:0]pc_next,
    output reg [31:0]pc,
    input rst
    );
    
    always @(posedge clk, posedge rst)begin
        if(rst)
            pc <= 32'd0;
        else if(pc_write)
            pc <= pc_next;
       end
    
endmodule