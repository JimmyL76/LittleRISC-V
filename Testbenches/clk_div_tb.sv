`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/07/2025 10:22:29 PM
// Design Name: 
// Module Name: clk_div_tb
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


module clk_div_tb();
    
    logic CLK, RST;
    logic CLK10, CLK25;
    
    initial begin
        CLK <= 0;
        RST <= 0;
        forever #2.5 CLK <= ~CLK;
    end
    
    initial begin
        #98 RST = 1;
        #10 RST = 0;
    end
    
    // 5ns * 2 = 10
    
    clk_div #(.DIV(2)) c10(
    .CLK(CLK), .RST(RST),
    .CLK_out(CLK10)
    );
    
    // 5ns * 5 = 25 
    
    clk_div #(.DIV(5)) c25(
    .CLK(CLK), .RST(RST),
    .CLK_out(CLK25)
    );
    
endmodule
