`timescale 1ns / 1ps

module store_tb();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        dut.dp.instrmem_inst.mem_loc[0] = 32'h0050a023; // sw x5, 0(x1)   -> addr 0, word 0
        dut.dp.instrmem_inst.mem_loc[1] = 32'h00609123; // sh x6, 2(x1)   -> addr 2, upper half of word 0
        dut.dp.instrmem_inst.mem_loc[2] = 32'h00708423; // sb x7, 8(x1)   -> addr 8, byte 0 of word 2
        dut.dp.instrmem_inst.mem_loc[3] = 32'h00809623; // sh x8, 12(x1)  -> addr 12, lower half of word 3

        // nops 
        dut.dp.instrmem_inst.mem_loc[4] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[5] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[6] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[7] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[8] = 32'h00000013;

        // init base registers for addressing
        dut.dp.rf.regs[1] = 32'd0;

        // init registers with data to be stored into memory
        dut.dp.rf.regs[5] = 32'h11223344; 
        dut.dp.rf.regs[6] = 32'h0000AABB; 
        dut.dp.rf.regs[7] = 32'h000000CC; 
        dut.dp.rf.regs[8] = 32'h0000DDEE; 
        
        //clearing datamemory for testing
        dut.dp.dm.regs[0] = 32'd0;
        dut.dp.dm.regs[1] = 32'd0;
        dut.dp.dm.regs[2] = 32'd0;
        dut.dp.dm.regs[3] = 32'd0;

        #15 rst = 0;

        // wait for 4 instrs + 5 nops to clear the MEM stage
        #150;

        if (dut.dp.dm.regs[0] !== 32'hAABB3344) begin $display("FAIL: SW/SH 1 expected AABB3344, got %h", dut.dp.dm.regs[0]); err_count = err_count + 1; end
        if (dut.dp.dm.regs[2] !== 32'h000000CC) begin $display("FAIL: SB expected 000000CC, got %h", dut.dp.dm.regs[2]); err_count = err_count + 1; end
        if (dut.dp.dm.regs[3] !== 32'h0000DDEE) begin $display("FAIL: SH 2 expected 0000DDEE, got %h", dut.dp.dm.regs[3]); err_count = err_count + 1; end

        if (err_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s).", err_count);
        end

        $finish;
    end
endmodule