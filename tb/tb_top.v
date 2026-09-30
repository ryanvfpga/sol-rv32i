`timescale 1ns / 1ps

module tb_top();
    localparam MEM_WORDS = 8192;                 // 32 KB / 4
    localparam SIG_WORD  = MEM_WORDS - 1;        // 0x7FFC : PASS(1)/FAIL(2)
    localparam TN_WORD   = MEM_WORDS - 2;        // 0x7FF8 : failing TESTNUM (riscv-tests)
    localparam MAX_CYCLES = 800000;

    reg clk;
    reg rst;
    integer timeout;
    integer i;

    reg [1024*8-1:0] imem_file;
    reg [1024*8-1:0] dmem_file;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

        // NOP all IMEM locations
        for (i = 0; i < MEM_WORDS; i = i + 1) begin
            dut.dp.instrmem_inst.mem_loc[i] = 32'h00000013;
            dut.dp.dm.regs[i]               = 32'h0;
        end

        //Load .hex files for instruction/data memory dynamically.
        if ($value$plusargs("IMEM_HEX=%s", imem_file)) begin
            $readmemh(imem_file, dut.dp.instrmem_inst.mem_loc);
        end else begin
            $display("FAIL: Missing +IMEM_HEX argument");
            $finish;
        end

        if ($value$plusargs("DMEM_HEX=%s", dmem_file)) begin
            $readmemh(dmem_file, dut.dp.dm.regs);
        end

        #17 rst = 0;

        // Poll the signature word (top of DMEM, 0x7FFC) until PASS(1) / FAIL(2) or timeout.
        timeout = 0;
        while (dut.dp.dm.regs[SIG_WORD] !== 32'd1 && dut.dp.dm.regs[SIG_WORD] !== 32'd2 && timeout < MAX_CYCLES) begin
            #10;
            timeout = timeout + 1;
        end

        $display("CYCLES: %0d", dut.dp.mcycle);
        $display("INSTRET: %0d", dut.dp.minstret);
        if (dut.dp.minstret != 0) begin
            $display("CPI: %0.3f", $itor(dut.dp.mcycle) / $itor(dut.dp.minstret));
            $display("IPC: %0.3f", $itor(dut.dp.minstret) / $itor(dut.dp.mcycle));
        end

        $display("BRANCHES: %0d", dut.dp.branch_count);
        $display("MISPREDICTS: %0d", dut.dp.branch_mispredict);
        if (dut.dp.branch_count != 0)
            $display("BP_ACCURACY: %0.2f%%", 100.0 * (1.0 - $itor(dut.dp.branch_mispredict) / $itor(dut.dp.branch_count)));

        // Verify status code (PASS/FAIL)
        if (dut.dp.dm.regs[SIG_WORD] === 32'd1) begin
            $display("PASS");
        end else if (dut.dp.dm.regs[SIG_WORD] === 32'd2) begin
            $display("FAIL: test reported failure (Signature = 2, TESTNUM = %0d)", dut.dp.dm.regs[TN_WORD]);
        end else if (timeout >= MAX_CYCLES) begin
            $display("FAIL: Simulation Timeout (CPU did not write signature to 0x7FFC)");
        end else begin
            $display("FAIL: Unexpected signature value 0x%h", dut.dp.dm.regs[SIG_WORD]);
        end

        $finish;
    end
endmodule