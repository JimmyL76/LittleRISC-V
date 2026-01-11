module uart #(
    parameter CLK_FREQ = 50_000_000, // 50 MHz clock
    parameter BAUD_RATE = 9600,
    // timer that translates between CLK freq speed and baud rate speed
    parameter CLKS_PER_BIT = (CLK_FREQ / BAUD_RATE) // ~5208.33 cycles/baud, -1 for 0 index
    // decimal rounding is ok since timing is reset every byte
)(
    input logic CLK, clk_cpu, RST,
    input logic rx_serial,
    output logic tx_serial,
    
    // RX interface 
    output logic [7:0] rx_byte,
    output logic rx_valid,
    
    // TX interface
    input logic [7:0] tx_byte,
    input logic tx_start,
    output logic tx_busy,

    // led debug
    output logic [3:0] dbg_uart_state
);

    assign dbg_uart_state = {tx_state, rx_state};

    // RX logic
    typedef enum logic [1:0] {RX_IDLE, RX_START, RX_DATA, RX_STOP} rx_state_t;
    rx_state_t rx_state;

    logic [$clog2(CLKS_PER_BIT)-1:0] rx_timer;
    logic [2:0] rx_bit_idx; // up to 8 bits
    
    always_ff @(posedge CLK) begin
        if (RST) begin
            rx_state <= RX_IDLE;
            rx_valid <= 0;
            rx_timer <= 0;
            rx_byte <= 0;
        end else begin
            if (clk_cpu) begin
            rx_valid <= 0; // default
            case (rx_state)
                RX_IDLE: begin
                    if (rx_serial == 0) begin // start bit
                        rx_timer <= rx_timer + 1; // add additional timer to handle electrical noise
                        if (rx_timer == 10) begin
                            rx_state <= RX_START;
                            rx_timer <= (CLKS_PER_BIT-1) / 2; // capture on middle of bit - ~2600 cycles
                            // adjust middle if add noise timer gets too long
                        end
                    end else rx_timer <= 0;
                end
                RX_START: begin
                    if (rx_timer == 0) begin
                        rx_state <= RX_DATA;
                        rx_timer <= (CLKS_PER_BIT-1); // now wait for a full baud/bit cycle
                        rx_bit_idx <= 0;
                    end else rx_timer <= rx_timer - 1;
                end
                RX_DATA: begin
                    if (rx_timer == 0) begin
                        rx_byte <= {rx_serial, rx_byte[7:1]}; // receive LSB first
                        rx_timer <= (CLKS_PER_BIT-1);
                        if (rx_bit_idx == 7) rx_state <= RX_STOP;
                        else rx_bit_idx <= rx_bit_idx + 1;
                    end else rx_timer <= rx_timer - 1;
                end
                RX_STOP: begin // only necessary to wait for stop bit
                    if (rx_timer == 0) begin
                        rx_state <= RX_IDLE;
                        rx_valid <= 1; // one cycle active
                    end else rx_timer <= rx_timer - 1;
                end
            endcase
            end
        end
    end

    // TX logic
    typedef enum logic [1:0] {TX_IDLE, TX_START, TX_DATA, TX_STOP} tx_state_t;
    tx_state_t tx_state;

    logic [$clog2(CLKS_PER_BIT)-1:0] tx_timer;
    logic [2:0]  tx_bit_idx;
    logic [7:0]  tx_data_saved;

    assign tx_busy = (tx_state != TX_IDLE);
    assign tx_serial = (tx_state == TX_DATA) ? tx_data_saved[0] : 
                        (tx_state == TX_START) ? 0 : 1; // idle high

    always_ff @(posedge CLK) begin
        if (RST) begin
            tx_state <= TX_IDLE;
            tx_timer <= 0;
        end else begin
            if (clk_cpu) begin
            case (tx_state)
                TX_IDLE: begin
                    if (tx_start) begin
                        tx_data_saved <= tx_byte; // latch current value
                        tx_state <= TX_START;
                        tx_timer <= (CLKS_PER_BIT-1); // don't need middle of baud anymore
                    end
                end
                TX_START: begin 
                    if (tx_timer == 0) begin
                        tx_state <= TX_DATA;
                        tx_timer <= (CLKS_PER_BIT-1);
                        tx_bit_idx <= 0;
                    end else tx_timer <= tx_timer - 1;
                end
                TX_DATA: begin
                    if (tx_timer == 0) begin
                        tx_data_saved <= tx_data_saved >> 1; // send LSB first
                        tx_timer <= (CLKS_PER_BIT-1);
                        if (tx_bit_idx == 7) tx_state <= TX_STOP;
                        else tx_bit_idx <= tx_bit_idx + 1; 
                    end else tx_timer <= tx_timer - 1;
                end
                TX_STOP: begin // send stop bit
                    if (tx_timer == 0) begin
                        tx_state <= TX_IDLE;
                    end else tx_timer <= tx_timer - 1;
                end
            endcase
            end
        end
    end
endmodule
