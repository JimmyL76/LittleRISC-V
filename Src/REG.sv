`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/15/2025 05:17:09 PM
// Design Name: 
// Module Name: REG
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


module REG(CLK, LdR, RD, RS1, RS2, DataR, ReadReg1, ReadReg2);
  input CLK;
  input LdR;
  input [4:0] RD;
  input [4:0] RS1;
  input [4:0] RS2;
  input [31:0] DataR;
  output reg [31:0] ReadReg1;
  output reg [31:0] ReadReg2;

  reg [31:0] REG [0:31];
  integer i;
  initial begin
    for(i=0; i<32; i=i+1)
        REG[i] = 32'h0;
  end

  initial begin
    ReadReg1 = 0;
    ReadReg2 = 0;
  end

  always @(negedge CLK)
  begin
    // hardware R0 to 0
    REG[0] <= 0;

    if(LdR == 1'b1)
      REG[RD] <= DataR[31:0];

    ReadReg1 <= REG[RS1];
    ReadReg2 <= REG[RS2];
  end
endmodule