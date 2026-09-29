module bpredictor(
    input clk,
    input rst,
    input [3:0] ctrl,
    output reg [31:0] predicted_pc,
    input [31:0] id_pc,
    input [31:0] pc,
    input [31:0] jump_target,
    output predicted
);

    wire t_branch    = ctrl[3];
    wire branch_ctrl = ctrl[2];
    wire jal_ctrl    = ctrl[1];
    wire jalr_ctrl   = ctrl[0];

    wire [7:0] index = id_pc[9:2];

    reg [31:0] btb [0:255];
    reg [1:0] count [0:255];

    reg [31:0] btb_out;
    reg [1:0] count_out;

    assign predicted = (count_out == 2'b10 || count_out == 2'b11);

    always @(*) begin
        btb_out = btb[pc[9:2]];
        count_out = count[pc[9:2]];
        case(count_out)
            2'b00: predicted_pc = pc + 32'd4;
            2'b01: predicted_pc = pc + 32'd4;
            2'b10: predicted_pc = btb_out;
            2'b11: predicted_pc = btb_out;
        endcase
    end
    
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 256; i = i + 1) begin 
                btb[i]   <= 32'b0;
                count[i] <= 2'b00; 
            end
        end else begin
            if (branch_ctrl || jal_ctrl || jalr_ctrl) begin
                btb[index] <= jump_target;

                if (jal_ctrl || jalr_ctrl) begin
                    count[index] <= 2'b11;
                end 
                else if (branch_ctrl && t_branch) begin
                    if (count[index] != 2'b11)
                        count[index] <= count[index] + 1'b1;
                end 
                else if (branch_ctrl && !t_branch) begin
                    if (count[index] != 2'b00)
                        count[index] <= count[index] - 1'b1;
                end
            end
        end
    end
endmodule