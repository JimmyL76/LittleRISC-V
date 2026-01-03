`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/15/2025 09:04:28 AM
// Design Name: 
// Module Name: memory
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


//`define SIMULATION

module Memory #(
    parameter init, 
    // parameter MEM_TOP // instr = 0x00004000, data = 0x00008000
    parameter instr // 0 data mem, 1 instr mem
   )(
    input CS, CLK,
    input [3:0] WE,
    input [31:0] ADDR,
    inout [31:0] Mem_Bus,
    // UART port (for dual-port BRAM)
    input logic [31:0] debug_addr,
    input logic debug_we,
    inout wire [31:0] debug_data
);

    localparam MEMSPACE = (2**12); // for 16KB of BRAM space: 16KB/(4B/word) = 4K of words, or 4,096 

    reg [31:0] data_out;
    reg [31:0] RAM [0:MEMSPACE-1]; 

    integer i;
    initial begin
        for(i=0; i<(MEMSPACE); i=i+1) begin
            RAM[i] = 32'h0;
        end
    
      //if (init) $readmemh(INIT_FILE, RAM);
        if (init) $readmemh("instr.mem", RAM);
      
        `ifdef SIMULATION
      // simulation code
            if (init) begin
                for (i = 0; i <(MEMSPACE); i = i+1) // testing
                    $display("I_MEM[%0d] = %b", i, RAM[i]);
            end
            $monitor("MEM_Bus = %h, ADDR = %0d, CS = %b, WE = %b", Mem_Bus, ADDR, CS, WE);
        `endif
    end

    assign Mem_Bus = ((CS == 1'b0) || (WE)) ? 32'bZ : data_out;

    // port A - CPU
    always @(negedge CLK) begin
        if (CS && WE) begin
            for (i=0; i < 4; i=i+1) 
                if (WE[i]) RAM[ADDR][i*8 +: 8] <= Mem_Bus[i*8 +: 8];
        end
        data_out <= RAM[ADDR]; // load
    end

    logic [31:0] debug_data_out;
    // logic in_range = (debug_addr < MEM_TOP) && (debug_addr >= (MEM_TOP - 32'h00004000));
    logic in_range; assign in_range = (instr) ? (!debug_addr[14]) : (debug_addr[14]); // efficient bit masking
    assign debug_data = (!debug_we && in_range) ? debug_data_out : 32'bZ; // only drive inside range of valid addrs

    // port B - UART
    always @(negedge CLK) begin // 2^14 = 16KB, so use [13:2], any debug_addr >= 32'h00004000 wraps around
        if (debug_we && in_range) RAM[debug_addr[13:2]] <= debug_data;
        debug_data_out <= RAM[debug_addr[13:2]]; // read RAM based on word, not byte address
    end
  
endmodule
