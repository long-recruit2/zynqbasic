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
    // input wire [3:0] btn,
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
    // (* fsm_encoding = "none" *) output logic [7:0] jc,
    output logic scljd1,
    inout wire sdajd1,
    output logic scljd2,
    inout wire sdajd2,
    output logic scljc1,
    inout wire sdajc1,
    output logic scljc2,
    inout wire sdajc2,
    (* fsm_encoding = "none" *) output logic [7:0] je,
    input wire [3:0] row,            // jb
    (* fsm_encoding = "none" *) output logic [3:0] col // jb
);
    wire [7:0] oled;
    assign je = oled;
    /*
    logic scljc;
    assign scljc1 = scljc;
    assign scljc2 = scljc;
    
    logic sdajc;
    assign sdajc1 = sdajc; // To drive the inout net
    assign sdajc = sdajc1; // To read from inout net
    assign sdajc2 = sdajc; // To drive the inout net
    assign sdajc = sdajc2; // To read from inout net


    logic scljd;
    assign scljd1 = scljd;
    assign scljd2 = scljd;
    
    logic sdajd;
    assign sdajd1 = sdajd; // To drive the inout net
    assign sdajd = sdajd1; // To read from inout net
    assign sdajd2 = sdajd; // To drive the inout net
    assign sdajd = sdajd2; // To read from inout net
    */
    
    logic arm_clko;
    logic arm_rstno;

    logic [31:0] arm_gpo01;
    logic [31:0] ps_counter;

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

    logic [31:0] pl_counter = 0;
    always_ff @(posedge clk)
        if (!rstn) pl_counter <= 0;
        else pl_counter<= pl_counter + 1;

    logic counter_changed; // wire
    counter_event #(.W(32)) ev (
        .clk(clk),
        .rstn(rstn),
        .counter(ps_counter),
        .changed(counter_changed)
    );

    // apparently this module only runs with 100MHz clock
    logic [3:0] keys[2:0];

    logic [31:0] keys_32bit;
    always_comb
        keys_32bit = {20'b0, keys[2], keys[1], keys[0]};

    // logic key_trigger;
    logic rst = 'b0;
    logic keyupdated = 0;
    event_t eventupdated = None;
    (* dont_touch = "true" *) logic [31:0] ps_counter_r;
    always_ff @(posedge sysclk) begin // this may need to be arm_clko
        ps_counter_r <= ps_counter;
    end
    PmodOLEDCtrl ctrl(
        .CLK(sysclk),
        .RST(rst), // rstn may not work here
        .CS(oled[0]),
        .SDIN(oled[1]),
        .SCLK(oled[3]),
        .DC(oled[4]),
        .RES(oled[5]),
        .VBAT(oled[6]),
        .VDD(oled[7]),
        .KEYS(keys),
        .SCREEN_UPDATE(keyupdated || counter_changed || eventupdated != None),
        .PSCOUNTER(ps_counter_r),
        .EVENTUPDATE(eventupdated),
        .TENS(tens),
        .ONES(ones),
        .read_data(read_data),
        .read_data1(read_data1)
    );

    // logic [3:0] tens;
    // logic [3:0] ones;

    logic all_not_pressed;
    always_comb
        led6_b = all_not_pressed;

    logic [3:0] key;
    always_comb
        led = key == 'hA ? keys[2] : key;

    logic pressed;
    keypad_decode #(CLK_FREQ, POLL_PERIOD) decode(
        .sysclk(sysclk),
        .row(row),
        .col(col),
        .key(key),
        .pressed(pressed),
        .all_not_pressed(all_not_pressed)
    );

    /*
        input clk,
    input swF, rst, sw1, sw2,  //swF = sw15

    output scl,
    inout sda,
    output wire [6:0] seg,
    output wire [7:0] dig
    output [3:0] tens,
    output [3:0] ones
    */
    logic [6:0] seg;
    logic [7:0] dig;
    logic [3:0] tens;
    logic [3:0] ones;
    logic [15:0] data;
    // logic sw1 = 1;
    // logic sw2 = 1;
    // logic swF = 1;
    logic dummyscl;
    logic dummysda;
    i2c i(
    // i2c22 i(
        .clk(sysclk),
        .rst(rst),
        .sw1(sw[0]),
        .sw2(sw[1]),
        .swF(sw[2]),
        .scl(scljc1),
        .sda(sdajc1),
        .data(data),
        .seg(seg),
        .dig(dig),
        .tens(tens),
        .ones(ones)
        );

    logic [7:0] read_data = 0;
    logic [7:0] read_data1 = 0;
    logic rstn = 1;
    temp_sensor tmp(
        .clk(sysclk),
        .rst_n(rstn),
        .scl(scljd1),
        .sda(sdajd1),
        .read_data(read_data),
        .read_data1(read_data1)        
    );        

    logic [3:0] answer[2:0] = '{ 'h1, 'h2, 'h3}; // 123
    always_ff @(posedge sysclk) begin
        keyupdated <= 0;
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
                answer <= keys;
            end
            else begin
                keyupdated <= 1;
                eventupdated <= None;
                keys <= {keys[1:0], key};
                led5_b <= 'b0;
                led5_r <= 'b0;
            end
        end
    end

endmodule : ZYBO_top

`default_nettype wire