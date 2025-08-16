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


`define SIMULATION

module Memory #(
  parameter init 
  //parameter INIT_FILE
)(
  input CS, CLK,
  input [3:0] WE,
  input [31:0] ADDR,
  inout [31:0] Mem_Bus);
  
  localparam MEMSPACE = (2**6);

  reg [31:0] data_out;
  reg [31:0] RAM [0:MEMSPACE-1]; // made it 6 bits due to limited BRAM fpga space
  
  integer i;
  initial begin
    for(i=0; i<(MEMSPACE); i=i+1) begin
        RAM[i] = 32'h0;
    end
    
    //if(init) $readmemh(INIT_FILE, RAM);
    if(init) $readmemh("instr.mem", RAM);
    
    `ifdef SIMULATION
  // simulation code
        if(init) begin
            for (i = 0; i <(MEMSPACE); i = i+1) // testing
                $display("I_MEM[%0d] = %b", i, RAM[i]);
        end
        $monitor("MEM_Bus = %h, ADDR = %0d, CS = %b, WE = %b", Mem_Bus, ADDR, CS, WE);
    `endif
  end

  assign Mem_Bus = ((CS == 1'b0) || (WE)) ? 32'bZ : data_out;

  always @(negedge CLK)
  begin
    if(CS && WE) begin
        for (i=0; i < 4; i=i+1) 
            if(WE[i]) RAM[ADDR][i*8 +: 8] <= Mem_Bus[i*8 +: 8];
    end
    data_out <= RAM[ADDR]; // load
  end
  
endmodule
