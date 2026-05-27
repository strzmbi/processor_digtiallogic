`timescale 1ns/1ps
/*
  COMPILE:
  iverilog -o tb.vvp control_unit.v cpu_sim.v alu.v sreg.v gle.v \
           register_file.v pc.v tristate_buffer_16bit.v rom.v ram.v \
           decoder.v tristate_buffer.v one_hot.v tb_ldi_add_sub.v hex_decoder.v \
           output_to_bus.v
  RUN:
  vvp tb.vvp
*/

module tb_ldi_add_sub;

    // ----------------------------------------------------------------
    // DUT signals
    // ----------------------------------------------------------------
    reg  [9:0] SW;
    reg        CLOCK_50;

    cpu_sim dut(
        .SW(SW),
        .CLOCK_50(CLOCK_50)
    );

    // ----------------------------------------------------------------
    // Clock — 20 ns period
    // ----------------------------------------------------------------
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
    localparam OP_JMP = 4'b0000;

    function [15:0] enc;
        input [1:0] comp;
        input [3:0] op;
        input [4:0] a1;   // destination reg or branch target
        input [4:0] a2;   // source reg or immediate value
        begin
            enc = {comp, op, a1, a2};
        end
    endfunction

    // ----------------------------------------------------------------
    // Pass/fail
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

    // ----------------------------------------------------------------
    // Load a program into ROM while reset is still high.
    // Clears all 32 locations first, then writes the supplied words.
    // ----------------------------------------------------------------
    task load_program;
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

    // ----------------------------------------------------------------
    // Reset sequence.
    // 1. Assert SW[0] high
    // 2. Load program into ROM (while CPU is held in reset)
    // 3. Hold reset for 8 more cycles to guarantee register file clears
    // 4. Release reset
    // 5. Wait 2 cycles for pipeline to settle
    // ----------------------------------------------------------------
    task reset_and_load;
        input [15:0] i0,  i1,  i2,  i3,  i4,
                     i5,  i6,  i7,  i8,  i9,
                     i10, i11, i12, i13, i14, i15;
        begin
            SW[0] = 1;
            repeat(4) @(posedge CLOCK_50);

            // Load ROM while reset is asserted
            load_program(i0,  i1,  i2,  i3,  i4,
                         i5,  i6,  i7,  i8,  i9,
                         i10, i11, i12, i13, i14, i15);

            // Hold reset a few more cycles
            repeat(4) @(posedge CLOCK_50);

            // Release on falling edge so FSM sees clean rising edge next
            @(negedge CLOCK_50);
            SW[0] = 0;

            // Let pipeline settle (FETCH + IDLE)
            repeat(4) @(posedge CLOCK_50);
        end
    endtask

    // ----------------------------------------------------------------
    // Wait until FSM returns to IDLE or FETCH (instruction complete)
    // Timeout after max_cycles to avoid hanging
    // ----------------------------------------------------------------
    task wait_for_idle;
        input integer max_cycles;
        integer i;
        begin
            i = 0;
            while (i < max_cycles) begin
                @(posedge CLOCK_50);
                #1;
                if (dut.c.current_state == 4'b0000 ||  // IDLE
                    dut.c.current_state == 4'b1000)     // FETCH
                    i = max_cycles;  // exit
                else
                    i = i + 1;
            end
            // One extra cycle to let register write settle
            repeat(2) @(posedge CLOCK_50);
            #1;
        end
    endtask

    // ----------------------------------------------------------------
    // Wait for N complete instruction cycles
    // Each instruction: worst case ~15 cycles
    // ----------------------------------------------------------------
    task wait_n_instructions;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1)
                wait_for_idle(30);
        end
    endtask

    // ----------------------------------------------------------------
    // Shorthand for NOP/halt slot (JMP to self)
    // ----------------------------------------------------------------
    function [15:0] halt;
        input [4:0] addr;
        begin
            halt = enc(COMP_BR, OP_JMP, addr, 5'd0);
        end
    endfunction

    // ================================================================
    // TESTS
    // ================================================================
    initial begin
        SW = 10'b0;

        $display("========================================");
        $display("  LDI / ADD / SUB  TESTBENCH");
        $display("========================================");

        // ------------------------------------------------------------
        // TEST 1 — LDI R1, 5
        // ------------------------------------------------------------
        $display("\n--- TEST 1: LDI R1, 5 ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd5),  // LDI R1, 5
            halt(5'd1),                           // JMP 1 (halt)
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(2);
        check(dut.register_file.regs[1], 16'd5, "R1=5 after LDI");

        // ------------------------------------------------------------
        // TEST 2 — LDI R1,3  LDI R2,9  (independence)
        // ------------------------------------------------------------
        $display("\n--- TEST 2: LDI R1,3  LDI R2,9 ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd3),  // LDI R1, 3
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd9),  // LDI R2, 9
            halt(5'd2),                           // JMP 2 (halt)
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(3);
        check(dut.register_file.regs[1], 16'd3, "R1=3 after LDI");
        check(dut.register_file.regs[2], 16'd9, "R2=9 after LDI");

        // ------------------------------------------------------------
        // TEST 3 — ADD R1,R2  (4+6=10)
        // ------------------------------------------------------------
        $display("\n--- TEST 3: ADD R1,R2  (4+6=10) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd4),  // LDI R1, 4
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd6),  // LDI R2, 6
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd2),  // ADD R1, R2
            halt(5'd3),                           // JMP 3 (halt)
            16'h0, 16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(4);
        check(dut.register_file.regs[1], 16'd10, "R1=10 after ADD 4+6");

        // ------------------------------------------------------------
        // TEST 4 — ADD R1,R1  (7+7=14)
        // ------------------------------------------------------------
        $display("\n--- TEST 4: ADD R1,R1  (7+7=14) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd7),  // LDI R1, 7
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd1),  // ADD R1, R1
            halt(5'd2),                           // JMP 2 (halt)
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(3);
        check(dut.register_file.regs[1], 16'd14, "R1=14 after ADD R1,R1");

        // ------------------------------------------------------------
        // TEST 5 — SUB R1,R2  (10-3=7)
        // ------------------------------------------------------------
        $display("\n--- TEST 5: SUB R1,R2  (10-3=7) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd10), // LDI R1, 10
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd3),  // LDI R2, 3
            enc(COMP_ALU, OP_SUB, 5'd1, 5'd2),  // SUB R1, R2
            halt(5'd3),                           // JMP 3 (halt)
            16'h0, 16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(4);
        check(dut.register_file.regs[1], 16'd7,  "R1=7 after SUB 10-3");

        // ------------------------------------------------------------
        // TEST 6 — SUB to zero  (5-5=0)
        // ------------------------------------------------------------
        $display("\n--- TEST 6: SUB R1,R2  (5-5=0) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd5),  // LDI R1, 5
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd5),  // LDI R2, 5
            enc(COMP_ALU, OP_SUB, 5'd1, 5'd2),  // SUB R1, R2
            halt(5'd3),                           // JMP 3 (halt)
            16'h0, 16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(4);
        check(dut.register_file.regs[1], 16'd0,  "R1=0 after SUB 5-5");

        // ------------------------------------------------------------
        // TEST 7 — SUB R1,R1  (self subtract = 0)
        // ------------------------------------------------------------
        $display("\n--- TEST 7: SUB R1,R1  (self=0) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd12), // LDI R1, 12
            enc(COMP_ALU, OP_SUB, 5'd1, 5'd1),  // SUB R1, R1
            halt(5'd2),                           // JMP 2 (halt)
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(3);
        check(dut.register_file.regs[1], 16'd0,  "R1=0 after SUB R1,R1");

        // ------------------------------------------------------------
        // TEST 8 — Chained ADD  (2+3=5, 5+3=8)
        // ------------------------------------------------------------
        $display("\n--- TEST 8: Chained ADD (2+3=5, 5+3=8) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd2),  // LDI R1, 2
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd3),  // LDI R2, 3
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd2),  // ADD R1,R2 → 5
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd2),  // ADD R1,R2 → 8
            halt(5'd4),                           // JMP 4 (halt)
            16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(5);
        check(dut.register_file.regs[1], 16'd8,  "R1=8 after chained ADD");

        // ------------------------------------------------------------
        // TEST 9 — ADD then SUB  (10+4=14, 14-4=10)
        // ------------------------------------------------------------
        $display("\n--- TEST 9: ADD then SUB (10+4-4=10) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd10), // LDI R1, 10
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd4),  // LDI R2, 4
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd2),  // ADD R1,R2 → 14
            enc(COMP_ALU, OP_SUB, 5'd1, 5'd2),  // SUB R1,R2 → 10
            halt(5'd4),                           // JMP 4 (halt)
            16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(5);
        check(dut.register_file.regs[1], 16'd10, "R1=10 after ADD then SUB");

        // ------------------------------------------------------------
        // TEST 10 — Large values ADD  (15+16=31)
        // ------------------------------------------------------------
        $display("\n--- TEST 10: ADD large (15+16=31) ---");
        reset_and_load(
            enc(COMP_MEM, OP_LDI, 5'd1, 5'd15), // LDI R1, 15
            enc(COMP_MEM, OP_LDI, 5'd2, 5'd16), // LDI R2, 16
            enc(COMP_ALU, OP_ADD, 5'd1, 5'd2),  // ADD R1,R2 → 31
            halt(5'd3),                           // JMP 3 (halt)
            16'h0, 16'h0, 16'h0, 16'h0,
            16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0, 16'h0);
        wait_n_instructions(4);
        check(dut.register_file.regs[1], 16'd31, "R1=31 after ADD 15+16");

        // ----------------------------------------------------------------
        // SUMMARY
        // ----------------------------------------------------------------
        $display("\n========================================");
        $display("  Results: %0d passed, %0d failed",
                 pass_count, fail_count);
        $display("========================================");
        if (fail_count == 0)
            $display("  All tests passed.");
        else
            $display("  Failures remain — check signals above.");

        $finish;
    end

    // ----------------------------------------------------------------
    // Timeout watchdog
    // ----------------------------------------------------------------
    initial begin
        #500000;
        $display("TIMEOUT — increase wait counts or check FSM");
        $finish;
    end

    // ----------------------------------------------------------------
    // VCD dump
    // ----------------------------------------------------------------
    initial begin
        $dumpfile("tb_ldi_add_sub.vcd");
        $dumpvars(0, tb_ldi_add_sub);
    end

    // ----------------------------------------------------------------
    // Write monitor — prints every register write so you can trace
    // wrong values immediately without opening GTKWave
    // ----------------------------------------------------------------
    // always @(posedge CLOCK_50) begin
    //     if (dut.register_write)
    //         $display("  [WRITE] t=%0t  addr=R%0d  BUS=%h",
    //             $time, dut.register_en, dut.BUS);
    // end

endmodule