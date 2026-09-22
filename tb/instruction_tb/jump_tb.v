`timescale 1ns / 1ps

module jump_tb();
    reg clk;
    reg rst;
    integer err_count;
    integer i;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        for (i = 0; i < 64; i = i + 1) begin
            dut.dp.instrmem_inst.mem_loc[i] = 32'h00000013;
        end

        // JAL 1: jal x1, 16 (PC = 0 -> Target PC = 16)
        dut.dp.instrmem_inst.mem_loc[0]  = 32'h010000EF;
        dut.dp.instrmem_inst.mem_loc[3]  = 32'h0FF00513; // addi x10, x0, 255 (should be skipped)
        dut.dp.instrmem_inst.mem_loc[4]  = 32'h00100513; // Target: addi x10, x0, 1

        // JAL 2: jal x2, 16 (PC = 28 -> Target PC = 44)
        dut.dp.instrmem_inst.mem_loc[7]  = 32'h0100016F;
        dut.dp.instrmem_inst.mem_loc[10] = 32'h0FF00593; // addi x11, x0, 255 (should be skipped)
        dut.dp.instrmem_inst.mem_loc[11] = 32'h00200593; // Target: addi x11, x0, 2

        // JALR 1: jalr x5, x3, 12 (Target: 56 + 12 = 68)
        dut.dp.instrmem_inst.mem_loc[14] = 32'h00C182E7;
        dut.dp.instrmem_inst.mem_loc[17] = 32'h00300613; // Target: addi x12, x0, 3

        // JALR 2: jalr x6, x4, 7 (Target: (85 + 7) & ~1 = 92)
        dut.dp.instrmem_inst.mem_loc[20] = 32'h00720367;
        dut.dp.instrmem_inst.mem_loc[23] = 32'h00400693; // Target: addi x13, x0, 4

        dut.dp.rf.regs[1]  = 32'd0;
        dut.dp.rf.regs[2]  = 32'd0;
        dut.dp.rf.regs[3]  = 32'd56; // Base for JALR 1
        dut.dp.rf.regs[4]  = 32'd85; // Base for JALR 2 (odd value to test bit-0 masking)
        dut.dp.rf.regs[5]  = 32'd0;
        dut.dp.rf.regs[6]  = 32'd0;
        dut.dp.rf.regs[10] = 32'd0;
        dut.dp.rf.regs[11] = 32'd0;
        dut.dp.rf.regs[12] = 32'd0;
        dut.dp.rf.regs[13] = 32'd0;

        #15 rst = 0;
        #350;

        if (dut.dp.rf.regs[1] !== 32'd4) begin
            $display("FAIL: JAL 1 link x1 = %0d (exp: 4)", dut.dp.rf.regs[1]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[10] !== 32'd1) begin
            $display("FAIL: JAL 1 target x10 = %0d (exp: 1)", dut.dp.rf.regs[10]);
            err_count = err_count + 1;
        end

        if (dut.dp.rf.regs[2] !== 32'd32) begin
            $display("FAIL: JAL 2 link x2 = %0d (exp: 32)", dut.dp.rf.regs[2]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[11] !== 32'd2) begin
            $display("FAIL: JAL 2 target x11 = %0d (exp: 2)", dut.dp.rf.regs[11]);
            err_count = err_count + 1;
        end

        if (dut.dp.rf.regs[5] !== 32'd60) begin
            $display("FAIL: JALR 1 link x5 = %0d (exp: 60)", dut.dp.rf.regs[5]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[12] !== 32'd3) begin
            $display("FAIL: JALR 1 target x12 = %0d (exp: 3)", dut.dp.rf.regs[12]);
            err_count = err_count + 1;
        end

        if (dut.dp.rf.regs[6] !== 32'd84) begin
            $display("FAIL: JALR 2 link x6 = %0d (exp: 84)", dut.dp.rf.regs[6]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[13] !== 32'd4) begin
            $display("FAIL: JALR 2 target x13 = %0d (exp: 4)", dut.dp.rf.regs[13]);
            err_count = err_count + 1;
        end

        if (err_count == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s).", err_count);

        $finish;
    end
endmodule