`timescale 1ns / 1ps

module datamem(
    input [31:0] address,
    input [31:0] write_data,
    output [31:0] data,
    input clk,
    input mem_write,
    input [2:0] funct3,
    input rst
    );
    
    reg [31:0] temp_data;
    reg [31:0] regs [0:8191];
    reg [7:0] mem_byte; 
    reg [15:0] halfword;
    reg [31:0] read_data;
    reg [31:0] reg_address;
    reg [2:0] reg_funct3;
    
    assign data = temp_data;

    always @(posedge clk)
        if(rst) begin
            read_data <= 32'b0;
            reg_address <= 32'b0;
            reg_funct3 <= 3'b0;
        end else begin
            read_data <= regs[address[31:2]];
            reg_address <= address;
            reg_funct3 <= funct3;
        end

    always @(*) begin
        case(reg_address[1:0]) 
            2'b00: mem_byte = read_data[7:0];
            2'b01: mem_byte = read_data[15:8];
            2'b10: mem_byte = read_data[23:16];
            2'b11: mem_byte = read_data[31:24];
        endcase
       
        case(reg_address[1])
            1'b0: halfword = read_data[15:0];
            1'b1: halfword = read_data[31:16];
        endcase
       
        case(reg_funct3) 
            3'b000: temp_data = {{24{mem_byte[7]}}, mem_byte};     // LB
            3'b001: temp_data = {{16{halfword[15]}}, halfword};    // LH
            3'b010: temp_data = read_data;                         // LW
            3'b100: temp_data = {24'b0, mem_byte};                 // LBU
            3'b101: temp_data = {16'b0, halfword};                 // LHU
            default: temp_data = read_data;
        endcase
    end
    
    reg [3:0] we;

    always @(*) begin
        case(funct3)
            3'b000: 
            begin
                case(address[1:0]) //SB
                    2'b00: we = 4'b0001;
                    2'b01: we = 4'b0010;
                    2'b10: we = 4'b0100;
                    2'b11: we = 4'b1000;
                endcase
            end
            3'b001: we = (!address[1])?4'b0011:4'b1100; //SHW
            3'b010: we = 4'b1111; //SW
            default: we = 4'b0000;

        endcase
    end

   reg [31:0] align_data;
    always @(*) begin
        case(funct3)
            3'b000:  align_data = {4{write_data[7:0]}}; 
            3'b001:  align_data = {2{write_data[15:0]}}; 
            3'b010:  align_data = write_data;            
            default: align_data = write_data;
        endcase
    end

    always @(posedge clk) begin
        if(mem_write) begin
            if (we[0]) regs[address[31:2]][7:0]   <= align_data[7:0];
            if (we[1]) regs[address[31:2]][15:8]  <= align_data[15:8];
            if (we[2]) regs[address[31:2]][23:16] <= align_data[23:16];
            if (we[3]) regs[address[31:2]][31:24] <= align_data[31:24];
        end
    end

    
endmodule