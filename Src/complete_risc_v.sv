`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/16/2025 11:18:46 AM
// Design Name: 
// Module Name: complete_risc_v
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


module complete_risc_v(
    input logic CLK, RST, Pause, Tx, init,
    output logic [7:0] led,
    output logic Rx
    );
    
    logic I_CS, D_CS;
    logic [3:0] I_WE, D_WE;
    logic [31:0] I_ADDR, D_ADDR;
    wire [31:0] I_Mem_Bus, D_Mem_Bus;
    
//module risc_v(
//    input logic CLK, RST, Pause, init,
//    output logic I_CS, D_CS,
//    output logic [3:0] I_WE, D_WE,
//    output logic [31:0] I_ADDR, D_ADDR,
//    inout [31:0] I_Mem_Bus, D_Mem_Bus,
//    output logic [7:0] led
//    );
    risc_v CPU(.*);
    
    Memory #(1) I_MEM (I_CS, CLK, I_WE, I_ADDR, I_Mem_Bus);
    Memory #(0) D_MEM (D_CS, CLK, D_WE, D_ADDR, D_Mem_Bus);
endmodule
