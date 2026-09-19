`timescale 1ns / 1ps

module datamem(
    input [31:0] address,
    input [31:0] write_data,
    output reg [31:0] data,
    input clk,
    input mem_write,
    input [2:0] funct3,
    input rst
    );
    
    reg [31:0] temp_data;

    reg [31:0] regs [0:1023];
    
    reg [7:0] mem_byte; 
    reg [15:0] halfword;
    wire [31:0] read_data;
    
    assign read_data = regs[address[31:2]];

    always @(posedge clk)
        if(rst)
            data <= 32'b0;
        else
            data <= temp_data;

    always @(*) begin
        case(address[1:0]) 
            2'b00: mem_byte = read_data[7:0];
            2'b01: mem_byte = read_data[15:8];
            2'b10: mem_byte = read_data[23:16];
            2'b11: mem_byte = read_data[31:24];
        endcase
       
        case(address[1])
            1'b0: halfword = read_data[15:0];
            1'b1: halfword = read_data[31:16];
        endcase
       
        case(funct3) 
            3'b000: temp_data = {{24{mem_byte[7]}}, mem_byte};     // LB
            3'b001: temp_data = {{16{halfword[15]}}, halfword};    // LH
            3'b010: temp_data = read_data;                         // LW
            3'b100: temp_data = {24'b0, mem_byte};                 // LBU
            3'b101: temp_data = {16'b0, halfword};                 // LHU
            default: temp_data = read_data;
        endcase
    end
    
    always @(posedge clk) begin
        if (mem_write) begin
            case(funct3)
                3'b000: begin
                    case(address[1:0])
                        2'b00: regs[address[31:2]][7:0]   <= write_data[7:0];
                        2'b01: regs[address[31:2]][15:8]  <= write_data[7:0];
                        2'b10: regs[address[31:2]][23:16] <= write_data[7:0];
                        2'b11: regs[address[31:2]][31:24] <= write_data[7:0];
                    endcase
                end
                3'b001: begin
                    if(address[1])
                        regs[address[31:2]][31:16] <= write_data[15:0];
                    else
                        regs[address[31:2]][15:0]  <= write_data[15:0];
                end
                3'b010: begin
                    regs[address[31:2]] <= write_data;
                end
            endcase
        end
    end
    
endmodule