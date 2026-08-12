module alu_top32 (
    input  [31:0] a,
    input  [31:0] b,
    input  [3:0]  opcode,
    output reg [31:0] alu_out
);
    wire [31:0] ksa_sum;
    wire [31:0] logic_and_out;
    wire [31:0] logic_or_out;
    wire [31:0] logic_xor_out;
    wire ksa_cout;

    // For subtraction
    wire is_sub = (opcode == 4'b0010);          
    wire [31:0] b_in = is_sub ? ~b : b;         
    wire cin_in = is_sub ? 1'b1 : 1'b0;         


    ksa32 u_ksa (
        .in_a   (a),
        .in_b   (b_in),
        .in_cin (cin_in),
        .out_s  (ksa_sum),
        .out_cout(ksa_cout)
    );

   
    logic_unit32 u_logic (
        .in_a   (a),
        .in_b   (b),
        .out_and(logic_and_out),
        .out_or (logic_or_out),
        .out_xor(logic_xor_out)
    );

    always @(*) begin
        case (opcode)
            4'b0100: alu_out = ksa_sum;        // ADD
            4'b0010: alu_out = ksa_sum;        // SUB
            4'b0000: alu_out = logic_and_out; // AND
            4'b1100: alu_out = logic_or_out;  // ORR
            4'b0001: alu_out = logic_xor_out; // EOR
            default: alu_out = 32'b0;
        endcase
    end

endmodule