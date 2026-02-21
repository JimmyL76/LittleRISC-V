`timescale 1ns / 1ps

module mmio_tb();

    logic CLK;
    logic btnL, btnR, btnU, btnD;
    logic [2:0] sw;
    logic rx_external, tx_external;
    logic [15:0] led;
    logic [6:0] sseg;
    logic [3:0] an;
    complete_risc_v r(.*);

    logic [31:0] cycle_count;
    logic [31:0] last_pc;
    integer stall_counter;
    logic CPU_CLK;
    
    localparam MAX_CYCLES = 5000;       
    localparam DEBUG_ALL_CYCLES = 1; 

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    initial begin
        CPU_CLK = 1;
        forever #10 CPU_CLK = ~CPU_CLK;
    end

    initial begin
        btnL = 0; btnR = 0; btnU = 0; btnD = 0;
        sw = 3'b011; 
        rx_external = 1; 
        cycle_count = 0;
        stall_counter = 0;

        #50;
        $display("--- RESET RELEASED ---");
        sw = 3'b010; 
    end

    // watchdog and ctr
    always @(posedge CPU_CLK) begin
        cycle_count <= cycle_count + 1;
        
        if (cycle_count > MAX_CYCLES) begin
            $display("--- TIMEOUT: Max Cycles Reached ---");
            $finish;
        end
    end

    always @(negedge CPU_CLK) begin
        // check for stalls
        if (r.CPU.PC == last_pc) begin
            stall_counter <= stall_counter + 1;
        end else begin
            stall_counter <= 0;
            last_pc <= r.CPU.PC;
        end

        if (r.MMIO_ctrl.mem_we || (stall_counter > 5) || DEBUG_ALL_CYCLES) begin
            print_pipeline_state();
        end

        if (stall_counter > 20) begin
            $display("--- ERROR: CPU Pipeline Stuck at PC %h for 20+ cycles ---", r.CPU.PC);
            print_pipeline_state();
            $finish;
        end
    end

    task print_pipeline_state;
        begin
            $display("----------------------------------------------------------------");
            $display("Time=%0t | Cycle=%0d | Stall=%0d", $time, cycle_count, stall_counter);
            
            // mmio check
            if (r.MMIO_ctrl.mem_we && (r.MMIO_ctrl.mem_addr >= 32'h0000_8000))
                $display(" >> MMIO WRITE: Addr=%0h Data=%0h", r.MMIO_ctrl.mem_addr, r.MMIO_ctrl.mem_wdata);

            $display(" [F] PC:%0h / word %0d", r.CPU.PC, r.CPU.PC >> 2);
            // $display(" >> I_MEM ADDR:%h or word %0d or real %0d", r.I_MEM.ADDR, r.I_MEM.ADDR >> 2, r.I_MEM.ADDR[13:2]);

            $display(" [D] Instr:%s or %0h | Valid:%b | Load:%b", get_asm(r.CPU.decode.instr), r.CPU.decode.instr, r.CPU.decode.valid, r.CPU.Ld_D);

            $display(" [E] PC:%0h | Valid:%b | ALU_Res:%0h | PCMux_E:%b | RDID:%0d", r.CPU.execute.pc, r.CPU.execute.valid, r.CPU.alu_result, r.CPU.PCMux_E, r.CPU.execute.rdid); 
            if (r.CPU.PCMux_E === 1'bx) print_PCMux_E_logic();

            $display(" [M] NPC:%0h | Valid:%b | DMemEN:%b | DMemR_W:%b | Store_result:%0d | Load_result:%0d | RDID:%0d", r.CPU.memory.npc, r.CPU.memory.valid, r.CPU.memory.contr.w_store.DMemEN, r.CPU.memory.contr.DMemR_W, r.CPU.store_result, r.CPU.load_result, r.CPU.memory.rdid);

            $display(" [W] NPC:%0h | Valid:%b | LdR_W:%b | WriteReg:%d | WriteData:%0h", r.CPU.writeback.npc, r.CPU.writeback.valid, r.CPU.LdR_W, r.CPU.writeback.rdid, r.CPU.DataR_W);
            
            // reg or mem dump
            // $display("Reg[10]=%h  Reg[15]=%h", r.CPU.registers.REG[10], r.CPU.registers.REG[15]);
            // $display("MMIO LED=%h", r.MMIO_ctrl.led_reg); 
            $display("MMIO 7SEG=%h", r.MMIO_ctrl.sseg_reg); 
        end
    endtask

    // save prev cycle info to see how PCMux_E got to 1'bx
    logic DF1_ff;
    logic [31:0] DF1_data_ff, ReadReg1_ff;
    logic e1_match_ff, m1_match_ff, w1_match_ff;
    logic [1:0] IsBR_J_ff;
    logic DMemEN_ff;
    logic [31:0] memory_npc_ff, load_result_ff, memory_alu_ff;
    always @(negedge CPU_CLK) begin
        DF1_ff <= r.CPU.DF1;
        DF1_data_ff <= r.CPU.DF1_data;
        ReadReg1_ff <= r.CPU.ReadReg1;
        e1_match_ff <= r.CPU.e1_match;
        m1_match_ff <= r.CPU.m1_match;
        w1_match_ff <= r.CPU.w1_match;
        IsBR_J_ff <= r.CPU.memory.contr.w_store.IsBR_J;
        memory_npc_ff <= r.CPU.memory.npc;
        DMemEN_ff <= r.CPU.memory.contr.w_store.DMemEN;
        load_result_ff <= r.CPU.load_result;
        memory_alu_ff <= r.CPU.memory.alu;
    end
    task print_PCMux_E_logic;
        begin
            $display(" [E] PCMux_E:%b | execute.rs1:%0d | execute.rs2:%0d", r.CPU.PCMux_E, r.CPU.execute.rs1, r.CPU.execute.rs2);
            // execute.rs1 <= (DF1) ? (DF1_data) : ReadReg1;
            $display(" [E] Prev Cycle: DF1=%b | DF1_data=%0d | execute.rs1=%0d", DF1_ff, DF1_data_ff, ReadReg1_ff);
                // casez({e1_match, m1_match, w1_match}) 
                // // jump and load are the only rd values not on alu
                //     3'b1??: DF1_data = (execute.contr.m_store.w_store.IsBR_J == 2) ? nextpc : alu_result;
                //     3'b01?: DF1_data = (memory.contr.w_store.IsBR_J == 2) ? memory.npc : 
                //                         (memory.contr.w_store.DMemEN) ? load_result : memory.alu;
                //     3'b001: DF1_data = (writeback.contr.IsBR_J == 2) ? writeback.npc : 
                //                         (writeback.contr.DMemEN) ? writeback.data : writeback.alu;
                //     3'b000: DF1 = 0;
                // endcase 
            if ($isunknown(DF1_data_ff)) $display(" [E] DF1_data unknown down memory path due to e1_match_ff=%b, m1_match_ff=%b, w1_match_ff=%b, IsBR_J_ff=%b, memory_npc_ff=%0h, DMemEN_ff=%b, load_result_ff=%0h, memory_alu_ff=%0d", e1_match_ff, m1_match_ff, w1_match_ff, IsBR_J_ff, memory_npc_ff, DMemEN_ff, load_result_ff, memory_alu_ff);

            // logic cpu_in_range; assign cpu_in_range = (instr) ? (ADDR[15:14] == 2'b00) : (ADDR[15:14] == 2'b01); // cpu views data and instr mem at x0000-x7FFF, MMIO begins at x8000
            // assign Mem_Bus = ( !((CS == 1'b0) || WE) && cpu_in_range) ? data_out : 32'bZ; // only drive a read when in range to not affect MMIO reads
            // if ($isunknown(alu_result_ff)) $display()
        end
    endtask

    // interpret assembly from instr
    function string get_asm(logic [31:0] instr);
        logic [6:0] opcode;
        logic [2:0] funct3;
        logic [6:0] funct7;
        logic [4:0] rd, rs1, rs2;
        logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;
        string mnemonic;
        
        opcode = instr[6:0];
        rd     = instr[11:7];
        funct3 = instr[14:12];
        rs1    = instr[19:15];
        rs2    = instr[24:20];
        funct7 = instr[31:25];

        // imm SEXT
        imm_i = {{20{instr[31]}}, instr[31:20]};
        imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
        imm_u = {instr[31:12], 12'b0};
        imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

        case (opcode)
            // --- R-Type (0110011) ---
            7'b0110011: begin
                case (funct3)
                    3'b000: mnemonic = (funct7[5]) ? "sub" : "add";
                    3'b001: mnemonic = "sll";
                    3'b010: mnemonic = "slt";
                    3'b011: mnemonic = "sltu";
                    3'b100: mnemonic = "xor";
                    3'b101: mnemonic = (funct7[5]) ? "sra" : "srl";
                    3'b110: mnemonic = "or";
                    3'b111: mnemonic = "and";
                    default: mnemonic = "R-UNKNOWN";
                endcase
                return $sformatf("%s x%0d, x%0d, x%0d", mnemonic, rd, rs1, rs2);
            end

            // --- I-Type (0010011) ---
            7'b0010011: begin
                case (funct3)
                    3'b000: mnemonic = "addi";
                    3'b010: mnemonic = "slti";
                    3'b011: mnemonic = "sltiu";
                    3'b100: mnemonic = "xori";
                    3'b110: mnemonic = "ori";
                    3'b111: mnemonic = "andi";
                    3'b001: begin mnemonic = "slli"; imm_i = {27'b0, instr[24:20]}; end
                    3'b101: begin mnemonic = (funct7[5]) ? "srai" : "srli"; imm_i = {27'b0, instr[24:20]}; end
                    default: mnemonic = "I-ALU-UNKNOWN";
                endcase
                return $sformatf("%s x%0d, x%0d, %0d", mnemonic, rd, rs1, $signed(imm_i));
            end

            // --- Load (0000011) ---
            7'b0000011: begin
                case (funct3)
                    3'b000: mnemonic = "lb";
                    3'b001: mnemonic = "lh";
                    3'b010: mnemonic = "lw";
                    3'b100: mnemonic = "lbu";
                    3'b101: mnemonic = "lhu";
                    default: mnemonic = "LOAD-UNKNOWN";
                endcase
                // lw rd, offset(rs1)
                return $sformatf("%s x%0d, %0d(x%0d)", mnemonic, rd, $signed(imm_i), rs1);
            end

            // --- Store (0100011) ---
            7'b0100011: begin
                case (funct3)
                    3'b000: mnemonic = "sb";
                    3'b001: mnemonic = "sh";
                    3'b010: mnemonic = "sw";
                    default: mnemonic = "STORE-UNKNOWN";
                endcase
                // sw rs2, imm(rs1)
                return $sformatf("%s x%0d, %0d(x%0d)", mnemonic, rs2, $signed(imm_s), rs1);
            end

            // --- Branch (1100011) ---
            7'b1100011: begin
                case (funct3)
                    3'b000: mnemonic = "beq";
                    3'b001: mnemonic = "bne";
                    3'b100: mnemonic = "blt";
                    3'b101: mnemonic = "bge";
                    3'b110: mnemonic = "bltu";
                    3'b111: mnemonic = "bgeu";
                    default: mnemonic = "BRANCH-UNKNOWN";
                endcase
                return $sformatf("%s x%0d, x%0d, %0d", mnemonic, rs1, rs2, $signed(imm_b));
            end

            // --- U-Type (LUI 0110111, AUIPC 0010111) ---
            7'b0110111: return $sformatf("lui x%0d, 0x%0h", rd, imm_u[31:12]);  
            7'b0010111: return $sformatf("auipc x%0d, 0x%0h", rd, imm_u[31:12]);

            // --- J-Type (JAL 1101111) ---
            7'b1101111: return $sformatf("jal x%0d, %0d", rd, $signed(imm_j));

            // --- JALR (1100111) ---
            7'b1100111: return $sformatf("jalr x%0d, x%0d, %0d", rd, rs1, $signed(imm_i));

            default: return $sformatf("UNKNOWN OP: %b", opcode);
        endcase
    endfunction

endmodule