
module counter_fsm ( input CLOCK_50, input [3:0] KEY, input [9:0] SW, output [6:0] HEX0, output reg [9:0] LEDR );

    reg[3:0] seconds_counted;
    hex_decoder display (.hex_digits(seconds_counted), .segments(HEX0));

    reg reset;
    wire pulse;
    counter clock_pacer(.CLOCK(CLOCK_50), .pulse(pulse), .reset(reset));

    localparam RESET_COUNTER = 0;
    localparam COUNT_ONE = 1;
    localparam COUNT_ZERO = 2;
    localparam FINISHED_ZERO = 3;
    localparam FINISHED_ONE = 4;

    reg [4:0] current_state;
    reg [4:0] next_state;
    reg [3:0] number_needed;

    always @(posedge CLOCK_50) begin
        current_state <= next_state;

        if (KEY[3] == 0) begin
            next_state <= RESET_COUNTER;
        end
    end

    always @(posedge CLOCK_50) begin
        case (current_state)
        RESET_COUNTER: begin
                reset <= 1;
                seconds_counted <= 4'd0; 
                number_needed <= SW[9:6];

                if (SW[0] == 1) next_state <= COUNT_ONE;
                if (SW[0] == 0) next_state <= COUNT_ZERO;
            end
        default: begin reset <= 0; end
        endcase
    end

    always @(posedge CLOCK_50) begin
        if (pulse) begin
            case (current_state)
            COUNT_ONE: begin
                seconds_counted <= seconds_counted + 1;

                if (number_needed == seconds_counted) next_state <= FINISHED_ONE;
                if (SW[0] == 0) next_state <= RESET_COUNTER;
            end

            COUNT_ZERO: begin
                seconds_counted <= seconds_counted + 1;

                if (number_needed == seconds_counted) next_state <= FINISHED_ZERO;
                if (SW[0] == 1) next_state <= RESET_COUNTER;
            end

            FINISHED_ZERO: begin
                LEDR <= 10'b1111111111;
                if (SW[0] == 1) next_state <= RESET_COUNTER;
            end

            FINISHED_ONE: begin
                LEDR <= 10'b1111111111;
                if (SW[0] == 0) next_state <= RESET_COUNTER;
            end

            default: begin
                next_state <= RESET_COUNTER;
            end
            endcase
        end
    end
    
endmodule