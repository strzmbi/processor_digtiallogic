`timescale 1ns/1ps
/*
  COMPILE:
  iverilog -o tb.vvp control_unit.v cpu_sim.v alu.v sreg.v gle.v \
           register_file.v pc.v tristate_buffer_16bit.v rom.v ram.v \
           decoder.v tristate_buffer.v one_hot.v tb_full.v output_to_bus.v
  RUN:
  vvp tb.vvp
*/

module tb_full;

    // ----------------------------------------------------------------
    // DUT
    // ----------------------------------------------------------------
    reg  [9:0] SW;
    reg        CLOCK_50;

    cpu_sim dut(
        .SW(SW),
        .CLOCK_50(CLOCK_50)
    );

    initial CLOCK_50 = 0;
    always  #10 CLOCK_50 = ~CLOCK_50;

    // ----------------------------------------------------------------
    // Instruction encoding
    // {comp[1:0], opcode[3:0], arg1[4:0], arg2[4:0]}
    // ----------------------------------------------------------------
    localparam COMP_ALU = 2'b00;
    localparam COMP_MEM = 2'b01;
    localparam COMP_BR  = 2'b11;

    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
    localparam OP_LDI = 4'b0000;
    localparam OP_LD  = 4'b0001;
    localparam OP_ST  = 4'b0010;
    localparam OP_JMP = 4'b0000;
    localparam OP_JE  = 4'b0001;
    localparam OP_JG  = 4'b0010;
    localparam OP_JL  = 4'b0011;
    localparam OP_CP  = 4'b0100;

    function [15:0] enc;
        input [1:0] comp;
        input [3:0] op;
        input [4:0] a1;
        input [4:0] a2;
        begin
            enc = {comp, op, a1, a2};
        end
    endfunction

    function [15:0] halt;
        input [4:0] addr;
        begin
            halt = enc(COMP_BR, OP_JMP, addr, 5'd0);
        end
    endfunction

    // ----------------------------------------------------------------
    // Pass/fail tracking
    // ----------------------------------------------------------------
    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [15:0] actual;
        input [15:0] expected;
        input [127:0] label;
        begin
            if (actual === expected) begin
                $display("  PASS  %0s  got=%0d", label, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %0s  got=%0d  expected=%0d",
                         label, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_pc;
        input [4:0] actual;
        input [4:0] expected;
        input [127:0] label;
        begin
            if (actual === expected) begin
                $display("  PASS  %0s  PC=%0d", label, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL  %0s  PC got=%0d  expected=%0d",
                         label, actual, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // ----------------------------------------------------------------
    // ROM loading — always done during reset
    // ----------------------------------------------------------------
    task load_rom_direct;
        input [15:0] i0,  i1,  i2,  i3,  i4,
                     i5,  i6,  i7,  i8,  i9,
                     i10, i11, i12, i13, i14, i15;
        integer k;
        begin
            for (k = 0; k < 32; k = k + 1)
                dut.rom.mem[k] = 16'h0000;
            dut.rom.mem[0]  = i0;
            dut.rom.mem[1]  = i1;
            dut.rom.mem[2]  = i2;
            dut.rom.mem[3]  = i3;
            dut.rom.mem[4]  = i4;
            dut.rom.mem[5]  = i5;
            dut.rom.mem[6]  = i6;
            dut.rom.mem[7]  = i7;
            dut.rom.mem[8]  = i8;
            dut.rom.mem[9]  = i9;
            dut.rom.mem[10] = i10;
            dut.rom.mem[11] = i11;
            dut.rom.mem[12] = i12;
            dut.rom.mem[13] = i13;
            dut.rom.mem[14] = i14;
            dut.rom.mem[15] = i15;
        end
    endtask

    task reset_and_load;
        input [15:0] i0,  i1,  i2,  i3,  i4,
                     i5,  i6,  i7,  i8,  i9,
                     i10, i11, i12, i13, i14, i15;
        begin
            SW[0] = 1;
            repeat(4) @(posedge CLOCK_50);
            load_rom_direct(i0,  i1,  i2,  i3,  i4,
                            i5,  i6,  i7,  i8,  i9,
                            i10, i11, i12, i13, i14, i15);
            repeat(4) @(posedge CLOCK_50);
            @(negedge CLOCK_50);
            SW[0] = 0;
            repeat(4) @(posedge CLOCK_50);
        end
    endtask

    // ----------------------------------------------------------------
    // Wait helpers
    // ----------------------------------------------------------------
    task wait_for_idle;
        input integer max_cycles;
        integer i;
        begin
            i = 0;
            while (i < max_cycles) begin
                @(posedge CLOCK_50);
                #1;
                if (dut.c.current_state == 4'b0000 ||
                    dut.c.current_state == 4'b1000)
                    i = max_cycles;
                else
                    i = i + 1;
            end
            repeat(2) @(posedge CLOCK_50);
            #1;
        end
    endtask

    task wait_n_instructions;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                wait_for_idle(30);
        end
    endtask

    // Wait until PC reaches a specific address (branch landed)
    task wait_for_pc;
        input [4:0] target;
        input integer max_cycles;
        integer i;
        begin
            i = 0;
            while (i < max_cycles) begin
                @(posedge CLOCK_50);
                #1;
                if (dut.pc_out === target)
                    i = max_cycles;
                else
                    i = i + 1;
            end
            repeat(2) @(posedge CLOCK_50);
            #1;
        end
    endtask

    // ================================================================
    // MAIN TEST SEQUENCE
    // ================================================================
    initial begin
        SW = 10'b0;

        $display("========================================");
        $display("  FULL CPU TESTBENCH");
        $display("  LDI / ADD / SUB / JMP / JE / JG / JL");
        $display("  ST / LD (memory round-trip)");
        $display("========================================");

        // ============================================================
        // SECTION 1 — LDI / ADD / SUB  (carried over)
        // ============================================================
        $display("\n====== SECTION 1: LDI / ADD / SUB ======");

        $display("\n--- TEST 1: LDI R1, 5 ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd5),
            halt(5'd1),
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0, 16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(2);
        check(dut.register_file.regs[1], 16'd5, "R1=5 after LDI");

        $display("\n--- TEST 2: LDI R1,3  LDI R2,9 ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd3),
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd9),
            halt(5'd2),
            16'h0,16'h0,16'h0,16'h0,16'h0, 16'h0, 
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(3);
        check(dut.register_file.regs[1], 16'd3, "R1=3");
        check(dut.register_file.regs[2], 16'd9, "R2=9");

        $display("\n--- TEST 3: ADD R1,R2 (4+6=10) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd4),
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd6),
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd2),
            halt(5'd3),
            16'h0,16'h0,16'h0,16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(4);
        check(dut.register_file.regs[1], 16'd10, "R1=10 after ADD 4+6");

        $display("\n--- TEST 4: ADD R1,R1 (7+7=14) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd7),
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd1),
            halt(5'd2),
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(3);
        check(dut.register_file.regs[1], 16'd14, "R1=14 after ADD R1,R1");

        $display("\n--- TEST 5: SUB R1,R2 (10-3=7) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd10),
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd3),
            enc(COMP_ALU, OP_SUB, 5'd1, 5'd2),
            halt(5'd3),
            16'h0,16'h0,16'h0,16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(4);
        check(dut.register_file.regs[1], 16'd7, "R1=7 after SUB 10-3");

        $display("\n--- TEST 6: SUB R1,R1 (self=0) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd12),
            enc(COMP_ALU, OP_SUB, 5'd1, 5'd1),
            halt(5'd2),
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(3);
        check(dut.register_file.regs[1], 16'd0, "R1=0 after SUB R1,R1");

        // ============================================================
        // SECTION 2 — JMP (unconditional)
        // ============================================================
        $display("\n====== SECTION 2: JMP (unconditional) ======");

        // TEST 7 — JMP skips an instruction
        // addr 0: LDI R1,1
        // addr 1: JMP 3          ← should skip addr 2
        // addr 2: LDI R1,99      ← should be skipped
        // addr 3: LDI R2,7       ← should execute
        // addr 4: JMP 4 (halt)
        $display("\n--- TEST 7: JMP skips instruction ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd1),   // addr 0: LDI R1,1
            enc(COMP_BR,  OP_JMP, 5'd3, 5'd0),    // addr 1: JMP 3
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd31),   // addr 2: LDI R1,31 (skipped)
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd7),    // addr 3: LDI R2,7
            halt(5'd4),                             // addr 4: halt
            16'h0,16'h0,16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(5);
        check(dut.register_file.regs[1], 16'd1,  "R1=1 (addr2 skipped)");
        check(dut.register_file.regs[2], 16'd7,  "R2=7 (landed at addr3)");

        // TEST 8 — JMP to self (infinite loop — check PC stays put)
        // addr 0: LDI R1,5
        // addr 1: JMP 1  (loops to itself)
        $display("\n--- TEST 8: JMP to self (PC stays at 1) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd5),   // addr 0: LDI R1,5
            halt(5'd1),                             // addr 1: JMP 1 (halt)
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0, 16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(4);
        check(dut.register_file.regs[1], 16'd5, "R1=5 before halt");
        check_pc(dut.pc_out, 5'd1, "PC=1 at self-loop");

        // ============================================================
        // SECTION 3 — Conditional branches
        // For each branch we need CP (compare) to set flags first.
        // CP does a subtract and writes flags without storing result.
        // Flags: status_flags[2]=zero, [0]=positive, [1]=negative
        // JE branches if zero flag (equal)
        // JG branches if positive flag (greater)
        // JL branches if negative flag (less)
        // ============================================================
        $display("\n====== SECTION 3: Conditional branches ======");

        // TEST 9 — JE taken (R1==R2 → zero flag → branch)
        // addr 0: LDI R1,5
        // addr 1: LDI R2,5
        // addr 2: CP R1,R2        ← sets zero flag (5-5=0)
        // addr 3: JE 5            ← should branch to 5
        // addr 4: LDI R3,99       ← should be skipped
        // addr 5: LDI R3,7        ← should execute
        // addr 6: JMP 6 (halt)
        $display("\n--- TEST 9: JE taken (5==5) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd5),    // 0: LDI R1,5
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd5),    // 1: LDI R2,5
            enc(COMP_BR,  OP_CP,  5'd1, 5'd2),    // 2: CP R1,R2
            enc(COMP_BR,  OP_JE,  5'd5, 5'd0),    // 3: JE 5
            enc(COMP_MEM, OP_LDI, 5'd3, 5'd31),   // 4: LDI R3,31 (skipped)
            enc(COMP_MEM, OP_LDI, 5'd3, 5'd7),    // 5: LDI R3,7
            halt(5'd6),                             // 6: halt
            16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(8);
        check(dut.register_file.regs[3], 16'd7,  "R3=7 (JE taken, landed addr5)");

        // TEST 10 — JE not taken (R1!=R2 → no zero flag → fall through)
        // addr 0: LDI R1,5
        // addr 1: LDI R2,3
        // addr 2: CP R1,R2        ← result positive, not zero
        // addr 3: JE 6            ← should NOT branch
        // addr 4: LDI R3,11       ← should execute (fall through)
        // addr 5: JMP 5 (halt)
        $display("\n--- TEST 10: JE not taken (5!=3) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd5),    // 0: LDI R1,5
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd3),    // 1: LDI R2,3
            enc(COMP_BR,  OP_CP,  5'd1, 5'd2),    // 2: CP R1,R2
            enc(COMP_BR,  OP_JE,  5'd6, 5'd0),    // 3: JE 6 (not taken)
            enc(COMP_MEM, OP_LDI, 5'd3, 5'd11),   // 4: LDI R3,11
            halt(5'd5),                             // 5: halt
            16'h0,16'h0, 16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(7);
        check(dut.register_file.regs[3], 16'd11, "R3=11 (JE not taken, fell through)");

        // TEST 11 — JG taken (R1>R2 → positive flag → branch)
        // addr 0: LDI R1,8
        // addr 1: LDI R2,3
        // addr 2: CP R1,R2        ← 8-3=5, positive flag
        // addr 3: JG 5            ← should branch
        // addr 4: LDI R3,31       ← skipped
        // addr 5: LDI R3,4
        // addr 6: halt
        $display("\n--- TEST 11: JG taken (8>3) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd8),    // 0: LDI R1,8
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd3),    // 1: LDI R2,3
            enc(COMP_BR,  OP_CP,  5'd1, 5'd2),    // 2: CP R1,R2
            enc(COMP_BR,  OP_JG,  5'd5, 5'd0),    // 3: JG 5
            enc(COMP_MEM, OP_LDI, 5'd3, 5'd31),   // 4: skipped
            enc(COMP_MEM, OP_LDI, 5'd3, 5'd4),    // 5: LDI R3,4
            halt(5'd6),                             // 6: halt
            16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(8);
        check(dut.register_file.regs[3], 16'd4,  "R3=4 (JG taken, 8>3)");

        // TEST 12 — JG not taken (R1<R2)
        // addr 0: LDI R1,2
        // addr 1: LDI R2,9
        // addr 2: CP R1,R2        ← 2-9 negative, JG not taken
        // addr 3: JG 6            ← not taken
        // addr 4: LDI R3,6
        // addr 5: halt
        $display("\n--- TEST 12: JG not taken (2<9) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd2),    // 0: LDI R1,2
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd9),    // 1: LDI R2,9
            enc(COMP_BR,  OP_CP,  5'd1, 5'd2),    // 2: CP R1,R2
            enc(COMP_BR,  OP_JG,  5'd6, 5'd0),    // 3: JG 6 (not taken)
            enc(COMP_MEM, OP_LDI, 5'd3, 5'd6),    // 4: LDI R3,6
            halt(5'd5),                             // 5: halt
            16'h0,16'h0, 16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(7);
        check(dut.register_file.regs[3], 16'd6,  "R3=6 (JG not taken, fell through)");

        // TEST 13 — JL taken (R1<R2 → negative flag → branch)
        // addr 0: LDI R1,3
        // addr 1: LDI R2,10
        // addr 2: CP R1,R2        ← 3-10 negative, JL taken
        // addr 3: JL 5
        // addr 4: LDI R3,31       ← skipped
        // addr 5: LDI R3,9
        // addr 6: halt
        $display("\n--- TEST 13: JL taken (3<10) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd3),    // 0: LDI R1,3
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd10),   // 1: LDI R2,10
            enc(COMP_BR,  OP_CP,  5'd1, 5'd2),    // 2: CP R1,R2
            enc(COMP_BR,  OP_JL,  5'd5, 5'd0),    // 3: JL 5
            enc(COMP_MEM, OP_LDI, 5'd3, 5'd31),   // 4: skipped
            enc(COMP_MEM, OP_LDI, 5'd3, 5'd9),    // 5: LDI R3,9
            halt(5'd6),                             // 6: halt
            16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(8);
        check(dut.register_file.regs[3], 16'd9,  "R3=9 (JL taken, 3<10)");

        // ============================================================
        // SECTION 4 — Memory: ST (store) and LD (load)
        // ============================================================
        $display("\n====== SECTION 4: Memory ST / LD ======");

        // TEST 14 — ST then LD round-trip
        // Store R1=7 into RAM[5], load it back into R2
        // addr 0: LDI R1,7
        // addr 1: ST  R1, addr=5   ← store R1 to RAM[5]
        // addr 2: LD  R2, addr=5   ← load RAM[5] into R2
        // addr 3: halt
        $display("\n--- TEST 14: ST then LD round-trip (val=7, addr=5) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd7),    // 0: LDI R1,7
            enc(COMP_MEM, OP_ST,  5'd1, 5'd5),    // 1: ST R1,addr5
            enc(COMP_MEM, OP_LD,  5'd2, 5'd5),    // 2: LD R2,addr5
            halt(5'd3),                             // 3: halt
            16'h0,16'h0,16'h0,16'h0, 16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(5);
        check(dut.register_file.regs[2], 16'd7,  "R2=7 after LD from addr5");
        check(dut.ram.mem[5],            16'd7,  "RAM[5]=7 after ST");

        // TEST 15 — Store to different addresses, load back
        // R1=3 → RAM[2], R2=9 → RAM[8]
        // load RAM[2] → R3, load RAM[8] → R4
        $display("\n--- TEST 15: ST to two addresses, LD both back ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd3),    // 0: LDI R1,3
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd9),    // 1: LDI R2,9
            enc(COMP_MEM, OP_ST,  5'd1, 5'd2),    // 2: ST R1,addr2
            enc(COMP_MEM, OP_ST,  5'd2, 5'd8),    // 3: ST R2,addr8
            enc(COMP_MEM, OP_LD,  5'd3, 5'd2),    // 4: LD R3,addr2
            enc(COMP_MEM, OP_LD,  5'd4, 5'd8),    // 5: LD R4,addr8
            halt(5'd6),                             // 6: halt
            16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(8);
        check(dut.register_file.regs[3], 16'd3,  "R3=3 after LD addr2");
        check(dut.register_file.regs[4], 16'd9,  "R4=9 after LD addr8");
        check(dut.ram.mem[2],            16'd3,  "RAM[2]=3 after ST");
        check(dut.ram.mem[8],            16'd9,  "RAM[8]=9 after ST");

        // TEST 16 — Compute, store result, load back
        // R1=4, R2=6, ADD→R1=10, ST R1 to addr7, LD addr7→R3
        $display("\n--- TEST 16: ADD result stored and reloaded ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd4),    // 0: LDI R1,4
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd6),    // 1: LDI R2,6
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd2),    // 2: ADD R1,R2 → R1=10
            enc(COMP_MEM, OP_ST,  5'd1, 5'd7),    // 3: ST R1,addr7
            enc(COMP_MEM, OP_LD,  5'd3, 5'd7),    // 4: LD R3,addr7
            halt(5'd5),                             // 5: halt
            16'h0,16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(7);
        check(dut.register_file.regs[1], 16'd10, "R1=10 after ADD");
        check(dut.register_file.regs[3], 16'd10, "R3=10 after LD from stored result");
        check(dut.ram.mem[7],            16'd10, "RAM[7]=10 after ST");

        // ============================================================
        // SECTION 5 — Combined: branch based on computed value
        // ============================================================
        $display("\n====== SECTION 5: Combined branch + memory ======");
        // TEST 18 — Store in loop, verify memory
        // Store incrementing values 1,2,3 into RAM[0],RAM[1],RAM[2]
        // addr 0: LDI R1,0      ← index
        // addr 1: LDI R2,1      ← step / value
        // addr 2: LDI R3,3      ← limit
        // addr 3: ADD R1,R2     ← index++ (also serves as value)
        // addr 4: ST  R1,R1     ← RAM[R1] = R1  (addr=R1, data=R1)
        // addr 5: CP  R1,R3
        // addr 6: JL  3
        // addr 7: halt
        // Note: ST uses arg1=source register, arg2=address register
        // This tests ST R1 to addr held in arg2 field
        $display("\n--- TEST 17: Store loop — RAM[1]=1, RAM[2]=2, RAM[3]=3 ---");
        // For this test we store fixed addresses to avoid complexity
        // LDI R1,1, ST R1,addr1, LDI R1,2, ST R1,addr2, LDI R1,3, ST R1,addr3
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd1),    // 0: LDI R1,1
            enc(COMP_MEM, OP_ST,  5'd1, 5'd1),    // 1: ST R1,addr1
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd2),    // 2: LDI R1,2
            enc(COMP_MEM, OP_ST,  5'd1, 5'd2),    // 3: ST R1,addr2
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd3),    // 4: LDI R1,3
            enc(COMP_MEM, OP_ST,  5'd1, 5'd3),    // 5: ST R1,addr3
            halt(5'd6),                             // 6: halt
            16'h0,16'h0,
            16'h0,16'h0,16'h0,16'h0,16'h0,16'h0,16'h0);
        wait_n_instructions(8);
        check(dut.ram.mem[1], 16'd1, "RAM[1]=1");
        check(dut.ram.mem[2], 16'd2, "RAM[2]=2");
        check(dut.ram.mem[3], 16'd3, "RAM[3]=3");

        // ============================================================
        // SUMMARY
        // ============================================================
        $display("\n========================================");
        $display("  Results: %0d passed, %0d failed",
                 pass_count, fail_count);
        $display("========================================");
        if (fail_count == 0)
            $display("  All tests passed.");
        else
            $display("  Failures detected — check [WRITE] log above");
        $finish;
    end

    // ----------------------------------------------------------------
    // Timeout — increase if tests need more cycles
    // ----------------------------------------------------------------
    initial begin
        #2000000;
        $display("TIMEOUT");
        $finish;
    end

    // ----------------------------------------------------------------
    // VCD
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("tb_full.vcd");
        $dumpvars(0, tb_full);
    end

    // ----------------------------------------------------------------
    // Write monitor
    // ----------------------------------------------------------------
    always @(posedge CLOCK_50) begin
        if (dut.register_write)
            $display("  [WRITE] t=%0t  R%0d <= %h",
                $time, dut.register_en, dut.BUS);
    end

    // ----------------------------------------------------------------
    // Memory write monitor
    // ----------------------------------------------------------------
    always @(posedge CLOCK_50) begin
        if (dut.memory_write_en)
            $display("  [ST]    t=%0t  RAM[%0d] <= %h",
                $time, dut.memory_addr, dut.BUS);
    end

endmodule