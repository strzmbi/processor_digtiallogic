module top_level(
    input [9:0]SW,
    input CLOCK_50

    ); 

    assign reset = SW[0];
    
    reg[15:0] BUS;
    reg[15:0] TEMP_REG_INT;
    reg[15:0] TEMP_REG_STAT_IN;
    reg[15:0] TEMP_REG_STAT_OUT;
    reg[15:0] not_q;

    // Reset (async)
    wire reset;

	//Decoded Instruction
    wire [15:0]         raw_instruction;
    wire [5:0]         decoded_instruction;
    wire [4:0]         argument_1, argument_2;
    wire [4:0]          pc_out;

    wire one_hot_enable;
    
    //Register Signal
     reg [4:0]    register_tri;
     reg [4:0]    register_en;
     wire register_write;

	//Immediate Loading Signals 
	 reg		immediate_en;
	 reg   		immediate_tri;
	 reg [15:0]	immediate_val;
    
    //Alu Signals
     reg          alu_load_en;
     reg			alu_result_en;
	 reg			alu_result_tri;
     reg [5:0]    alu_instruction_select;
     wire          reg_read_en;
    
    //Memory Signals
     wire         chip_sel;
     reg         memory_read_en;
     reg         memory_write_en;
    
     reg [4:0]   memory_addr;
    
    //Program Counter
     reg         increment_program_counter;
     reg         branch_en;
     reg [4:0]   branch_addr;
     reg [31:0] instruction_addr;

     assign chip_sel = memory_read_en | memory_write_en;        // ram enable

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

        .increment_program_counter(increment_program_counter),
        .branch_en(branch_en),
        .branch_addr(branch_addr), 

        .pc_out(pc_out)
        );


    // We need to connect alu like the diagram 

    reg [15:0] alu_arg_0, alu_arg_1;

    always @(posedge CLOCK_50) begin
        if (alu_load_en) begin
            alu_arg_0 <= alu_arg_1; 
            alu_arg_1 <= BUS;
        end
    end   

    alu alu(
        .arg_0(alu_arg_0),
        .arg_1(alu_arg_1),
        .operation(decoded_instruction),
        .result(TEMP_REG_STAT_IN)
    );

    // register register(
    //     .d(),
    //    .clk(CLOCK_50),
    //    .rst(reset),
    //    .write_e(register_en),
    //    .Q(TEMP_REG_INT),
    //    .notQ(not_q)
    //  );
     register_file register_file(
        .d(BUS),
        .clk(CLOCK_50), 
        .rst(reset),
        .write_addr(register_en),   // from register_en
        .write_en(register_write),     //  enable
        .read_addr(register_tri),    // from register_tri
        .Q(TEMP_REG_INT)
    );

    tristate_buffer_16bit reg_tri(
        .a(TEMP_REG_INT),
        .b(BUS),
        .enable(reg_read_en)
     );

    sreg status_reg(
        .difference(TEMP_REG_STAT_IN),
        .clk(CLOCK_50),
        .rst(reset),
        .write_e(1),
        .Q(TEMP_REG_STAT_OUT),
        .notQ(not_q)
     );

    ram ram(
        .address(memory_addr), 
        .data(BUS),                            // Data bi-directional
        .chip_sel(chip_sel),                       // Chip Select
        .write_en(memory_write_en),                       // Write Enable/Read Enable
        .read_en(memory_read_en)                        // Output Enable
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