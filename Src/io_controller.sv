`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/08/2025 08:54:37 AM
// Design Name: 
// Module Name: io_controller
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


module io_controller(
    input logic clk100hz, clk1000hz, 
    input logic btnL, btnR, btnU, btnD,
    input logic [31:0] R_IO,
    output logic [6:0] seg,
    output logic [3:0] an,
    output logic dBTNL, dBTNR, dBTNU, dBTND
    );
    
    button_debounce left(.CLK(clk100hz), .btn_in(btnL), .btn_out(dBTNL));
    button_debounce right(.CLK(clk100hz), .btn_in(btnR), .btn_out(dBTNR));
    button_debounce up(.CLK(clk100hz), .btn_in(btnU), .btn_out(dBTNU));
    button_debounce down(.CLK(clk100hz), .btn_in(btnD), .btn_out(dBTND));
    
    sevenSeg disp(.CLK(clk1000hz), .*);
    
endmodule

module sevenSeg (
    input logic CLK, dBTNL,
    input logic [31:0] R_IO,
    output logic [6:0] seg,
    output logic [3:0] an
    );
    
    // save R_IO with additional register to minimize flickering latency from accessing reg file
    // logic [31:0] R_IO_ff;
    
    always @(posedge CLK) begin
        // R_IO_ff <= R_IO;
        case(an)
            4'b1110: an <= 4'b1101;
            4'b1101: an <= 4'b1011;
            4'b1011: an <= 4'b0111;
            4'b0111: an <= 4'b1110;
            default: an <= 4'b1110;
        endcase   
    end
    
    // dBTNL shows upper 4 hex digits of register
    wire [3:0] bin_num = (an == 4'b1110) ? ((dBTNL) ? R_IO[19:16] : R_IO[3:0]) :
                (an == 4'b1101) ? ((dBTNL) ? R_IO[23:20] : R_IO[7:4]) :
                (an == 4'b1011) ? ((dBTNL) ? R_IO[27:24] : R_IO[11:8]) :
                (an == 4'b0111) ? ((dBTNL) ? R_IO[31:28] : R_IO[15:12]) :
                    0; // default 0
                    
    assign seg = (bin_num==0) ? 7'b1000000 :
                (bin_num==1) ? 7'b1111001 :
                (bin_num==2) ? 7'b0100100 :
                (bin_num==3) ? 7'b0110000 :
                (bin_num==4) ? 7'b0011001 :
                (bin_num==5) ? 7'b0010010 :
                (bin_num==6) ? 7'b0000010 :
                (bin_num==7) ? 7'b1111000 :
                (bin_num==8) ? 7'b0000000 :
                (bin_num==9) ? 7'b0010000 :
                (bin_num==10) ? 7'b0001000 :
                (bin_num==11) ? 7'b0000011 :
                (bin_num==12) ? 7'b0100111 :
                (bin_num==13) ? 7'b0100001 :
                (bin_num==14) ? 7'b0000110 :
                (bin_num==15) ? 7'b0001110 :
                7'b1000000;
    
endmodule

module button_debounce(
    input logic CLK, btn_in,
    output logic btn_out
    );
    
    logic [1:0] B_de;
    
    always@(posedge CLK) begin
        {B_de} <= {B_de[0], btn_in};
    end
    
    assign btn_out = B_de[1];
    
endmodule
