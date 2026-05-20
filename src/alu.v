module alu(
    input  [4:0] A, B,
    input  [5:0] ALUop,
    output reg [4:0] Result
);

always @(*) begin
    case (ALUop)
        3'b000: Result = A + B;     // ADD
        3'b001: Result = A - B;     // SUB
        3'b010: Result = A + 1;     // INC
        3'b011: Result = A - 1;     // DEC
        3'b100: Result = A >> 1;    // LSR
        3'b101: Result = A << 1;    // LSL
        3'b110: Result = A ^ B;     // XOR 
        3'b111: Result = A & B;     // AND
        3'b011: Result = ~(A | B);  // NOR
        3'b101: Result = ~A;        // NOT
        3'b110: Result = A | B;     // OR
        default: Result = 0;
    endcase
end

endmodule



