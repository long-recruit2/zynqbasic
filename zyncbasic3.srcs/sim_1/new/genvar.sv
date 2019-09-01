`timescale 1ns / 1ps

module genvartest;
    logic clk;
    logic [3:0] row;
    logic [3:0] col;
    logic [3:0] led;
    logic led5_r;
    logic led5_b;
    logic led6_r;
    logic [7:0] jb;
    logic [7:0] je;
    logic rst;

    localparam CLK_FREQ = 125e6;
    localparam CLK_HALF_PERIOD = 1/real'(CLK_FREQ)*1000e6/2;
    localparam DRIVE_DLY = 1;

    always begin
        #CLK_HALF_PERIOD clk = 1;
        #CLK_HALF_PERIOD clk = 0;
    end

    default clocking cb@(posedge clk);
    endclocking

    reg [31:0] PSCOUNTER = 0;
	int ps_counter_i;
	always_comb
		ps_counter_i = PSCOUNTER;

	logic [3:0] decimal[0:9]; // int max 2147483647 // replace with genvar
	logic [31:0] ps_counter_t[0:9];
	genvar index;
	generate
		for (index = 0; index < 10; index = index + 1) begin
			always_comb begin
				ps_counter_t[index] = int'(PSCOUNTER / int'(10^index));				
				// ps_counter_t[index] = int'(ps_counter_i / int'(10 ^ index));				
				decimal[index] = int'(ps_counter_t[index] % 10);
				$display("index : %d, ps_counter_i : %d, ps_counter_t[index] : %d , decimal %d", index, ps_counter_i, ps_counter_t[index], decimal[index]);
			end
		end
	endgenerate
    
    initial begin
        clk <= 0;
        rst <= 1;
        $display("Current time = %t", $time);
        ##10
        rst <= 0;
        PSCOUNTER <= PSCOUNTER + 1;
        ##10
        PSCOUNTER <= PSCOUNTER + 10;
        ##10
        PSCOUNTER <= PSCOUNTER + 100;
        ##10
        PSCOUNTER <= PSCOUNTER + 1000;
        $finish();
    end
endmodule