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


module REG #(parameter int R_IO_NUM = 1)(CLK, clk_cpu, LdR, RD, RS1, RS2, DataR, ReadReg1, ReadReg2, R_IO);
  input logic CLK;
  input logic clk_cpu;
  input logic LdR;
  input logic [4:0] RD;
  input logic [4:0] RS1;
  input logic [4:0] RS2;
  input logic [31:0] DataR;
  output logic [31:0] ReadReg1;
  output logic [31:0] ReadReg2;
  output logic [31:0] R_IO;

  logic [31:0] REG [0:31];
  integer i;
  initial begin
    for(i=0; i<32; i=i+1)
        REG[i] = 32'h0;
  end

//  initial begin
//    ReadReg1 = 0;
//    ReadReg2 = 0;
//  end

  always @(negedge CLK)
  begin
    if (clk_cpu) begin
    // hardware R0 to 0
    REG[0] <= 0;

    if (LdR == 1'b1)
      REG[RD] <= DataR[31:0];

    ReadReg1 <= REG[RS1];
    ReadReg2 <= REG[RS2];
    R_IO <= REG[R_IO_NUM];
    end
  end
endmodule