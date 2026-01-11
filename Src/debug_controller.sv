module debug_controller(
    input logic CLK, clk_cpu, RST,
    
    // UART external pins
    input logic rx_serial,
    output logic tx_serial,

    // mem interface
    output logic [31:0] mem_addr,
    output logic mem_we,
    inout wire [31:0] mem_data,

    output logic cpu_reset_req,

    // debug
    output logic [7:0] dbg_state
);

    logic [7:0] rx_byte, tx_byte;
    logic rx_valid, tx_start, tx_busy;

    uart uart_transceiver(.*);

    typedef enum logic [3:0] {IDLE, GET_ADDR, GET_DATA, EXEC_READ, EXEC_WRITE, SEND_ACK, SEND_DATA} state_t;
    state_t state;
    
    logic [3:0] dbg_uart_state;
    assign dbg_state = {state, dbg_uart_state};

    logic [7:0] cmd_reg;
    logic [31:0] addr_reg;
    logic [31:0] data_reg;
    logic [1:0] byte_count; // up to 4 bytes for addr/data

    assign tx_byte = (state == SEND_ACK) ? 8'h41 : data_reg[31:24]; // 'A' or cont asgn to data reg
    assign tx_start = (state == SEND_ACK) || (state == SEND_DATA && !tx_busy);
    assign mem_addr = addr_reg;
    assign mem_data = (mem_we) ? data_reg : 32'bZ;

    always_ff @(posedge CLK) begin
        if (RST) begin
            state <= IDLE;
            mem_we <= 0;
            // tx_start <= 0;
            cpu_reset_req <= 1; // begin cpu as halted (wait for instrs to be loaded)
            cmd_reg <= 0; addr_reg <= 0; data_reg <= 0;
        end else begin
            if (clk_cpu) begin
            mem_we <= 0;
            // tx_start <= 0;

            case (state)
                IDLE: begin
                    if (rx_valid) begin // each rx_valid is waiting for one additional byte
                        cmd_reg <= rx_byte;
                        byte_count <= 0;
                        
                        if (rx_byte == 8'h50) state <= SEND_ACK; // 'P'ing
                        else if ((rx_byte == 8'h57) || (rx_byte == 8'h52)) state <= GET_ADDR; // 'W'rite or 'R'ead
                        else if (rx_byte == 8'h48) begin // 'H' (Halt) - and reset
                            cpu_reset_req <= 1; 
                            state <= SEND_ACK;
                        end
                        else if (rx_byte == 8'h47) begin // 'G' (Go)
                            cpu_reset_req <= 0;
                            state <= SEND_ACK;
                        end    
                    end
                end
                GET_ADDR: begin
                    if (rx_valid) begin
                        // MSB first for bytes
                        addr_reg <= {addr_reg[23:0], rx_byte}; 
                        byte_count <= byte_count + 1;
                        
                        if (byte_count == 3) begin
                            if (cmd_reg == 8'h57) state <= GET_DATA; // write has data
                            else state <= EXEC_READ;
                            byte_count <= 0;
                        end
                    end
                end
                GET_DATA: begin
                    if (rx_valid) begin
                        data_reg <= {data_reg[23:0], rx_byte};
                        byte_count <= byte_count + 1;
                        
                        if (byte_count == 3) begin
                            state <= EXEC_WRITE;
                            byte_count <= 0; // reset ctr for sending data
                        end
                    end
                end
                EXEC_WRITE: begin
                    // mem_addr <= addr_reg;
                    // mem_wdata <= data_reg;
                    mem_we <= 1;
                    state <= SEND_ACK;
                end
                EXEC_READ: begin
                    // mem_addr <= addr_reg;
                    state <= SEND_DATA; 
                    data_reg <= mem_data; // assume one cycle read
                end
                SEND_ACK: begin
                    if (!tx_busy) begin
                        // tx_byte <= 8'h41; // 'A'
                        // tx_start <= 1;
                        state <= IDLE;
                    end
                end
                SEND_DATA: begin
                    if (!tx_busy) begin
                        data_reg <= data_reg << 8;
                        // tx_start <= 1;
                        
                        if (byte_count == 3) state <= IDLE;
                        else byte_count <= byte_count + 1;
                    end
                end
            endcase
            end
        end
    end
endmodule
