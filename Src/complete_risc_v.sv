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
    // U = step forward, L = show upper disp bits, R = show upper led bits, D = switch sseg to show R1 and led to show alu.rs1
    input logic btnL, btnR, btnU, btnD, 
    input logic [2:0] sw, // 0 = RST, 1 = default GO, 2 = step x10, neither = step 1 cycle, in priority order

    input logic rx_external, // UART signals
    output logic tx_external,

    output logic [15:0] led, // taps alu.rs1 + debug states
    output logic [6:0] sseg, // displays REG[1]
    output logic [3:0] an
    );
    
    // --- clock dividers ---
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

    logic RST; 

    // --- UART --- 
    logic [7:0] rx_byte, tx_byte;
    logic rx_valid, tx_start, tx_busy;
    logic [3:0] dbg_uart_state;
    logic debug_RST; assign debug_RST = sw[0]; // UART logic should not reset itself
    uart uart_transceiver(.RST(debug_RST), .*); //* specify debug-specific reset now that UART is outside

    // --- UART debug controller --- 
    logic [31:0] debug_addr;
    logic debug_we, debug_mem_valid;
    wire [31:0] debug_data;
    logic debug_reset_req; assign RST = sw[0] || debug_reset_req; // cpu reset
    logic debug_active;
    logic [7:0] debug_tx_byte;
    logic debug_tx_start;
    logic [2:0] dbg_state;
    debug_controller UART_ctrl(.RST(debug_RST), .tx_byte(debug_tx_byte), .tx_start(debug_tx_start), .mem_addr(debug_addr), .mem_we(debug_we), .mem_valid(debug_mem_valid), .mem_data(debug_data), .cpu_reset_req(debug_reset_req), .*);

    logic I_CS, D_CS;
    logic [3:0] I_WE, D_WE;
    logic [31:0] I_ADDR, D_ADDR;
    wire [31:0] I_Mem_Bus, D_Mem_Bus;
    // // without UART
    // logic Init; assign Init = 0; 
    // logic [31:0] InitPC, Init_Data; assign InitPC = 0; assign Init_Data = 0;
    
    // --- instr and data mem ---
    Memory #(1, 1) I_MEM (I_CS, CLK, I_WE, I_ADDR, I_Mem_Bus, debug_addr, debug_we, debug_data);
    Memory #(0, 0) D_MEM (D_CS, CLK, D_WE, D_ADDR, D_Mem_Bus, debug_addr, debug_we, debug_data);

    // --- MMIO controller ---
    //    32'h0000_8000: led_reg {16'b0, led_reg};
    //    32'h0000_8004: sseg_reg
    //    32'h0000_8008: UART status reg {30'b0, tx_busy, rx_valid}; 
    //    32'h0000_800C: UART data reg {24'b0, rx_byte};
    // rest of mem will not activate if addr is in MMIO range, and MMIO mem will not work unless in range, so treat as extension of normal d mem
    // MMIO addr range: 0x0000_8000 to 0x0000_8FFF (high bit 15)
    logic [31:0] MMIO_sseg_value, MMIO_led_value;
    logic [7:0] MMIO_tx_byte;
    logic MMIO_tx_start;

    // with MMIO, either UART or normal mem can write/read to MMIO space, so prioritize the debug controller, since in normal operation, any manual UART should halt CPU first
    // debug_active only true when something is on the rx line (computer is trying to manually talk to UART), any tx_start from mmio_ctrl goes straight to UART module
    logic [31:0] MMIO_mem_addr; assign MMIO_mem_addr = (debug_active) ? debug_addr : D_ADDR;
    logic MMIO_mem_we; assign MMIO_mem_we = (debug_active) ? debug_we : (&D_WE); // assume lw/sw (not byte)
    logic MMIO_mem_valid; assign MMIO_mem_valid = (debug_active) ? debug_mem_valid : D_CS; // signifies an active read or write

    // assume MMIO gets normal reset
    mmio_controller MMIO_ctrl(.mem_addr(MMIO_mem_addr), .mem_we(MMIO_mem_we), .mem_valid(MMIO_mem_valid), .debug_mem_data(debug_data), .cpu_mem_data(D_Mem_Bus), .tx_byte(MMIO_tx_byte), .tx_start(MMIO_tx_start), .sseg_value(MMIO_sseg_value), .led_value(MMIO_led_value), .*);
    // cannot have multiple drivers for TX outputs, give priority to debug controller
    assign tx_byte = (debug_active) ? debug_tx_byte : MMIO_tx_byte;
    assign tx_start = (debug_active) ? debug_tx_start : MMIO_tx_start;
    // --- other IO controller ---
    logic dBTNL, dBTNR, dBTNU, dBTND;
    logic [31:0] sseg_value;
    io_controller IO(.*);
    // input logic CLK, clk_led, clk_sseg, 
    // input logic btnL, btnR, btnU, btnD,
    // input logic [31:0] sseg_value,
    // output logic [6:0] sseg,
    // output logic [3:0] an,
    // output logic dBTNL, dBTNR, dBTNU, dBTND
    
    // --- RISC-V CPU ---
    logic [31:0] R_led, R_IO;
    risc_v CPU(.GO(sw[1]), .STEPx10(sw[2]), .*);

    assign sseg_value = dBTND ? R_IO : MMIO_sseg_value; // show REG[1] if btnD
    assign led = (dBTNR && !dBTND) ? MMIO_led_value[31:16] : 
                (dBTNR && dBTND) ? R_led[31:16] :
                dBTND ? R_led[15:0] : 
                MMIO_led_value[15:0]; // lower 16 bits of alu.rs1 if btnD
    // logic [7:0] dbg_total_state; assign dbg_total_state = {state, dbg_uart_state};
    // assign led[7:0] = dBTNR ? R_led[15:8] : R_led[7:0]; // lower 16 bits of alu.rs1
    // assign led[15:8] = dbg_total_state; // led[15:12] debug ctrl state, led[11:10] uart TX state, led[9:8] uart RX state
    
endmodule
