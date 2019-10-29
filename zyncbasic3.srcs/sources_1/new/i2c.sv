`timescale 1ns / 1ps

module i2c(
	clk,rst,
	sw1,sw2,swF,
	scl,sda,
	data,
	seg, dig,
	tens, ones
);

	input  clk;		// 100MHz
	input  rst;
	input  sw1,sw2;
	input swF;
	output scl;
	output [7:0] dig;
	output [6:0] seg;
	inout wire sda;
	output [15:0] data;
	output [4:0] tens;
	output [4:0] ones;


//--------------------------------------------

	reg sw1_r,sw2_r;
	reg swF_r;
	reg[19:0] cnt_20ms;

	always @ (posedge clk)
		if(rst)
			cnt_20ms <= 20'd0;
		else
			cnt_20ms <= cnt_20ms+1'b1;

	always @ (posedge clk)
		if(rst)
			begin
				sw1_r <= 1'b1;
				sw2_r <= 1'b1;
			end
		else if(cnt_20ms == 20'hfffff)
			begin
				sw1_r <= sw1;
				sw2_r <= sw2;
			end



//---------------------------------------------

	reg[2:0] cnt;
	reg[8:0] cnt_delay;
	reg[31:0] count;
	reg clk1=1'b0;
	reg scl_r;

	always @ (posedge clk)
		if(rst)
			cnt_delay <= 10'd0;
		else if(cnt_delay == 10'd999) // 100KHz -> 10us
			cnt_delay <= 10'd0;
		else
			cnt_delay <= cnt_delay+1'b1;

	always @ (posedge clk)
		if(rst)
			begin
				count<=0;
			end
		else
			begin
				if(count==32'd100000)
					begin
						clk1<=~clk1;
						count<=0;
					end
				else count<=count+1;
			end

	always @ (posedge clk) begin
		if(rst)
			cnt <= 3'd5;
		else
			begin
				case (cnt_delay)
					9'd124:	cnt <= 3'd1;
					9'd249:	cnt <= 3'd2;
					9'd374:	cnt <= 3'd3;
					9'd499:	cnt <= 3'd0;
					default: cnt <= 3'd5;
				endcase
			end
	end

	`define SCL_POS		(cnt==3'd0)
	`define SCL_HIG		(cnt==3'd1)
	`define SCL_NEG		(cnt==3'd2)
	`define SCL_LOW		(cnt==3'd3)

	always @ (posedge clk)
		if(rst)
			scl_r <= 1'b0;
		else if(cnt==3'd0)
			scl_r <= 1'b1;
		else if(cnt==3'd2)
			scl_r <= 1'b0;

	assign scl = scl_r;
//---------------------------------------------


	`define	READ	8'b1001_0111
	`define WRITE	8'b1001_0110 // 4b + 0(read)
	// `define WRITE	8'h4b

	`define	WR_DATA      8'b0000_0111
	`define REG_ADDR    8'b0000_0000

	reg[7:0] db_r;
	reg[15:0] read_data;

//---------------------------------------------
	parameter 	IDLE 	= 4'd0;
	parameter 	START1 	= 4'd1;
	parameter 	ADD1 	= 4'd2;
	parameter 	ACK1 	= 4'd3;
	parameter 	ADD2 	= 4'd4;
	parameter 	ACK2 	= 4'd5;
	parameter 	START2 	= 4'd6;
	parameter 	ADD3 	= 4'd7;
	parameter 	ACK3	= 4'd8;
	parameter 	MSB 	= 4'd9;
	parameter 	ACK4	= 4'd10;
	parameter 	LSB 	= 4'd11;
	parameter 	NACK	= 4'd12;
	parameter 	STOP1 	= 4'd13;
	parameter 	STOP2 	= 4'd14;

	reg[3:0] state;
	reg sda_r;
	reg sda_link;
	reg[3:0] num;

	always @ (posedge clk)
		begin
			if(rst)
				begin
					state <= IDLE;
					sda_r <= 1'b1;
					sda_link <= 1'b0;
					num <= 4'd0;
					read_data <= 16'b0000_0000_0000_0000;
				end
			else
				case (state)
					IDLE:
						begin
							sda_link <= 1'b1;
							sda_r <= 1'b1;
							if(!sw1_r || !sw2_r)
								begin
									// db_r <= `WRITE;
									// state <= START1;
									db_r <= `READ;
									state <= START2;
								end
							else
								state <= IDLE;
						end
					START1:
						begin
							if(`SCL_HIG)
								begin
									sda_link <= 1'b1;
									sda_r <= 1'b0;
									state <= ADD1;
									num <= 4'd0;
								end
							else
								state <= START1;
						end
					ADD1:
						begin
							if(`SCL_LOW)
								begin
									if(num == 4'd8)
										begin
											num <= 4'd0;
											sda_r <= 1'b1;
											sda_link <= 1'b0;
											state <= ACK1;
										end
									else
										begin
											state <= ADD1;
											num <= num+1'b1;
											case (num)
												4'd0: sda_r <= db_r[7];
												4'd1: sda_r <= db_r[6];
												4'd2: sda_r <= db_r[5];
												4'd3: sda_r <= db_r[4];
												4'd4: sda_r <= db_r[3];
												4'd5: sda_r <= db_r[2];
												4'd6: sda_r <= db_r[1];
												4'd7: sda_r <= db_r[0];
												default: ;
											endcase
										end
								end
							else
								state <= ADD1;
						end
					ACK1:
						begin
							if(/*!sda*/`SCL_NEG)
								begin
									state <= ADD2;
									db_r <= `REG_ADDR;
								end
							else
								state <= ACK1;
						end
					ADD2:
						begin
							if(`SCL_LOW)
								begin
									if(num==4'd8)
										begin
											num <= 4'd0;
											sda_r <= 1'b1;
											sda_link <= 1'b0;
											state <= ACK2;
										end
									else
										begin
											sda_link <= 1'b1;
											num <= num+1'b1;
											case (num)
												4'd0: sda_r <= db_r[7];
												4'd1: sda_r <= db_r[6];
												4'd2: sda_r <= db_r[5];
												4'd3: sda_r <= db_r[4];
												4'd4: sda_r <= db_r[3];
												4'd5: sda_r <= db_r[2];
												4'd6: sda_r <= db_r[1];
												4'd7: sda_r <= db_r[0];
												default: ;
											endcase
											state <= ADD2;
										end
								end
							else
								state <= ADD2;
						end
					ACK2:	begin
						if(/*!sda*/`SCL_NEG) begin
							if(!sw1_r) begin
								state <= MSB;
								db_r <= `WR_DATA;
							end
							else if(!sw2_r) begin
								db_r <= `READ;
								state <= START2;
							end
						end
						else state <= ACK2;
					end
					START2: begin
						if(`SCL_LOW) begin
							sda_link <= 1'b1;
							sda_r <= 1'b1;
							state <= START2;
						end
						else if(`SCL_HIG) begin
							sda_r <= 1'b0;
							state <= ADD3;
						end
						else state <= START2;
					end
					ADD3:	begin
						if(`SCL_LOW) begin
							if(num==4'd8) begin
								num <= 4'd0;
								sda_r <= 1'b1;
								sda_link <= 1'b0;
								state <= ACK3;
							end
							else begin
								num <= num+1'b1;
								case (num)
									4'd0: sda_r <= db_r[7];
									4'd1: sda_r <= db_r[6];
									4'd2: sda_r <= db_r[5];
									4'd3: sda_r <= db_r[4];
									4'd4: sda_r <= db_r[3];
									4'd5: sda_r <= db_r[2];
									4'd6: sda_r <= db_r[1];
									4'd7: sda_r <= db_r[0];
									default: ;
								endcase
								state <= ADD3;
							end
						end
						else state <= ADD3;
					end
					ACK3:	begin
						if(/*!sda*/`SCL_NEG) begin
							state <= MSB;
							sda_link <= 1'b0;
						end
						else state <= ACK3;
					end
					MSB:	begin
						if(!sw2_r) begin
							if(num<=4'd7) begin
								state <= MSB;
								if(`SCL_HIG) begin
									num <= num+1'b1;
									case (num)
										4'd0: read_data[15] <= sda;
										4'd1: read_data[14] <= sda;
										4'd2: read_data[13] <= sda;
										4'd3: read_data[12] <= sda;
										4'd4: read_data[11] <= sda;
										4'd5: read_data[10] <= sda;
										4'd6: read_data[9] <= sda;
										4'd7: read_data[8] <= sda;
										default: ;
									endcase
								end
							end
							else if((`SCL_LOW) && (num==4'd8)) begin
								num <= 4'd0;
								state <= ACK4;
							end
							else state <= MSB;
						end
					end
					ACK4: begin
						if(/*!sda*/`SCL_HIG)
							begin
								sda_link <= 1'b1;
								sda_r <= 1'b0;
								state <= LSB;
							end
						else state <= ACK4;
					end
					LSB:	begin
						if(!sw2_r) begin
							if(num<=4'd7) begin
								state <= LSB;
								if(`SCL_HIG) begin
									num <= num+1'b1;
									case (num)
										4'd0: read_data[7] <= sda;
										4'd1: read_data[6] <= sda;
										4'd2: read_data[5] <= sda;
										4'd3: read_data[4] <= sda;
										4'd4: read_data[3] <= sda;
										4'd5: read_data[2] <= sda;
										4'd6: read_data[1] <= sda;
										4'd7: read_data[0] <= sda;
										default: ;
									endcase
								end
							end
							else if((`SCL_LOW) && (num==4'd8)) begin
								num <= 4'd0;
								state <= NACK;
							end
							else state <= LSB;
						end
					end
					NACK: begin
						if(/*!sda*/`SCL_HIG) begin
							sda_link <= 1'b1;
							sda_r <= 1'b1;
							state <= STOP1;
						end
						else state <= NACK;
					end
					STOP1:	begin
						if(`SCL_LOW) begin
							sda_link <= 1'b1;
							sda_r <= 1'b0;
							state <= STOP1;
						end
						else if(`SCL_HIG) begin
							sda_r <= 1'b1;
							state <= STOP2;
						end
						else state <= STOP1;
					end
					STOP2:	begin
						if(`SCL_LOW) sda_r <= 1'b1;
						else if(cnt_20ms==20'hffff0) state <= IDLE;
						else state <= STOP2;
					end
					default: state <= IDLE;
				endcase
		end

	assign sda = sda_link ? sda_r:1'bz;
	assign data = read_data;
	assign swF_n = ~swF;

	tempF t( clk1,swF,data[14:7],seg,dig, tens, ones);

endmodule