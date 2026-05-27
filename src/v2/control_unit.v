module control_unit ( 
    // Reset (async)
    input reset,

    //One Hot Enable
    output reg          one_hot_enable,

	//Decoded Instruction
    input clk,
    input [5:0]         instruction,
    input [4:0]         argument_1, argument_2,
    
    //Register Signal
    output reg [4:0]    register_tri,
    output reg [4:0]    register_en,
    output reg          register_write,
    output reg          reg_read_en,

	//Immediate Loading Signals 
	output reg			immediate_en,
	output reg   		immediate_tri,
	output reg [15:0]	immediate_val,
    
    //Alu Signals
    output reg          alu_load_en,
    output reg			alu_result_en,
	output reg			alu_result_tri,
    output reg [5:0]    alu_instruction_select,
    
    //Memory Signals
    output reg          memory_read_en,
    output reg          memory_write_en,
    
    output reg [4:0]    memory_addr,

    output [4:0]        pc_out,

    //Stat reg flags
    input [2:0]         status_flags

);

/***************************************************************************
   OPERATIONS; 6 BIT BINARY ENCODINGS - up to 64 instructions
 -------------------------------------------------------------------------
   | COMPONENT   | MSB   |
   -----------------------
   | ALU         | 00    |
   | MEMORY      | 01    |
   | BRANCHES    | 11    |
 --------------------------------------------------------------------------*/
    localparam      ADD     = 6'b000000,        
                    SUB     = 6'b000001,
                    INC     = 6'b000011,
                    DEC     = 6'b000100,
                    LSR     = 6'b000101,
                    LSL     = 6'b000110,
                    XOR     = 6'b001000,
                    AND     = 6'b001001,
                    NOR     = 6'b001010,
                    NOT     = 6'b001011,
                    OR      = 6'b001100, //11

                    LDI     = 6'b010000,
                    LD      = 6'b010001,
                    ST      = 6'b010010,
                    MOV     = 6'b010011, //15
        
                    JMP     = 6'b110000,
                    JE      = 6'b110001,
                    JG      = 6'b110010,
                    JL      = 6'b110100,
                    CP      = 6'b110011; //20

/***************************************************************************
   FSM STATES; 4 BIT BINARY ENCODINGS - up to 16 states
 -------------------------------------------------------------------------*/
 
	localparam      IDLE                        = 4'b0000,
                    LOAD_BUS                    = 4'b0001,
					LOAD_1                      = 4'b0010, 
					LOAD_2                      = 4'b0011,
					UPDATE_PC                   = 4'b0100,
					LOAD_LITERAL                = 4'b0101,
					STORE_REGISTER              = 4'b0110,
					SEND_INSTRUCTION_SIGNALS    = 4'b0111;
				
/***************************************************************************
   SEQUENTIAL LOGIC
 -------------------------------------------------------------------------*/
 
	reg [3:0]   clock_counter;
	reg [3:0]   current_state, next_state; 

    reg     [5:0] latched_instruction;
    reg     [4:0] latched_arg1, latched_arg2;
	
   always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_state       <= IDLE;
            clock_counter       <= 0;

            latched_instruction <= 0;
            latched_arg1        <= 0;
            latched_arg2        <= 0;

        end else begin
            current_state <= next_state;

            if (current_state != next_state)
                clock_counter <= 0;
            else
                clock_counter <= clock_counter + 1;

            // latch fetched instruction
            if (current_state == IDLE) begin
                latched_instruction <= instruction;
                latched_arg1        <= argument_1;
                latched_arg2        <= argument_2;
            end
        end
    end

    //Program Counter
    reg         increment_program_counter;
    reg         branch_en;
    reg     [4:0]   branch_addr;
    wire    [4:0]  instruction_addr;

    pc pc(
        .clk(clk),             
        .enable(increment_program_counter),          
        .branch_en(branch_en),     
        .branch_addr(branch_addr), 
        .reset(reset),
        .pc(instruction_addr)
    );

    assign pc_out = instruction_addr;

/***************************************************************************
   OUTPUT LOGIC
 -------------------------------------------------------------------------*/

