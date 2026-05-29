/* COMPILE

*/
module fpga_top (

    input CLOCK_50,
    input [9:0] SW,
    input [3:0] KEY,

    output [9:0] LEDR,
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5,
    output [6:0] HEX6,
    output [6:0] HEX7
);

wire reset;
assign reset = ~KEY[0];   // pushbutton reset
assign LEDR = {5'b0, pc_out};

// Example instruction ROM outputs
reg [5:0] instruction;
reg [4:0] arg1;
reg [4:0] arg2;
wire slow_clk;

// CPU outputs
wire [4:0] pc_out;
wire [2:0] TEMP_REG_STAT_OUT;
wire [15:0] BUS;

// Instantiate your CPU
cpu_fpga cpu (
    .clk(CLOCK_50),
    .reset(reset),
    .decoded_instruction(instruction),
    .argument_1(arg1),
    .argument_2(arg2),
    .pc_out(pc_out),
    .TEMP_REG_STAT_OUT(TEMP_REG_STAT_OUT),
    .BUS(BUS)
);

always @(*) begin
    case (pc_out)

        // R1 = 5
        5'd0: begin
            instruction = 6'b010000; // LDI
            arg1 = 5'd1;
            arg2 = 5'd5;
        end

        // R2 = 6
        5'd1: begin
            instruction = 6'b010000; // LDI
            arg1 = 5'd2;
            arg2 = 5'd6;
        end

        // R1 = R1 + R2
        5'd2: begin
            instruction = 6'b000000; // ADD
            arg1 = 5'd1;
            arg2 = 5'd2;
        end

        default: begin
            instruction = 0;
            arg1 = 0;
            arg2 = 0;
        end
    endcase
end

counter clk_divider(
    .CLOCK(CLOCK_50),
    .reset(reset),
    .pulse(slow_clk)
);

hex_decoder h0(
    .bin(pc_out[3:0]),
    .seg(HEX0)
);
hex_decoder h1(
    .bin({3'b000, pc_out[4]}),
    .seg(HEX1)
);

hex_decoder h2(
    .bin(BUS[3:0]),
    .seg(HEX2)
);

hex_decoder h3(
    .bin(BUS[7:4]),
    .seg(HEX3)
);

hex_decoder h4(
    .bin(BUS[11:8]),
    .seg(HEX4)
);

hex_decoder hex_bus3(
    .bin(BUS[15:12]),
    .seg(HEX5)
);

// CPU outputs
hex_decoder h6(
    .bin(instruction[3:0]),
    .seg(HEX6)
);

hex_decoder h7(
    .bin({2'b00, instruction[5:4]}),
    .seg(HEX7)
);


assign LEDR[9] = TEMP_REG_STAT_OUT[0]; // GT
assign LEDR[8] = TEMP_REG_STAT_OUT[1]; // LT
assign LEDR[7] = TEMP_REG_STAT_OUT[2]; // EQ
assign LEDR[5] = slow_clk;



endmodule