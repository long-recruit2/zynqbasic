`timescale 1ns / 1ps

module I2CTest;
    logic clk;
    logic rst;

    logic sw1 = 0;
    logic sw2 = 0;
    logic swF = 0;
    logic scl = 0;
    wire sda;
    logic [15:0] data;
    logic [6:0] seg;
    logic [7:0] dig;
    logic [4:0] tens;
    logic [4:0] ones;

    localparam CLK_FREQ = 125e6;
    localparam CLK_HALF_PERIOD = 1/real'(CLK_FREQ)*1000e6/2;
    localparam DRIVE_DLY = 1;

    always begin
        #CLK_HALF_PERIOD clk = 1;
        #CLK_HALF_PERIOD clk = 0;
    end

    default clocking cb@(posedge clk);
    endclocking

    i2c i(
        .*
    );

    logic scl2 = 0;
    wire sda2;
    wire [6:0] seg2;
    wire [7:0] dig2;
    logic [3:0] tens2;
    logic [3:0] ones2;

    i2c2 i2(
        .clk(clk),
        .rst(rst),
        .scl(scl2),
        .sda(sda2),
        .seg(seg2),
        .dig(dig2),
        .tens(tens2),
        .ones(ones2)
    );
    /*
    input clk,
    input swF, rst, sw1, sw2,  //swF = sw15

    output scl,
    inout sda,
    output wire [6:0] seg,
    output wire [7:0] dig,
    output [3:0] tens,
    output [3:0] ones
    );
    */

    initial begin
        clk <= 0;
        rst <= 1;
        // $display("Current time = %t", $time);
        ##1
            rst <= 0;
        ##1000
            ;
        ##1000
            ;
        ##1000
            ;
        ##1000
            ;
        $finish();
    end
endmodule
