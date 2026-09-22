`timescale 1ns / 1ps

module fibonacci_tb();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        dut.dp.rf.regs[1] = 32'd1; // F_curr
        dut.dp.rf.regs[2] = 32'd0; // F_prev
        dut.dp.rf.regs[3] = 32'd5; // Loop counter N = 5

        // Fibonacci Loop
        dut.dp.instrmem_inst.mem_loc[0] = 32'h00208233; // add x4, x1, x2
        dut.dp.instrmem_inst.mem_loc[1] = 32'h00008113; // addi x2, x1, 0
        dut.dp.instrmem_inst.mem_loc[2] = 32'h00020093; // addi x1, x4, 0
        dut.dp.instrmem_inst.mem_loc[3] = 32'hfff18193; // addi x3, x3, -1
        dut.dp.instrmem_inst.mem_loc[4] = 32'hFE0198E3;

        // NOP padding to flush pipeline
        dut.dp.instrmem_inst.mem_loc[5] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[6] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[7] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[8] = 32'h00000013;

        #15 rst = 0;
        #600;

        if (dut.dp.rf.regs[1] !== 32'd8) begin
            $display("FAIL: Fibonacci test failed: F(6) expected 8, got %d", dut.dp.rf.regs[1]);
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