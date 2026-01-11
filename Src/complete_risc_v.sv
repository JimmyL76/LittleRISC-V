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
    // U = step forward, L = show upper disp bits, R = show upper led bits
    input logic btnL, btnR, btnU, btnD, 
    input logic sw, // reset switch tied to RST

    input logic rx, // UART signals
    output logic tx,

    output logic [15:0] led, // taps alu.rs1 + debug states
    output logic [6:0] seg, // displays REG[1]
    output logic [3:0] an
    );
    
    // basys 3 at 100 Mhz, 100_000_000 / 1_000_000 = 100hz
    // 100_000_000 / 100_000 = 1000hz
    logic clk_led, clk_sseg, clk_cpu;
    `ifdef SIMULATION
        parameter div100hz = 2; 
        parameter div1000hz = 2;
        parameter div50Mhz = 2;
    `else
        parameter div100hz = 1_000_000; 
        parameter div1000hz = 100_000;
        parameter div50Mhz = 2;
    `endif
    fpga_clk_div #(.DIV(div100hz)) led_clk_div(CLK, clk_led); // led
    // for debounce -> 100 hz = 10 ms should also be good
    fpga_clk_div #(.DIV(div1000hz)) sseg_clk_div(CLK, clk_sseg); // seven seg
    fpga_clk_div #(.DIV(div50Mhz)) cpu_clk_div(CLK, clk_cpu); // cpu

    logic [31:0] R_IO, R_led;
    logic dBTNL, dBTNR, dBTNU, dBTND;
    logic RST; 
    
    io_controller IO(.*);
//    input logic clk100hz, clk1000hz,
//    input logic btnL, btnR, btnU, btnD,
//    input logic [31:0] R_IO,
//    output logic [6:0] seg,
//    output logic [3:0] an,
//    output logic dBTNL, dBTNR, dBTNU, dBTND

    // UART 
    logic [31:0] debug_addr;
    logic debug_we;
    wire [31:0] debug_data;
    logic debug_reset_req; assign RST = sw || debug_reset_req; // cpu reset
    logic debug_RST; assign debug_RST = sw; // UART logic should not reset itself
    logic [7:0] dbg_state;
    debug_controller UART_ctrl(.RST(debug_RST), .rx_serial(rx), .tx_serial(tx), .mem_addr(debug_addr), .mem_we(debug_we), .mem_data(debug_data), .cpu_reset_req(debug_reset_req), .*);
    
    logic I_CS, D_CS;
    logic [3:0] I_WE, D_WE;
    logic [31:0] I_ADDR, D_ADDR;
    wire [31:0] I_Mem_Bus, D_Mem_Bus;
    // // without UART
    // logic Init; assign Init = 0; 
    // logic [31:0] InitPC, Init_Data; assign InitPC = 0; assign Init_Data = 0;
    
    Memory #(1, 1) I_MEM (I_CS, CLK, clk_cpu, I_WE, I_ADDR, I_Mem_Bus, debug_addr, debug_we, debug_data);
    Memory #(0, 0) D_MEM (D_CS, CLK, clk_cpu, D_WE, D_ADDR, D_Mem_Bus, debug_addr, debug_we, debug_data);
    
    risc_v CPU(.*);
    // dBTNR shows upper 16 bits of alu.rs1
    // assign led = dBTNR ? R_led[31:16] : R_led[15:0];
    assign led[7:0] = dBTNR ? R_led[15:8] : R_led[7:0]; // lower 16 bits of alu.rs1
    assign led[15:8] = dbg_state; // led[15:12] debug ctrl state, led[11:10] uart TX state, led[9:8] uart RX state
    
endmodule
