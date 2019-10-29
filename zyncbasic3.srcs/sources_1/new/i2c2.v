`timescale 1ns / 1ps

module i2c2(
    input clk,
    input swF, rst, sw1, sw2,  //swF = sw15
   
    output scl,
    inout sda,
    output wire [6:0] seg,
    output wire [7:0] dig,
    output [3:0] tens,
    output [3:0] ones
    );

    wire [15:0] data;
 
   assign rst_n = ~rst;
   //Temp Sensor
   i2c22 i2(clk,rst_n,sw1,sw2,swF,scl,sda,data,seg,dig, tens, ones);

endmodule