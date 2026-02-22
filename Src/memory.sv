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

    integer i, r, fd;
    initial begin
        for(i=0; i<(MEMSPACE); i=i+1) begin
            RAM[i] = 32'h0;
        end
    
      if (init) $readmemh("instr.mem", RAM);
      // if (init) $readmemh("C:/Little_RISCV/Little_RISCV.srcs/sources_1/imports/InitMem/led_test.mem", RAM);
      // if (init) $readmemh("seg_test.mem", RAM);
    //   if (init) begin 
    //     fd = $fopen("add_test.bin", "rb");
    //     if (fd == 0) begin
    //         $display("ERROR: Could not open add_test.bin");
    //         $finish;
    //     end
    //     r = $fread(RAM, fd);
    //     $fclose(fd);
    //   end
      
        `ifdef SIMULATION
            if (init) begin
                for (i = 0; i <(MEMSPACE / 4); i = i+1) // testing
                    $display("I_MEM[%0d] = %h", i, RAM[i]);
            end
            // $monitor("MEM_Bus = %h, ADDR = %0d, CS = %b, WE = %b", Mem_Bus, ADDR, CS, WE);
        `endif

        // $monitor("Time=%0t Instr=%0d | CPU In Range = %b", $time, instr, cpu_in_range);
        // $monitor("Time=%0t Instr=%0d | Debug We = %b, Debug Addr = %h, Debug Data = %h", $time, instr, debug_we, debug_addr, debug_data);
        // $monitor("Time=%0t Instr=%0d | CPU CS = %b, WE = %b, ADDR = %h, Mem_Bus = %h", $time, instr, CS, WE, ADDR, Mem_Bus);
    end

    // logic in_range = (debug_addr < MEM_TOP) && (debug_addr >= (MEM_TOP - 32'h00004000));
    logic debug_in_range; assign debug_in_range = (instr) ? (debug_addr[15:14] == 2'b00) : (debug_addr[15:14] == 2'b01); // efficient bit masking - bit 15 checks for MMIO addr spaces
    logic cpu_in_range; assign cpu_in_range = (instr) ? (ADDR[15:14] == 2'b00) : (ADDR[15:14] == 2'b01); // cpu views data and instr mem at x0000-x7FFF, MMIO begins at x8000

    assign Mem_Bus = ( !((CS == 1'b0) || WE) && cpu_in_range) ? data_out :
        (!instr && (ADDR[15:14] == 2'b00) && !WE && CS) ? debug_data : 32'bZ; 
    // for data_out, only drive a read when in range to not affect MMIO reads
    // for debug_data, check when D_Mem accesses I_Mem (D_Mem, addr < x4000, read only, D_Mem selected)
    // debug_data will always be correct if D_Mem needs to access I_Mem -> 3 possible drivers: D_Mem cannot due to debug_in_range, debug_ctrl outputs Z, so only I_Mem
    // assume debug_ctrl will not be active during normal CPU operation

    // port A - CPU
    // for fpga_clk_div, single-cycle enable doesn't work with neg edge clk, switch to posedge at full clk freq
    always @(posedge CLK) begin
        if (CS && WE && cpu_in_range) begin
            for (i=0; i < 4; i=i+1) 
                if (WE[i]) RAM[ADDR[13:2]][i*8 +: 8] <= Mem_Bus[i*8 +: 8]; // byte write, and mask byte addr to word addr + wrap around x4000
        end
        if (CS) data_out <= RAM[ADDR[13:2]]; // load

        `ifdef SIMULATION
            if ((ADDR == 32'h0000_8000) || (ADDR == 32'h0000_8004)) begin
                $display("Time=%0t | Instr=%0d, CS = %b, WE = %b", $time, instr, CS, WE);
                $display("MMIO_mem_we = %b, D_WE = %b", r.MMIO_ctrl.mem_we, r.D_WE);
                if (CS && WE) $display("CPU MEM WRITE to addr %h, data = %h", ADDR, Mem_Bus);
                else if (CS && !WE) $display("CPU MEM READ from addr %h, data = %h", ADDR, data_out);
            end
        `endif
    end

    logic [31:0] debug_data_out;
    assign debug_data = (!debug_we && debug_in_range) ? debug_data_out : 32'bZ; // only drive inside range of valid addrs

    // this is different from cpu which treats data mem as starting at addr 0
    // also assume UART will never write to mem while CPU is running program (assume only write for program loads)

    // port B - UART
    always @(posedge CLK) begin // 2^14 = 16KB, so use [13:2], any debug_addr >= 32'h00004000 wraps around
        if (debug_we && debug_in_range) RAM[debug_addr[13:2]] <= debug_data;
        debug_data_out <= RAM[debug_addr[13:2]]; // read RAM based on word, not byte address
    end
  
endmodule
