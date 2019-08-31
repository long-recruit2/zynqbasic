`timescale 1ns / 1ps

`default_nettype none
`include "type.sv"

import types::*; // * is required to import enum label

module ZYBO_top
 #(
    parameter CLK_FREQ = 125e6,
    parameter POLL_PERIOD = 1e-3
)(
    input wire sysclk,
    // input wire rst,
    // input wire CLK125M,
    input wire [3:0] btn,
    input wire [3:0] sw,
    inout wire [14:0] DDR_addr,
    inout wire [2:0] DDR_ba,
    inout wire DDR_cas_n, DDR_ck_n, DDR_ck_p, DDR_cke, DDR_cs_n,
    inout wire [3:0] DDR_dm,
    inout wire [31:0] DDR_dq,
    inout wire [3:0] DDR_dqs_n,
    inout wire [3:0] DDR_dqs_p,
    inout wire DDR_odt, DDR_ras_n, DDR_reset_n, DDR_we_n, FIXED_IO_ddr_vrn, FIXED_IO_ddr_vrp,
    inout wire [53:0] FIXED_IO_mio,
    inout wire FIXED_IO_ps_clk, FIXED_IO_ps_porb, FIXED_IO_ps_srstb,

    output logic [3:0] led,
    output logic led6_b,
    output logic led5_b,
    output logic led5_r,
    (* fsm_encoding = "none" *) output logic [7:0] jc,
    (* fsm_encoding = "none" *) output logic [7:0] je,
    input wire [3:0] row,            // jb
    (* fsm_encoding = "none" *) output logic [3:0] col // jb
);

    wire 	arm_clko;
    wire 	arm_rstno;

    wire [31:0] arm_gpo01;
    wire [31:0] ps_counter;

    logic clk;
    always_comb
        clk = sysclk;

    logic rstn;
    always_comb
        rstn = arm_rstno;
        // rstn=rst;

    Zynq_PS Zynq_PS_i(
        // these ports come from zynq
        .DDR_addr(DDR_addr),
        .DDR_ba(DDR_ba),
        .DDR_cas_n(DDR_cas_n),
        .DDR_ck_n(DDR_ck_n),
        .DDR_ck_p(DDR_ck_p),
        .DDR_cke(DDR_cke),
        .DDR_cs_n(DDR_cs_n),
        .DDR_dm(DDR_dm),
        .DDR_dq(DDR_dq),
        .DDR_dqs_n(DDR_dqs_n),
        .DDR_dqs_p(DDR_dqs_p),
        .DDR_odt(DDR_odt),
        .DDR_ras_n(DDR_ras_n),
        .DDR_reset_n(DDR_reset_n),
        .DDR_we_n(DDR_we_n),
        .FIXED_IO_ddr_vrn(FIXED_IO_ddr_vrn),
        .FIXED_IO_ddr_vrp(FIXED_IO_ddr_vrp),
        .FIXED_IO_mio(FIXED_IO_mio),
        .FIXED_IO_ps_clk(FIXED_IO_ps_clk),
        .FIXED_IO_ps_porb(FIXED_IO_ps_porb),
        .FIXED_IO_ps_srstb(FIXED_IO_ps_srstb),
        .clko(arm_clko),   // clock from PS
        .rstno(arm_rstno), // reset from PS
        // port names come from block design port I added, connected with AXI GPIO
        .gpi01(keys_32bit), // in to cpu, out from PL
        .gpi02(pl_counter),
        .gpo01(arm_gpo01), // out from cpu, in to PL (counter)
        .gpo02(ps_counter));

    reg [31:0] 	pl_counter = 0;
    always @(posedge clk)
        if (!rstn) pl_counter<=0;
        else pl_counter<=pl_counter+1;

    logic [3:0] sw_r = 0;
    logic [3:0] btn_r = 0;

    always_ff @(posedge clk) begin
        if (pl_counter==0) begin // anti-chattering
            sw_r  <= sw;
            btn_r <= btn;
        end
    end

    logic [31:0] prev_ps_counter = 0;
    always_ff @(posedge clk)
        prev_ps_counter <= ps_counter;
    logic counter_changed;
    always_comb
        counter_changed = ps_counter != prev_ps_counter;

    // apparently this module only runs with 100MHz clock
    logic [3:0] keys[2:0];

    logic [31:0] keys_32bit;
    always_comb
        keys_32bit = {20'b0, keys[2], keys[1], keys[0]};

    // logic key_trigger;
    logic rst = 'b0;
    logic keyupdated = 0;
    event_t eventupdated = None;
    PmodOLEDCtrl ctrl(
        .CLK(sysclk),
        .RST(rst), // rstn may not work here
        .CS(je[0]),
        .SDIN(je[1]),
        .SCLK(je[3]),
        .DC(je[4]),
        .RES(je[5]),
        .VBAT(je[6]),
        .VDD(je[7]),
        .KEYS(keys),
        .SCREEN_UPDATE(keyupdated || counter_changed || eventupdated != None),
        .PSCOUNTER(ps_counter),
        .EVENTUPDATE(eventupdated)
    );

    logic all_not_pressed;
    always_comb
        led6_b = all_not_pressed;

    logic [3:0] key;
    logic pressed;
    keypad_decode #(CLK_FREQ, POLL_PERIOD) decode(
        .sysclk(sysclk),
        .row(row),
        .col(col),
        .key(key),
        .pressed(pressed),
        .all_not_pressed(all_not_pressed)
    );

    parameter [3:0] answer[2:0] = '{ 'h1, 'h2, 'h3}; // 123
    always_ff @(posedge sysclk) begin
        keyupdated <= 0;
        eventupdated <= None;
        if(pressed) begin
            if (key == 'hA) begin
                if(keys == answer) begin
                    eventupdated <=  RightAnswer;
                    led5_b <= 'b1;
                    led5_r <= 'b0;
                end
                else begin
                    eventupdated <=  WrongAnswer;
                    led5_b <= 'b0;
                    led5_r <= 'b1;
                end
            end
            else if (key == 'hB) begin
                // store new password
                eventupdated <=  NewPassword;
            end
            else begin
                keyupdated <= 1;
                keys <= {keys[1:0], key};
                led5_b <= 'b0;
                led5_r <= 'b0;
            end
        end
    end

    always_comb
        led = key == 'hA ? keys[2] : key;

endmodule : ZYBO_top

`default_nettype wire