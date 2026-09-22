`timescale 1ns / 1ps

module raw_hazard_tb();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        // x1 = 10, x2 = 20, x3 = 5
        dut.dp.rf.regs[1] = 32'd10;
        dut.dp.rf.regs[2] = 32'd20;
        dut.dp.rf.regs[3] = 32'd5;

        // Test 1: EX-to-EX Forwarding (1-cycle distance)
        // add x4, x1, x2   -> x4 = 10 + 20 = 30
        dut.dp.instrmem_inst.mem_loc[0] = 32'h00208233;
        // add x5, x4, x3   -> x5 = 30 + 5  = 35 (needs x4 forwarded from EX)
        dut.dp.instrmem_inst.mem_loc[1] = 32'h003202b3;

        // Test 2: MEM-to-EX Forwarding (2-cycle distance)
        // add x6, x1, x3   -> x6 = 10 + 5  = 15
        dut.dp.instrmem_inst.mem_loc[2] = 32'h00308333;
        // add x7, x2, x3   -> x7 = 20 + 5  = 25 (independent instruction)
        dut.dp.instrmem_inst.mem_loc[3] = 32'h003103b3;
        // add x8, x6, x2   -> x8 = 15 + 20 = 35 (needs x6 forwarded from MEM)
        dut.dp.instrmem_inst.mem_loc[4] = 32'h00230433;

        // Test 3: Priority Check (Consecutive writes to same register)
        // add x9, x1, x3   -> x9 = 10 + 5  = 15
        dut.dp.instrmem_inst.mem_loc[5] = 32'h003084b3;
        // add x9, x9, x2   -> x9 = 15 + 20 = 35 (most recent write)
        dut.dp.instrmem_inst.mem_loc[6] = 32'h002484b3;
        // add x10, x9, x3  -> x10 = 35 + 5 = 40 (must pick EX result 35, not MEM result 15)
        dut.dp.instrmem_inst.mem_loc[7] = 32'h00348533;

        // Test 4: Store Data Forwarding (rs2 into memory)
        // add x11, x1, x2  -> x11 = 10 + 20 = 30
        dut.dp.instrmem_inst.mem_loc[8] = 32'h002085b3;
        // sw  x11, 0(x0)   -> writes 30 into mem[0] (needs x11 forwarded to ex_rs2)
        dut.dp.instrmem_inst.mem_loc[9] = 32'h00b02023;

        // Test 5: 4 Consecutive ADDs (WB-to-ID hazard / Negedge RF Read Check)
        // add x12, x1, x2  -> x12 = 30 (Writes x12 in WB when x15 reads x12 in ID)
        dut.dp.instrmem_inst.mem_loc[10] = 32'h00208633;
        // add x13, x1, x2  -> x13 = 30
        dut.dp.instrmem_inst.mem_loc[11] = 32'h002086b3;
        // add x14, x1, x2  -> x14 = 30
        dut.dp.instrmem_inst.mem_loc[12] = 32'h00208733;
        // add x15, x12, x3 -> x15 = 30 + 5 = 35 (Requires negedge write to read fresh x12 in ID)
        dut.dp.instrmem_inst.mem_loc[13] = 32'h003607b3;

        // NOPs to flush pipeline
        dut.dp.instrmem_inst.mem_loc[14] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[15] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[16] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[17] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[18] = 32'h00000013;

        #15 rst = 0;
        #240;

        if (dut.dp.rf.regs[4] !== 32'd30) begin
            $display("FAIL: Test 1 failed: x4 expected 30, got %d", dut.dp.rf.regs[4]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[5] !== 32'd35) begin
            $display("FAIL: Test 1 failed (EX->EX): x5 expected 35, got %d", dut.dp.rf.regs[5]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[8] !== 32'd35) begin
            $display("FAIL: Test 2 failed (MEM->EX): x8 expected 35, got %d", dut.dp.rf.regs[8]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[10] !== 32'd40) begin
            $display("FAIL: Test 3 failed (Priority): x10 expected 40, got %d", dut.dp.rf.regs[10]);
            err_count = err_count + 1;
        end
        if (dut.dp.dm.regs[0] !== 32'd30) begin
            $display("FAIL: Test 4 failed (Store forward): mem[0] expected 30, got %d", dut.dp.dm.regs[0]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[15] !== 32'd35) begin
            $display("FAIL: Test 5 failed (Negedge RF WB->ID): x15 expected 35, got %d", dut.dp.rf.regs[15]);
            err_count = err_count + 1;
        end

        if (err_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s).", err_count);
        end

        $finish;
    end
endmodule