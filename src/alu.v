module alu(
    input[15:0] arg_0, arg_1,
    input [5:0] operation,
    output reg [15:0] result
);

always @(*) begin
    case (operation)
        6'b000000: result = arg_0 + arg_1;     // arg_0DD
        6'b000001: result = arg_0 - arg_1;     // SUB
        6'b000011: result = arg_0 + 1;     // INC
        6'b000100: result = arg_0 - 1;     // DEC
        6'b000101: result = arg_0 >> 1;    // LSR
        6'b000110: result = arg_0 << 1;    // LSL
        6'b001000: result = arg_0 ^ arg_1;     // XOR 
        6'b001001: result = arg_0 & arg_1;     // AND
        6'b001010: result = ~(A | arg_1);  // NOR
        6'b001011: result = ~A;        // NOT
        6'b001100: result = A | arg_1;     // OR
        default: result = 0;
    endcase
end

endmodule
