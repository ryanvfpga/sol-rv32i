`timescale 1ns / 1ps

module control_hazard_break_tb();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        dut.dp.rf.regs[1] = 32'd10;
        dut.dp.rf.regs[2] = 32'd10;
        dut.dp.rf.regs[4] = 32'd0;
        dut.dp.rf.regs[10] = 32'd0; 


        dut.dp.instrmem_inst.mem_loc[0] = 32'h00208663; // beq x1, x2, 12 (target: mem_loc[3])
        dut.dp.instrmem_inst.mem_loc[1] = 32'h00500213; // addi x4, x0, 5   (Flushed by ID/EX flush)
        dut.dp.instrmem_inst.mem_loc[2] = 32'h06300513; // addi x10, x0, 99 (Flushed by IF/ID flush)
        dut.dp.instrmem_inst.mem_loc[3] = 32'h01400213; // addi x4, x0, 20  (Branch target)

        // NOP padding
        dut.dp.instrmem_inst.mem_loc[4] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[5] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[6] = 32'h00000013;

        #15 rst = 0;
        #200;


        if (dut.dp.rf.regs[10] !== 32'd0) begin
            $display("FAIL: IF/ID flush bug! x10 expected 0, got %d (mem_loc[2] executed!)", dut.dp.rf.regs[10]);
            err_count = err_count + 1;
        end

        if (dut.dp.rf.regs[4] !== 32'd20) begin
            $display("FAIL: Target execution wrong! x4 expected 20, got %d", dut.dp.rf.regs[4]);
            err_count = err_count + 1;
        end

        if (err_count == 0) begin
            $display("All tests passed.");
        end else begin
            $display("Testbench failed with %d error(s).", err_count);
        end

        $finish;
    end
endmodule