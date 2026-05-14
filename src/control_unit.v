

module control_unit ( 
	//reset
    input reset
	
	//Decoded Instruction
    input clk;
    input [5:0]         instruction;
    input [4:0]         argument_1, argument_2;
    
    //Register Signal
    output reg [4:0]    register_tri;
    output reg [4:0]    register_en;

	//Immediate Loading Signals 
	output reg			immediate_en;
	output reg   		immediate_tri;
	output reg [15:0]	immediate_val;
    
    //Alu Signals
    output reg          alu_load_en;
    output reg			alu_result_en;
	output reg			alu_result_tri;
    output reg [5:0]    alu_instruction_select;
    
    //Memory Signals
    output reg         memory_read_en;
    output reg         memory_write_en;
    
    output reg [4:0]   memory_read_addr;
	output reg [4:0]   memory_write_addr;
    
    //Program Counter
    output reg         increment_program_counter;
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
                    OR      = 6'b001100,

                    LDI     = 6'b010000,
                    LD      = 6'b010001,
                    ST      = 6'b010010,
                    MOV     = 6'b010011,
        
                    JMP     = 6'b110000,
                    JE      = 6'b110001,
                    JG      = 6'b110010,
                    JL      = 6'b110100,
                    CP      = 6'b110011;
					


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
	reg [3:0]   current_state,  next_state; 
	
    always @(posedge clk) begin
        clock_counter <= clock_counter + 4'd1;
        current_state <= next_state;
    end

	always @(reset) begin
        current_state = IDLE;
        next_state = IDLE;
    end
	
/***************************************************************************
   OUTPUT LOGIC
 -------------------------------------------------------------------------*/

	always @(posedge clk) begin
		case (current_state)
			IDLE: begin
				case (instruction)
					ADD, SUB, XOR, AND, XOR, NOR, OR, CP: next_state <= LOAD_2;
					INC, DEC, LSL, LSR, NOT: next_state <= LOAD_1;
					LDI: next_state <= LOAD_LITERAL;
                    LD, ST: next_state <= LOAD_BUS;
					
					default: next_state <= SEND_INSTRUCTION_SIGNALS;
				endcase
				
				clock_counter <= 4'b0000;
			end
			
			LOAD_1: begin
				if (clock_counter == 4'b0000) begin
					
					register_tri <= argument_1;
					alu_load_en <= 1'd1;
				
				end else begin
				
					alu_load_en <= 1'd0;
					next_state <= SEND_INSTRUCTION_SIGNALS;
                    clock_counter <= 4'b0000;

				end
			end
			
			LOAD_2: begin
				if (clock_counter == 4'b0000) begin
					
					register_tri <= argument_1;
					alu_load_en <= 1'd1;
				
				end else if (clock_counter == 4'b0001) begin
				
					alu_load_en <= 1'd0;
					register_tri <= argument_2;
				
				end else begin
				
					next_state <= SEND_INSTRUCTION_SIGNALS;
					clock_counter <= 4'b0000; 
					
				end
			end
			
			LOAD_LITERAL: begin // puts the value onto the bus
				if (clock_counter == 4'b0000) begin
					
					immediate_val <= argument_1;
					immediate_en <= 1'd1;
					
				end else if (clock_counter == 4'b0001) begin

					immediate_en <= 1'd0;
					immediate_tri <= 1'd1;
					
				end else begin 
					
					next_state <= SEND_INSTRUCTION_SIGNALS;
					clock_counter <= 4'b0000; 

				end
			end

            LOAD_BUS: begin
                case (instruction)
                    LD: begin // puts the memory onto the bus

                        if (clock_counter == 4'b0000) begin // can break with register select
                            
                            memory_read_addr <= argument_2;
                            memory_read_en <= 1'd1;
                                                        
                        end else begin
                            memory_read_en <= 1'd0;

                            next_state <= SEND_INSTRUCTION_SIGNALS;
                            clock_counter <= 4'b0000;
                        end
                        
                    end 
                    default: begin // puts register onto the bus

                        if (clock_counter == 4'b0000) begin // can break with register select

                            memory_write_addr <= argument_2;
                            register_tri <= argument_1;
                            memory_write_en <= 1'd1;
                            
                        end else begin
                            memory_write_en <= 1'd0;

                            next_state <= SEND_INSTRUCTION_SIGNALS;
                            clock_counter <= 4'b0000;
                        end

                    end
                endcase
            end
			
			SEND_INSTRUCTION_SIGNALS: begin
                case (instruction)
                endcase
			end
			
			STORE_REGISTER: begin
                if (clock_counter == 0) begin
                    register_tri <= argument_1;
				end
				else begin
					next_state <= UPDATE_PC;
					clock_counter <= 4'b0000; 
				end
			end
			
			UPDATE_PC: begin
				if (clock_counter == 0) begin
					increment_program_counter <= 1'd1; 
				end
				else begin
					increment_program_counter <= 1'd0;
					next_state <= IDLE;
					clock_counter <= 4'b0000; 
				end
			end
		endcase
	end

endmodule
