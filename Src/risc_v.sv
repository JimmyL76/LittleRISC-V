`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/15/2025 08:50:38 AM
// Design Name: 
// Module Name: risc_v
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

`define CONTROL_STORE_SIZE 20

module risc_v(
    input logic CLK, RST, Pause, Init,
    input logic [31:0] InitPC, init_data,
    output logic I_CS, D_CS,
    output logic [3:0] I_WE, D_WE,
    output logic [31:0] I_ADDR, D_ADDR,
    inout [31:0] I_Mem_Bus, D_Mem_Bus,
    output logic [7:0] led
    );
    
    typedef enum logic [6:0] {
        R = 7'b0110011,
        I_AR = 7'b0010011,
        I_LD = 7'b0000011,
        S = 7'b0100011,
        B = 7'b1100011,
        J_JAL = 7'b1101111,
        I_JALR = 7'b1100111,
        U_LUI = 7'b0110111,
        U_AUIPC = 7'b0010111
    } opcode_e;

    // define control store for each stage
    typedef struct packed {
        logic LdReg;
        logic [1:0] IsBR_J;
        logic DMemEN;
    } w_store_t;
    
    typedef struct packed {
        logic [1:0] DataSize;
        logic DMemR_W;
        logic Usign;
        w_store_t w_store;
    } m_store_t;
    
    typedef struct packed {
        logic RS1Mux;
        logic [1:0] BR;
        logic EXdone;
        logic [3:0] ALUK;
        logic RS2Mux;
        // logic [2:0] ImmLogic;
        // logic RS1need;
        // logic RS2need;
        m_store_t m_store;
    } e_store_t;
            
//    /* create struct for parts of instr that need to be passed
//    to subsequent stages */
//    typedef struct packed {
//        opcode_e opcode; 
//        logic [2:0] funct3;
//        logic [6:0] funct7;
//    } instr_t;
    
    // define each pipeline stage's registers
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] instr;
//        instr_t decoded_instr;
        logic load;
        logic valid;
    } decode_t;
    
    typedef struct packed {
        e_store_t contr;
        logic [31:0] pc;
        logic [31:0] imm;
        logic [31:0] rs1;
        logic [31:0] rs2;
        logic [4:0] rdid;
        logic load;
        logic valid;
    } execute_t;
    
    typedef struct packed {
        m_store_t contr;
        logic [31:0] npc;
        logic [31:0] alu;
        logic [31:0] rs2;
        logic [4:0] rdid;
//        logic load;
        logic valid;
    } memory_t;
    
    typedef struct packed {
        w_store_t contr;
        logic [31:0] data;
        logic [31:0] npc;
        logic [31:0] alu;
        logic [4:0] rdid;
//        logic load;
        logic valid;
    } writeback_t;
    
    decode_t decode;
    execute_t execute;
    memory_t memory;
    writeback_t writeback;
    
    // module REG(CLK, LdR, RD, RS1, RS2, DataR, ReadReg1, ReadReg2);
    logic LdR_W;
    logic [31:0] DataR_W; 
    logic [31:0] ReadReg1, ReadReg2; 
    // dependency
    logic LdPC, Ld_D, V_D, Ld_E, V_E, V_M, V_W, DF1, DF2;
    logic [31:0] DF1_data, DF2_data, TargetPC_E;
    // for reg
    logic [4:0] RS1, RS2; assign RS1 = decode.instr[19:15], RS2 = decode.instr[24:20];
    logic [4:0] RD; assign RD = decode.instr[11:7];
    REG registers(CLK, LdR_W, writeback.rdid, RS1, RS2, DataR_W, 
                                                ReadReg1, ReadReg2);
                                              
    logic [31:0] store_result;
    logic [31:0] PC;
//    logic I_MemEN_result; // initialization?
    logic D_MemEN_result;
    assign IMemR_W = Init; // 0 = R, 1 = W
    assign I_CS = 1; assign D_CS = D_MemEN_result; 
    assign I_WE = (IMemR_W) ? 4'b1111 : 4'b0000; //drive memory bus only during writes
    assign I_Mem_Bus = (IMemR_W) ? init_data : 32'bZ; // InitPC comes from UART controller
    assign D_Mem_Bus = (memory.contr.DMemR_W)? store_result : 32'bZ;
    assign I_ADDR = (IMemR_W) ? InitPC[31:2] : PC[31:2]; 
    assign D_ADDR = memory.alu[31:2];
