`timescale 1ns / 1ps
/*
ADT 7420 returns data in 16 bit data [15:0]
data[15]: signed bit
data[14:8]: 7 bit for MSB for hundreds, tens, ones
data[7:3]: 5 bit for LSB for decimals
data[2:0] 3 bit reserved. See ADT 7420 Manual for more info
*/

/*
Current data seems to work, known issue is it increases/ decreases by +/- 2 Celsius. ( Software/Software issue)
Future work will fix this issue.
*/


module tempF(

    input clk,
    input swF_n,

    input [7:0] tempC,

    output reg [6:0] seg,

    output reg [7:0] dig
    ,
    output reg [3:0] tens,
    output reg [3:0] ones

);


    reg [3:0] hundreds;

    reg [3:0] decimal;

    reg [3:0] digitPos;

    parameter AN0=  8'b11111110;

    parameter AN1=  8'b11111101;

    parameter AN2 = 8'b11111011;

    parameter AN3 = 8'b11110111;

    parameter AN4 = 8'b11101111;

    parameter AN5 = 8'b11011111;
    parameter AN6=  8'b10111111;

    parameter AN7=  8'b01111111;

    parameter    zero = 7'b100_0000,one = 7'b111_1001,two = 7'b010_0100,three = 7'b011_0000,four = 7'b001_1001,

                 five = 7'b001_0010,six = 7'b000_0010,seven = 7'b111_1000,eigth = 7'b000_0000,nine = 7'b001_0000;


    always@( posedge clk)


        begin
            case (tempC[7:0])

//0 -10c
//        F = 1.8*C +32   // temp in sensor might not be correct
                8'b00000000    :    begin hundreds <= 4'b0000; tens <= 4'b0011; ones <= 4'b0010; end      //0 C =032 F

                8'b00000001    :    begin hundreds <= 4'b0000; tens <= 4'b0011; ones <= 4'b0011; decimal <= 4'b0100 ;end      //1 C =033.8 F

                8'b00000010    :    begin hundreds <= 4'b0000; tens <= 4'b0011; ones <= 4'b0101; decimal <= 4'b0110; end      //2 C =035.6 F

                8'b00000011    :    begin hundreds <= 4'b0000; tens <= 4'b0011; ones <= 4'b0111; decimal <= 4'b0100; end     //3 C =037.4 F

                8'b00000100    :    begin hundreds <= 4'b0000; tens <= 4'b0011; ones <= 4'b1001;  decimal <= 4'b0010; end      //4 C =039.2 F

                8'b00000101    :    begin hundreds <= 4'b0000; tens <= 4'b0100; ones <= 4'b0001;  decimal <= 4'b0000; end      //5 C =041 F

                8'b00000110    :    begin hundreds <= 4'b0000; tens <= 4'b0100; ones <= 4'b0010; decimal <= 4'b1000; end      //6 C =042.8 F

                8'b00000111    :    begin hundreds <= 4'b0000; tens <= 4'b0100; ones <= 4'b0100; decimal <= 4'b0110; end      //7 C =044.6 F

                8'b00001000    :    begin hundreds <= 4'b0000; tens <= 4'b0100; ones <= 4'b0110;  decimal <= 4'b0100; end      //8 C =046.4 F

                8'b00001001    :    begin hundreds <= 4'b0000; tens <= 4'b0100; ones <= 4'b1000;  decimal <= 4'b0010; end      //9 C =48.2 F

                8'b00001010    :    begin hundreds <= 4'b0000; tens <= 4'b0101; ones <= 4'b0000; decimal <= 4'b0000; end      //10 C =050 F

                8'b00001011    :    begin hundreds <= 4'b0000; tens <= 4'b0101; ones <= 4'b0001;  decimal <= 4'b1000; end      //11 C =051.8 F

                8'b00001100    :    begin hundreds <= 4'b0000; tens <= 4'b0101; ones <= 4'b0110;  decimal <= 4'b0110; end      //12 C =055 F

                8'b00001101    :    begin hundreds <= 4'b0000; tens <= 4'b0101; ones <= 4'b0111; decimal <= 4'b0010; end      //13 C =057.2 F

                8'b00001110    :    begin hundreds <= 4'b0000; tens <= 4'b0101; ones <= 4'b1001;  decimal <= 4'b0000; end      //14 C =059 F

                8'b00001111    :    begin hundreds <= 4'b0000; tens <= 4'b0110; ones <= 4'b0000;  decimal <= 4'b1000; end      //15 C =061 F

                8'b00010000    :    begin hundreds <= 4'b0000; tens <= 4'b0110; ones <= 4'b0010;  decimal <= 4'b0110; end      //16 C =063 F

                8'b00010001    :    begin hundreds <= 4'b0000; tens <= 4'b0110; ones <= 4'b0100;   decimal <= 4'b0010; end      //17 C =064.2 F

                8'b00010010    :    begin hundreds <= 4'b0000; tens <= 4'b0110; ones <= 4'b0110;  decimal <= 4'b0010; end      //18 C =066 F

                8'b00010011    :    begin hundreds <= 4'b0000; tens <= 4'b0110; ones <= 4'b0110;  decimal <= 4'b0010; end      //19 C =068 F

                8'b00010100    :    begin hundreds <= 4'b0000; tens <= 4'b0110; ones <= 4'b1000;  decimal <=4'b0000; end      //20C =068 F  //20

                8'b00010101    :    begin hundreds <= 4'b0000; tens <= 4'b0110; ones <= 4'b1001; decimal <= 4'b1000; end      //21 C =072 F

                8'b00010110    :    begin hundreds <= 4'b0000; tens <= 4'b0111; ones <= 4'b0001;  decimal <= 4'b0110; end      //22 C =073 F

                8'b00010111    :    begin hundreds <= 4'b0000; tens <= 4'b0111; ones <= 4'b0110;  decimal <= 4'b0100;end      //23 C =075 F

                8'b00011000    :    begin hundreds <= 4'b0000; tens <= 4'b0111; ones <= 4'b0101;  decimal <= 4'b0010; end      //24 C =077 F

                8'b00011001    :    begin hundreds <= 4'b0000; tens <= 4'b0111; ones <= 4'b0111; decimal <= 4'b0000; end      //25 C =079 F


                8'b00011010    :    begin hundreds <= 4'b0000; tens <= 4'b0111; ones <= 4'b1000;  decimal <= 4'b1000; end      //26 C =081 F

                8'b00011011    :    begin hundreds <= 4'b0000; tens <= 4'b1000; ones <= 4'b0000; decimal <= 4'b0110; end      //27 C =082 F

                8'b00011100    :    begin hundreds <= 4'b0000; tens <= 4'b1000; ones <= 4'b0010;  decimal <= 4'b0100; end      //28 C =084 F

                8'b00011101    :    begin hundreds <= 4'b0000; tens <= 4'b1000; ones <= 4'b0100;  decimal <= 4'b0010; end      //29 C =086 F

                8'b00011110    :    begin hundreds <= 4'b0000; tens <= 4'b1000; ones <= 4'b0110;  decimal <= 4'b0000; end      //30 C =088 F

                8'b00011111    :    begin hundreds <= 4'b0000; tens <= 4'b1000; ones <= 4'b0111;  decimal <= 4'b1000; end      //31 C =090 F

                8'b00100000    :    begin hundreds <= 4'b0000; tens <= 4'b1000; ones <= 4'b1001;  decimal <= 4'b0110; end      //32 C =091 F

                8'b00100001    :    begin hundreds <= 4'b0000; tens <= 4'b1001; ones <= 4'b0001; decimal <= 4'b0100; end      //33 C =093 F

                8'b00100010    :    begin hundreds <= 4'b0000; tens <= 4'b1001; ones <= 4'b0011;  decimal <= 4'b0010; end      //34 C =095 F

                8'b00100011    :    begin hundreds <= 4'b0000; tens <= 4'b1001; ones <= 4'b0101;  decimal <= 4'b0000; end      //35 C =097 F

                8'b00100100    :    begin hundreds <= 4'b0000; tens <= 4'b1001; ones <= 4'b0110;  decimal <= 4'b1000; end      //36 C =099 F

                8'b00100101    :    begin hundreds <= 4'b0001; tens <= 4'b0000; ones <= 4'b0000;  decimal <= 4'b0100; end     //37 C =100 F

                8'b00100110    :    begin hundreds <= 4'b0001; tens <= 4'b0000; ones <= 4'b0010;  decimal <= 4'b0010; end     //38 C =100 F

                8'b00100111    :    begin hundreds <= 4'b0001; tens <= 4'b0000; ones <= 4'b0100;  decimal <= 4'b0000; end     //39 C =100 F


                default         :   begin hundreds <= 4'b0110; tens <= 4'b0110; ones <= 4'b0110; end
                //default :666
            endcase

        end



//Outlook display : [Of][Hundreds][tens][ones] [decimcal] [F] [Off] [Off]  //8 seven segment displays



    always@(posedge clk)

        begin


            if(swF_n)

                begin

                    if( digitPos ==7) digitPos =0;

                    else digitPos <= digitPos +1'd1;

                    case(digitPos)

                        6: begin  seg <= 7'b1111111;

                            dig <= AN7;

                        end

                        5: begin  seg <= 7'b1111111;

                            dig <= AN0;

                        end

                        4: begin    case(decimal)
                            4'b0000 : seg <= zero;

                            4'b0001 : seg <= one;

                            4'b0010 : seg <= two;

                            4'b0011: seg <= three;

                            4'b0100 : seg <= four;

                            4'b0101 : seg <= five;

                            4'b0110 : seg <= six;

                            4'b0111: seg <= seven;

                            4'b1000 : seg <= eigth;

                            4'b1001: seg <= nine;

                            default:seg <= 7'b1111111;
                        endcase

                            dig <= AN3;



                        end


                        3:begin

                            case(hundreds)

                                4'b0000 : seg <= zero;

                                4'b0001 : seg <= one;

                                4'b0010 : seg <= two;

                                4'b0011: seg <= three;

                                4'b0100 : seg <= four;

                                4'b0101 : seg <= five;

                                4'b0110 : seg <= six;

                                4'b0111: seg <= seven;

                                4'b1000 : seg <= eigth;

                                4'b1001: seg <= nine;

                                default:seg <= 7'b1111111;

                            endcase

                            dig <= AN6;

                        end

                        2:begin

                            case(tens)

                                4'b0000 : seg <= zero;

                                4'b0001 : seg <= one;

                                4'b0010 : seg <= two;

                                4'b0011 : seg <= three;
                                4'b0100 : seg <= four;

                                4'b0101 : seg <= five;

                                4'b0110 : seg <= six;

                                4'b0111 : seg <= seven;

                                4'b1000 : seg <= eigth;

                                4'b1001 : seg <= nine;

                                default:seg <= 7'b1111111;

                            endcase

                            dig <= AN5;

                        end

                        1:begin

                            case(ones )

                                4'b0000 : seg <= zero;


                                4'b0001 : seg <= one;

                                4'b0010 : seg <= two;

                                4'b0011 : seg <= three;

                                4'b0100 : seg <= four;

                                4'b0101 : seg <= five;

                                4'b0110 : seg <= six;

                                4'b0111 : seg <= seven;

                                4'b1000 : seg <= eigth;

                                4'b1001 : seg <= nine;

                                default:seg <= 7'b1111111;

                            endcase

                            dig <= AN4;

                        end

                        0:begin

                            seg <= 7'b0001110;

                            dig <= AN2;

                        end

                    endcase

                end

        end

endmodule