always @(*) begin
    // pulse defaults
    one_hot_enable            = 0;
    register_write            = 0;
    reg_read_en               = 0;
    alu_load_en               = 0;
    alu_result_en             = 0;
    alu_result_tri            = 0;
    immediate_en              = 0;
    immediate_tri             = 0;
    memory_read_en            = 0;
    memory_write_en           = 0;
    increment_program_counter = 0;
    branch_en                 = 0;

    next_state = current_state;

    if (reset) begin
        // clear held-value signals explicitly in output block
        register_en            = 5'b0;
        register_tri           = 5'b0;
        immediate_val          = 16'b0;
        alu_instruction_select = 6'b0;
        memory_addr            = 5'b0;
        branch_addr            = 5'b0;
    end else begin
        case (current_state)

        IDLE: begin
            one_hot_enable      = 1'b1;


				case (instruction)
					ADD, SUB, AND, XOR, NOR, OR, CP: next_state = LOAD_2;
					INC, DEC, LSL, LSR, NOT:         next_state = LOAD_1;
					LDI:                             next_state = LOAD_LITERAL;
                    LD, ST:                          next_state = LOAD_BUS;
					default:                         next_state = SEND_INSTRUCTION_SIGNALS;
				endcase
			end
			
			LOAD_1: begin
                if (clock_counter == 4'b0000) begin
                    one_hot_enable = 1'b1;
                    register_tri   = latched_arg1;
                    reg_read_en    = 1'b1;

                end else if (clock_counter == 4'b0001) begin
                    reg_read_en    = 1'b1;
                    alu_load_en    = 1'b1;

                end else if (clock_counter == 4'b0010) begin
                    reg_read_en    = 1'b1;         // hold while prev fires

                end else begin
                    one_hot_enable = 1'b0;
                    next_state     = SEND_INSTRUCTION_SIGNALS;
                end
            end
			

            LOAD_2: begin // CHRISTINE: skriv om til å matche resten 

                if (clock_counter == 0) begin
                    register_tri = latched_arg1;
                    reg_read_en  = 1'b1;

                end else if (clock_counter == 1) begin
                    register_tri = latched_arg1;
                    reg_read_en  = 1'b1;

                end else if (clock_counter == 2) begin
                    register_tri = latched_arg1;
                    reg_read_en  = 1'b1;
                    alu_load_en  = 1'b1;

                end else if (clock_counter == 3) begin
                    register_tri = latched_arg2;
                    reg_read_en  = 1'b1;

                end else if (clock_counter == 4) begin
                    register_tri = latched_arg2;
                    reg_read_en  = 1'b1;

                end else if (clock_counter == 5) begin
                    register_tri = latched_arg2;
                    reg_read_en  = 1'b1;
                    alu_load_en  = 1'b1;

                end else begin
                    next_state = SEND_INSTRUCTION_SIGNALS;
                end
            end
			// LOAD_2: begin
            //     if (clock_counter == 4'b0000) begin
            //         one_hot_enable = 1'b1;
            //         register_tri   = latched_arg2;
            //         reg_read_en    = 1'b1;         // put arg2 on BUS

            //     end else if (clock_counter == 4'b0001) begin
            //         reg_read_en    = 1'b1;         // hold arg2
            //         alu_load_en    = 1'b1;         // signal to latch

            //     end else if (clock_counter == 4'b0010) begin
            //         reg_read_en    = 1'b1;         // hold arg2 while prev fires
            //         register_tri   = latched_arg1;   // switch to arg1

            //     end else if (clock_counter == 4'b0011) begin
            //         reg_read_en    = 1'b1;         // put arg1 on BUS
            //         alu_load_en    = 1'b1;         // signal to latch

            //     end else if (clock_counter == 4'b0100) begin
            //         reg_read_en    = 1'b1;         // hold arg1 while prev fires

            //     end else begin
            //         one_hot_enable = 1'b0;
            //         next_state     = SEND_INSTRUCTION_SIGNALS;
            //     end
            // end
			
			LOAD_LITERAL: begin // puts the value onto the bus
				if (clock_counter == 4'b0000) begin
                    
					immediate_val = {11'b0, latched_arg2};
					immediate_en  = 1'b1;              
					
				end else if (clock_counter == 4'b0001) begin

					// T1 immediate_en  = 1'b0;
					immediate_tri = 1'b1;          // drive BUS with immediate

				end else begin 
                    immediate_tri = 1'b1;          // hold BUS stable for STORE_REGISTER
					next_state    = SEND_INSTRUCTION_SIGNALS;
				end
			end

            LOAD_BUS: begin
                case (latched_instruction)
                    LD: begin // puts the memory onto the bus

                        if (clock_counter == 4'b0000) begin
                            memory_addr    = latched_arg2;
                            memory_read_en = 1'b1;
                                                        
                        end else begin
                            next_state = SEND_INSTRUCTION_SIGNALS;
                        end
                        
                    end 
                    default: begin // puts register onto the bus

                        if (clock_counter == 4'b0000) begin
                            memory_addr     = latched_arg2;
                            register_tri    = latched_arg1;
                            memory_write_en = 1'b1;
                            
                        end else begin
                            next_state = SEND_INSTRUCTION_SIGNALS;
                        end

                    end
                endcase
            end
			
			SEND_INSTRUCTION_SIGNALS: begin
                case (latched_instruction)
                    ADD, SUB, XOR, AND, NOR, OR, INC, DEC, LSL, LSR, NOT: begin
                        if (clock_counter == 4'b0000) begin
                            alu_instruction_select = latched_instruction;
                            alu_result_en          = 1'b1; 

                        end else if (clock_counter == 4'b0001) begin

                            alu_result_tri = 1'b1;     // drive BUS with ALU result

                        end else begin

                            alu_result_tri = 1'b1;     // hold BUS stable for STORE_REGISTER
                            next_state     = STORE_REGISTER;

                        end
                    end
                    LDI: begin
                        immediate_tri = 1'b1;
                        next_state = STORE_REGISTER;
                    end

                    LD: begin
                        memory_read_en = 1'b1;
                        next_state = STORE_REGISTER;
                    end
                    ST: begin
                        next_state = UPDATE_PC;
                    end
                    CP: begin 
                        if (clock_counter == 4'b0000) begin
                            alu_instruction_select = latched_instruction;
                            alu_result_en          = 1'b1;     // only CP writes flags
                        end else begin
                            next_state = UPDATE_PC;
                        end
                    end
                    JMP: begin
                        branch_addr = latched_arg1;
                        branch_en   = 1'b1;
                        next_state  = UPDATE_PC;
                    end

                    // need stat reg input
                    JE: begin
                        if (status_flags[2]) begin  // FLAG_ZERO
                            branch_addr = latched_arg1;
                            branch_en   = 1'b1;
                        end
                        next_state = UPDATE_PC;
                    end
                    JG: begin
                        if (status_flags[0]) begin  // FLAG_GT
                            branch_addr = latched_arg1;
                            branch_en   = 1'b1;
                        end
                        next_state = UPDATE_PC;
                    end
                    JL: begin
                        if (status_flags[1]) begin  // FLAG_LT
                            branch_addr = latched_arg1;
                            branch_en   = 1'b1;
                        end
                        next_state = UPDATE_PC;
                    end
                endcase
			end
			
			STORE_REGISTER: begin
                if (clock_counter == 4'b0000) begin
                    register_en    = latched_arg1;   // destination register address
                end else if (clock_counter == 4'b0001) begin
                    register_write = 1'b1;         // write BUS into register
                    case (latched_instruction)          // write imm to BUS if load
                        LDI: immediate_tri = 1'b1;
                        LD : memory_read_en = 1'b1;
                        default: begin 
                            alu_result_tri = 1'b1; 
                            immediate_tri = 1'b0;  
                            reg_read_en = 1'b0; 
                            memory_write_en = 1'b0; 
                            memory_read_en= 1'b0; end
                    endcase

				end else begin
					next_state = UPDATE_PC;
				end
			end

			UPDATE_PC: begin
				if (clock_counter == 4'b0000) begin
                    // clear bus drivers before incrementing PC
                    alu_result_tri = 1'b0;
                    immediate_tri  = 1'b0;
                    reg_read_en = 1'b0; 
                    memory_write_en = 1'b0; 
                    memory_read_en= 1'b0; 
					increment_program_counter = 1'b1;  // pulse PC for one cycle

				end else begin
					increment_program_counter = 1'b0;
					next_state                = IDLE;
				end
			end

		endcase
	end
end

endmodule