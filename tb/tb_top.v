`timescale 1ns / 1ps

module tb_top();
    reg clk;
    reg rst;
    integer timeout;

    reg [1024*8-1:0] imem_file;
    reg [1024*8-1:0] dmem_file;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;

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

        #15 rst = 0;

        // 3. Poll address 0x1FFC (word index 1023) for signature with a 10,000 cycle timeout
        timeout = 0;
        // Wait as long as the signature is NOT 1 (PASS) and NOT 2 (FAIL)
        while (dut.dp.dm.regs[1023] !== 32'd1 && dut.dp.dm.regs[1023] !== 32'd2 && timeout < 10000) begin
            #10;
            timeout = timeout + 1;
        end

        // Verify status code (PASS/FAIL)
        if (dut.dp.dm.regs[1023] === 32'd1) begin
            $display("PASS");
        end else if (dut.dp.dm.regs[1023] === 32'd2) begin
            $display("FAIL: C execution reported test assertion failure (Signature = 2)");
        end else if (timeout >= 10000) begin
            $display("FAIL: Simulation Timeout (CPU did not write signature to 0x1FFC)");
        end else begin
            $display("FAIL: Unexpected signature value 0x%h", dut.dp.dm.regs[1023]);
        end

        $finish;
    end
endmodule