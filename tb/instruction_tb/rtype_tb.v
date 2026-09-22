`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.09.2026 13:36:27
// Design Name: 
// Module Name: rtype_tb
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

`timescale 1ns / 1ps

module rtype_tb();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        // load instructions directly to memory
        // x1=15, x2=25, x3=-5, x4=2
        dut.dp.instrmem_inst.mem_loc[0] = 32'h002082b3; // add x5, x1, x2  (15 + 25 = 40)
        dut.dp.instrmem_inst.mem_loc[1] = 32'h40110333; // sub x6, x2, x1  (25 - 15 = 10)
        dut.dp.instrmem_inst.mem_loc[2] = 32'h0020f3b3; // and x7, x1, x2  (15 & 25 = 9)
        dut.dp.instrmem_inst.mem_loc[3] = 32'h0020e433; // or x8, x1, x2   (15 | 25 = 31)
        dut.dp.instrmem_inst.mem_loc[4] = 32'h0020c4b3; // xor x9, x1, x2  (15 ^ 25 = 22)
        dut.dp.instrmem_inst.mem_loc[5] = 32'h00409533; // sll x10, x1, x4 (15 << 2 = 60)
        dut.dp.instrmem_inst.mem_loc[6] = 32'h004155b3; // srl x11, x2, x4 (25 >> 2 = 6)
        dut.dp.instrmem_inst.mem_loc[7] = 32'h4041d633; // sra x12, x3, x4 (-5 >>> 2 = -2)
        dut.dp.instrmem_inst.mem_loc[8] = 32'h0011a6b3; // slt x13, x3, x1 (-5 < 15 = 1)
        dut.dp.instrmem_inst.mem_loc[9] = 32'h0011b733; // sltu x14, x3, x1 (unsigned -5 < 15 = 0)

        // nops
        dut.dp.instrmem_inst.mem_loc[10] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[11] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[12] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[13] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[14] = 32'h00000013;

        // init registers
        dut.dp.rf.regs[1] = 32'd15;
        dut.dp.rf.regs[2] = 32'd25;
        dut.dp.rf.regs[3] = -32'd5;
        dut.dp.rf.regs[4] = 32'd2;

        #15 rst = 0;

       
        #150;

        // check results
        if (dut.dp.rf.regs[5] !== 32'd40) begin $display("FAIL: ADD expected 40, got %d", dut.dp.rf.regs[5]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[6] !== 32'd10) begin $display("FAIL: SUB expected 10, got %d", dut.dp.rf.regs[6]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[7] !== 32'd9)  begin $display("FAIL: AND expected 9, got %d", dut.dp.rf.regs[7]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[8] !== 32'd31) begin $display("FAIL: OR expected 31, got %d", dut.dp.rf.regs[8]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[9] !== 32'd22) begin $display("FAIL: XOR expected 22, got %d", dut.dp.rf.regs[9]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[10] !== 32'd60) begin $display("FAIL: SLL expected 60, got %d", dut.dp.rf.regs[10]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[11] !== 32'd6)  begin $display("FAIL: SRL expected 6, got %d", dut.dp.rf.regs[11]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[12] !== -32'd2) begin $display("FAIL: SRA expected -2, got %d", $signed(dut.dp.rf.regs[12])); err_count = err_count + 1; end
        if (dut.dp.rf.regs[13] !== 32'd1)  begin $display("FAIL: SLT expected 1, got %d", dut.dp.rf.regs[13]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[14] !== 32'd0)  begin $display("FAIL: SLTU expected 0, got %d", dut.dp.rf.regs[14]); err_count = err_count + 1; end

        if (err_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s).", err_count);
        end

        $finish;
    end
endmodule