//    Memory I_MEM(I_CS, I_WE, CLK, I_ADDR, I_Mem_Bus);
//    Memory D_MEM(D_CS, D_WE, CLK, D_ADDR, D_Mem_Bus);
    
    // DECODE LOGIC
    // control signals
    opcode_e opcode; assign opcode = opcode_e'(decode.instr[6:0]);
    logic [2:0] funct3; assign funct3 = decode.instr[14:12];
    logic [6:0] funct7; assign funct7 = decode.instr[31:25];
    
//            R = 7'b0110011,
//        I_AR = 7'b0010011,
//        I_LD = 7'b0000011,
//        S = 7'b0100011,
//        B = 7'b1100011,
//        J_JAL = 7'b1101111,
//        I_JALR = 7'b1100111,
//        U_LUI = 7'b0110111,
//        U_AUIPC = 7'b0010111
    
    // ld a reg if not store or BR instr
    wire LdReg = (opcode != S) && (opcode != B); 
    // only for ld/st, use funct3, 0=word 1=half 2=byte    
    wire [1:0] DataSize = 
//                ((opcode != I_LD) && (opcode != S)) ? 2'bx :
                ((funct3 == 1) || (funct3 == 5)) ? 1 : // halfword
                (funct3 == 2) ? 0 : // word
                2; // byte
    wire DMemR_W = (opcode == S); // only 1 (write) if store
    wire RS1Mux = (opcode == B) || (opcode == J_JAL)
                || (opcode == U_AUIPC); // 1 if using PC in ALU
    // 0 = no BR nor J, 1 = BR, 2 = J
    wire [1:0] IsBR_J = (opcode == B) ? 1 :
                    ((opcode == J_JAL) || (opcode == I_JALR)) ? 2 :
                    0;
    // 0 ==, 1 !=, 2 <, 3 >=
    wire [1:0] BR = (funct3 == 0) ? 0 :
                (funct3 == 1) ? 1 :
                ((funct3 == 4) || (funct3 == 6)) ? 2 :
                3;
    // 0 JAL, 1 JALR //    wire Jump = (opcode == I_JALR);
    // BR is don't care if IsBR_J is 0, Jump matters but will always be 0 if is BR;
    wire DMemEN = (opcode == S) || (opcode == I_LD);
    wire EXdone = !(opcode == I_LD); // 0 only if load
        // ld's must wait until value is fetched from D-MEM
        // every other instr gets rd or PC after execute
        
    // 0 add, 1 sub, 2 xor, 3 or, 4 and, 5 lshf R, 6 rshf R, 7 rshf R arith
    // 8 SLT (and U), 9 LUI, 10 AUIPC
    // U-type done with ImmLogic (lshf_12, add + lshf_12) 
    logic [3:0] ALUK;
    always_comb begin
        ALUK = 0; // default value
        if((opcode == R) || (opcode == I_AR)) begin
            case(funct3)
                0: if((opcode == R) && (funct7 == 7'h20)) ALUK = 1; // else=default
                1: ALUK = 5; // lshf
                2, 3: ALUK = 8; // SLT
                4: ALUK = 2; // xor
                5: begin // imm[5:11] is also funct7
                    if(funct7 == 7'h20) ALUK = 7;     
                    else ALUK = 6;    
                end
                6: ALUK = 3;
                7: ALUK = 4;    
                default: ALUK = 0;           
            endcase
        // for all other instr, using only add except lui (even AUIPC only adds)
        end else if(opcode == U_LUI) ALUK = 9;
//        else if(opcode == U_AUIPC) ALUK = 10;
    end
    
    wire RS2Mux = !(opcode == R); // all other instr use imm (1)
    wire Usign = ((opcode == R) || (opcode == I_AR)) ? (funct3 == 3) : // arith
            (opcode == I_LD) ? ((funct3 == 4) || (funct3 == 5)) : // ld's
            ((funct3 == 6) || (funct3 == 7)); // BR
            
    // these signals don't need to propagate beyond decode
    // 0 I-type, 1 S-type, 2 B-type, 3 U-type, 4 J-type
    wire [2:0] ImmLogic = ((opcode == I_AR) || (opcode == I_LD) || (opcode == I_JALR)) ? 0 :
                    (opcode == S) ? 1 :
                    (opcode == B) ? 2 :
                    ((opcode == U_LUI) || (opcode == U_AUIPC)) ? 3 :
                    4;
    // ImmLogic doesn't matter if opcode type is R
    wire RS1need = (!((opcode == J_JAL) || (opcode == U_LUI) 
                || (opcode == U_AUIPC))) && decode.valid; // all other instr need rs1
    wire RS2need = ((opcode == R) || (opcode == S) || (opcode == B)) && decode.valid; // needs rs2
    
    // if instr is all 0s, end execution after instrs in pipeline are done
    wire Finish = !decode.instr && decode.valid;
   
    // Imm Logic block
    logic [31:0] IMM;
    always_comb begin
        case (ImmLogic)
            0: IMM = {{21{decode.instr[31]}}, decode.instr[30:25],
                decode.instr[24:20]};
            1: IMM = {{21{decode.instr[31]}}, decode.instr[30:25],
                decode.instr[11:8], decode.instr[7]};
            2: IMM = {{20{decode.instr[31]}}, decode.instr[7],
                decode.instr[30:25], decode.instr[11:8], 1'b0};
            3: IMM = {decode.instr[31:12], 12'b0};
            4: IMM = {{12{decode.instr[31]}}, decode.instr[19:12],
                decode.instr[20], decode.instr[30:21], 1'b0};
            default: IMM = 32'bx; // def case, don't care
        endcase
    end
    
    // EXECUTE LOGIC
    // br logic
    logic PCMux_E;
    always_comb begin
        if ((!execute.valid) || (execute.contr.m_store.w_store.IsBR_J == 0)) PCMux_E = 0;
        else if(execute.contr.m_store.w_store.IsBR_J == 2) PCMux_E = 1;
        else begin
            case(execute.contr.BR) 
                0: PCMux_E = ($signed(execute.rs1) == $signed(execute.rs2));
                1: PCMux_E = ($signed(execute.rs1) != $signed(execute.rs2));
                2: begin
                    if(execute.contr.m_store.Usign) PCMux_E = ((execute.rs1) < (execute.rs2));
                    else PCMux_E = ($signed(execute.rs1) < $signed(execute.rs2));
                end
                3: begin
                    if(execute.contr.m_store.Usign) PCMux_E = ((execute.rs1) >= (execute.rs2));
                    else PCMux_E = ($signed(execute.rs1) >= $signed(execute.rs2));
                end
                default: PCMux_E = 1'bx;
            endcase
        end
    end    
    
    // ALU logic
    wire [31:0] alu_rs1 = (execute.contr.RS1Mux) ? execute.pc : execute.rs1;
    wire [31:0] alu_rs2 = (execute.contr.RS2Mux) ? execute.imm : execute.rs2; 
    logic [31:0] alu_result;
    always_comb begin
        case(execute.contr.ALUK)
            0: alu_result = alu_rs1 + alu_rs2;
            1: alu_result = alu_rs1 - alu_rs2;
            2: alu_result = alu_rs1 ^ alu_rs2;
            3: alu_result = alu_rs1 | alu_rs2;
            4: alu_result = alu_rs1 & alu_rs2;
            5: alu_result = alu_rs1 << alu_rs2[4:0];
            6: alu_result = alu_rs1 >> alu_rs2[4:0];
            7: alu_result = $signed(alu_rs1) >>> alu_rs2[4:0];
            8: begin
                if(execute.contr.m_store.Usign) alu_result = (alu_rs1 < alu_rs2) ? 1 : 0;
                else alu_result = ($signed(alu_rs1) < $signed(alu_rs2)) ? 1 : 0;
            end
            9: alu_result = alu_rs2;
//            10: alu_result = alu_rs1 + (alu_rs2 << 12);
            default: alu_result = 32'bx;
        endcase
    end
    
    wire [31:0] nextpc = execute.pc + 4;
    
    // MEMORY LOGIC
    // load & store + WE logic
    logic [31:0] load_result;
    logic [3:0] WE_result;
    always_comb begin
        case(memory.contr.DataSize) 
            0: begin 
                store_result = memory.rs2; 
                load_result = D_Mem_Bus; WE_result = 4'b1111;
            end
            1: begin
                store_result = {2{memory.rs2[15:0]}};
                if(memory.contr.Usign) 
                    case(memory.alu[1:0]) // assume no unaligned
                        0: begin
                        load_result = D_Mem_Bus[15:0];
                        WE_result = 4'b0011;
                        end
                        2: begin
                        load_result = D_Mem_Bus[31:16];
                        WE_result = 4'b1100;
                        end
                        default: begin load_result = 32'bx; WE_result = 4'bx; end
                    endcase
                else 
                    case(memory.alu[1:0]) 
                        0: begin
                        load_result = {{16{D_Mem_Bus[15]}}, D_Mem_Bus[15:0]};
                        WE_result = 4'b0011;
                        end
                        2: begin 
                        load_result = {{16{D_Mem_Bus[31]}}, D_Mem_Bus[31:16]};
                        WE_result = 4'b1100;
                        end
                        default: begin load_result = 32'bx; WE_result = 4'bx; end
                    endcase
            end
            2: begin
                store_result = {4{memory.rs2[7:0]}};
                if(memory.contr.Usign) 
                    case(memory.alu[1:0]) 
                        0: begin load_result = D_Mem_Bus[7:0]; WE_result = 4'b0001; end
                        1: begin load_result = D_Mem_Bus[15:8]; WE_result = 4'b0010; end
                        2: begin load_result = D_Mem_Bus[23:16]; WE_result = 4'b0100; end
                        3: begin load_result = D_Mem_Bus[31:24]; WE_result = 4'b1000; end
                    endcase
                else 
                    case(memory.alu[1:0]) 
                        0: begin load_result = {{24{D_Mem_Bus[7]}}, D_Mem_Bus[7:0]}; WE_result = 4'b0001; end
                        1: begin load_result = {{24{D_Mem_Bus[15]}}, D_Mem_Bus[15:8]}; WE_result = 4'b0010; end
                        2: begin load_result = {{24{D_Mem_Bus[23]}}, D_Mem_Bus[23:16]}; WE_result = 4'b0100; end
                        3: begin load_result = {{24{D_Mem_Bus[31]}}, D_Mem_Bus[31:24]}; WE_result = 4'b1000; end
                    endcase
            end 
            default: begin store_result = 32'bx; load_result = 32'bx; WE_result = 4'bx; end
        endcase
            if(!memory.contr.DMemR_W) 
                WE_result = 4'b0000; // if not store, WE is always 0
            else
                $display("Storing value");
    end
    assign D_WE = WE_result;
    // mem_enable
    assign D_MemEN_result = memory.contr.w_store.DMemEN && memory.valid;
    
    // WRITEBACK LOGIC
    assign LdR_W = writeback.contr.LdReg && writeback.valid;
    wire [31:0] DataR_W_mux1 = (writeback.contr.DMemEN) ? writeback.data : writeback.alu;
    assign DataR_W = (writeback.contr.IsBR_J == 2) ? writeback.npc : DataR_W_mux1;
    
    // FETCH LOGIC
    logic [31:0] next_pc;
    always_comb begin
        next_pc = (PCMux_E) ? TargetPC_E : PC + 4;
    end
    
    // dependency logic
    // if RS2need but also opcode == S, can jump to mem if only waiting on rs2
    // and mux to RS2.M
    //    logic LdPC, Ld_D, V_D, Ld_E, V_E, V_M, V_W, DF1, DF2;
    //    logic [31:0] DF1_data, DF2_data, TargetPC_E;
    logic stall;
    wire e1_match = (RS1 == execute.rdid) && execute.valid;
    wire m1_match = (RS1 == memory.rdid) && memory.valid;
    wire w1_match = (RS1 == writeback.rdid) && writeback.valid;
    wire e2_match = (RS2 == execute.rdid) && execute.valid;
    wire m2_match = (RS2 == memory.rdid) && memory.valid;
    wire w2_match = (RS2 == writeback.rdid) && writeback.valid;
    always_comb begin
        LdPC = 1; Ld_D = 1; V_D = 1; Ld_E = 1; V_E = 1; V_M = 1; V_W = 1;
        TargetPC_E = 32'bx; 
        DF1 = 0; DF2 = 0; stall = 0; DF1_data = 32'bx; DF2_data = 32'bx;
        
        // data dependency
        if(RS1need) begin
//            if((!e1_match) || (!m1_match) || (!w1_match))
//                stall = 0;
//            else 
            if((e1_match) && (!execute.contr.EXdone))
                stall = 1; // stall if waiting for load
            else begin
                DF1 = 1;
                casez({e1_match, m1_match, w1_match}) 
                // jump and load are the only rd values not on alu
                    3'b1??: DF1_data = (execute.contr.m_store.w_store.IsBR_J == 2) ? nextpc : alu_result;
                    3'b01?: DF1_data = (memory.contr.w_store.IsBR_J == 2) ? memory.npc : 
                                        (memory.contr.w_store.DMemEN) ? load_result : memory.alu;
                    3'b001: DF1_data = (writeback.contr.IsBR_J == 2) ? writeback.npc : 
                                        (writeback.contr.DMemEN) ? writeback.data : memory.alu;
                    3'b000: DF1 = 0;
                endcase 
            end 
        end if(RS2need) begin
            if((e2_match) && (!execute.contr.EXdone))
                stall = 1; // stall if waiting for load
            else begin
                DF2 = 1;
                casez({e2_match, m2_match, w2_match}) 
                    3'b1??: DF2_data = (execute.contr.m_store.w_store.IsBR_J == 2) ? nextpc : alu_result;
                    3'b01?: DF2_data = (memory.contr.w_store.IsBR_J == 2) ? memory.npc : 
                                        (memory.contr.w_store.DMemEN) ? load_result : memory.alu;
                    3'b001: DF2_data = (writeback.contr.IsBR_J == 2) ? writeback.npc : 
                                        (writeback.contr.DMemEN) ? writeback.data : memory.alu;
                    3'b000: DF2 = 0;
                endcase 
            end         
        end 
        
        // control dependency 
        // not taken was wrong, flush pipeline
        if(PCMux_E) begin
//            LdPC = 0; 
            TargetPC_E = alu_result; V_D = 0; V_E = 0;
            $display("Jumping from %h to %h", execute.pc, TargetPC_E);
        end
            
        // stall logic
        if(stall) begin
            LdPC = 0; Ld_D = 0; V_E = 0;
        end
        
        // on finish, set that stage as invalid so reg/mem isn't affected
        if(Finish) begin
            V_E = 0;
        end
                
    end

    // end when writeback instr is all 0s
    logic [1:0] Finish_Ctr;
    always_ff @(posedge CLK) begin
        // if last instr is a taken loop back, make sure to reset to 0 on !Finish
        if(RST || !Finish) Finish_Ctr = 0;
        else if(Finish_Ctr != 3) Finish_Ctr += 1;
    end

    always_ff @(posedge CLK) begin
        if(RST) begin
            PC <= 0;
            
            decode.load <= 1;
            
            decode.valid <= 0;
            execute.valid <= 0;
            memory.valid <= 0;
            writeback.valid <= 0;
        end else if(!Pause && (Finish_Ctr != 3)) begin
            decode.load <= Ld_D;
            decode.valid <= V_D;
            // if d.valid is 0, e.valid is always 0, otherwise V_E will always be right
            execute.valid <= (!decode.valid) ? 1'b0 : V_E;
            memory.valid <= execute.valid;
            writeback.valid <= memory.valid;
        
            if(decode.load) begin
                decode.pc <= PC;
                decode.instr <= I_Mem_Bus;
            end
            
//            if(execute.load) begin
            execute.contr.m_store.w_store.LdReg <= LdReg;
            execute.contr.m_store.w_store.IsBR_J <= IsBR_J;
            execute.contr.m_store.DataSize <= DataSize;
            execute.contr.m_store.DMemR_W <= DMemR_W;
            execute.contr.RS1Mux <= RS1Mux;
            execute.contr.BR <= BR;
            execute.contr.m_store.w_store.DMemEN <= DMemEN;
            execute.contr.EXdone <= EXdone;
            execute.contr.ALUK <= ALUK;
            execute.contr.RS2Mux <= RS2Mux;
            execute.contr.m_store.Usign <= Usign;
            execute.pc <= decode.pc;
            execute.imm <= IMM;
            execute.rs1 <= (DF1) ? (DF1_data) : ReadReg1;
            execute.rs2 <= (DF2) ? (DF2_data) : ReadReg2;
            execute.rdid <= RD;
//            end
                
            memory.contr <= execute.contr.m_store;
            memory.npc <= nextpc;
            memory.alu <= alu_result;
            memory.rs2 <= execute.rs2;
            memory.rdid <= execute.rdid;
                
            writeback.contr <= memory.contr.w_store;
            writeback.data <= load_result;
            writeback.npc <= memory.npc;
            writeback.alu <= memory.alu;
            writeback.rdid <= memory.rdid;
                
            if(LdPC) PC <= next_pc;
        end
    end
    
    
endmodule
