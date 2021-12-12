
## RISC-V CPU

This is a custom implementation of a 32-bit RISC-V core in VHDL. While it is almost identical to what is outlined in the standard, the one change I've had to make is with the B-type instructions. The leading '0' (bit 0) is omitted and assumed to be 0. However, in this core I am requiring (at least for now) that the entire address be there. Some of this is due to the fact that I am using the Harvard architecture, meaning separate instruction and data memory.

The purpose of this project is to give me a simple, working CPU core to do experiments on. It's also to give me a ready-to-use core that I can use one day when I get into FPGAs. I also wrote this because its fun.

### Instruction

The following instructions are supported:

* LUI
* BEQ
* BNE
* BLT
* BGE
* LB
* LH
* LW
* LBU
* LHU
* SB
* SH
* SW
* ADDI
* XORI
* ORI
* ANDI
* ADD
* SUB
* XOR
* OR
* AND

