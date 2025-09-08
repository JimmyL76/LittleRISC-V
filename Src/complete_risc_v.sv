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

// `define SIMULATION

module complete_risc_v(
    input logic CLK, 
    // input logic RST, Pause // could be UART controlled too
    // U = step forward, L = show upper led bits, R = show upper disp bits
    input logic btnL, btnR, btnU, btnD, 
    input logic sw, // reset switch tied to RST
//    input logic Rx, // UART signals
//    output logic Tx,
    output logic [15:0] led, // taps alu.rs1
    output logic [6:0] seg, // displays REG[1]
    output logic [3:0] an
    );
    
    logic I_CS, D_CS;
    logic [3:0] I_WE, D_WE;
    logic [31:0] I_ADDR, D_ADDR;
    wire [31:0] I_Mem_Bus, D_Mem_Bus;
    
    // without UART
    logic Init; assign Init = 0; 
    logic [31:0] InitPC, Init_Data; assign InitPC = 0; assign Init_Data = 0;
    
    logic [31:0] R_IO, R_led;
    logic dBTNL, dBTNR, dBTNU, dBTND;
    logic RST; assign RST = sw;
    
    // basys 3 at 100 Mhz, 100_000_000 / 1_000_000 = 100hz
    // 100_000_000 / 100_000 = 1000hz
    `ifdef SIMULATION
        parameter div100hz = 2; 
        parameter div1000hz = 2;
    `else
        parameter div100hz = 1_000_000; 
        parameter div1000hz = 100_000;
    `endif
    clk_div #(.DIV(div100hz)) u0(CLK, RST, clk100hz); // program and led
    // for debounce -> 100 hz = 10 ms should also be good
    clk_div #(.DIV(div1000hz)) u3(CLK, RST, clk1000hz); // seven seg
    
    io_controller IO(.*);
//    input logic clk100hz, clk1000hz, RST,
//    input logic btnL, btnR, btnU, btnD,
//    input logic [31:0] R_IO,
//    output logic [6:0] seg,
//    output logic [3:0] an,
//    output logic dBTNL, dBTNR, dBTNU, dBTND
    
    risc_v CPU(.CLK(clk100hz), .*);
    // dBTNR shows upper 16 bits of alu.rs1
    assign led = dBTNR ? R_led[31:16] : R_led[15:0];
        
    Memory #(1) I_MEM (I_CS, CLK, I_WE, I_ADDR, I_Mem_Bus);
    Memory #(0) D_MEM (D_CS, CLK, D_WE, D_ADDR, D_Mem_Bus);
endmodule
