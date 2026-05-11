module control_unit ( 

    input clk;
    input [5:0]         instruction;
    input [4:0]         argument_1, argument_2;

    output reg          program_counter_signal;
    output reg          result_register_signal;
    output reg          arithmetic_load_signal;
    output reg          memory_store_signal;

    output reg [4:0]    register_select;
    output reg [5:0]    instruction_select;

);

    /*
    //Decoded Instruction
    input clk;
    input [5:0]         instruction;
    input [4:0]         argument_1, argument_2;
    
    //Register Signal
    output reg [4:0]    register_tri;
    output reg [4:0]    register_en;
    
    //Alu Signals
    output reg          alu_load_en;
    output reg			alu_result_tri;
    output reg			alu_result_en;
    output reg [5:0]    alu_instruction_select;
    
    //Memory Signals
    output reg         memory_read_en;
    output reg         memory_write_en;
    
    output reg [4:0]   memory_write_addr;
    output reg [4:0]   memory_read_addr;
    
    //Program Counter
    output reg         increment_program_counter;
    */

/***************************************************************************
   FSM STATES; 3 BIT BINARY ENCODINGS - up to 8 states
 -------------------------------------------------------------------------*/
    localparam      IDLE                        = 3'b000,
                    STORE                       = 3'b001,
                    STORE_REGISTER              = 3'b010, 
                    LOAD_1                      = 3'b011, 
                    LOAD_2                      = 3'b100, 
                    LOAD_LITERAL                = 3'b101, 
                    UPDATE_PC                   = 3'b111,
                    SEND_INSTRUCTION_SIGNALS    = 3'b110;

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
   INITAL STATEMENT
 -------------------------------------------------------------------------*/
    reg [2:0]   current_state,  next_state; 
    reg [3:0]   counter;

    intial begin
        current_state = IDLE;
        next_state = IDLE;
        counter = 4'b0000;
        #10 $finish;
    end

/***************************************************************************
   SEQUENTIAL LOGIC
 -------------------------------------------------------------------------*/
    always @(posedge clk) begin
        counter <= counter + 4'd1;
        current_state <= next_state;
    end

/***************************************************************************
   OUTPUT LOGIC
 -------------------------------------------------------------------------*/
    always @(posedge clk) begin
        case (current_state)
        //decode
        IDLE: begin
            case (instruction)
                ADD, SUB, XOR, AND, XOR, NOR, OR, CP: next_state <= LOAD_2;
                INC, DEC, LSL, LSR, NOT: next_state <= LOAD_1;
                LDI: next_state <= LOAD_LITERAL;
                default: next_state <= SEND_INSTRUCTION_SIGNALS;
            endcase

            counter <= 4'b0000;
        end

        //fetch
        LOAD_1: begin
            if (counter == 4'b0000) begin
                register_select <= argument_1;
                arithmetic_load_signal <= 1'd1;
            end
            else begin
                arithmetic_load_signal <= 1'd0;
                next_state <= SEND_INSTRUCTION_SIGNALS;
                counter <= 4'b0000; 
            end
        end

        LOAD_2: begin
            if (counter == 4'b0000) begin
                register_select <= argument_1;
                arithmetic_load_signal <= 1'd1;         
            end
            else if (counter == 4'b0001) begin
                arithmetic_load_signal <= 1'd0;
                register_select <= argument_2;
            end
            else begin
                next_state <= SEND_INSTRUCTION_SIGNALS;
                counter <= 4'b0000; 
            end
        end

        LOAD_LITERAL: begin
        end

        //execute
        SEND_INSTRUCTION_SIGNALS: begin
            case (instruction)
                ADD, XOR, AND, XOR, NOR, OR, INC, DEC, LSL, NOT: begin
                    instruction_select <= instruction;
                    next_state <= STORE_REGISTER;
                    counter <= 4'b0000; 
                end
                LSR: begin
                    
                end
                CP, SUB: begin
                    
                end
                JMP, JE, JG, JL: begin
                    
                end
                LDI, LD, ST: begin
                    
                end
            endcase
        end

        //store
        STORE: begin
            //program the storing mechanism here.

            next_state <= UPDATE_PC;
            counter <= 4'b0000;
        end

        STORE_REGISTER: begin
            //program the storing mechanism here.

            next_state <= UPDATE_PC;
            counter <= 4'b0000;
        end

        UPDATE_PC: begin
            if (counter == 0) begin
                program_counter_signal <= 1'd1; 
            end
            else begin
                program_counter_signal <= 1'd0;
                next_state <= IDLE;
                counter <= 4'b0000; 
            end
        end

        default: next_state <= IDLE;
        endcase
    end

endmodule

/*
If you are reading this, This video below has a great explaination of how this works:
https://www.youtube.com/watch?v=Aq5WXmQQooo&pp=ygUJcmljayByb2xs
*/
