# Essential
Your task is to implement a processor that can execute the following instructions:

* **LDI** Rx D; (Rx = D, D is a constant)
* **MOV** Rx Ry; (Rx = Ry)
* **ADD** Rx Ry; (Rx = Rx + Ry)
* **SUB** Rx Ry; (Rx = Rx - Ry)

**Other details:**
* The initial processor must use **at least 3 16-bit registers**
* All the instructions can be passed to the processor using a **testbench**
* You only need to show this working in simulation
* The number of bits used to encode your instructions is up to you. It is recommended that you use **at least 3 or 4 instruction bits** so that you can add additional instructions later.

The simple architecture is described by the following diagram:

![[Essential Project 1.png]]

For more details of Register Enable Signals and Tri-state Buffer Signals, see here:

Implementation hints to be added here:
....... Waiting, David...
# Extension
You must implement a full **16-bit processor** that can implement a basic program. You must demonstrate this running in simulation and on the FPGA.

Your program must include:
* Conditional **branch** instructions
* Unconditional **jump** instructions.
* At least **5 different arithmetic** instructions
* **Loading and storing** to memory

The only input to your circuit should be a clock and reset input. The rest should be in your instruction memory. Your architecture should be similar to the following:

![[Extension Project.png]]

Implementation hints to be added here:
....... Still waiting...
# Advanced
You must implement a more advanced processor that can impress the demonstrators. 

This is deliberately left open, however, examples that could impress include:
* Being able to run at a very high clock frequency.
* Supporting Parallel instructions (e.g. SIMD)
* Supporting Pipelined instructions
* Supporting Complex (but useful) instructions that require a complex FSM implementation