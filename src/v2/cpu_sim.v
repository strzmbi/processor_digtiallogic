/* COMPILE
iverilog -o out.vvp control_unit.v alu.v ram.v register_file.v rom.v tristate_buffer_16bit.v tristate_buffer.v sreg.v one_hot.v pc.v decoder.v gle.v output_to_bus.v tb_ldi_add_sub.v cpu_sim.v
*/
module cpu_sim(
    input [9:0] SW,
    input       CLOCK_50
);

always @(posedge CLOCK_50) begin
    $display(
        "t=%0t imm_tri=%b reg_wr=%b reg_en=%b BUS=%h",
        $time,
        immediate_tri,
        register_write,
        register_en,
        BUS
    );
end

    wire reset = SW[0];

    wire [15:0] BUS;
    wire [15:0] TEMP_REG_INT;
    wire [15:0] TEMP_ALU_RES_OUT;
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

    always @(posedge CLOCK_50) begin
        if (alu_load_en > 1'b0) begin
            alu_arg_0 <= alu_arg_1;
            alu_arg_1 <= BUS;
        end
    end

    // one_hot one_hot_decoder(
    //     .out(out),   // Output of the counter
    //     .enable(one_hot_enable),            // enable for counter
    //     .instruction_reg(instruction_reg),  // instruction input
    //     .clk(clk),          // clock input
    //     .reset(reset)        // reset input
    // );


    alu alu_inst(
        .arg_0(alu_arg_0),
        .arg_1(alu_arg_1),
        .operation(alu_instruction_select),
        .result(TEMP_ALU_RES_OUT)
    );

    // ALU result to BUS via tristate
    // tristate_buffer_16bit alu_tri(
    //     .a(TEMP_ALU_RES_OUT),
    //     .b(BUS),
    //     .enable(alu_result_tri)
    // );

    // // Immediate value BUS via tristate
    // tristate_buffer_16bit imm_tri_buf(
    //     .a(immediate_val),
    //     .b(BUS),
    //     .enable(immediate_tri)
    // );
    // Flag unit and status register
    gle flag_unit(
        .difference(TEMP_ALU_RES_OUT),   // flags computed from ALU output
        .r(flags)
    );

    sreg status_reg(
        .difference(flags),
        .clk(CLOCK_50),
        .rst(reset),
        .write_e(alu_result_en),
        .values(TEMP_REG_STAT_OUT)
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

    // Register file output BUS via tristate
    // tristate_buffer_16bit reg_tri(
    //     .a(TEMP_REG_INT),
    //     .b(BUS),
    //     .enable(reg_read_en)
    // );

    wire [15:0] ram_data_out;

    ram ram(
        .address(memory_addr),
        .data_in(BUS),
        .data_out(ram_data_out),
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

    output_to_bus bus_outputs(
        .alu_data(TEMP_ALU_RES_OUT),
        .alu_enable(alu_result_tri),

        .immediate_data(immediate_val),
        .immediate_enable(immediate_tri),

        .register_data(TEMP_REG_INT),
        .register_enable(reg_read_en),

        .memory_data(ram_data_out),
        .memory_enable(memory_read_en),

        .BUS(BUS)
    );





endmodule