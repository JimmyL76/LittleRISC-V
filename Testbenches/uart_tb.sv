`timescale 1ns / 1ps

module uart_tb();
    logic CLK; 
    // U = step forward, L = show upper led bits, R = show upper disp bits
    logic btnL, btnR, btnU, btnD;
    logic sw; // reset switch tied to RST
    logic rx;
    
    logic tx;
    logic [15:0] led; // taps alu.rs1
    logic [6:0] seg; // displays REG[1]
    logic [3:0] an;

    assign btnL = 0; assign btnR = 0; assign btnU = 0; assign btnD = 0; 
    logic RST; assign sw = RST;

    complete_risc_v dut(.*);
// module complete_risc_v(
//     input logic CLK, 
//     // input logic RST, Pause // could be UART controlled too
//     // U = step forward, L = show upper led bits, R = show upper disp bits
//     input logic btnL, btnR, btnU, btnD, 
//     input logic sw, // reset switch tied to RST

//     input logic rx, // UART signals
//     output logic tx,

//     output logic [15:0] led, // taps alu.rs1
//     output logic [6:0] seg, // displays REG[1]
//     output logic [3:0] an
//     );

    initial begin
        CLK = 0;
        forever #10 CLK = ~CLK;
    end

    localparam CMD_WRITE = 8'h57; // 'W'
    localparam CMD_READ = 8'h52; // 'R'
    localparam CMD_PING = 8'h50; // 'P'
    localparam CMD_HALT = 8'h48; // 'H'
    localparam CMD_GO = 8'h47; // 'G'
    localparam ACK = 8'h41; // 'A'

    // 50MHz/9600 baud = ~5208 cycles/baud
    // localparam NS_PER_BIT = 5208 * 20; // 5208 * 20ns/1cycle
    localparam NS_PER_BIT = 5 * 20; // force 5 cycles/bit * 20ns/cycle

    task uart_send_byte(input [7:0] data);
        int i;
        begin
            rx = 0; 
            #(NS_PER_BIT);
            for (i=0; i<8; i=i+1) begin
                rx = data[i];
                #(NS_PER_BIT);
            end
            rx = 1;
            #(NS_PER_BIT);
        end
    endtask

    task uart_send_word(input [31:0] data);
        begin
            uart_send_byte(data[31:24]);
            uart_send_byte(data[23:16]);
            uart_send_byte(data[15:8]);
            uart_send_byte(data[7:0]);
        end
    endtask

    task uart_receive_byte(output [7:0] data);
        int i;
        begin
            @(negedge tx);
            #(NS_PER_BIT + (NS_PER_BIT/2));
            
            for (i=0; i<8; i=i+1) begin
                data[i] = tx;
                #(NS_PER_BIT);
            end
        end
    endtask

    task uart_receive_word(output [31:0] data);
        logic [7:0] b3, b2, b1, b0;
        begin
            uart_receive_byte(b3);
            uart_receive_byte(b2);
            uart_receive_byte(b1);
            uart_receive_byte(b0);
            data = {b3, b2, b1, b0}; // MSB first for bytes
        end
    endtask

    // random write then imm read to verify
    task test_random_rw(input int num_tests);
        logic [7:0] tx_byte;
        logic [31:0] rand_addr, rand_data, result;

        // logic [31:0] scoreboard [int]; 
        static int error_count = 0;
        
        $display("\n[TASK] Random R/W (%0d tests)", num_tests);

        for (int i = 0; i < num_tests; i++) begin
            rand_addr = $urandom_range(0, 32'h00007FFF) & 32'hFFFFFFFC; // limit to range and mask w/ xFFFFFFFC for words
            rand_data = $urandom;
            
            // write
            uart_send_byte(CMD_WRITE);
            uart_send_word(rand_addr);
            uart_send_word(rand_data);
            
            uart_receive_byte(tx_byte); 
            if (tx_byte != ACK) begin
                 $display("[FAIL] Write ACK missing on test %0d", i);
                 error_count++;
            end

            // scoreboard[rand_addr] = rand_data;
            
            #(NS_PER_BIT * 10); 

            // read
            uart_send_byte(CMD_READ);
            uart_send_word(rand_addr);
            
            uart_receive_word(result);

            // Compare
            if (result !== rand_data) begin
                $display("[FAIL] Addr %h: Expected %h, Got %h", rand_addr, rand_data, result);
                error_count++;
            end
            #(NS_PER_BIT * 2);
        end

        if (error_count == 0) $display("SUCCESS: Random R/W passed");
        else $display("FAILURE: Random R/W found %0d errors", error_count);
    endtask

    // do all writes then all reads
    task test_bulk_rw(input int num_tests);
        logic [31:0] rand_addr, rand_data, result;
        logic [7:0] tx_byte;
        
        logic [31:0] scoreboard [int]; // associative array instead of queue for random mem access
        logic [31:0] addr_history [$]; // queue to track every addr
        static int error_count = 0;
        
        $display("\n[TASK] Bulk Random R/W (%0d tests)", num_tests);

        for (int i = 0; i < num_tests; i++) begin
            rand_addr = $urandom_range(0, 32'h00007FFF) & 32'hFFFFFFFC;
            rand_data = $urandom;

            uart_send_byte(CMD_WRITE);
            uart_send_word(rand_addr);
            uart_send_word(rand_data);
            
            uart_receive_byte(tx_byte); 
            if (tx_byte != ACK) begin
                 $display("[FAIL] Write ACK missing on test %0d", i);
                 error_count++;
            end

            // duplicates are ok since scoreboard updates with latest data
            addr_history.push_back(rand_addr);
            scoreboard[rand_addr] = rand_data;
            
            #(NS_PER_BIT * 2);
        end

        // shuffle reads
        addr_history.shuffle(); 

        foreach (addr_history[i]) begin
            automatic logic [31:0] target_addr = addr_history[i];
            automatic logic [31:0] expected_data = scoreboard[target_addr];

            uart_send_byte(CMD_READ);
            uart_send_word(target_addr);

            uart_receive_word(result);

            if (result !== expected_data) begin
                $display("[FAIL] Addr %h: Expected %h, Got %h", target_addr, expected_data, result);
                error_count++;
            end 
            
            #(NS_PER_BIT * 2);
        end

        if (error_count == 0) $display("[SUCCESS] Bulk R/W passed");
        else $display("[FAILURE] Bulk R/W found %0d errors", error_count);
    endtask

    // burst write instrs starting at 0x0
    task test_load_program(input logic [31:0] instrs[]);
        logic [7:0] tx_byte;
        int i;
        $display("\n[TASK] Loading program (%0d instrs)", instrs.size());
        
        // uart_send_byte(CMD_HALT); // cpu should already be halted
        // uart_receive_byte(tx_byte); 

        for (i = 0; i < instrs.size(); i++) begin
            uart_send_byte(CMD_WRITE);
            uart_send_word(i * 4);
            uart_send_word(instrs[i]);
            
            uart_receive_byte(tx_byte);
            if (tx_byte != ACK) $display("[FAIL] Program load ACK missing at addr %h", i*4);
        end
    endtask

    // release for N cycles then halt
    task test_cpu_run(input int cycles_to_run);
        logic [7:0] tx_byte;
        $display("\n[TASK] Running CPU for %0d cycles", cycles_to_run);
        
        uart_send_byte(CMD_GO);
        uart_receive_byte(tx_byte);
        
        #(cycles_to_run * 20); // 20ns clock period

        uart_send_byte(CMD_HALT);
        uart_receive_byte(tx_byte); 
    endtask

    // dump mem with burst read
    task test_dump_mem(input logic [31:0] start_addr, input int count);
        logic [31:0] result;
        int i;
        $display("\n[TASK] Dumping Memory: Start=%h, Count=%0d", start_addr, count);

        for (i = 0; i < count; i++) begin
            automatic logic [31:0] current_addr = start_addr + (i * 4);
            
            uart_send_byte(CMD_READ);
            uart_send_word(current_addr);
            uart_receive_word(result);
            
            $display("DUMP [Addr %h]: %h", current_addr, result);
            #(NS_PER_BIT * 2);
        end
    endtask

    // dump registers - not UART controlled
    task test_dump_regs(input int num_regs);
        int i;
        $display("\n[TASK] Dumping CPU Registers:");
        for (i = 0; i < num_regs; i++) begin
            $display("REG[%0d] = %h", i, dut.CPU.registers.REG[i]);
        end
    endtask

    defparam dut.UART_ctrl.uart_transceiver.CLKS_PER_BIT = 5; // force 5 cycles/bit in uart

    logic [7:0] ping_byte;
    logic [31:0] instrs [];

    initial begin
        // $display("CLKS_PER_BIT=%0d", dut.UART_ctrl.uart_transceiver.CLKS_PER_BIT);
        RST = 1; rx = 1; force dut.CPU.Pause = 0; // don't single step
        #100; RST = 0; #100;

        uart_send_byte(CMD_PING);
        uart_receive_byte(ping_byte);
        if (ping_byte == ACK) $display("[PASS] Ping ack");
        else $display("[FAIL] Ping returned %h (Expected 41)", ping_byte); 

        test_random_rw(20);
        test_bulk_rw(20);

        // instructions.append(addi_instr(1, 0, 1))
        // instructions.append(addi_instr(1, 1, 2))
        // instructions.append(addi_instr(1, 1, 4))
        // instructions.append(addi_instr(1, 1, 8))
        // instructions.append(addi_instr(1, 1, 10))
        // instructions.append(addi_instr(2, 0, 2))
        // instructions.append(add_instr(3, 1, 2))
        instrs = new[7];
        instrs[0] = 32'h00100093; // addi x1, x0, 1
        instrs[1] = 32'h00208093; // addi x1, x1, 2
        instrs[2] = 32'h00408093; // addi x1, x1, 4
        instrs[3] = 32'h00808093; // addi x1, x1, 8
        instrs[4] = 32'h00A08093; // addi x1, x1, 10
        instrs[5] = 32'h00200113; // addi x2, x0, 2
        instrs[6] = 32'h002081B3; // add x3, x1, x2

        test_load_program(instrs);

        test_cpu_run(1000);
        test_dump_regs(4);

        test_dump_mem(0, instrs.size());

        // ping = CMD_PING;
        // tx_byte = 8'h00;
        // uart_send_byte(ping); 
        // $display("Sent ping %h", ping);
        
        // uart_wait_byte(tx_byte);
        // wait(tx_byte == ACK); // 'A' (0x41)

        // #(NS_PER_BIT * 10);

        // // cmd 'W'
        // uart_send_byte(CMD_WRITE);
        // // addr
        // uart_send_word(32'h00000000);
        // // data
        // uart_send_word(32'h01234567);
        // $display("Write sent 0x01234567 for addr 0x00000000");
        
        // #(NS_PER_BIT * 10);
        // // force dut.CPU.RST = 0; // release cpu reset
        // uart_send_byte(CMD_READ);
        // uart_send_word(32'h00000000);
        // uart_read_word(32'h00000000, matches);
        // $display("Read returned %h", matches);

        $finish;
    end
    
    initial begin
        // $monitor("Time=%0t RST=%b RX=%b TX=%h", $time, RST, rx, tx);
        // $monitor("Debug Controller State=%0d Cmd=%h Addr=%h Data=%h Mem_WE=%b", 
        //     dut.UART_ctrl.state, dut.UART_ctrl.cmd_reg, dut.UART_ctrl.addr_reg, dut.UART_ctrl.data_reg,
        //     dut.UART_ctrl.mem_we);
        // $monitor("UART RX State=%0d RX_Serial=%b RX_Byte=%h RX_Bit_Index=%0d RX_Valid=%b | TX_State=%0d TX_Serial=%b TX_Byte=%h TX_Start=%b TX_Busy=%b", 
        //     dut.UART_ctrl.uart_transceiver.rx_state, dut.UART_ctrl.uart_transceiver.rx_serial, dut.UART_ctrl.uart_transceiver.rx_byte, dut.UART_ctrl.uart_transceiver.rx_bit_idx, dut.UART_ctrl.uart_transceiver.rx_valid,
        //     dut.UART_ctrl.uart_transceiver.tx_state, dut.UART_ctrl.uart_transceiver.tx_serial, dut.UART_ctrl.uart_transceiver.tx_byte, dut.UART_ctrl.uart_transceiver.tx_start, dut.UART_ctrl.uart_transceiver.tx_busy);
    end

    always_ff @(negedge CLK) begin
        if (dut.D_MEM.CS && dut.D_MEM.WE) begin
            $display("Data Memory Write at Addr=%0h Data=%h WE=%b", dut.D_MEM.ADDR, dut.D_MEM.Mem_Bus, dut.D_MEM.WE);
        end else if (dut.I_MEM.CS && dut.I_MEM.WE) begin
            $display("Instr Memory Write at Addr=%0h Data=%h WE=%b", dut.I_MEM.ADDR, dut.I_MEM.Mem_Bus, dut.I_MEM.WE);
        end else if (dut.D_MEM.debug_we) begin
            $display("UART Data Memory Write at Addr=%0h Data=%h WE=%b", dut.D_MEM.debug_addr, dut.D_MEM.debug_data, dut.D_MEM.debug_we);
        end else if (dut.I_MEM.debug_we) begin
            $display("UART Instr Memory Write at Addr=%0h Data=%h WE=%b", dut.I_MEM.debug_addr, dut.I_MEM.debug_data, dut.I_MEM.debug_we);
        end
    end
endmodule
