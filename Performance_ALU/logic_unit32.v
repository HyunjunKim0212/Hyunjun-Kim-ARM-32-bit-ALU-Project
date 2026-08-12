module logic_unit32 (in_a, in_b, out_and, out_or, out_xor);
    input [31:0] in_a, in_b;
    output [31:0] out_and, out_or, out_xor;

    assign out_and = in_a & in_b;
    assign out_or = in_a | in_b;
    assign out_xor = in_a ^ in_b;
    
endmodule