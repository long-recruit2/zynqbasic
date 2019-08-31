`default_nettype none
`timescale 1ns / 1ps

module keypad_decode #(
    parameter CLK_FREQ = 125e6,
    parameter POLL_PERIOD = 1e-3
)(
    input wire sysclk,
    input wire [3:0] row,
    (* fsm_encoding = "none" *) output logic [3:0] col = 'b0111,
    output logic [3:0] key = 0,
    output logic pressed,
    output logic all_not_pressed
);
    localparam int CLK_DIV_COUNT = CLK_FREQ * POLL_PERIOD;
    logic [$clog2(CLK_DIV_COUNT)-1:0] counter = 0;

    logic [3:0] notpressed = 'h00;
    // logic all_not_pressed = 0;
    logic all_not_pressed_prev = 0;

    always_ff @(posedge sysclk)
        counter <= counter + 1;

    always_ff @(posedge sysclk)
        if (counter == 0)
            unique case (col)
                'b0111: col <= 'b1011;
                'b1011: col <= 'b1101;
                'b1101: col <= 'b1110;
                'b1110: col <= 'b0111;
            endcase

    always_ff @(posedge sysclk) begin
        if (counter == CLK_DIV_COUNT/2)
            unique case (col)
                'b0111: begin
                    notpressed[0] <= 'b0;
                    unique case(row)
                        'b0111: key <= 'h1;
                        'b1011: key <= 'h4;
                        'b1101: key <= 'h7;
                        'b1110: key <= 'h0;
                        default: notpressed[0] <= 'b1;
                    endcase
                end
                'b1011: begin
                    notpressed[1] <= 'b0;
                    unique case(row)
                        'b0111: key <= 'h2;
                        'b1011: key <= 'h5;
                        'b1101: key <= 'h8;
                        'b1110: key <= 'hF;
                        default: notpressed[1] <= 'b1;
                    endcase
                end
                'b1101: begin
                    notpressed[2] <= 'b0;
                    unique case(row)
                        'b0111: key <= 'h3;
                        'b1011: key <= 'h6;
                        'b1101: key <= 'h9;
                        'b1110: key <= 'hE;
                        default: notpressed[2] <= 'b1;
                    endcase
                end
                'b1110: begin
                    notpressed[3] <= 'b0;
                    unique case(row)
                        'b0111: key <= 'hA;
                        'b1011: key <= 'hB;
                        'b1101: key <= 'hC;
                        'b1110: key <= 'hD;
                        default: notpressed[3] <= 'b1;
                    endcase
                end
            endcase
    end

    always_comb
        all_not_pressed = notpressed[0] & notpressed[1] & notpressed[2] & notpressed[3];

    always_ff @(posedge sysclk)
        all_not_pressed_prev <= all_not_pressed;

    always_comb
        pressed = all_not_pressed == 0 && all_not_pressed_prev == 1;
    
endmodule : keypad_decode
`default_nettype wire