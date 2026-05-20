module decoder(

    input [15:0]            raw_binary_instruction,
    input                   enable,
    output wire [5:0]        decoded_instruction,
    output wire [4:0]        out_arg_1, out_arg_2

);

wire [1:0]      CIRCUIT;
wire [3:0]      INSTRUCTION;
wire [4:0]      ARG1;
wire [4:0]      ARG2;

/***************************************************************************
   COMPONENT UNIT; upper prefix bits, makes it easier for when debugging
 -------------------------------------------------------------------------*/
localparam  COMP_ALU    = 2'b00,
            COMP_MEM    = 2'b01,
            COMP_BRANCH = 2'b11;

/***************************************************************************
   INSTRUCTION; lower suffix bits
 -------------------------------------------------------------------------*/
localparam  // ALU
            ADD = 4'b0000,
            SUB = 4'b0001,
            INC = 4'b0010,
            DEC = 4'b0011,
            LSR = 4'b0100,
            LSL = 4'b0101,
            XOR = 4'b0110,
            AND = 4'b0111,
            NOR = 4'b1000,
            NOT = 4'b1001,
            OR  = 4'b1010,
            // MEMORY
            LDI = 4'b0000,
            LD  = 4'b0001,
            ST  = 4'b0010,
            MOV = 4'b0011,
            // BRANCH
            JMP = 4'b0000,
            JE  = 4'b0001,
            JG  = 4'b0010,
            JL  = 4'b0011,
            CP  = 4'b0100;

assign {CIRCUIT, INSTRUCTION, ARG1, ARG2} = raw_binary_instruction; 
assign out_arg_1 = ARG1; 
assign out_arg_2 = ARG2; 

// always @(*) begin
//     decoded_instruction = 6'b0; /* Default when the enable is off */
//     if (enable) begin
//         case (CIRCUIT[3:2]) // Only top 2 bits
//             4'HA: begin        /* ALU */ 
//                 case (INSTRUCTION)
//                     4'H1: begin    decoded_instruction = {ALU, ADD};    end
//                     4'H2: begin    decoded_instruction = {ALU, SUB};    end
//                     4'H3: begin    decoded_instruction = {ALU, INC};    end
//                     4'H4: begin    decoded_instruction = {ALU, DEC};    end
//                     4'H5: begin    decoded_instruction = {ALU, LSR};    end
//                     4'H6: begin    decoded_instruction = {ALU, LSL};    end
//                     4'H7: begin    decoded_instruction = {ALU, XOR};    end
//                     4'H8: begin    decoded_instruction = {ALU, AND};    end
//                     4'H9: begin    decoded_instruction = {ALU, NOR};    end
//                     4'HA: begin    decoded_instruction = {ALU, NOT};    end
//                     4'HB: begin    decoded_instruction = {ALU, OR};     end
//                 endcase
//             end
//             4'HD: begin         /* MEMORY */ 
//                 case (INSTRUCTION)
//                     4'H1: begin   decoded_instruction = {MEMORY, LDI};  end
//                     4'H2: begin   decoded_instruction = {MEMORY, LD};   end
//                     4'H3: begin   decoded_instruction = {MEMORY, ST};   end
//                     4'H4: begin   decoded_instruction = {MEMORY, MOV};  end
//                 endcase
//             end
//             4'HC: begin         /* BRANCH */ 
//                 case (INSTRUCTION)
//                     4'H1: begin    decoded_instruction = {BRANCH, JMP};   end
//                     4'H2: begin    decoded_instruction = {BRANCH, JE};    end
//                     4'H3: begin    decoded_instruction = {BRANCH, JG};    end
//                     4'H4: begin    decoded_instruction = {BRANCH, JL};    end
//                     4'H5: begin    decoded_instruction = {BRANCH, CP};    end
//                 endcase
//             end
//             default: begin       decoded_instruction = 6'b0;    end
//         endcase
//     end
// end

assign decoded_instruction = enable ? {CIRCUIT, INSTRUCTION} : 6'b0;

endmodule