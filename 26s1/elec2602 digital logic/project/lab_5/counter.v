module counter(input CLOCK, output reg pulse, input reset);

reg [25:0] data;
initial data = 25'd0;

always @(posedge CLOCK) begin
    if (reset) begin
        data <= 25'd0;
        pulse <= 0;
    end
end

always @(posedge CLOCK) begin
    if (data == 26'd49000000) begin
        data <= 25'd0;
        pulse <= 1;
    end
    else begin
        data <= data + 1;
        pulse <= 0;
    end
end

endmodule