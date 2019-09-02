`timescale 1ns / 1ps
`include "type.sv"

import types::*;

module OledEX(
	input logic CLK,
	input logic RST,
	input logic EN,
	output logic CS,
	output logic SDO,
	output logic SCLK,
	output logic DC,
	output logic FIN,
	input logic [3:0] KEYS[2:0],
	input logic KEYTRIGGER,
	input logic [31:0] PSCOUNTER,
	input event_t EVENTUPDATE
);

	// wire CS, SDO, SCLK, DC, FIN;

	//Variable that contains what the screen will be after the next UpdateScreen state
	logic [7:0] current_screen[0:3][0:15];

	// Constant that contains the screen filled with the Alphabet and numbers
	// parameter [7:0]  alphabet_screen[0:3][0:15] = '{'{8'h41, 8'h42, 8'h43, 8'h44, 8'h45, 8'h46, 8'h47, 8'h48, 8'h49, 8'h4A, 8'h4B, 8'h4C, 8'h4D, 8'h4E, 8'h4F, 8'h50}, '{8'h51, 8'h52, 8'h53, 8'h54, 8'h55, 8'h56, 8'h57, 8'h58, 8'h59, 8'h5A, 8'h61, 8'h62, 8'h63, 8'h64, 8'h65, 8'h66}, '{8'h67, 8'h68, 8'h69, 8'h6A, 8'h6B, 8'h6C, 8'h6D, 8'h6E, 8'h6F, 8'h70, 8'h71, 8'h72, 8'h73, 8'h74, 8'h75, 8'h76}, '{8'h77, 8'h78, 8'h79, 8'h7A, 8'h30, 8'h31, 8'h32, 8'h33, 8'h34, 8'h35, 8'h36, 8'h37, 8'h38, 8'h39, 8'h7F, 8'h7F}};
	// Constant that fills the screen with blank (spaces) entries
	parameter [7:0]  clear_screen[0:3][0:15] = '{'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}, '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};

	logic [7:0] wrong_password [0:15] = {8'h57, 8'h72, 8'h6F, 8'h6E, 8'h67, 8'h20, 8'h50, 8'h61, 8'h73, 8'h73, 8'h77, 8'h6F, 8'h72, 8'h64, 8'h20, 8'h20};
	logic [7:0] correct_password [0:15] = {8'h43, 8'h6F, 8'h72, 8'h72, 8'h65, 8'h63, 8'h74, 8'h20, 8'h50, 8'h61, 8'h73, 8'h73, 8'h77, 8'h6F, 8'h72, 8'h64};
	logic [7:0] new_password [0:15] = {8'h53, 8'h65, 8'h74, 8'h20, 8'h4E, 8'h65, 8'h77, 8'h20, 8'h50, 8'h61, 8'h73, 8'h73, 8'h77, 8'h6F, 8'h72, 8'h64};

	logic [4*10-1:0] outbcd;
    bin2bcd #(.W(32)) bcd2
    (
        .bin(PSCOUNTER),
        .bcd(outbcd)
    );
    
	logic [7:0] key_screen[0:3][0:15];
	always_ff @(posedge CLK) begin
		if (EVENTUPDATE == WrongAnswer) begin
			key_screen <=
				'{'{KEYS[2] + 'h30, KEYS[1] + 'h30, KEYS[0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				// '{ PSCOUNTER[31:28] + 'h30, PSCOUNTER[27:24] + 'h30, PSCOUNTER[23:20] + 'h30, PSCOUNTER[19:16] + 'h30, PSCOUNTER[15:12] + 'h30, PSCOUNTER[11:8] + 'h30, PSCOUNTER[7:4] + 'h30, PSCOUNTER[3:0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				{wrong_password},
				// '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
				'{ outbcd[39:36]+ 'h30, outbcd[35:32] + 'h30, outbcd[31:28] + 'h30, outbcd[27:24] + 'h30, outbcd[23:20] + 'h30, outbcd[19:16] + 'h30, outbcd[15:12] + 'h30, outbcd[11:8] + 'h30, outbcd[7:4] + 'h30, outbcd[3:0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
		end
		else if (EVENTUPDATE == RightAnswer) begin
			key_screen <=
				'{'{KEYS[2] + 'h30, KEYS[1] + 'h30, KEYS[0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				// '{ PSCOUNTER[31:28] + 'h30, PSCOUNTER[27:24] + 'h30, PSCOUNTER[23:20] + 'h30, PSCOUNTER[19:16] + 'h30, PSCOUNTER[15:12] + 'h30, PSCOUNTER[11:8] + 'h30, PSCOUNTER[7:4] + 'h30, PSCOUNTER[3:0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				{correct_password},
				// '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
				'{ outbcd[39:36]+ 'h30, outbcd[35:32] + 'h30, outbcd[31:28] + 'h30, outbcd[27:24] + 'h30, outbcd[23:20] + 'h30, outbcd[19:16] + 'h30, outbcd[15:12] + 'h30, outbcd[11:8] + 'h30, outbcd[7:4] + 'h30, outbcd[3:0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
		end
		else if (EVENTUPDATE == NewPassword) begin
			key_screen <=
				'{'{KEYS[2] + 'h30, KEYS[1] + 'h30, KEYS[0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				// '{ PSCOUNTER[31:28] + 'h30, PSCOUNTER[27:24] + 'h30, PSCOUNTER[23:20] + 'h30, PSCOUNTER[19:16] + 'h30, PSCOUNTER[15:12] + 'h30, PSCOUNTER[11:8] + 'h30, PSCOUNTER[7:4] + 'h30, PSCOUNTER[3:0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				{new_password},
				'{ outbcd[39:36]+ 'h30, outbcd[35:32] + 'h30, outbcd[31:28] + 'h30, outbcd[27:24] + 'h30, outbcd[23:20] + 'h30, outbcd[19:16] + 'h30, outbcd[15:12] + 'h30, outbcd[11:8] + 'h30, outbcd[7:4] + 'h30, outbcd[3:0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
				// '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
		end
		else begin
			key_screen <=
				'{'{KEYS[2] + 'h30, KEYS[1] + 'h30, KEYS[0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				// '{ PSCOUNTER[31:28] + 'h30, PSCOUNTER[27:24] + 'h30, PSCOUNTER[23:20] + 'h30, PSCOUNTER[19:16] + 'h30, PSCOUNTER[15:12] + 'h30, PSCOUNTER[11:8] + 'h30, PSCOUNTER[7:4] + 'h30, PSCOUNTER[3:0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				// this still doesnt work
				'{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				'{ outbcd[39:36]+ 'h30, outbcd[35:32] + 'h30, outbcd[31:28] + 'h30, outbcd[27:24] + 'h30, outbcd[23:20] + 'h30, outbcd[19:16] + 'h30, outbcd[15:12] + 'h30, outbcd[11:8] + 'h30, outbcd[7:4] + 'h30, outbcd[3:0] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
				// '{ decimal[0]+ 'h30, decimal[1] + 'h30, decimal[2] + 'h30, decimal[3] + 'h30, decimal[4] + 'h30, decimal[5] + 'h30, decimal[6] + 'h30, decimal[7] + 'h30, decimal[8] + 'h30, decimal[9] + 'h30, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				// '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20},
				// '{8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20, 8'h20}};
		end
	end

	typedef enum logic[$clog2(27)-1:0] {
		Idle,
		SetSPIEn,
		WaitSPIFin,
		SetDelayEn,
		WaitDelayFin,
		ClearSPIDelay,
		ClearDC,
		UpdateScreen,
		ClearScreen,
		KeyScreen,
		SendChar1,
		SendChar2,
		SendChar3,
		SendChar4,
		SendChar5,
		SendChar6,
		SendChar7,
		SendChar8,
		SetPage,
		PageNum,
		LeftColumn1,
		LeftColumn2,
		SetDC,
		ReadMem,
		ReadMem2,
		WaitInput,
		Done} state_t;

	//Current overall state of the state machine
	state_t current_state;
	//State to go to after the SPI transmission is finished
	state_t after_state;
	//State to go to after the set page sequence
	state_t after_page_state;
	//State to go to after sending the character sequence
	state_t after_char_state;
	//State to go to after the UpdateScreen is finished
	state_t after_update_state;

	integer i = 0;
	integer j = 0;

	//Contains the value to be outputted to DC
	// reg temp_dc;

	//-------------- Variables used in the Delay Controller Block --------------
	logic [11:0] temp_delay_ms;		//amount of ms to delay
	logic temp_delay_en;				//Enable signal for the delay block
	wire temp_delay_fin;				//Finish signal for the delay block

	//-------------- Variables used in the SPI controller block ----------------
	logic temp_spi_en;					//Enable signal for the SPI block
	logic [7:0] temp_spi_data;		//Data to be sent out on SPI
	wire temp_spi_fin;				//Finish signal for the SPI block

	logic [7:0] temp_char;				//Contains ASCII value for character
	logic [10:0] temp_addr;			//Contains address to BYTE needed in memory
	wire [7:0] temp_dout;			//Contains byte outputted from memory
	logic [1:0] temp_page;				//Current page
	logic [3:0] temp_index;			//Current character on page

	// ===========================================================================
	// 										Implementation
	// ===========================================================================

	// assign DC = temp_dc;
	//Example finish flag only high when in done state
	always_comb
		FIN = (current_state == Done) ? 1'b1 : 1'b0;

	//Instantiate SPI Block
	SpiCtrl SPI_COMP(
		.CLK(CLK),
		.RST(RST),
		.SPI_EN(temp_spi_en),
		.SPI_DATA(temp_spi_data),
		.CS(CS),
		.SDO(SDO),
		.SCLK(SCLK),
		.SPI_FIN(temp_spi_fin)
	);

	//Instantiate Delay Block
	Delay DELAY_COMP(
		.CLK(CLK),
		.RST(RST),
		.DELAY_MS(temp_delay_ms),
		.DELAY_EN(temp_delay_en),
		.DELAY_FIN(temp_delay_fin)
	);

	//Instantiate Memory Block
	charLib CHAR_LIB_COMP(
		.clka(CLK),
		.addra(temp_addr),
		.douta(temp_dout)
	);

	//  State Machine
	always @(posedge CLK) begin
		unique case(current_state)
			// Idle until EN pulled high than intialize Page to 0 and go to state Alphabet afterwards
			Idle : begin
				if(EN == 1'b1) begin
					current_state <= ClearDC;
					after_page_state <= KeyScreen;
					temp_page <= 2'b00;
				end
			end

			// Set currentScreen to constant digilent_screen and update the screen. Go to state Done afterwards
			KeyScreen : begin
				for(i = 0; i <= 3 ; i=i+1) begin
					for(j = 0; j <= 15 ; j=j+1) begin
						current_screen[i][j] <= key_screen[i][j];
					end
				end
				after_update_state <= WaitInput;
				current_state <= UpdateScreen;
			end

			WaitInput : begin
				if(KEYTRIGGER == 'b1)
					current_state <= KeyScreen;
			end

			// Do nothing until EN is deassertted and then current_state is Idle
			Done : begin
				if(EN == 1'b0) begin
					current_state <= Idle;
				end
			end

			//UpdateScreen State
			//1. Gets ASCII value from current_screen at the current page and the current spot of the page
			//2. If on the last character of the page transition update the page number, if on the last page(3)
			//			then the updateScreen go to after_update_state after
			UpdateScreen : begin
				temp_char <= current_screen[temp_page][temp_index];
				if(temp_index == 'd15) begin
					temp_index <= 'd0;
					temp_page <= temp_page + 1'b1;
					after_char_state <= ClearDC;

					if(temp_page == 2'b11) begin
						after_page_state <= after_update_state;
					end
					else	begin
						after_page_state <= UpdateScreen;
					end
				end
				else begin
					temp_index <= temp_index + 1'b1;
					after_char_state <= UpdateScreen;
				end
				current_state <= SendChar1;
			end

			//Update Page states
			//1. Sets DC to command mode
			//2. Sends the SetPage Command
			//3. Sends the Page to be set to
			//4. Sets the start pixel to the left column
			//5. Sets DC to data mode
			ClearDC : begin
				DC <= 1'b0;
				current_state <= SetPage;
			end

			SetPage : begin
				temp_spi_data <= 8'b00100010;
				after_state <= PageNum;
				current_state <= SetSPIEn;
			end

			PageNum : begin
				temp_spi_data <= {6'b000000,temp_page};
				after_state <= LeftColumn1;
				current_state <= SetSPIEn;
			end

			LeftColumn1 : begin
				temp_spi_data <= 8'b00000000;
				after_state <= LeftColumn2;
				current_state <= SetSPIEn;
			end

			LeftColumn2 : begin
				temp_spi_data <= 8'b00010000;
				after_state <= SetDC;
				current_state <= SetSPIEn;
			end

			SetDC : begin
				DC <= 1'b1;
				current_state <= after_page_state;
			end

			//Send Character States
			//1. Sets the Address to ASCII value of char with the counter appended to the end
			//2. Waits a clock for the data to get ready by going to ReadMem and ReadMem2 states
			//3. Send the byte of data given by the block Ram
			//4. Repeat 7 more times for the rest of the character bytes
			SendChar1 : begin
				temp_addr <= {temp_char, 3'b000}; // temp_addr -> temp_dout
				after_state <= SendChar2;
				current_state <= ReadMem;
			end

			SendChar2 : begin
				temp_addr <= {temp_char, 3'b001};
				after_state <= SendChar3;
				current_state <= ReadMem;
			end

			SendChar3 : begin
				temp_addr <= {temp_char, 3'b010};
				after_state <= SendChar4;
				current_state <= ReadMem;
			end

			SendChar4 : begin
				temp_addr <= {temp_char, 3'b011};
				after_state <= SendChar5;
				current_state <= ReadMem;
			end

			SendChar5 : begin
				temp_addr <= {temp_char, 3'b100};
				after_state <= SendChar6;
				current_state <= ReadMem;
			end

			SendChar6 : begin
				temp_addr <= {temp_char, 3'b101};
				after_state <= SendChar7;
				current_state <= ReadMem;
			end

			SendChar7 : begin
				temp_addr <= {temp_char, 3'b110};
				after_state <= SendChar8;
				current_state <= ReadMem;
			end

			SendChar8 : begin
				temp_addr <= {temp_char, 3'b111};
				after_state <= after_char_state;
				current_state <= ReadMem;
			end

			ReadMem : begin
				current_state <= ReadMem2;
				// temp_spi_data <= temp_dout;
				// current_state <= SetSPIEn;
			end

			ReadMem2 : begin
				temp_spi_data <= temp_dout;
				current_state <= SetSPIEn;
			end
			//  End Send Character States

			// SPI transitions
			// 1. Set SPI_EN to 1
			// 2. Waits for SpiCtrl to finish
			// 3. Goes to clear state (Transition5)
			SetSPIEn: begin
				temp_spi_en <= 1'b1;
				current_state <= WaitSPIFin;
			end

			WaitSPIFin: begin
				if(temp_spi_fin == 1'b1) begin
					current_state <= ClearSPIDelay;
				end
			end

			// Delay Transitions
			// 1. Set DELAY_EN to 1
			// 2. Waits for Delay to finish
			// 3. Goes to Clear state (Transition_Done)
			SetDelayEn: begin
				temp_delay_en <= 1'b1;
				current_state <= WaitDelayFin;
			end

			WaitDelayFin: begin
				if(temp_delay_fin == 1'b1) begin
					current_state <= ClearSPIDelay;
				end
			end

			// Clear transition
			// 1. Sets both DELAY_EN and SPI_EN to 0
			// 2. Go to after state
			ClearSPIDelay: begin
				temp_spi_en <= 1'b0;
				temp_delay_en <= 1'b0;
				current_state <= after_state;
			end
			//END SPI transitions
			//END Delay Transitions
			//END Clear transition

			default : current_state <= Idle;
		endcase
	end
endmodule
