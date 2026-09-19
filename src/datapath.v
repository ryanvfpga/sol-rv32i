`timescale 1ns / 1ps

module datapath(
    input clk,
    input rst,
    output [31:0] instruction,
    input [2:0] reg_ctrl,
    input [6:0] alu_ctrl,
    input [2:0] imm_ctrl,
    input mem_write,
    input pc_ctrl,
    input jump_ctrl,
    input jalr_ctrl
); 

    wire [31:0] pc;
    wire [31:0] pc_next;
    wire [31:0] branch_target_pc;
    wire branch_taken;
    wire pc_write;
    wire load_use_hazard;
    wire instrmem_flush;
    wire instrmem_stall;

    reg [31:0] if_pc;
    wire [31:0] if_instr;
    wire if_id_stall;

    reg [31:0] id_pc;
    reg [31:0] id_rs1;
    reg [31:0] id_rs2;
    reg [4:0] id_rs1_addr;
    reg [4:0] id_rs2_addr;
    reg [31:0] id_immediate;
    reg [4:0] id_rd;
    reg [2:0] id_reg_ctrl;
    reg [6:0] id_alu_ctrl;
    reg [2:0] id_funct3;
    reg id_pc_ctrl;
    reg id_jump_ctrl;
    reg id_jalr_ctrl;
    reg id_mem_write;
    wire id_ex_flush;

    reg [31:0] ex_pc;
    reg [31:0] ex_rs2;
    reg [31:0] ex_alu_result;
    reg [4:0] ex_rd;
    reg [2:0] ex_reg_ctrl;
    reg [2:0] ex_funct3;
    reg ex_mem_write;

    reg [31:0] mem_pc;
    reg [31:0] mem_alu_result;
    reg [4:0] mem_rd;
    reg [2:0] mem_reg_ctrl;
    wire [31:0] mem_datamem_read;

    wire [31:0] rs1;
    wire [31:0] rs2;
    wire [31:0] immediate;
    wire [31:0] alu_result;
    wire t_branch;
    reg [31:0] alu_in_1;
    wire [31:0] alu_in_2;
    reg [31:0] regfile_data_in;
    wire [1:0] t_forward_1;
    wire [1:0] t_forward_2;
    reg [31:0] fwd_rs1;
    reg [31:0] fwd_rs2;

    assign instrmem_flush = branch_taken; 
    assign instrmem_stall = load_use_hazard;
    assign pc_write = !load_use_hazard;
    assign if_id_stall = load_use_hazard; 
    assign id_ex_flush = load_use_hazard || branch_taken; 

    assign load_use_hazard = (id_reg_ctrl[2:1] == 2'b01) && (id_rd != 5'd0) && ((if_instr[19:15] == id_rd) || (if_instr[24:20] == id_rd));
    assign instruction = if_instr;
    assign branch_target_pc = id_jalr_ctrl ? (alu_result & 32'hFFFFFFFE) : id_pc + id_immediate;
    assign pc_next = branch_taken ? branch_target_pc : pc + 32'd4;   
    assign branch_taken = (id_pc_ctrl & (t_branch | id_jump_ctrl | id_jalr_ctrl));

    always @(*) begin
        case(t_forward_1)
            2'b01:   fwd_rs1 = ex_alu_result;
            2'b10:   fwd_rs1 = regfile_data_in;
            default: fwd_rs1 = id_rs1;
        endcase

        case(t_forward_2)
            2'b01:   fwd_rs2 = ex_alu_result;
            2'b10:   fwd_rs2 = regfile_data_in;
            default: fwd_rs2 = id_rs2;
        endcase
    end

    assign alu_in_2 = id_alu_ctrl[4] ? id_immediate : fwd_rs2; 

    always @(*) begin
        case(id_alu_ctrl[6:5])
            2'b00:   alu_in_1 = fwd_rs1;
            2'b01:   alu_in_1 = 32'b0;
            2'b10:   alu_in_1 = id_pc;
            default: alu_in_1 = fwd_rs1;
        endcase
    end

    always @(*) begin
        case(mem_reg_ctrl[2:1])
            2'b00: regfile_data_in = mem_alu_result;
            2'b01: regfile_data_in = mem_datamem_read;
            2'b10: regfile_data_in = mem_pc + 32'd4;
            default: regfile_data_in = 32'd0; 
        endcase
    end

    // IF/ID Pipeline Register
    always @(posedge clk) begin
        if (rst) begin
            if_pc <= 32'd0;
        end else if (!if_id_stall) begin
            if (branch_taken) begin
                if_pc <= 32'd0;
            end else begin
                if_pc <= pc;
            end
        end
    end

    // ID/EX Pipeline Register
    always @(posedge clk) begin
        if (rst || id_ex_flush) begin
            id_rs1 <= 32'd0;
            id_rs2 <= 32'd0;
            id_immediate <= 32'd0;
            id_rd <= 5'd0;            
            id_alu_ctrl <= 7'b0;
            id_reg_ctrl <= 3'b0;      
            id_mem_write <= 1'b0;   
            id_pc <= 32'd0;
            id_pc_ctrl <= 1'b0;
            id_jump_ctrl <= 1'b0;
            id_jalr_ctrl <= 1'b0;
            id_funct3 <= 3'b0;
            id_rs1_addr <= 5'b0;
            id_rs2_addr <= 5'b0;
        end else begin
            id_rs1 <= rs1;
            id_rs2 <= rs2;
            id_immediate <= immediate;
            id_rd <= if_instr[11:7]; 
            id_alu_ctrl <= alu_ctrl;
            id_reg_ctrl <= reg_ctrl;
            id_mem_write <= mem_write;
            id_pc <= if_pc;
            id_pc_ctrl <= pc_ctrl;
            id_jump_ctrl <= jump_ctrl;
            id_jalr_ctrl <= jalr_ctrl;
            id_funct3 <= if_instr[14:12];
            id_rs1_addr <= if_instr[19:15];
            id_rs2_addr <= if_instr[24:20];
        end
    end

    // EX/MEM Pipeline Register
    always @(posedge clk) begin
        if (rst) begin
            ex_alu_result <= 32'd0;
            ex_rd <= 5'd0;
            ex_reg_ctrl <= 3'b0;
            ex_mem_write <= 1'b0;
            ex_rs2 <= 32'd0;
            ex_pc <= 32'd0;
            ex_funct3 <= 3'b0;
        end else begin
            ex_alu_result <= alu_result;
            ex_rd <= id_rd;
            ex_reg_ctrl <= id_reg_ctrl;
            ex_mem_write <= id_mem_write;
            ex_rs2 <= fwd_rs2;
            ex_pc <= id_pc;
            ex_funct3 <= id_funct3;
        end
    end

    // MEM/WB Pipeline Register
    always @(posedge clk) begin
        if (rst) begin
            mem_alu_result <= 32'd0;
            mem_rd <= 5'd0;
            mem_reg_ctrl <= 3'b0;
            mem_pc <= 32'd0;
        end else begin
            mem_alu_result <= ex_alu_result;
            mem_rd <= ex_rd;
            mem_reg_ctrl <= ex_reg_ctrl;
            mem_pc <= ex_pc;
        end
    end

    instrmem instrmem_inst (
        .address(pc), 
        .data(if_instr), 
        .instrmem_flush(instrmem_flush), 
        .clk(clk), 
        .instrmem_stall(instrmem_stall), 
        .rst(rst)
    );

    pc pc_inst (
        .clk(clk), 
        .pc_write(pc_write), 
        .pc_next(pc_next), 
        .pc(pc), 
        .rst(rst)
    );

    regfile rf (
        .rs1(if_instr[19:15]),
        .rs2(if_instr[24:20]),
        .rd(mem_rd),
        .write_data_in(regfile_data_in),
        .reg_write(mem_reg_ctrl[0]),
        .clk(clk),
        .rs1_read_o(rs1),
        .rs2_read_o(rs2)
    );
    
    immgen immgen_inst (
        .instr(if_instr), 
        .imm_ctrl(imm_ctrl), 
        .imm(immediate)
    );
   
    alu alu_inst (
        .alu_ctrl(id_alu_ctrl[3:0]), 
        .a(alu_in_1), 
        .b(alu_in_2), 
        .alu_result(alu_result), 
        .t_branch(t_branch)
    );
    
    datamem dm (
        .address(ex_alu_result),
        .write_data(ex_rs2),
        .data(mem_datamem_read),
        .clk(clk),
        .mem_write(ex_mem_write),
        .funct3(ex_funct3),
        .rst(rst)
    );

    forwardunit fw (
        .rs1(id_rs1_addr),
        .rs2(id_rs2_addr),
        .ex_reg_write(ex_reg_ctrl[0]),
        .mem_reg_write(mem_reg_ctrl[0]),
        .ex_rd(ex_rd),
        .mem_rd(mem_rd),
        .forward_1(t_forward_1),
        .forward_2(t_forward_2)
    );

endmodule