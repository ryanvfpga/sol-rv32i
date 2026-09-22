`timescale 1ns / 1ps

module loaduse_hazard_tb();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        dut.dp.rf.regs[3] = 32'd10;
        dut.dp.dm.regs[0] = 32'd100;

        // Test 1: Load-Use Hazard on rs1
        // lw  x1, 0(x0)     -> x1 = 100
        // add x2, x1, x3    -> x2 = 100 + 10 = 110
        dut.dp.instrmem_inst.mem_loc[0] = 32'h00002083;
        dut.dp.instrmem_inst.mem_loc[1] = 32'h00308133;

        // Test 2: Load-Use Hazard on rs2
        // lw  x4, 0(x0)     -> x4 = 100
        // add x6, x3, x4    -> x6 = 10 + 100 = 110
        dut.dp.instrmem_inst.mem_loc[2] = 32'h00002203;
        dut.dp.instrmem_inst.mem_loc[3] = 32'h00418333;

        // Test 3: Load-Use Hazard followed immediately by RAW Hazard
        // lw  x7, 0(x0)     -> x7 = 100
        // add x8, x7, x3    -> x8 = 100 + 10 = 110 (Load-Use hazard on x7)
        // add x9, x8, x3    -> x9 = 110 + 10 = 120 (RAW hazard on x8 right after stall)
        dut.dp.instrmem_inst.mem_loc[4] = 32'h00002383;
        dut.dp.instrmem_inst.mem_loc[5] = 32'h00338433;
        dut.dp.instrmem_inst.mem_loc[6] = 32'h003404b3;

        // NOPs to flush pipeline
        dut.dp.instrmem_inst.mem_loc[7]  = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[8]  = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[9]  = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[10] = 32'h00000013;

        #15 rst = 0;
        #200;

        if (dut.dp.rf.regs[2] !== 32'd110) begin
            $display("FAIL: Test 1 failed (rs1): x2 expected 110, got %d", dut.dp.rf.regs[2]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[6] !== 32'd110) begin
            $display("FAIL: Test 2 failed (rs2): x6 expected 110, got %d", dut.dp.rf.regs[6]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[8] !== 32'd110) begin
            $display("FAIL: Test 3 failed (Load-Use): x8 expected 110, got %d", dut.dp.rf.regs[8]);
            err_count = err_count + 1;
        end
        if (dut.dp.rf.regs[9] !== 32'd120) begin
            $display("FAIL: Test 3 failed (RAW after Load-Use): x9 expected 120, got %d", dut.dp.rf.regs[9]);
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