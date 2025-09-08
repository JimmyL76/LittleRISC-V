# LittleRISC-V

A pipelined RISC-V processor for FPGA platforms, built for educational purposes and hands-on learning. Current Project Time: ~65 Hours.

## Overview

The purpose of this project is to expand upon my learning of RTL design and computer architecture by implementing a 32-bit RISC-V processor core supporting the RV32I ISA. The design uses a simple 5-stage pipeline with data forwarding and hazard detection to optimize performance while handling dependencies.

## Architecture

![little-risc-v architecture](./readme/little-risc-v-architecture200.png "little-risc-v architecture")

## Implementation Details

### Pipeline Stages
1. **Fetch (F)**: Instruction fetch from instruction memory
2. **Decode (D)**: Instruction decode, register read, immediate generation
3. **Execute (E)**: ALU operations, branch/jump target calculation
4. **Memory (M)**: Data memory access for loads/stores
5. **Writeback (W)**: Register file write-back

### Memory Interface
The memory is separated into data memory in the Memory stage and instruction memory in the Fetch stage. The instruction memory is loaded either with a Vivado Mem file and `$readmemh`, or through UART control (to be implemented). Both are 32-bit word-based memory systems, with data memory using a WE logic block's 4-bit write-enable signals for byte and halfword instructions.

Currently, all memory requests are carried out using negative edge clocking to avoid single-cycle delays. In a real implementation, this might be replaced with proper DDR controllers, handshaking, and clock domain crossing.

### ALU Execution
For arithmetic operations, a combined ALU and shifter unit carries out calculations involving the Program Counter, immediates, registers RS1/RS2, and signed/unsigned values. Address generation also occurs in this unit.

### Hazard Handling and Data Forwarding
The dependency/data forwarding unit handles all of the control and data signals needed for stalling and data forwarding. 

For example, the decode stage's control store contains `RS1need` and `RS2need` to track which instructions need certain values from the register file. If these values are currently in subsequent stages but have not been written back yet (detected by matching `RDID` to the RS1/RS2 needed), then we can forward these values to the decode stage with control signals `DF1` and `DF2`. 

The values themselves come from tapping the ALU signal for most instructions, or NPC for jumps and data for loads (decided with `IsBR_J`). If data forwarding is unavailable, such as for load instructions, we stall at decode and fetch, and insert a bubble into the execute stage. 

### Branch Prediction
Another potential chance for stalling comes from waiting for a control instruction to execute, such as a jump or branch instruction. This implementation uses simple always-not-taken branch prediction since the additional logic needed is very simple. 

Whenever a control instruction reaches the decode stage, execution of subsequent instructions continues until the target address is calculated in the execute stage. On a correct prediction (either for not-taken branches or jumps/branches to the next instruction), normal execution continues. Otherwise, we flush decode and execute and begin at fetch with the new PC address.

## Other Features

### UART Communication

Since this project targets the Basys 3 FPGA board, instructions and program data can be loaded and received through the built-in USB-to-UART port. Here, the computer acts as the host, running a PySerial script to communicate with the FPGA through serial communication (allowing for initial program loading, data monitoring, etc.).

This system would also benefit from a FIFO buffer that acts as a hardware queue to store data sent to or from the FPGA. This way, both programs can send sudden bursts of data and continue with their other tasks without having to either wait for every packet to be acknowledged or risk losing data from too slow receiving logic. 

### Low-Power Design Optimization

To optimize the power used by the system, there are many different techniques. To start, clock gating can be implemented to only provide clock edges to logic when actually needed. For instance, idle pipeline stages or functional units can all be disabled during inactive times to reduce dynamic power usage. This means that we only pass the clock signal through to certain stages or execution units when they are needed.

In terms of the switching activity due to data flow through logic blocks, operand isolation can be used. This is the idea to block certain pieces of data from propagating through certain logic blocks/gates, such as with the ALU.

Lastly, we can also gate power itself to certain areas of the hardware by partitioning into power islands and deciding which islands can be inactive during which operations. However, this may prove more difficult to directly control on FPGAs.

## Testing & Verification

All testing was done with a Vivado testbench using Mem files for loading instructions generated by Python. Testing included all RV32I instruction types (arithmetic, memory, branch and jump) as well as pipeline hazard and dependency scenarios.

## Challenges & Lessons Learned

### Instruction Decoding
RISC-V uses six basic instruction formats (R, I, S, B, U, J) all with different decoding schemes and immediate value generation. Both the Python code for creating the hex bits themselves as well as the control store/immediate logic had to have proper logic execution and be optimized to reduce unnecessary hardware.

### Pipeline Coordination
Careful management of each stage's valid bits and PC/decode load bits were necessary for propering pipelining function. Unbalanced coordination with data forwarding and branch predictions would either lead to suboptimal performance or pipeline stalling failures.

### Finish Signal
To decide on the exact moment the current process is done executing, and stop further pipeline stages as soon as the last instruction is complete, isn't as simple for a pipelined processor as seeing a HALT instruction. 

Here, a HALT is implemented as just an address in the instruction memory with all 0's. Prior stages should begin getting valid bits set to 0 as soon as a HALT enters the decode stage. However, a branch/jump might still be in the later stages of the pipeline. This was solved using a `FinishCtr` that gets reset upon a jump back, but which also stops the processor once three finish signals are set in a row

## Video Demo

![Little RISC-V Basys 3 Add Demo](readme/Little-RISC-V%20Basys%203%20Add%20Demo.gif)

Using the Basys 3 for synthesis, this video shows the basic `generate_add_test()` example from `testScript.py`. The LEDs show the lower 16 bits of the execute stage ALU's input data ALU.RS1, and the display shows the lower 16 hexadecimal bits of Register 1 (which was added to with 1, 2, 4, 8, then 10).

## Next Steps

Currently working on...
- [ ] Writing UART interface for serial communication and instruction loading with Python
- [ ] Synthesizing on Basys 3 FPGA
- [ ] Optimizing for low power with clock gating/operand isolation
- [ ] Adding FIFO for faster and more complex UART communication
- [ ] Considering power islands with power gating of different logic blocks 

Next in line...
- [ ] Other power optimization techniques, such as dynamic voltage and frequency scaling
- [ ] Advanced branch prediction with two-bit predictors or branch target buffers
- [ ] More robust memory cache implementation
- [ ] Implementing RISC-V ISA extensions

## Acknowledgements
Most of this project is based on the knowledge I've gathered from my Digital System Design with HDL and Computer Architecture classes at university.

Special thanks for the specifics of the ISA coming from [RISC-V](https://github.com/riscv) RV32I.
