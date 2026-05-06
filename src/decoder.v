module decoder(

    input [15:0]            raw_binary_instruction,
    input                   enable,
    output reg [5:0]        decoded_instruction,
    output wire [4:0]        out_arg_1, out_arg_2

);

wire [3:0]      CIRCUIT;
wire [3:0]      INSTRUCTION;
wire [3:0]      ARG1;
wire [3:0]      ARG2;

/***************************************************************************
   COMPONENT UNIT; upper prefix bits, makes it easier for when debugging
 -------------------------------------------------------------------------*/
localparam  ALU         = 2'b00,
            MEMORY      = 3'b010,
            BRANCH      = 3'b110,
            PADDING3    = 3,
            PADDING4    = 4;

/***************************************************************************
   INSTRUCTION; lower suffix bits
 -------------------------------------------------------------------------*/
localparam      ADD     = 4'b0000,        
                SUB     = 4'b0001,
                INC     = 4'b0011,
                DEC     = 4'b0100,
                LSR     = 4'b0101,
                LSL     = 4'b0110,
                XOR     = 4'b1000,
                AND     = 4'b1001,
                NOR     = 4'b1010,
                NOT     = 4'b1011,
                OR      = 4'b1100,

                LDI     = 3'b000,
                LD      = 3'b001,
                ST      = 3'b010,
                MOV     = 3'b011,
    
                JMP     = 3'b000,
                JE      = 3'b001,
                JG      = 3'b010,
                JL      = 3'b100,
                CP      = 3'b011;

assign {CIRCUIT, INSTRUCTION, ARG1, ARG2} = raw_binary_instruction; 
assign out_arg_1 = ARG1; 
assign out_arg_2 = ARG2; 

always @(*) begin
    decoded_instruction = 6'b0; /* Default when the enable is off */
    if (enable) begin
        case (CIRCUIT) 
            4'HA: begin        /* ALU */ 
                case (INSTRUCTION)
                    4'H1: begin    decoded_instruction = {ALU, ADD};    end
                    4'H2: begin    decoded_instruction = {ALU, SUB};    end
                    4'H3: begin    decoded_instruction = {ALU, INC};    end
                    4'H4: begin    decoded_instruction = {ALU, DEC};    end
                    4'H5: begin    decoded_instruction = {ALU, LSR};    end
                    4'H6: begin    decoded_instruction = {ALU, LSL};    end
                    4'H7: begin    decoded_instruction = {ALU, XOR};    end
                    4'H8: begin    decoded_instruction = {ALU, AND};    end
                    4'H9: begin    decoded_instruction = {ALU, NOR};    end
                    4'HA: begin    decoded_instruction = {ALU, NOT};    end
                    4'HB: begin    decoded_instruction = {ALU, OR};     end
                endcase
            end
            4'HD: begin         /* MEMORY */ 
                case (INSTRUCTION)
                    4'H1: begin   decoded_instruction = {MEMORY, LDI};  end
                    4'H2: begin   decoded_instruction = {MEMORY, LD};   end
                    4'H3: begin   decoded_instruction = {MEMORY, ST};   end
                    4'H4: begin   decoded_instruction = {MEMORY, MOV};  end
                endcase
            end
            4'HC: begin         /* BRANCH */ 
                case (INSTRUCTION)
                    4'H1: begin    decoded_instruction = {BRANCH, JMP};   end
                    4'H2: begin    decoded_instruction = {BRANCH, JE};    end
                    4'H3: begin    decoded_instruction = {BRANCH, JG};    end
                    4'H4: begin    decoded_instruction = {BRANCH, JL};    end
                    4'H5: begin    decoded_instruction = {BRANCH, CP};    end
                endcase
            end
            default: begin       decoded_instruction = 6'b0;    end
        endcase
    end
end

endmodule