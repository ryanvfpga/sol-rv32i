`timescale 1ns / 1ps

module bubble_sort();
    reg clk;
    reg rst;
    integer err_count;

    cpu dut (.clk(clk), .rst(rst));

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        err_count = 0;

        // Initialize 8 unsorted elements in Data Memory 
        dut.dp.dm.regs[0] = 32'd88;
        dut.dp.dm.regs[1] = 32'd33;
        dut.dp.dm.regs[2] = 32'd55;
        dut.dp.dm.regs[3] = 32'd11;
        dut.dp.dm.regs[4] = 32'd99;
        dut.dp.dm.regs[5] = 32'd22;
        dut.dp.dm.regs[6] = 32'd77;
        dut.dp.dm.regs[7] = 32'd44;

      
        dut.dp.instrmem_inst.mem_loc[0]  = 32'h00000093; // init:       addi x1, x0, 0   (Base Address = 0)
        dut.dp.instrmem_inst.mem_loc[1]  = 32'h00800113; //             addi x2, x0, 8   (Array Size N = 8)
        
        dut.dp.instrmem_inst.mem_loc[2]  = 32'hfff10113; // outer_loop: addi x2, x2, -1  (N = N - 1)
        dut.dp.instrmem_inst.mem_loc[3]  = 32'h02010863; //             beq x2, x0, end  (if N == 0, done)
        dut.dp.instrmem_inst.mem_loc[4]  = 32'h000001b3; //             add x3, x0, x0   (j = 0)
        dut.dp.instrmem_inst.mem_loc[5]  = 32'h00008233; //             add x4, x1, x0   (ptr = base_address)
        
        dut.dp.instrmem_inst.mem_loc[6]  = 32'hfe21d8e3; // inner_loop: bge x3, x2, outer_loop (if j >= N, next pass)
        dut.dp.instrmem_inst.mem_loc[7]  = 32'h00022283; //             lw x5, 0(x4)     (load arr[j])
        dut.dp.instrmem_inst.mem_loc[8]  = 32'h00422303; //             lw x6, 4(x4)     (load arr[j+1])
        dut.dp.instrmem_inst.mem_loc[9]  = 32'h00535663; //             bge x6, x5, no_swap (if arr[j+1] >= arr[j], skip)
        
        dut.dp.instrmem_inst.mem_loc[10] = 32'h00622023; // swap:       sw x6, 0(x4)     (arr[j] = arr[j+1])
        dut.dp.instrmem_inst.mem_loc[11] = 32'h00522223; //             sw x5, 4(x4)     (arr[j+1] = arr[j])
        
        dut.dp.instrmem_inst.mem_loc[12] = 32'h00118193; // no_swap:    addi x3, x3, 1   (j = j + 1)
        dut.dp.instrmem_inst.mem_loc[13] = 32'h00420213; //             addi x4, x4, 4   (ptr = ptr + 4 bytes)
        dut.dp.instrmem_inst.mem_loc[14] = 32'hFE1FF06F; //             jal x0, inner_loop (jump to inner_loop)
        
        dut.dp.instrmem_inst.mem_loc[15] = 32'h00000013; // end:        nop
        


        dut.dp.instrmem_inst.mem_loc[16] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[17] = 32'h00000013;
        dut.dp.instrmem_inst.mem_loc[18] = 32'h00000013;

        #15 rst = 0;
   
        #8000; 

        if (dut.dp.dm.regs[0] > dut.dp.dm.regs[1]) begin $display("FAIL: Element out of order at index 0!"); err_count = err_count + 1; end
        if (dut.dp.dm.regs[1] > dut.dp.dm.regs[2]) begin $display("FAIL: Element out of order at index 1!"); err_count = err_count + 1; end
        if (dut.dp.dm.regs[2] > dut.dp.dm.regs[3]) begin $display("FAIL: Element out of order at index 2!"); err_count = err_count + 1; end
        if (dut.dp.dm.regs[3] > dut.dp.dm.regs[4]) begin $display("FAIL: Element out of order at index 3!"); err_count = err_count + 1; end
        if (dut.dp.dm.regs[4] > dut.dp.dm.regs[5]) begin $display("FAIL: Element out of order at index 4!"); err_count = err_count + 1; end
        if (dut.dp.dm.regs[5] > dut.dp.dm.regs[6]) begin $display("FAIL: Element out of order at index 5!"); err_count = err_count + 1; end
        if (dut.dp.dm.regs[6] > dut.dp.dm.regs[7]) begin $display("FAIL: Element out of order at index 6!"); err_count = err_count + 1; end

        if (err_count == 0) begin
            $display("PASS");
        end else begin
            $display("FAIL: %0d error(s).", err_count);
        end

        $finish;
    end
endmodule