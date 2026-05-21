/* COMPILE
iverilog -o out.vvp control_unit.v top_level.v alu.v sreg.v gle.v one_hot.v register_file.v pc.v tristate_buffer_16bit.v rom.v ram.v decoder.v tristate_buffer.v register.v dflipflop.v whole_tb.v
*/
module top_level(
    input [9:0] SW,
    input       CLOCK_50
);

    wire reset = SW[0];

    wire [15:0] BUS;
    wire [15:0] TEMP_REG_INT;
    wire [15:0] TEMP_ALU_OUT;
    wire [2:0]  TEMP_REG_STAT_OUT;
    wire [2:0]  flags;

    wire [15:0] raw_instruction;
    wire [5:0]  decoded_instruction;
    wire [4:0]  argument_1, argument_2;
    wire [4:0]  pc_out;
    wire        one_hot_enable;

    wire [4:0]  register_tri;
    wire [4:0]  register_en;
    wire        register_write;
    wire        reg_read_en;

    wire        immediate_en;
    wire        immediate_tri;
    wire [15:0] immediate_val;

    wire        alu_load_en;
    wire        alu_result_en;
    wire        alu_result_tri;
    wire [5:0]  alu_instruction_select;

    wire        chip_sel;
    wire        memory_read_en;
    wire        memory_write_en;
    wire [4:0]  memory_addr;

    assign chip_sel = memory_read_en | memory_write_en;

    control_unit c(
        .reset(SW[0]),
        .one_hot_enable(one_hot_enable),
        .clk(CLOCK_50),
        .instruction(decoded_instruction),
        .argument_1(argument_1),
        .argument_2(argument_2),
        .register_tri(register_tri),
        .register_en(register_en),
        .register_write(register_write),
        .reg_read_en(reg_read_en),
        .immediate_en(immediate_en),
        .immediate_tri(immediate_tri),
        .immediate_val(immediate_val),
        .alu_load_en(alu_load_en),
        .alu_result_en(alu_result_en),
        .alu_result_tri(alu_result_tri),
        .alu_instruction_select(alu_instruction_select),
        .memory_read_en(memory_read_en),
        .memory_write_en(memory_write_en),
        .memory_addr(memory_addr),
        .status_flags(TEMP_REG_STAT_OUT),
        .pc_out(pc_out)
    );

    reg [15:0] alu_arg_0, alu_arg_1;
    reg alu_load_en_prev;

    always @(posedge CLOCK_50) begin
        alu_load_en_prev <= alu_load_en;
        if (alu_load_en_prev) begin
            alu_arg_0 <= BUS;
            alu_arg_1 <= alu_arg_0;
        end
    end

    alu alu(
        .arg_0(alu_arg_0),
        .arg_1(alu_arg_1),
        .operation(alu_instruction_select),   // use CU select, not raw decoded
        .result(TEMP_ALU_OUT)
    );

    // ALU result → BUS via tristate
    tristate_buffer_16bit alu_tri(
        .a(TEMP_ALU_OUT),
        .b(BUS),
        .enable(alu_result_tri)
    );

    // Immediate value → BUS via tristate
    tristate_buffer_16bit imm_tri(
        .a(immediate_val),
        .b(BUS),
        .enable(immediate_tri)
    );

    // Flag unit and status register
    gle flag_unit(
        .difference(TEMP_ALU_OUT),   // flags computed from ALU output
        .r(flags)
    );

    sreg status_reg(
        .difference(flags),
        .clk(CLOCK_50),
        .rst(reset),
        .write_e(alu_result_en),
        .Q(TEMP_REG_STAT_OUT)
    );

    register_file register_file(
        .d(BUS),
        .clk(CLOCK_50),
        .rst(reset),
        .write_addr(register_en),
        .write_en(register_write),
        .read_addr(register_tri),
        .Q(TEMP_REG_INT)
    );

    // Register file output → BUS via tristate
    tristate_buffer_16bit reg_tri(
        .a(TEMP_REG_INT),
        .b(BUS),
        .enable(reg_read_en)
    );

    ram ram(
        .address(memory_addr),
        .data(BUS),
        .chip_sel(chip_sel),
        .write_en(memory_write_en),
        .read_en(memory_read_en)
    );

    decoder dec(
        .raw_binary_instruction(raw_instruction),
        .enable(one_hot_enable),
        .decoded_instruction(decoded_instruction),
        .out_arg_1(argument_1),
        .out_arg_2(argument_2)
    );

    rom rom(
        .address(pc_out),
        .instruction(raw_instruction)
    );

endmodule