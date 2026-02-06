module mmio_controller(
    input logic CLK, RST,
    
    // cpu mem-like interface
    input logic [31:0] mem_addr,
    input logic mem_we, mem_valid, debug_active,
    inout wire [31:0] debug_mem_data, cpu_mem_data,

    // UART internal pins
    input logic [7:0] rx_byte,
    input logic rx_valid, 
    output logic [7:0] tx_byte,
    output logic tx_start, 
    input logic tx_busy,

    // ext pins
    output logic [31:0] led_value,
    output logic [31:0] sseg_value
);

    logic [31:0] led_reg; assign led_value = led_reg;
    logic [31:0] sseg_reg; assign sseg_value = sseg_reg;

    logic rx_data_ready; // sticky bit for new data from UART

    // write logic
    logic [31:0] data_out;
    logic in_mmio_range; assign in_mmio_range = (mem_addr[15] == 1'b1);
    logic MMIO_drive; assign MMIO_drive = (!mem_we && in_mmio_range); // signals when driving MMIO data lines

    assign debug_mem_data = (MMIO_drive) ? data_out : 32'bZ; 
    assign cpu_mem_data = (MMIO_drive) ? data_out : 32'bZ; 
    // only drive when reading and in MMIO range to avoid multiple drivers from normal cpu to d mem
    // separate wires for debug and cpu to avoid conflicts, then mux/prioritize
    logic [31:0] mem_wdata; assign mem_wdata = (debug_active) ? debug_mem_data : cpu_mem_data; // read high-Z logic handled by debug ctrl and risc-v modules

    // when writing UART data, use cont. assign for UART transceiver's 1 cycle delay
    // also avoids weird issues with negedge clk (in old clk_div configuration)
    assign tx_byte = data_out[7:0]; // 'A' or cont asgn to data reg
    assign tx_start = (mem_we && (mem_addr == 32'h0000_800C)); // when performing strict MMIO addr checks, assume upper bits will always be 0 (always valid addr space)

    // double clk_cpu freq, like mem
    always_ff @(posedge CLK) begin
        if (RST) begin
            led_reg <= 0;
            sseg_reg <= 0;
            rx_data_ready <= 0;
            // tx_start <= 0;
        end else begin
            // $monitor("Time = %0t | MMIO Access: WE = %b, VALID = %b, DATA_IN = %h, DATA_OUT = %h", $time, mem_we, mem_valid, mem_wdata, data_out);
            // $monitor("Time = %0t | DATA_IN = %h, DATA_OUT = %h", $time, mem_wdata, data_out);
            if (rx_valid) rx_data_ready <= 1;

            // if (clk_cpu) begin
            // tx_start <= 0; 
            if (mem_we) begin
                case (mem_addr)
                    32'h0000_8000: led_reg <= mem_wdata; 
                    32'h0000_8004: sseg_reg <= mem_wdata;
                    // 32'h8000_000C: begin                      
                    //     tx_byte <= data_out[7:0];
                    //     tx_start <= 1; 
                    // end
                endcase
            // end
            end
            case (mem_addr)
                32'h0000_8000: data_out = {16'b0, led_reg}; // LED readback
                32'h0000_8004: data_out = sseg_reg; // sseg readback
                // UART status reg: bit 0 = RX valid (data ready), bit 1 = TX busy (wait before sending)
                32'h0000_8008: begin 
                    data_out = {30'b0, tx_busy, rx_data_ready}; 
                    if (!rx_valid && mem_valid) rx_data_ready <= 0; // clear if actively read and no new data
                end
                32'h0000_800C: data_out = {24'b0, rx_byte}; // UART data reg
            endcase
        end
    end

endmodule