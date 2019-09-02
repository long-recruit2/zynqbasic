`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/09/02 22:20:37
// Design Name: 
// Module Name: counter_event
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

module counter_event #(parameter W = 32)
(
    input logic clk,
    input logic rstn,
    input logic counter,
    output logic changed
);

    logic [W-1:0] prev_counter = 0;
    always_ff @(posedge clk)
        if (!rstn) prev_counter <= 0;
        else prev_counter <= counter;

    always_comb
        changed = counter != prev_counter;

endmodule : counter_event
