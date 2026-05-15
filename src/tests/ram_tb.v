`timescale 1ns / 1ps
module ram_tb();

reg[3:0] count;
initial begin
    $dumpfile("function.vcd");
    $dumpvars(0, ram_tb);
    count = 4'b0000;
    #1000

    $finish;
end

always begin
    #5 count = count +1; 
end

parameter   DATA_WIDTH      = 16   ;
parameter   ADDR_WIDTH      = 4    ;

reg [ADDR_WIDTH-1:0]    address ;   // Address reg
reg [DATA_WIDTH-1:0]   data    ;   // Data bi-directional
wire [DATA_WIDTH-1:0]   data_out    ;   // Data bi-directional
reg                     cs_en      ;   // Chip Select
reg                     w_en      ;   // Write Enable/Read Enable
reg                     r_en      ;   // Output Enable  

ram d(
    .address(   address ),
    .data   (   data    ),
    .cs_en  (   cs_en      ),
    .w_en   (   w_en      ), 
    .r_en   (   r_en      ),
    .data_tri(  data_out)
);

always @(*) begin
    case (count)
        4'b0000: begin address = 4'b0000; data = 16'hAAAA; cs_en = 1'b1; w_en = 1'b1; r_en = 1'b0; end
        4'b0001: begin address = 4'b0000; data = 16'hAAAA; cs_en = 1'b1; w_en = 1'b0; r_en = 1'b1; end
        4'b0010: begin address = 4'b0001; data = 16'hAAAA; cs_en = 1'b1; w_en = 1'b0; r_en = 1'b1; end
        4'b0010: begin address = 4'b0001; data = 16'hAAAA; cs_en = 1'b0; w_en = 1'b0; r_en = 1'b1; end
        4'b0010: begin address = 4'b0001; data = 16'hAAAA; cs_en = 1'b0; w_en = 1'b0; r_en = 1'b1; end
        default: begin address = 4'b0001; data = 16'hAAAA; cs_en = 1'b1; w_en = 1'b1; r_en = 1'b0; end
    endcase
end

endmodule