module pc(
    input clk,              // clock input
    input enable,           // enable for counter
    input branch_en,        // branching enabler
    input[4:0] branch_addr, // branch address
    input reset,            // reset input
    output reg[4:0] pc     
);

always @(posedge clk or posedge reset) begin
    if (reset) begin
        pc <= 5'b0;            /* reset to start address */ 
    end else if (enable) begin
            if (branch_en) begin
                pc <= branch_addr;
            end else begin
                pc <= pc + 1; 
            end
        end 
end

endmodule