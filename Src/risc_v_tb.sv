`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2025 03:02:30 PM
// Design Name: 
// Module Name: risc_v_tb
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


module risc_v_tb();

    // inputs
    logic CLK, btnL, btnR, btnU, btnD, sw;
    // U = step forward, L = show upper led bits, R = show upper disp bits
    // reset switch tied to RST
    
    // outputs
    logic [15:0] led; // taps alu.rs1
    logic [6:0] seg; // displays REG[1]
    logic [3:0] an;
    
    complete_risc_v r(.*);
    
    // reg dump
    logic [6:0] cycle_count;
    
    initial begin
        CLK <= 0;
        // Init <= 0;
        // RST <= 1;
        // Pause <= 0;
        btnL <= 0; btnR <= 0; btnU <= 0; btnD <= 0;
        sw <= 1;
        cycle_count <= 0;
        forever #5 CLK <= ~CLK;
    end
    
    initial begin
        #50;
        // RST = 0;
        sw <= 0;
        #20 btnU <= 1;
        #20 btnU <= 0;
        #20 btnU <= 1;
        #20 btnU <= 0;
    end
    
    

    always @(posedge CLK) begin
        $display("F.PC = %d or 0x%h", r.CPU.PC, r.CPU.PC);
        
        $display("D.pc = %h", r.CPU.decode.pc);
        $display("D.instr = %h", r.CPU.decode.instr);
        if (r.CPU.RS2Mux)
            $display("D.decoded_instr: %s R%0d, R%0d, #%0d", r.CPU.opcode.name, r.CPU.RD, r.CPU.RS1, $signed(r.CPU.IMM));
        else 
            $display("D.decoded_instr: %s R%0d, R%0d, R%0d", r.CPU.opcode.name, r.CPU.RD, r.CPU.RS1, r.CPU.RS2);        
        $display("D.load = %h", r.CPU.decode.load);
        $display("D.valid = %h", r.CPU.decode.valid);
//typedef struct packed {
//        logic [31:0] pc;
//        logic [31:0] instr;
////        instr_t decoded_instr;
//        logic load;
//        logic valid;
//    } decode_t;
    
        $display("E.control: %p", r.CPU.execute.contr);
        $display("E.pc = %h", r.CPU.execute.pc);
        $display("E.imm = %h", r.CPU.execute.imm);
        $display("E.rs1 = %h", r.CPU.execute.rs1);
        $display("E.rs2 = %h", r.CPU.execute.rs2);
        $display("E.rdid = %d", r.CPU.execute.rdid);
        // $display("E.load = %h", r.CPU.execute.load);
        $display("E.valid = %h", r.CPU.execute.valid);
        //    typedef struct packed {
//        e_store_t contr;
//        logic [31:0] pc;
//        logic [31:0] imm;
//        logic [31:0] rs1;
//        logic [31:0] rs2;
//        logic [4:0] rdid;
//        logic load;
//        logic valid;
//    } execute_t;

        $display("M.control: %p", r.CPU.memory.contr);
        $display("M.npc = %h", r.CPU.memory.npc);
        $display("M.alu = %h", r.CPU.memory.alu);
        $display("M.rs2 = %h", r.CPU.memory.rs2);
        $display("M.rdid = %d", r.CPU.memory.rdid);
        $display("M.valid = %h", r.CPU.memory.valid);
//    typedef struct packed {
//        m_store_t contr;
//        logic [31:0] npc;
//        logic [31:0] alu;
//        logic [31:0] rs2;
//        logic [4:0] rdid;
////        logic load;
//        logic valid;
//    } memory_t;
    
        $display("W.control: %p", r.CPU.writeback.contr);
        $display("W.data = %h", r.CPU.writeback.data);
        $display("W.npc = %h", r.CPU.writeback.npc);
        $display("W.alu = %h", r.CPU.writeback.alu);
        $display("W.rdid = %d", r.CPU.writeback.rdid);
        $display("W.valid = %h", r.CPU.writeback.valid);    
//    typedef struct packed {
//        w_store_t contr;
//        logic [31:0] data;
//        logic [31:0] npc;
//        logic [31:0] alu;
//        logic [4:0] rdid;
////        logic load;
//        logic valid;
//    } writeback_t;
        
        for(integer j = 0; j<10; j=j+1)
            $display("REG[%0d] = %h", j, r.CPU.registers.REG[j]);//rdump
        for(integer j = 0; j<10; j=j+1)    
            $display("D_MEM[%0d] = %h", j, r.D_MEM.RAM[j]); //mdump
        $display("Cycle Count = %d", cycle_count);
        cycle_count <= cycle_count + 1;
//        $stop; // check waveform
//        if (cycle_count == 21) begin
//            $display("Jumped to cycle %d", cycle_count);
//        end
        if (r.CPU.Finish_Ctr == 3) begin // stop when final instr is done
            for(integer j = 0; j<(2**6); j=j+1)
                $display("D_MEM[%0d] = %h", j, r.D_MEM.RAM[j]); //mdump
            $display("TEST COMPLETE");
            $stop;
        end       
    end 
    
endmodule
