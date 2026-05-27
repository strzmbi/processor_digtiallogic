module gle(difference, r);
    input[15:0] difference;
    output reg[2:0] r;

    always @(difference) begin
        if (difference == 3'b000) begin
            r = 3'b001;
        end else begin
            if (difference[15] == 1'b0) begin
                r = 3'b010;
            end else begin
                r = 3'b100;
            end
        end
    end
    
endmodule


// // module gle(difference, overflow, r);
// module gle(difference, r);
//     input[15:0] difference;
//     // input overflow;
//     output reg[15:0] r;

//     always @(difference or overflow) begin
//         if (difference == 15'b000000000000000) begin
//             r = 3'b001;
//         end else begin
//             if (difference[15] == 1'b0) begin
//                 r = 3'b010;
//             end else begin
//                 r = 3'b100;
//             end
//         end
//     end
    
// endmodule