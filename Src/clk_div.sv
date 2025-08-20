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


module clk_div #(parameter div = 2)(
    input logic CLK, RST,
    output logic CLK_out
    );
    
    logic [$clog2(div)-1:0] ctr;
    
    always_ff @(posedge CLK) begin
        if(RST) begin
            ctr <= 0;
            CLK_out <= 0;
        end else begin
            if(ctr == div - 1) begin
                CLK_out <= ~CLK_out;
                ctr <= 0;
            end else begin
                ctr <= ctr + 1;
            end
        end
    end
endmodule
