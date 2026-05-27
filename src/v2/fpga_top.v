/* COMPILE

*/
module de1_soc_top (

    input CLOCK_50,
    input [9:0] SW,
    input [3:0] KEY,

    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1
);

wire reset;
assign reset = ~KEY[0];   // pushbutton reset

// Example instruction ROM outputs
reg [5:0] instruction;
reg [4:0] arg1;
reg [4:0] arg2;

// CPU outputs
wire [4:0] pc_out;

// Instantiate your CPU
cpu_fpga cpu (
    .clk(CLOCK_50),
    .reset(reset),
    .decoded_instruction(instruction),
    .argument_1(arg1),
    .argument_2(arg2),
    .pc_out(pc_out)
);

always @(*) begin
    case (pc_out)

        5'd0: begin
            instruction = 6'b010000; // LDI
            arg1 = 5'b00001;         // R1
            arg2 = 5'd5;
        end

        5'd1: begin
            instruction = 6'b010000; // LDI
            arg1 = 5'b00010;         // R2
            arg2 = 5'd6;
        end

        5'd2: begin
            instruction = 6'b000000; // ADD
            arg1 = 5'b00001;
            arg2 = 5'b00010;
        end

        default: begin
            instruction = 0;
            arg1 = 0;
            arg2 = 0;
        end
    endcase
end

hex_decoder h(
    .bin(pc_out),
    .seg(HEX0)
);

endmodule