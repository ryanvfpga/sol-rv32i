`timescale 1ns / 1ps

module load_tb();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        // lw  x5, 0(x1)  -> load 32 bits from addr 0
        dut.dp.instrmem_inst.mem_loc[0] = 32'h0000a283; 
        // lb  x6, 1(x1)  -> load byte from addr 1 (0x80, sign-extended)
        dut.dp.instrmem_inst.mem_loc[1] = 32'h00108303; 
        // lbu x7, 1(x1)  -> load byte from addr 1 (0x80, zero-extended)
        dut.dp.instrmem_inst.mem_loc[2] = 32'h0010c383; 
        // lh  x8, 2(x1)  -> load halfword from addr 2 (0x8ABC, sign-extended)
        dut.dp.instrmem_inst.mem_loc[3] = 32'h00209403; 
        // lhu x9, 2(x1)  -> load halfword from addr 2 (0x8ABC, zero-extended)
        dut.dp.instrmem_inst.mem_loc[4] = 32'h0020d483; 

        dut.dp.instrmem_inst.mem_loc[5] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[6] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[7] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[8] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[9] = 32'h00000013;

        dut.dp.rf.regs[1] = 32'd0;

        dut.dp.rf.regs[5] = 32'd0;
        dut.dp.rf.regs[6] = 32'd0;
        dut.dp.rf.regs[7] = 32'd0;
        dut.dp.rf.regs[8] = 32'd0;
        dut.dp.rf.regs[9] = 32'd0;

        // Byte layout at word 0: [3]=0x8A, [2]=0xBC, [1]=0x80, [0]=0x7F
        dut.dp.dm.regs[0] = 32'h8ABC807F; 

        #15 rst = 0;
        #180;

        if (dut.dp.rf.regs[5] !== 32'h8ABC807F) begin 
            $display("FAIL: LW expected 8ABC807F, got %h", dut.dp.rf.regs[5]); 
            err_count = err_count + 1; 
        end
        if (dut.dp.rf.regs[6] !== 32'hFFFFFF80) begin 
            $display("FAIL: LB expected FFFFFF80, got %h", dut.dp.rf.regs[6]); 
            err_count = err_count + 1; 
        end
        if (dut.dp.rf.regs[7] !== 32'h00000080) begin 
            $display("FAIL: LBU expected 00000080, got %h", dut.dp.rf.regs[7]); 
            err_count = err_count + 1; 
        end
        if (dut.dp.rf.regs[8] !== 32'hFFFF8ABC) begin 
            $display("FAIL: LH expected FFFF8ABC, got %h", dut.dp.rf.regs[8]); 
            err_count = err_count + 1; 
        end
        if (dut.dp.rf.regs[9] !== 32'h00008ABC) begin 
            $display("FAIL: LHU expected 00008ABC, got %h", dut.dp.rf.regs[9]); 
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