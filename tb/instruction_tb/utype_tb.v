`timescale 1ns / 1ps

module utype_tb();
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

        // lui x1, 0x12345
        dut.dp.instrmem_inst.mem_loc[0]  = 32'h123450B7;

        // lui x2, 0xABCDE
        dut.dp.instrmem_inst.mem_loc[3]  = 32'hABCDE137;

        // auipc x3, 0x00001 (PC = 24 = 0x18 -> 0x1000 + 0x18 = 0x1018)
        dut.dp.instrmem_inst.mem_loc[6]  = 32'h00001197;

        // auipc x4, 0x12345 (PC = 36 = 0x24 -> 0x12345000 + 0x24 = 0x12345024)
        dut.dp.instrmem_inst.mem_loc[9]  = 32'h12345217;

        dut.dp.rf.regs[1] = 32'd0;
        dut.dp.rf.regs[2] = 32'd0;
        dut.dp.rf.regs[3] = 32'd0;
        dut.dp.rf.regs[4] = 32'd0;

        #15 rst = 0;
        #350;

        if (dut.dp.rf.regs[1] !== 32'h12345000) begin
            $display("FAIL: x1 = %h (exp: 12345000)", dut.dp.rf.regs[1]);
            err_count = err_count + 1;
        end

        if (dut.dp.rf.regs[2] !== 32'hABCDE000) begin
            $display("FAIL: x2 = %h (exp: ABCDE000)", dut.dp.rf.regs[2]);
            err_count = err_count + 1;
        end

        if (dut.dp.rf.regs[3] !== 32'h00001018) begin
            $display("FAIL: x3 = %h (exp: 00001018)", dut.dp.rf.regs[3]);
            err_count = err_count + 1;
        end

        if (dut.dp.rf.regs[4] !== 32'h12345024) begin
            $display("FAIL: x4 = %h (exp: 12345024)", dut.dp.rf.regs[4]);
            err_count = err_count + 1;
        end

        if (err_count == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s).", err_count);

        $finish;
    end
endmodule