`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/16/2025 10:23:27 AM
// Design Name: 
// Module Name: clk_div
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

module clk_div #(
    parameter DIV
    )(
    input logic CLK, RST, // ignore reset on clk_div for now
    output logic CLK_out
    );
    
    logic [$clog2(DIV)-1:0] ctr = 0;
    logic CLK_p, CLK_n = 0;
    logic odd; assign odd = DIV[0];
    
    always_ff @(posedge CLK) begin
//        if (RST) begin
//            ctr <= 0;
//        end else 
        begin 
            if(ctr == DIV - 1)
                ctr <= 0;
            else 
                ctr <= ctr + 1;
        end
    end
    
    // for even, true from (div-1) to (div/2), ex: for 6 or 0 to 5, 3-5
    // for old, true from (div-1) to (div/2 + 1), ex: for 5 or 0 to 4, 3-4
    assign CLK_p = (ctr > ((DIV-1)/2));
    
    always_ff @(negedge CLK) begin
//        if (RST)
//            CLK_n <= 0;
//        else 
        if (odd)
            CLK_n <= CLK_p;
    end
    
    assign CLK_out = odd ? (CLK_p | CLK_n) : CLK_p;
    
endmodule
