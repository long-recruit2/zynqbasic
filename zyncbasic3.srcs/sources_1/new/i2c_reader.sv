`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2019/10/29 21:51:04
// Design Name: 
// Module Name: i2c_reader
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


module i2c_reader #(
    parameter CLK_FREQ = 100e6
)(
    input logic clk,
    input logic rst,
    input logic en,
    output logic scl = 1,
    inout wire sda,
    output logic done = 0,
    output logic [15:0] read = 0
);

localparam int SCLCOUNT = CLK_FREQ / (1000 * 4 * 100);
logic [$clog2(SCLCOUNT):0] count = 0;
logic out_en = 0;
logic out_data = 0;

always_ff @(posedge clk)
    if(count == SCLCOUNT)
        count <= 0;
    else if(en)
        count++;

logic scl_edge = 0;
always_ff @(posedge clk) begin
    if(count == SCLCOUNT / 2 - 1 && en && scl == 0)
        scl_edge <= 1;
    else
        scl_edge <= 0;    

    if(count == SCLCOUNT / 2 && en)
        scl <= ~scl;
end

typedef enum logic[$clog2(5)-1:0]{
    Idle,
    ADDRESS,
    ACK,
    READ,
    READACK,
    DONE
} state_t;

assign sda = out_en ? out_data : 'bZ;

state_t current_state = Idle;
state_t next_state = Idle;

logic [7:0] tmp_address = 8'b10010111;
logic [7:0] read_byte = 0;

int counter = 0;
int debut = 0;
int iteration = 0;

always_ff @(posedge clk) begin
    if(rst == 'b1 || en == 'b0) begin
        current_state <= Idle;
        counter <= 0;
        iteration <= 0;
        done <= 0;
    end
    else begin
        if(scl_edge == 1)
            unique case(current_state)
                Idle: begin
                    current_state <= ADDRESS;
                    out_en <= 1;
                    counter <= counter + 1;
                    out_data <= tmp_address[$bits(tmp_address) - 1];
                end
                ADDRESS: begin
                    if(counter < $bits(tmp_address)) begin
                        out_en <= 1;
                        debut <= $bits(tmp_address) - counter - 1;
                        out_data <= tmp_address[$bits(tmp_address) - counter - 1];
                    end
                    else begin
                        current_state <= ACK;
                        next_state <= READ;
                        out_en <= 0;
                    end
                    counter <= counter + 1;
                end
                ACK : begin
                    counter <= 1;
                    current_state <= next_state;
                    read_byte[$bits(read_byte) - 1] <= sda;
                end
                READ : begin
                    if(counter < $bits(read_byte)) begin
                        out_en <= 0;
                        read_byte[$bits(read_byte) - counter - 1] <= sda;
                    end
                    else begin
                        current_state <= READACK;
                        next_state <= ADDRESS;
                        iteration <= iteration + 1;
                    end
                    counter <= counter + 1;                    
                end
                READACK : begin
                    if(iteration == 2)
                        current_state <= DONE;
                    else begin
                        current_state <= next_state;
                        counter <= 1;
                        out_en <= 1;
                        out_data <= tmp_address[$bits(tmp_address) - 1];
                    end
                end
                DONE : begin
                    current_state <= DONE;
                    done <= 1;
                end
                default : 
                    current_state <= Idle;
            endcase
    end
end












endmodule
