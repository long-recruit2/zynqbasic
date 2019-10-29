`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/29 22:15:30
// Design Name: 
// Module Name: i2c_reader_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module i2c_reader_tb();
    logic clk = 0;
    logic rst = 0;
    logic en = 0;
    localparam CLK_FREQ = 100e6;
    localparam CLK_HALF_PERIOD = 1/real'(CLK_FREQ)*1000e6/2;
    always begin
        #CLK_HALF_PERIOD clk = 1;
        #CLK_HALF_PERIOD clk = 0;
    end
    
    logic scl;
    wire sda;
    logic [15:0] read;
    logic done;

    i2c_reader i2c(.*);
    
    localparam int SCLCOUNT = CLK_FREQ / (1000 * 4 * 100);
    logic [$clog2(SCLCOUNT):0] count = 0;
    logic scl_lo = 0;
    always_ff @(posedge clk)
        if(count == SCLCOUNT)
            count <= 0;
        else if(en)
            count++;

    always_ff @(posedge clk) begin
        if(count == SCLCOUNT / 2 && en)
            scl_lo <= ~scl_lo;
    end

    default clocking clock @(posedge clk);
    endclocking
    
    initial begin
        ##1
        rst <= 1;
        ##1
        rst <= 0;
        en <= 1;
        #1000000
        $finish(1);
    end
endmodule
