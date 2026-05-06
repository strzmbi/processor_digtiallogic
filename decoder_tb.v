module decoder_tb();

initial begin
    $dumpfile("function.vcd");
    $dumpvars(0, decoder_tb);
    instruction = 16'h000;
    count = 4'b0000;
    #1000

    $finish;
end

always begin
    #5 count = count +1; 
end

decoder d(
    .raw_binary_instruction(instruction),
    .enable(1'b1),
    .decoded_instruction(decoded_instruction),
    .out_arg_1(argument_1), .out_arg_2(argument_2)
);

reg[3:0] count;
reg [15:0] instruction;
wire [5:0] decoded_instruction;
wire [4:0] argument_1, argument_2;

always @(*) begin
    case (count)
        4'b0000: begin instruction = 16'hA122; end
        4'b0001: begin instruction = 16'hA231; end
        4'b0010: begin instruction = 16'hA562; end
        4'b0011: begin instruction = 16'hA121; end
        default: begin instruction = 16'hA421; end
    endcase
end

endmodule