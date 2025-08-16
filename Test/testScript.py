#!/usr/bin/env python3

"""
risc-v test generator for FPGA SysVerilog .mem files
"""

def add_instr(rd, rs1, rs2):
    return (rs2 << 20) | (rs1 << 15) | (rd << 7) | 0x33

def addi_instr(rd, rs1, imm):
    imm = imm & 0xfff # otherwise would have to assume all imm's are legal values
    return (imm << 20) | (rs1 << 15) | (rd << 7) | 0x13

def sub_instr(rd, rs1, rs2):
    return (0x20 << 25) | (rs2 << 20) | (rs1 << 15) | (rd << 7) | 0x33 

def xor_instr(rd, rs1, rs2):
    return (rs2 << 20) | (rs1 << 15) | (4 << 12) | (rd << 7) | 0x33

def xori_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (4 << 12) | (rd << 7) | 0x13

def or_instr(rd, rs1, rs2):
    return (rs2 << 20) | (rs1 << 15) | (6 << 12) | (rd << 7) | 0x33

def ori_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (6 << 12) | (rd << 7) | 0x13

def and_instr(rd, rs1, rs2):
    return (rs2 << 20) | (rs1 << 15) | (7 << 12) | (rd << 7) | 0x33

def andi_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (7 << 12) | (rd << 7) | 0x13

def sll_instr(rd, rs1, rs2): 
    return (rs2 << 20) | (rs1 << 15) | (1 << 12) | (rd << 7) | 0x33

def slli_instr(rd, rs1, imm): 
    imm = imm & 0x1f
    return (imm << 20) | (rs1 << 15) | (1 << 12) | (rd << 7) | 0x13

