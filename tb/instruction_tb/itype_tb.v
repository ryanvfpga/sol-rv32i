module itype_tb();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

     
        // x1=15, x2=25, x3=-5, x4=3
        dut.dp.instrmem_inst.mem_loc[0] = 32'h00a08293; // addi x5, x1, 10   (15 + 10 = 25)
        dut.dp.instrmem_inst.mem_loc[1] = 32'h0001a313; // slti x6, x3, 0    (-5 < 0 = 1)
        dut.dp.instrmem_inst.mem_loc[2] = 32'h00a1b393; // sltiu x7, x3, 10  (unsigned -5 < 10 = 0)
        dut.dp.instrmem_inst.mem_loc[3] = 32'h00f0c413; // xori x8, x1, 15   (15 ^ 15 = 0)
        dut.dp.instrmem_inst.mem_loc[4] = 32'h00616493; // ori x9, x2, 6     (25 | 6 = 31)
        dut.dp.instrmem_inst.mem_loc[5] = 32'h00917513; // andi x10, x2, 9   (25 & 9 = 9)
        dut.dp.instrmem_inst.mem_loc[6] = 32'h00221593; // slli x11, x4, 2   (3 << 2 = 12)
        dut.dp.instrmem_inst.mem_loc[7] = 32'h00215613; // srli x12, x2, 2   (25 >> 2 = 6)
        dut.dp.instrmem_inst.mem_loc[8] = 32'h4021d693; // srai x13, x3, 2   (-5 >>> 2 = -2)

        // nops
        dut.dp.instrmem_inst.mem_loc[9] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[10] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[11] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[12] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[13] = 32'h00000013;

        // init registers
        dut.dp.rf.regs[1] = 32'd15;
        dut.dp.rf.regs[2] = 32'd25;
        dut.dp.rf.regs[3] = -32'd5;
        dut.dp.rf.regs[4] = 32'd3;

        #15 rst = 0;

       
        #150;
        
        if (dut.dp.rf.regs[5] !== 32'd25) begin $display("ADDI failed: expected 25, got %d", dut.dp.rf.regs[5]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[6] !== 32'd1)  begin $display("SLTI failed: expected 1, got %d", dut.dp.rf.regs[6]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[7] !== 32'd0)  begin $display("SLTIU failed: expected 0, got %d", dut.dp.rf.regs[7]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[8] !== 32'd0)  begin $display("XORI failed: expected 0, got %d", dut.dp.rf.regs[8]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[9] !== 32'd31) begin $display("ORI failed: expected 31, got %d", dut.dp.rf.regs[9]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[10] !== 32'd9) begin $display("ANDI failed: expected 9, got %d", dut.dp.rf.regs[10]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[11] !== 32'd12) begin $display("SLLI failed: expected 12, got %d", dut.dp.rf.regs[11]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[12] !== 32'd6)  begin $display("SRLI failed: expected 6, got %d", dut.dp.rf.regs[12]); err_count = err_count + 1; end
        if (dut.dp.rf.regs[13] !== -32'd2) begin $display("SRAI failed: expected -2, got %d", $signed(dut.dp.rf.regs[13])); err_count = err_count + 1; end
        
        if (err_count == 0) begin
            $display("Test finished. All I-type instructions passed.");
        end else begin
            $display("Test finished with %d errors.", err_count);
        end

        $finish;
    end
endmodule