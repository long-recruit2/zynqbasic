module temp_sensor(
	clk,rst_n,scl,sda,read_data,read_data1
);

	input clk,rst_n;
	output scl;
	inout sda;
	output [7:0] read_data;
	output [7:0] read_data1;



	reg scl;


	reg clk_out;

	parameter N=200;
	reg [32:0] counter;

	always@(posedge clk,negedge rst_n)
		begin

			if(!rst_n)
				begin
					counter <= 32'd0;
					clk_out <= 1'b0;
				end
			else if(counter == ((N/2)-1))
				begin
					clk_out<=~clk_out;
					counter<=1'b0;
				end
			else counter <=counter +1'b1;


		end

	always@(posedge clk_out,negedge rst_n)

		begin

			if(!rst_n)
				scl <= 1'b1;
			else
				scl <= ~scl;

		end

//`define DEVICE_READ  8'b10010111 //��?���팏�n���i?����j
//`define DEVICE_WRITE 8'b10010110 //��?���팏�n���i�ʑ���j
//`define WRITE_DATA      8'b0000_0111 //�ʓ�EEPROM�I����
//`define BYTE_ADDR 8'b0000_0000 //�ʓ�/?�oEEPROM�I�n���񑶊�

	parameter  ready = 4'd0;
	parameter  idle  = 4'd1;
	parameter  start  = 4'd2;
	parameter  add1  = 4'd3;
	parameter  add2  = 4'd4;
	parameter  idle1  = 4'd5;
	parameter  wait1 = 4'd6;
	parameter  add3  = 4'd7;
	parameter  add4  = 4'd8;
	parameter  add5 = 4'd9;
	parameter  stop  = 4'd10;
	parameter  stop1 = 4'd11;


	reg[3:0] state; //��?�񑶊�
	reg sda_r;  //?�o�����񑶊�
	reg sda_link; //?�o����sda�M��inout�����T����
	reg [3:0] num; //
	reg [7:0] mid_buf;
	reg [7:0] read_data;
	reg [7:0] read_data1;
	reg [31:0] counter1;


	always @ (negedge clk_out or negedge rst_n)
		begin

			if(!rst_n)
				begin


					sda_r <= 1'b1;
					sda_link <= 1'b0;
					state <= ready;
					num <= 4'd0;
					read_data <= 8'b0000_0000;
					read_data1 <= 8'b0000_0000;
					mid_buf <= 8'b0000_0000;
					counter1 <= 32'd0;

				end

			else
				case (state)

					ready:begin
						if(counter1==32'd159999)	begin state <=idle;counter1 <= 32'd0;sda_link <= 1'b0;end
						else begin counter1 <= counter1 + 1'd1;state <= ready;end

					end
					// idle:begin sda_link <= 1'b1;state <= start;mid_buf <= 8'b10010111;end
					idle:begin sda_link <= 1'b1;state <= start;mid_buf <= 8'h4b;end

					start:if(scl) begin sda_r <= 1'b0;state <= add1;end
					else state <= start;

					add1: begin
						if(!scl)
							begin
								if(num == 4'd8)
									begin
										num <= 4'd0;
//								sda_r <= 1'b0;
//								sda_link <= 1'b1;
										sda_link <= 1'b0;
										state <= add2;
										//	mid_buf <= `BYTE_ADDR;
									end

								else
									begin
										state <= add1;
										num <= num+1'd1;

										case (num)
											4'd0: sda_r <= mid_buf[7];
											4'd1: sda_r <= mid_buf[6];
											4'd2: sda_r <= mid_buf[5];
											4'd3: sda_r <= mid_buf[4];
											4'd4: sda_r <= mid_buf[3];
											4'd5: sda_r <= mid_buf[2];
											4'd6: sda_r <= mid_buf[1];
											4'd7: sda_r <= mid_buf[0];
											default:  ;
										endcase
									end
							end


						else state <= add1;
					end
					add2:begin state <= add4;end

					add4:begin


						if(num<=4'd7)
							begin
								state <= add4;
								if(scl)
									begin
										num <= num+1'd1;

										case (num)
											4'd0: read_data[7] <= sda;
											4'd1: read_data[6] <= sda;
											4'd2: read_data[5] <= sda;
											4'd3: read_data[4] <= sda;
											4'd4: read_data[3] <= sda;
											4'd5: read_data[2] <= sda;
											4'd6: read_data[1] <= sda;
											4'd7: read_data[0] <= sda;



											default:  ;
										endcase
									end
							end
						else if((!scl) && (num==4'd8))
							begin
								num <= 4'd0;
								sda_r <= 1'b0;
								state <= add3;
								sda_link <= 1'b1;

							end
						else begin state <= add4;end

					end

					add3:begin state <= add5;end

					add5:begin


						if(num<=4'd7)
							begin
								state <= add5;
								sda_link <= 1'b0;
								if(scl)
									begin
										num <= num+1'd1;

										case (num)
											4'd0: read_data1[7] <= sda;
											4'd1: read_data1[6] <= sda;
											4'd2: read_data1[5] <= sda;
											4'd3: read_data1[4] <= sda;
											4'd4: read_data1[3] <= sda;
											4'd5: read_data1[2] <= sda;
											4'd6: read_data1[1] <= sda;
											4'd7: read_data1[0] <= sda;
											default:  ;
										endcase
									end
							end
						else if((!scl) && (num==4'd8))
							begin
								num <= 4'd0;
								state <= wait1;
								sda_r <= 1'b1;
								sda_link <= 1'b1;
							end
						else state <= add5;

					end
					wait1:state <=stop;
					stop: if(!scl) begin sda_r <= 1'b0;state <= stop1;end

					else state <= stop;
					stop1:if(scl)begin sda_r <= 1'b1;state <= ready;end
				endcase

		end

	assign sda = sda_link ? sda_r:1'bz;

endmodule