def srl_instr(rd, rs1, rs2): 
    return (rs2 << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x33

def srli_instr(rd, rs1, imm): 
    imm = imm & 0x1f
    return (imm << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x13

def sra_instr(rd, rs1, rs2): 
    return (0x20 << 25) | (rs2 << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x33

def srai_instr(rd, rs1, imm): 
    imm = imm & 0x1f
    return (0x20 << 25) | (imm << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x13

def slt_instr(rd, rs1, rs2): 
    return (rs2 << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x33

def slti_instr(rd, rs1, imm): 
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x13

def sltu_instr(rd, rs1, rs2): 
    return (rs2 << 20) | (rs1 << 15) | (3 << 12) | (rd << 7) | 0x33

def sltiu_instr(rd, rs1, imm):
    imm = imm & 0xfff 
    return (imm << 20) | (rs1 << 15) | (3 << 12) | (rd << 7) | 0x13

def lb_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (rd << 7) | 0x03

def lh_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (1 << 12) | (rd << 7) | 0x03

def lw_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (2 << 12) | (rd << 7) | 0x03

def lbu_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (4 << 12) | (rd << 7) | 0x03

def lhu_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (5 << 12) | (rd << 7) | 0x03

def sb_instr(rs1, rs2, imm):
    imm = imm & 0xfff
    imm11_5 = (imm >> 5) & 0x7f
    imm4_0 = imm & 0x1f
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (imm4_0 << 7) | 0x23

def sh_instr(rs1, rs2, imm):
    imm = imm & 0xfff
    imm11_5 = (imm >> 5) & 0x7f
    imm4_0 = imm & 0x1f
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (1 << 12) | (imm4_0 << 7) | 0x23

def sw_instr(rs1, rs2, imm):
    imm11_5 = (imm >> 5) & 0x7f
    imm4_0 = imm & 0x1f
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (2 << 12) | (imm4_0 << 7) | 0x23

def beq_instr(rs1, rs2, imm):
    imm12, imm10_5 = (imm >> 12) & 0x1, (imm >> 5) & 0x3f 
    imm4_1, imm11 = (imm >> 1) & 0xf, (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (0 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63

def bne_instr(rs1, rs2, imm):
    imm12, imm10_5 = (imm >> 12) & 0x1, (imm >> 5) & 0x3f 
    imm4_1, imm11 = (imm >> 1) & 0xf, (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (1 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63

def blt_instr(rs1, rs2, imm):
    imm12, imm10_5 = (imm >> 12) & 0x1, (imm >> 5) & 0x3f 
    imm4_1, imm11 = (imm >> 1) & 0xf, (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (4 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63

def bge_instr(rs1, rs2, imm):
    imm12, imm10_5 = (imm >> 12) & 0x1, (imm >> 5) & 0x3f 
    imm4_1, imm11 = (imm >> 1) & 0xf, (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (5 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63

def bltu_instr(rs1, rs2, imm):
    imm12, imm10_5 = (imm >> 12) & 0x1, (imm >> 5) & 0x3f 
    imm4_1, imm11 = (imm >> 1) & 0xf, (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (6 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63

def bgeu_instr(rs1, rs2, imm):
    imm12, imm10_5 = (imm >> 12) & 0x1, (imm >> 5) & 0x3f 
    imm4_1, imm11 = (imm >> 1) & 0xf, (imm >> 11) & 0x1
    return (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (7 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63

def jal_instr(rd, imm):
    imm20, imm11 = (imm >> 20) & 0x1, (imm >> 11) & 0x1
    imm10_1, imm19_12 = (imm >> 1) & 0x3ff, (imm >> 12) & 0xff
    return (imm20 << 31) | (imm10_1 << (31-10)) | (imm11 << 20) | (imm19_12 << 12) | (rd << 7) | 0x6f

def jalr_instr(rd, rs1, imm):
    imm = imm & 0xfff
    return (imm << 20) | (rs1 << 15) | (0 << 12) | (rd << 7) | 0x67

def lui_instr(rd, imm):
    imm = (imm >> 12) & 0xfffff
    return (imm << 12) | (rd << 7) | 0x37

def auipc_instr(rd, imm):
    imm = (imm >> 12) & 0xfffff
    return (imm << 12) | (rd << 7) | 0x17

def nop_instr():
    """encoded as ADDI x0, x0, 0"""
    return 0x13

# use instructions to generate test programs
def generate_add_test():
    instructions = []

    instructions.append(addi_instr(1, 0, 1))
    instructions.append(addi_instr(2, 0, 2))
    instructions.append(add_instr(3, 1, 2))

    return instructions

def generate_logic_test():
    """no dependencies or mem access or control instr's"""
    instructions = []

    for i in range(1, 5):
        instructions.append(addi_instr(i,0,i)) # r1-3 = 1-4
    instructions.append(addi_instr(9,0,-1)) # r9 = -1
    instructions.append(addi_instr(8,0,-8)) # r8 = -8

    # reg-reg tests
    instructions.append(add_instr(5,1,2)) # r5 = 3
    instructions.append(sub_instr(5,1,2)) # r5 = -1
    instructions.append(xor_instr(5,1,2)) # r5 = 3
    instructions.append(or_instr(5,1,2)) # r5 = 3
    instructions.append(and_instr(5,1,2)) # r5 = 0
    instructions.append(sll_instr(5,1,2)) # r5 = 4
    instructions.append(srl_instr(5,1,2)) # r5 = 0
    instructions.append(sra_instr(5,1,2)) # r5 = 0
    instructions.append(sra_instr(5,9,2)) # r5 = xffffffff
    instructions.append(sra_instr(5,8,2)) # r5 = xfffffffe
    instructions.append(slt_instr(5,1,2)) # r5 = 1
    instructions.append(slt_instr(5,1,9)) # r5 = 0
    instructions.append(sltu_instr(5,1,2)) # r5 = 1
    instructions.append(sltu_instr(5,1,9)) # r5 = 1

    # reg-imm tests
    instructions.append(addi_instr(5,1,2)) # r5 = 3
    instructions.append(addi_instr(5,1,-1)) # r5 = 0
    instructions.append(addi_instr(5,1,-10)) # r5 = -9
    instructions.append(xori_instr(5,1,2)) # r5 = 3
    instructions.append(ori_instr(5,1,2)) # r5 = 3
    instructions.append(andi_instr(5,1,2)) # r5 = 0
    instructions.append(slli_instr(5,4,2)) # r5 = 16
    instructions.append(srli_instr(5,4,2)) # r5 = 1
    instructions.append(srai_instr(5,4,2)) # r5 = 1
    instructions.append(srai_instr(5,9,2)) # r5 = xffffffff
    instructions.append(srai_instr(5,8,2)) # r5 = xfffffffe
    instructions.append(slti_instr(5,1,2)) # r5 = 1
    instructions.append(slti_instr(5,1,-1)) # r5 = 0
    instructions.append(sltiu_instr(5,1,2)) # r5 = 1
    instructions.append(sltiu_instr(5,1,-1)) # r5 = 1

    # load upp imm tests
    instructions.append(lui_instr(5,5)) # r5 = 0
    instructions.append(lui_instr(5,0xf0f0f0f0)) # r5 = 0xf0f0f
    instructions.append(auipc_instr(5,5)) # r5 = pc+0
    instructions.append(auipc_instr(5,0xf0f0f0f0)) # r5 = pc+0xf0f0f 

    return instructions

def generate_mem_test():
    instructions = []

    instructions.append(addi_instr(1,0,4))
    instructions.append(addi_instr(2,0,0x12345678)) 
    instructions.append(lui_instr(4,0x12345678)) 
    instructions.append(add_instr(2,2,4)) # r2 = x12345678
    instructions.append(addi_instr(3,0,0x86548654)) 
    instructions.append(lui_instr(4,0x86548654)) 
    instructions.append(add_instr(3,3,4)) # r3 = 0x86548654


    instructions.append(sw_instr(0,2,0)) # M0 = x12345678
    instructions.append(sh_instr(0,2,4)) # M1 = x5678
    instructions.append(sh_instr(0,2,8+2)) # M2 = x56780000
    instructions.append(sb_instr(0,2,12)) # M3 = x78
    instructions.append(sb_instr(0,2,16+1)) # M4 = x7800
    instructions.append(sb_instr(0,2,20+2)) # M5 = x780000
    instructions.append(sb_instr(0,2,24+3)) 
    instructions.append(sb_instr(0,2,24+1)) # M6 = x78007800

    instructions.append(sw_instr(0,3,28)) # M7 = x86548654
    instructions.append(sw_instr(1,3,28)) # M8 = x86548654
    
    instructions.append(lw_instr(5,0,0)) # R5 = x12345678
    instructions.append(lh_instr(5,0,4)) # R5 = x5678
    instructions.append(lhu_instr(6,0,4)) # R6 = x5678
    instructions.append(lh_instr(5,0,4+2)) # R5 = x0000
    instructions.append(lhu_instr(6,0,4+2)) # R6 = x0000
    instructions.append(lb_instr(5,0,24)) # R5 = x00
    instructions.append(lb_instr(5,0,24+1)) # R5 = x78
    instructions.append(lb_instr(5,0,24+2)) # R5 = x00
    instructions.append(lb_instr(5,0,24+3)) # R5 = x78
    instructions.append(lbu_instr(6,0,24)) # R6 = x00
    instructions.append(lbu_instr(6,0,24+1)) # R6 = x78
    instructions.append(lbu_instr(6,0,24+2)) # R6 = x00
    instructions.append(lbu_instr(6,0,24+3)) # R6 = x78

    instructions.append(lh_instr(5,0,28)) # R5 = xffff8654
    instructions.append(lhu_instr(6,0,28)) # R6 = x00008654
    instructions.append(lb_instr(5,0,28)) # R5 = x54
    instructions.append(lb_instr(5,0,28+1)) # R5 = xffffff86
    instructions.append(lb_instr(5,0,28+2)) # R5 = x54
    instructions.append(lb_instr(5,0,28+3)) # R5 = xffffff86
    instructions.append(lbu_instr(6,0,28)) # R6 = x54
    instructions.append(lbu_instr(6,0,28+1)) # R6 = x86
    instructions.append(lbu_instr(6,0,28+2)) # R6 = x54
    instructions.append(lbu_instr(6,0,28+3)) # R6 = x86


    return instructions

def generate_br_test():
    instructions = []

    for i in range(5):
        instructions.append(addi_instr(i,0,i))
    instructions.append(addi_instr(7,0,2)) # loop counter
    # loop - r5 = 1-3
    instructions.append(sub_instr(5,4,3)) # r5 = 1
    instructions.append(xori_instr(5,3,1)) # r5 = 2
    instructions.append(addi_instr(5,3,0)) # r5 = 3
    instructions.append(addi_instr(7,7,-1)) # r7 = 1,0
    instructions.append(bne_instr(7,0,-4*4)) # 2 loops

    instructions.append(add_instr(5,3,3)) # r5 = 6
    instructions.append(add_instr(5,3,4)) # r5 = 7
    instructions.append(addi_instr(7,7,1)) # r7 = 1,2
    instructions.append(beq_instr(7,1,-3*4)) # 2 loops

    instructions.append(addi_instr(5,0,8)) # r5 = 8
    instructions.append(addi_instr(5,0,9)) # r5 = 9
    instructions.append(addi_instr(7,7,1)) # r7 = 3,4
    instructions.append(blt_instr(7,4,-3*4)) # 2 loops

    instructions.append(addi_instr(5,0,9)) # r5 = 9
    instructions.append(addi_instr(5,0,10)) # r5 = 10
    instructions.append(addi_instr(7,7,-1)) # r7 = 3,2
    instructions.append(bge_instr(7,3,-3*4)) # 2 loops

    # negative unsigned tests
    instructions.append(addi_instr(7,0,-4))
    instructions.append(addi_instr(4,0,-4))

    instructions.append(addi_instr(5,0,11)) # r5 = 11
    instructions.append(addi_instr(5,0,12)) # r5 = 12
    instructions.append(addi_instr(7,7,1)) # r7 = -3,-2,-1,0,1,2
    instructions.append(blt_instr(7,2,-3*4)) # 6 loops

    instructions.append(addi_instr(7,0,-4))
    instructions.append(addi_instr(5,0,12)) # r5 = 12
    instructions.append(addi_instr(5,0,13)) # r5 = 13
    instructions.append(addi_instr(7,7,1)) # r7 = -3
    instructions.append(bltu_instr(7,2,-3*4)) # 1 loop

    instructions.append(addi_instr(7,0,-2))
    instructions.append(addi_instr(5,0,14)) # r5 = 14
    instructions.append(addi_instr(5,0,15)) # r5 = 15
    instructions.append(addi_instr(7,7,-1)) # r7 = -3,-4,-5
    instructions.append(bge_instr(7,4,-3*4)) # 3 loops

    instructions.append(addi_instr(7,0,-2))
    instructions.append(addi_instr(5,0,16)) # r5 = 16
    instructions.append(addi_instr(5,0,17)) # r5 = 17
    instructions.append(addi_instr(7,7,1)) # r7 = -3
    instructions.append(bgeu_instr(7,2,-3*4)) # 1 loop

    return instructions

def generate_jump_test():
    instructions = []
    
    for i in range(5):
        instructions.append(addi_instr(i,0,i))

    instructions.append(add_instr(5,1,2)) # r5 = 3
    instructions.append(jal_instr(7,2*4)) # r7 = 7*4 = 28 (pc+4)

    instructions.append(add_instr(5,1,1)) # r5 = 2 skipped
    instructions.append(add_instr(5,2,2)) # r5 = 4
    instructions.append(addi_instr(6,0,11*4)) # r6 = 11*4
    instructions.append(jalr_instr(7,6,4)) # r7 = 11*4 = 44 (pc+4)

    instructions.append(add_instr(5,1,1)) # r5 = 2 skipped
    instructions.append(add_instr(5,2,3)) # r5 = 5
    instructions.append(add_instr(5,2,4)) # r5 = 6

    return instructions



def generate_dep_test():
    instructions = []

    for i in range(1,5):
        instructions.append(addi_instr(i,0,i))

    instructions.append(add_instr(5,1,2)) # r5 = 3
    instructions.append(add_instr(5,5,1)) # r5 = 4
    instructions.append(sub_instr(5,5,2)) # r5 = 2
    instructions.append(xori_instr(6,5,5)) # r6 = 7
    instructions.append(addi_instr(5,5,1)) # r5 = 3
    instructions.append(andi_instr(5,5,5)) # r5 = 1
    instructions.append(add_instr(6,6,1)) # r6 = 8

    instructions.append(beq_instr(4,0,-4*4)) 
    instructions.append(bne_instr(4,4,-4*4)) 
    instructions.append(blt_instr(4,2,-4*4)) # no jumps

    instructions.append(addi_instr(5,1,2)) # r5 = 3
    instructions.append(addi_instr(5,5,1)) # r5 = 4
    instructions.append(addi_instr(5,5,1)) # r5 = 5

    return instructions

# convert to hex .mem file for readmemh
def write_mem(instructions, filename):
    with open(filename, "w") as f:
        for i, instr in enumerate(instructions):
            f.write(f"{instr:08x}\n")
    print(f"Generated {len(instructions)} instructions in {filename}")

def write_v(instructions, filename):
    with open(filename, "w") as f:
        f.write(f"initial begin\n")
        for i, instr in enumerate(instructions):
            f.write(f"  mem[{i}] = 32'h{instr:08x};\n")
        f.write(f"end\n")
    print(f"Generated {len(instructions)} instructions in {filename}")

# main
if __name__ == "__main__":
    full_test = generate_jump_test()

    # while (len(full_test) < 64):
    #     full_test.append(nop_instr())

    write_mem(full_test, "instr.mem")

    for i, instr in enumerate(full_test):
        print(f"I-MEM[{i}]: 0x{instr:08x}")
