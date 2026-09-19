`timescale 1ns / 1ps

module branch_tb();
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

        // Register initial mapping:
        // x1 = 10, x2 = 10, x3 = 20, x4 = -5 (0xFFFFFFFB)

        // 1. BEQ taken: x1 == x2 (PC = 0 -> Target PC = 12 / index 3)
        dut.dp.instrmem_inst.mem_loc[0]  = 32'h00208663; // beq x1, x2, 12
        dut.dp.instrmem_inst.mem_loc[3]  = 32'h00100513; // Target: addi x10, x0, 1

        // 2. BEQ not taken: x1 == x3 (PC = 16 -> fallthrough to PC = 20 / index 5)
        dut.dp.instrmem_inst.mem_loc[4]  = 32'h00308663; // beq x1, x3, 12 (skipped)
        dut.dp.instrmem_inst.mem_loc[5]  = 32'h00100593; // Fallthrough: addi x11, x0, 1

        // 3. BNE taken: x1 != x3 (PC = 28 -> Target PC = 40 / index 10)
        dut.dp.instrmem_inst.mem_loc[7]  = 32'h00309663; // bne x1, x3, 12
        dut.dp.instrmem_inst.mem_loc[10] = 32'h00100613; // Target: addi x12, x0, 1

        // 4. BNE not taken: x1 != x2 (PC = 44 -> fallthrough to PC = 48 / index 12)
        dut.dp.instrmem_inst.mem_loc[11] = 32'h00209663; // bne x1, x2, 12 (skipped)
        dut.dp.instrmem_inst.mem_loc[12] = 32'h00100693; // Fallthrough: addi x13, x0, 1

        // 5. BLT taken: x4 < x1 (-5 < 10 signed) (PC = 56 -> Target PC = 68 / index 17)
        dut.dp.instrmem_inst.mem_loc[14] = 32'h00124663; // blt x4, x1, 12
        dut.dp.instrmem_inst.mem_loc[17] = 32'h00100713; // Target: addi x14, x0, 1

        // 6. BLT not taken: x1 < x4 (10 < -5 signed) (PC = 72 -> fallthrough to PC = 76 / index 19)
        dut.dp.instrmem_inst.mem_loc[18] = 32'h0040C663; // blt x1, x4, 12 (skipped)
        dut.dp.instrmem_inst.mem_loc[19] = 32'h00100793; // Fallthrough: addi x15, x0, 1

        // 7. BGE taken: x1 >= x4 (10 >= -5 signed) (PC = 84 -> Target PC = 96 / index 24)
        dut.dp.instrmem_inst.mem_loc[21] = 32'h0040D663; // bge x1, x4, 12
        dut.dp.instrmem_inst.mem_loc[24] = 32'h00100813; // Target: addi x16, x0, 1

        // 8. BGE not taken: x4 >= x1 (-5 >= 10 signed) (PC = 100 -> fallthrough to PC = 104 / index 26)
        dut.dp.instrmem_inst.mem_loc[25] = 32'h00125663; // bge x4, x1, 12 (skipped)
        dut.dp.instrmem_inst.mem_loc[26] = 32'h00100893; // Fallthrough: addi x17, x0, 1

        // 9. BLTU taken: x1 < x4 (10 < 0xFFFFFFFB unsigned) (PC = 112 -> Target PC = 124 / index 31)
        dut.dp.instrmem_inst.mem_loc[28] = 32'h0040E663; // bltu x1, x4, 12
        dut.dp.instrmem_inst.mem_loc[31] = 32'h00100913; // Target: addi x18, x0, 1

        // 10. BLTU not taken: x4 < x1 (0xFFFFFFFB < 10 unsigned) (PC = 128 -> fallthrough to PC = 132 / index 33)
        dut.dp.instrmem_inst.mem_loc[32] = 32'h00126663; // bltu x4, x1, 12 (skipped)
        dut.dp.instrmem_inst.mem_loc[33] = 32'h00100993; // Fallthrough: addi x19, x0, 1

        // 11. BGEU taken: x4 >= x1 (0xFFFFFFFB >= 10 unsigned) (PC = 140 -> Target PC = 152 / index 38)
        dut.dp.instrmem_inst.mem_loc[35] = 32'h00127663; // bgeu x4, x1, 12
        dut.dp.instrmem_inst.mem_loc[38] = 32'h00100A13; // Target: addi x20, x0, 1

        // 12. BGEU not taken: x1 >= x4 (10 >= 0xFFFFFFFB unsigned) (PC = 156 -> fallthrough to PC = 160 / index 40)
        dut.dp.instrmem_inst.mem_loc[39] = 32'h0040F663; // bgeu x1, x4, 12 (skipped)
        dut.dp.instrmem_inst.mem_loc[40] = 32'h00100A93; // Fallthrough: addi x21, x0, 1

        // Input register initialization
        dut.dp.rf.regs[0] = 32'd0;
        dut.dp.rf.regs[1] = 32'd10;
        dut.dp.rf.regs[2] = 32'd10;
        dut.dp.rf.regs[3] = 32'd20;
        dut.dp.rf.regs[4] = 32'hFFFFFFFB; // -5

        // Clear output registers
        for (i = 10; i <= 21; i = i + 1) begin
            dut.dp.rf.regs[i] = 32'd0;
        end

        #15 rst = 0;
        #550;

        if (dut.dp.rf.regs[10] !== 32'd1) begin $display("FAIL: BEQ taken (x10 = %0d)", dut.dp.rf.regs[10]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[11] !== 32'd1) begin $display("FAIL: BEQ not taken (x11 = %0d)", dut.dp.rf.regs[11]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[12] !== 32'd1) begin $display("FAIL: BNE taken (x12 = %0d)", dut.dp.rf.regs[12]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[13] !== 32'd1) begin $display("FAIL: BNE not taken (x13 = %0d)", dut.dp.rf.regs[13]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[14] !== 32'd1) begin $display("FAIL: BLT taken (x14 = %0d)", dut.dp.rf.regs[14]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[15] !== 32'd1) begin $display("FAIL: BLT not taken (x15 = %0d)", dut.dp.rf.regs[15]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[16] !== 32'd1) begin $display("FAIL: BGE taken (x16 = %0d)", dut.dp.rf.regs[16]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[17] !== 32'd1) begin $display("FAIL: BGE not taken (x17 = %0d)", dut.dp.rf.regs[17]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[18] !== 32'd1) begin $display("FAIL: BLTU taken (x18 = %0d)", dut.dp.rf.regs[18]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[19] !== 32'd1) begin $display("FAIL: BLTU not taken (x19 = %0d)", dut.dp.rf.regs[19]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[20] !== 32'd1) begin $display("FAIL: BGEU taken (x20 = %0d)", dut.dp.rf.regs[20]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[21] !== 32'd1) begin $display("FAIL: BGEU not taken (x21 = %0d)", dut.dp.rf.regs[21]); err_count = err_count + 1; end

        if (err_count == 0)
            $display("PASS: All 12 branch conditions (taken and not taken) passed.");
        else
            $display("FAIL: %0d error(s).", err_count);

        $finish;
    end
endmodule