module control_unit_tb();

initial begin
    $dumpfile("function.vcd");
    $dumpvars(0, control_unit_tb);
    instruction = 16'h000;
    count = 4'b0000;
    reset = 1;
    arg1 = 5'd0; 
    arg2 = 5'd1; 
    clk = 0; 
    #1000


    $finish;
end

always begin
    #5 count = count +1; 
end


always #5 clk = ~clk;

control_unit_v2 control( 
	// Reset (async)
    .reset(reset),
	
	//Decoded Instruction
    .clk(clk), 
    .instruction(instruction), 
    .argument_1(arg1), 
    .argument_2(arg2),
    
    //Register Signal
    .register_tri(register_tri),
    .register_en(register_en),

	//Immediate Loading Signals 
	.immediate_en(immediate_en),
	.immediate_tri(immediate_tri),
	.immediate_val(immediate_val),
    
    //Alu Signals
    .alu_load_en(alu_load_en),
    .alu_result_en(alu_result_en),
	.alu_result_tri(alu_result_tri),
    .alu_instruction_select(alu_instruction_select),
    
    //Memory Signals
    .memory_read_en(memory_read_en),
    .memory_write_en(memory_write_en),
    
    .memory_read_addr(memory_read_addr),
	.memory_write_addr(memory_write_addr),
    
    //Program Counter
    .increment_program_counter(increment_program_counter)
);

    reg reset;
    reg[3:0] count;
    reg clk; 
    reg [5:0]         instruction; 
    reg [4:0]         arg1;
    reg [4:0]         arg2;
    
    //Register Signal
    wire[4:0]    register_tri;
    wire[4:0]    register_en;

	//Immediate Loading Signals 
	wire			immediate_en;
	wire  		immediate_tri;
	wire[15:0]	immediate_val;
    
    //Alu Signals
    wire         alu_load_en;
    wire			alu_result_en;
	wire			alu_result_tri;
    wire[5:0]    alu_instruction_select;
    
    //Memory Signals
    wire        memory_read_en;
    wire        memory_write_en;
    
    wire[4:0]   memory_read_addr;
	wire[4:0]   memory_write_addr;
    
    //Program Counter

always @(count) begin
    case (count)
        4'b0000: begin instruction = 6'h0; reset = 0; end
        4'b0001: begin instruction = 6'b000001; end
        4'b0010: begin instruction = 6'b000011; end
        4'b0011: begin instruction = 6'b000101; end
        4'b0100: begin instruction = 6'b110000; end
        4'b0101: begin instruction = 6'b010011; end
        4'b0110: begin instruction = 6'b010001; end
        4'b0111: begin instruction = 6'b010010; end
        default: begin instruction = 6'b110000; end
    endcase
end

endmodule