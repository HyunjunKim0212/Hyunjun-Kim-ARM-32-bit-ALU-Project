# 32-bit ARM-based ALU Architecture Design & ASIC Implementation

Personal hardware design project implementing a high-performance 32-bit Arithmetic Logic Unit (ALU) based on the ARM instruction set architecture (ISA). 

## Project Overview & Objectives
The goal of this project is to gain hands-on experience in high-speed digital circuit design and complete an ASIC implementation flow—from RTL modeling to physical design.

Key Learning Outcomes & Engineering Focus:
- Deep understanding of microarchitecture design for Arithmetic Logic Units (ALUs).
- Hands-on application of the ARM 32-bit instruction set architecture (ISA) opcodes and operation modes.
- Production-level RTL coding in Verilog/SystemVerilog.
- Practice with industry-standard Electronic Design Automation (EDA) synthesis and P&R tools, specifically **Synopsys Design Compiler** (Logic Synthesis) and **Cadence Innovus** (Place and Route / Physical Design).

## What is an ALU?
An **Arithmetic Logic Unit (ALU)** is a fundamental combinational building block of a Central Processing Unit (CPU). It receives control signals and data operands to execute mathematical operations (such as addition and subtraction) as well as bitwise logical operations (AND, OR, XOR, etc.).

## Architecture & Operation Principles

The top-level ALU architecture processes two 32-bit input operands (`a` and `b`) in parallel through four internal functional sub-units:

1. **Kogge-Stone Adder (KSA):** A high-speed parallel-prefix carry-lookahead adder chosen for low-latency addition and subtraction operations.
2. **Bitwise AND Unit**
3. **Bitwise OR Unit**
4. **Bitwise XOR Unit (EOR)**

### Execution Flow:
1. Both 32-bit inputs (`a` and `b`) are broadcast to all functional units simultaneously.
2. Each unit computes its respective operation in parallel.
3. Based on the incoming 4-bit **Opcode** control signal, an output Multiplexer (MUX) routes the single valid operation result to the final 32-bit ALU output port (`result`).

## Opcode & Control Unit Mapping

The control unit decodes the **4-bit Opcode** input signal to select the appropriate execution unit and multiplexer path. 

Below is the control mapping implemented for the 32-bit ARM data-processing instruction format:

| Opcode (`[3:0]`) | Mnemonic | Operation Name | Description & RTL Action |
| :---: | :---: | :---: | :--- |
| `0100` | **ADD** | Addition | `Result = A + B` |
| `0010` | **SUB** | Subtraction | `Result = A - B` *(Calculated via 2's complement using KSA)* |
| `0000` | **AND** | Bitwise AND | `Result = A & B` |
| `1100` | **ORR** | Bitwise OR | `Result = A \| B` |
| `0001` | **EOR** | Bitwise Exclusive-OR | `Result = A ^ B` |

## RTL Designing
### 32-bit Kogge-Stone Adder (KSA)

Kogge–Stone adder (KSA) is a high-speed, parallel-prefix form of a carry-lookahead adder used in digital computing and electronics to add binary numbers quickly. It computes carry signals simultaneously in \(O(\log_2 N)\) time, making it one of the fastest known adder designs, though it requires a larger physical chip area and complex wiring.

![image](https://github.com/HyunjunKim0212/Hyunjun-Kim-ARM-32-bit-ALU-Project/blob/main/image/32%20bit%20KSA%20layer.png)

```
// generation & propagation for the 32-bit Kogge-Stone Adder
module gp(in_a, in_b, out_g, out_p);
    input in_a, in_b;
    output out_g, out_p;

    assign out_g = in_a & in_b; // generate
    assign out_p = in_a ^ in_b; // propagate
endmodule

// get g(i:k) and p(i:k)
module merge (in_ga, in_pa, in_gb, in_pb, out_gnew, out_pnew);
    input in_ga, in_pa, in_gb, in_pb;
    output out_gnew, out_pnew;

    assign out_gnew = in_gb | (in_pb & in_ga); // g(i:k) = g(i:j) + p(i:j)*g(j-1:k)
    assign out_pnew = in_pa & in_pb; // p(i:k) = p(i:j)*p(j-1:k)
endmodule

// summation module
module sum(in_p, in_c, out_s);
    input in_p, in_c;
    output out_s;

    assign out_s = in_p ^ in_c; // s(i) = p(i) + c(i-1)
endmodule

// carry out module
module carry(in_g, in_p,in_cin, out_cout);
    input in_g, in_p, in_cin;
    output out_cout;

    assign out_cout = in_g | (in_p & in_cin); // c(i) = g(i) + p(i)*c(i-1)
endmodule

// 32-bit Kogge-Stone Adder
module ksa32(in_a, in_b, in_cin, out_s, out_cout);
    input [31:0] in_a, in_b;
    input in_cin;
    output [31:0] out_s;
    output out_cout;

    // generate g & p
    wire w_g0, w_g1, w_g2, w_g3, w_g4, w_g5, w_g6, w_g7, w_g8, w_g9, w_g10, w_g11, w_g12, w_g13, w_g14, w_g15, w_g16, w_g17, w_g18, w_g19, w_g20, w_g21, w_g22, w_g23, w_g24, w_g25, w_g26, w_g27, w_g28, w_g29, w_g30, w_g31;
    wire w_p0, w_p1, w_p2, w_p3, w_p4, w_p5, w_p6, w_p7, w_p8, w_p9, w_p10, w_p11, w_p12, w_p13, w_p14, w_p15, w_p16, w_p17, w_p18, w_p19, w_p20, w_p21, w_p22, w_p23, w_p24, w_p25, w_p26, w_p27, w_p28, w_p29, w_p30, w_p31;

    gp A0(.in_a(in_a[0]), .in_b(in_b[0]), .out_g(w_g0), .out_p(w_p0));
    gp A1(.in_a(in_a[1]), .in_b(in_b[1]), .out_g(w_g1), .out_p(w_p1));
    gp A2(.in_a(in_a[2]), .in_b(in_b[2]), .out_g(w_g2), .out_p(w_p2));
    gp A3(.in_a(in_a[3]), .in_b(in_b[3]), .out_g(w_g3), .out_p(w_p3));
    gp A4(.in_a(in_a[4]), .in_b(in_b[4]), .out_g(w_g4), .out_p(w_p4));
    gp A5(.in_a(in_a[5]), .in_b(in_b[5]), .out_g(w_g5), .out_p(w_p5));
    gp A6(.in_a(in_a[6]), .in_b(in_b[6]), .out_g(w_g6), .out_p(w_p6));
    gp A7(.in_a(in_a[7]), .in_b(in_b[7]), .out_g(w_g7), .out_p(w_p7));
    gp A8(.in_a(in_a[8]), .in_b(in_b[8]), .out_g(w_g8), .out_p(w_p8));
    gp A9(.in_a(in_a[9]), .in_b(in_b[9]), .out_g(w_g9), .out_p(w_p9));
    gp A10(.in_a(in_a[10]), .in_b(in_b[10]), .out_g(w_g10), .out_p(w_p10));
    gp A11(.in_a(in_a[11]), .in_b(in_b[11]), .out_g(w_g11), .out_p(w_p11));
    gp A12(.in_a(in_a[12]), .in_b(in_b[12]), .out_g(w_g12), .out_p(w_p12));
    gp A13(.in_a(in_a[13]), .in_b(in_b[13]), .out_g(w_g13), .out_p(w_p13));
    gp A14(.in_a(in_a[14]), .in_b(in_b[14]), .out_g(w_g14), .out_p(w_p14));
    gp A15(.in_a(in_a[15]), .in_b(in_b[15]), .out_g(w_g15), .out_p(w_p15));
    gp A16(.in_a(in_a[16]), .in_b(in_b[16]), .out_g(w_g16), .out_p(w_p16));
    gp A17(.in_a(in_a[17]), .in_b(in_b[17]), .out_g(w_g17), .out_p(w_p17));
    gp A18(.in_a(in_a[18]), .in_b(in_b[18]), .out_g(w_g18), .out_p(w_p18));
    gp A19(.in_a(in_a[19]), .in_b(in_b[19]), .out_g(w_g19), .out_p(w_p19));
    gp A20(.in_a(in_a[20]), .in_b(in_b[20]), .out_g(w_g20), .out_p(w_p20));
    gp A21(.in_a(in_a[21]), .in_b(in_b[21]), .out_g(w_g21), .out_p(w_p21));
    gp A22(.in_a(in_a[22]), .in_b(in_b[22]), .out_g(w_g22), .out_p(w_p22));
    gp A23(.in_a(in_a[23]), .in_b(in_b[23]), .out_g(w_g23), .out_p(w_p23));
    gp A24(.in_a(in_a[24]), .in_b(in_b[24]), .out_g(w_g24), .out_p(w_p24));
    gp A25(.in_a(in_a[25]), .in_b(in_b[25]), .out_g(w_g25), .out_p(w_p25));
    gp A26(.in_a(in_a[26]), .in_b(in_b[26]), .out_g(w_g26), .out_p(w_p26));
    gp A27(.in_a(in_a[27]), .in_b(in_b[27]), .out_g(w_g27), .out_p(w_p27));
    gp A28(.in_a(in_a[28]), .in_b(in_b[28]), .out_g(w_g28), .out_p(w_p28));
    gp A29(.in_a(in_a[29]), .in_b(in_b[29]), .out_g(w_g29), .out_p(w_p29));
    gp A30(.in_a(in_a[30]), .in_b(in_b[30]), .out_g(w_g30), .out_p(w_p30));
    gp A31(.in_a(in_a[31]), .in_b(in_b[31]), .out_g(w_g31), .out_p(w_p31));

    // generate gnew
    wire w_gn_1_0, w_gn_1_1, w_gn_1_2, w_gn_1_3, w_gn_1_4, w_gn_1_5, w_gn_1_6, w_gn_1_7, w_gn_1_8, w_gn_1_9, w_gn_1_10, w_gn_1_11, w_gn_1_12, w_gn_1_13, w_gn_1_14, w_gn_1_15, w_gn_1_16, w_gn_1_17, w_gn_1_18, w_gn_1_19, w_gn_1_20, w_gn_1_21, w_gn_1_22, w_gn_1_23, w_gn_1_24, w_gn_1_25, w_gn_1_26, w_gn_1_27, w_gn_1_28, w_gn_1_29, w_gn_1_30;
    wire w_pn_1_0, w_pn_1_1, w_pn_1_2, w_pn_1_3, w_pn_1_4, w_pn_1_5, w_pn_1_6, w_pn_1_7, w_pn_1_8, w_pn_1_9, w_pn_1_10, w_pn_1_11, w_pn_1_12, w_pn_1_13, w_pn_1_14, w_pn_1_15, w_pn_1_16, w_pn_1_17, w_pn_1_18, w_pn_1_19, w_pn_1_20, w_pn_1_21, w_pn_1_22, w_pn_1_23, w_pn_1_24, w_pn_1_25, w_pn_1_26, w_pn_1_27, w_pn_1_28, w_pn_1_29, w_pn_1_30;

    // first layer
    merge U0(.in_ga(w_g0), .in_pa(w_p0), .in_gb(w_g1), .in_pb(w_p1), .out_gnew(w_gn_1_0), .out_pnew(w_pn_1_0)); //gp(1:0)
    merge U1(.in_ga(w_g1), .in_pa(w_p1), .in_gb(w_g2), .in_pb(w_p2), .out_gnew(w_gn_1_1), .out_pnew(w_pn_1_1)); //gp(2:1)
    merge U2(.in_ga(w_g2), .in_pa(w_p2), .in_gb(w_g3), .in_pb(w_p3), .out_gnew(w_gn_1_2), .out_pnew(w_pn_1_2)); //gp(3:2)
    merge U3(.in_ga(w_g3), .in_pa(w_p3), .in_gb(w_g4), .in_pb(w_p4), .out_gnew(w_gn_1_3), .out_pnew(w_pn_1_3)); //gp(4:3)
    merge U4(.in_ga(w_g4), .in_pa(w_p4), .in_gb(w_g5), .in_pb(w_p5), .out_gnew(w_gn_1_4), .out_pnew(w_pn_1_4)); //gp(5:4)
    merge U5(.in_ga(w_g5), .in_pa(w_p5), .in_gb(w_g6), .in_pb(w_p6), .out_gnew(w_gn_1_5), .out_pnew(w_pn_1_5)); //gp(6:5)
    merge U6(.in_ga(w_g6), .in_pa(w_p6), .in_gb(w_g7), .in_pb(w_p7), .out_gnew(w_gn_1_6), .out_pnew(w_pn_1_6)); //gp(7:6)
    merge U7(.in_ga(w_g7), .in_pa(w_p7), .in_gb(w_g8), .in_pb(w_p8), .out_gnew(w_gn_1_7), .out_pnew(w_pn_1_7)); //gp(8:7)
    merge U8(.in_ga(w_g8), .in_pa(w_p8), .in_gb(w_g9), .in_pb(w_p9), .out_gnew(w_gn_1_8), .out_pnew(w_pn_1_8)); //gp(9:8)
    merge U9(.in_ga(w_g9), .in_pa(w_p9), .in_gb(w_g10), .in_pb(w_p10), .out_gnew(w_gn_1_9), .out_pnew(w_pn_1_9)); //gp(10:9)
    merge U10(.in_ga(w_g10), .in_pa(w_p10), .in_gb(w_g11), .in_pb(w_p11), .out_gnew(w_gn_1_10), .out_pnew(w_pn_1_10)); //gp(11:10)
    merge U11(.in_ga(w_g11), .in_pa(w_p11), .in_gb(w_g12), .in_pb(w_p12), .out_gnew(w_gn_1_11), .out_pnew(w_pn_1_11)); //gp(12:11)
    merge U12(.in_ga(w_g12), .in_pa(w_p12), .in_gb(w_g13), .in_pb(w_p13), .out_gnew(w_gn_1_12), .out_pnew(w_pn_1_12)); //gp(13:12)
    merge U13(.in_ga(w_g13), .in_pa(w_p13), .in_gb(w_g14), .in_pb(w_p14), .out_gnew(w_gn_1_13), .out_pnew(w_pn_1_13)); //gp(14:13)
    merge U14(.in_ga(w_g14), .in_pa(w_p14), .in_gb(w_g15), .in_pb(w_p15), .out_gnew(w_gn_1_14), .out_pnew(w_pn_1_14)); //gp(15:14)
    merge U15(.in_ga(w_g15), .in_pa(w_p15), .in_gb(w_g16), .in_pb(w_p16), .out_gnew(w_gn_1_15), .out_pnew(w_pn_1_15)); //gp(16:15)
    merge U16(.in_ga(w_g16), .in_pa(w_p16), .in_gb(w_g17), .in_pb(w_p17), .out_gnew(w_gn_1_16), .out_pnew(w_pn_1_16)); //gp(17:16)
    merge U17(.in_ga(w_g17), .in_pa(w_p17), .in_gb(w_g18), .in_pb(w_p18), .out_gnew(w_gn_1_17), .out_pnew(w_pn_1_17)); //gp(18:17)
    merge U18(.in_ga(w_g18), .in_pa(w_p18), .in_gb(w_g19), .in_pb(w_p19), .out_gnew(w_gn_1_18), .out_pnew(w_pn_1_18)); //gp(19:18)
    merge U19(.in_ga(w_g19), .in_pa(w_p19), .in_gb(w_g20), .in_pb(w_p20), .out_gnew(w_gn_1_19), .out_pnew(w_pn_1_19)); //gp(20:19)
    merge U20(.in_ga(w_g20), .in_pa(w_p20), .in_gb(w_g21), .in_pb(w_p21), .out_gnew(w_gn_1_20), .out_pnew(w_pn_1_20)); //gp(21:20)
    merge U21(.in_ga(w_g21), .in_pa(w_p21), .in_gb(w_g22), .in_pb(w_p22), .out_gnew(w_gn_1_21), .out_pnew(w_pn_1_21)); //gp(22:21)
    merge U22(.in_ga(w_g22), .in_pa(w_p22), .in_gb(w_g23), .in_pb(w_p23), .out_gnew(w_gn_1_22), .out_pnew(w_pn_1_22)); //gp(23:22)
    merge U23(.in_ga(w_g23), .in_pa(w_p23), .in_gb(w_g24), .in_pb(w_p24), .out_gnew(w_gn_1_23), .out_pnew(w_pn_1_23)); //gp(24:23)
    merge U24(.in_ga(w_g24), .in_pa(w_p24), .in_gb(w_g25), .in_pb(w_p25), .out_gnew(w_gn_1_24), .out_pnew(w_pn_1_24)); //gp(25:24)
    merge U25(.in_ga(w_g25), .in_pa(w_p25), .in_gb(w_g26), .in_pb(w_p26), .out_gnew(w_gn_1_25), .out_pnew(w_pn_1_25)); //gp(26:25)
    merge U26(.in_ga(w_g26), .in_pa(w_p26), .in_gb(w_g27), .in_pb(w_p27), .out_gnew(w_gn_1_26), .out_pnew(w_pn_1_26)); //gp(27:26)
    merge U27(.in_ga(w_g27), .in_pa(w_p27), .in_gb(w_g28), .in_pb(w_p28), .out_gnew(w_gn_1_27), .out_pnew(w_pn_1_27)); //gp(28:27)
    merge U28(.in_ga(w_g28), .in_pa(w_p28), .in_gb(w_g29), .in_pb(w_p29), .out_gnew(w_gn_1_28), .out_pnew(w_pn_1_28)); //gp(29:28)
    merge U29(.in_ga(w_g29), .in_pa(w_p29), .in_gb(w_g30), .in_pb(w_p30), .out_gnew(w_gn_1_29), .out_pnew(w_pn_1_29)); //gp(30:29)
    merge U30(.in_ga(w_g30), .in_pa(w_p30), .in_gb(w_g31), .in_pb(w_p31), .out_gnew(w_gn_1_30), .out_pnew(w_pn_1_30)); //gp(31:30)

    // second layer
    wire w_gn_2_0, w_gn_2_1, w_gn_2_2, w_gn_2_3, w_gn_2_4, w_gn_2_5, w_gn_2_6, w_gn_2_7, w_gn_2_8, w_gn_2_9, w_gn_2_10, w_gn_2_11, w_gn_2_12, w_gn_2_13, w_gn_2_14, w_gn_2_15, w_gn_2_16, w_gn_2_17, w_gn_2_18, w_gn_2_19, w_gn_2_20, w_gn_2_21, w_gn_2_22, w_gn_2_23, w_gn_2_24, w_gn_2_25, w_gn_2_26, w_gn_2_27, w_gn_2_28, w_gn_2_29;
    wire w_pn_2_0, w_pn_2_1, w_pn_2_2, w_pn_2_3, w_pn_2_4, w_pn_2_5, w_pn_2_6, w_pn_2_7, w_pn_2_8, w_pn_2_9, w_pn_2_10, w_pn_2_11, w_pn_2_12, w_pn_2_13, w_pn_2_14, w_pn_2_15, w_pn_2_16, w_pn_2_17, w_pn_2_18, w_pn_2_19, w_pn_2_20, w_pn_2_21, w_pn_2_22, w_pn_2_23, w_pn_2_24, w_pn_2_25, w_pn_2_26, w_pn_2_27, w_pn_2_28, w_pn_2_29;

    merge U31(.in_ga(w_g0), .in_pa(w_p0), .in_gb(w_gn_1_1), .in_pb(w_pn_1_1), .out_gnew(w_gn_2_0), .out_pnew(w_pn_2_0)); //gp(2:0)
    merge U32(.in_ga(w_gn_1_0), .in_pa(w_pn_1_0), .in_gb(w_gn_1_2), .in_pb(w_pn_1_2), .out_gnew(w_gn_2_1), .out_pnew(w_pn_2_1)); //gp(3:1)
    merge U33(.in_ga(w_gn_1_1), .in_pa(w_pn_1_1), .in_gb(w_gn_1_3), .in_pb(w_pn_1_3), .out_gnew(w_gn_2_2), .out_pnew(w_pn_2_2)); //gp(4:2)
    merge U34(.in_ga(w_gn_1_2), .in_pa(w_pn_1_2), .in_gb(w_gn_1_4), .in_pb(w_pn_1_4), .out_gnew(w_gn_2_3), .out_pnew(w_pn_2_3)); //gp(5:3)
    merge U35(.in_ga(w_gn_1_3), .in_pa(w_pn_1_3), .in_gb(w_gn_1_5), .in_pb(w_pn_1_5), .out_gnew(w_gn_2_4), .out_pnew(w_pn_2_4)); //gp(6:4)
    merge U36(.in_ga(w_gn_1_4), .in_pa(w_pn_1_4), .in_gb(w_gn_1_6), .in_pb(w_pn_1_6), .out_gnew(w_gn_2_5), .out_pnew(w_pn_2_5)); //gp(7:5)
    merge U37(.in_ga(w_gn_1_5), .in_pa(w_pn_1_5), .in_gb(w_gn_1_7), .in_pb(w_pn_1_7), .out_gnew(w_gn_2_6), .out_pnew(w_pn_2_6)); //gp(8:6)
    merge U38(.in_ga(w_gn_1_6), .in_pa(w_pn_1_6), .in_gb(w_gn_1_8), .in_pb(w_pn_1_8), .out_gnew(w_gn_2_7), .out_pnew(w_pn_2_7)); //gp(9:7)
    merge U39(.in_ga(w_gn_1_7), .in_pa(w_pn_1_7), .in_gb(w_gn_1_9), .in_pb(w_pn_1_9), .out_gnew(w_gn_2_8), .out_pnew(w_pn_2_8)); //gp(10:8)
    merge U40(.in_ga(w_gn_1_8), .in_pa(w_pn_1_8), .in_gb(w_gn_1_10), .in_pb(w_pn_1_10), .out_gnew(w_gn_2_9), .out_pnew(w_pn_2_9)); //gp(11:9)
    merge U41(.in_ga(w_gn_1_9), .in_pa(w_pn_1_9), .in_gb(w_gn_1_11), .in_pb(w_pn_1_11), .out_gnew(w_gn_2_10), .out_pnew(w_pn_2_10)); //gp(12:10)
    merge U42(.in_ga(w_gn_1_10), .in_pa(w_pn_1_10), .in_gb(w_gn_1_12), .in_pb(w_pn_1_12), .out_gnew(w_gn_2_11), .out_pnew(w_pn_2_11)); //gp(13:11)
    merge U43(.in_ga(w_gn_1_11), .in_pa(w_pn_1_11), .in_gb(w_gn_1_13), .in_pb(w_pn_1_13), .out_gnew(w_gn_2_12), .out_pnew(w_pn_2_12)); //gp(14:12)
    merge U44(.in_ga(w_gn_1_12), .in_pa(w_pn_1_12), .in_gb(w_gn_1_14), .in_pb(w_pn_1_14), .out_gnew(w_gn_2_13), .out_pnew(w_pn_2_13)); //gp(15:13)
    merge U45(.in_ga(w_gn_1_13), .in_pa(w_pn_1_13), .in_gb(w_gn_1_15), .in_pb(w_pn_1_15), .out_gnew(w_gn_2_14), .out_pnew(w_pn_2_14)); //gp(16:14)
    merge U46(.in_ga(w_gn_1_14), .in_pa(w_pn_1_14), .in_gb(w_gn_1_16), .in_pb(w_pn_1_16), .out_gnew(w_gn_2_15), .out_pnew(w_pn_2_15)); //gp(17:15)
    merge U47(.in_ga(w_gn_1_15), .in_pa(w_pn_1_15), .in_gb(w_gn_1_17), .in_pb(w_pn_1_17), .out_gnew(w_gn_2_16), .out_pnew(w_pn_2_16)); //gp(18:16)
    merge U48(.in_ga(w_gn_1_16), .in_pa(w_pn_1_16), .in_gb(w_gn_1_18), .in_pb(w_pn_1_18), .out_gnew(w_gn_2_17), .out_pnew(w_pn_2_17)); //gp(19:17)
    merge U49(.in_ga(w_gn_1_17), .in_pa(w_pn_1_17), .in_gb(w_gn_1_19), .in_pb(w_pn_1_19), .out_gnew(w_gn_2_18), .out_pnew(w_pn_2_18)); //gp(20:18)
    merge U50(.in_ga(w_gn_1_18), .in_pa(w_pn_1_18), .in_gb(w_gn_1_20), .in_pb(w_pn_1_20), .out_gnew(w_gn_2_19), .out_pnew(w_pn_2_19)); //gp(21:19)
    merge U51(.in_ga(w_gn_1_19), .in_pa(w_pn_1_19), .in_gb(w_gn_1_21), .in_pb(w_pn_1_21), .out_gnew(w_gn_2_20), .out_pnew(w_pn_2_20)); //gp(22:20)
    merge U52(.in_ga(w_gn_1_20), .in_pa(w_pn_1_20), .in_gb(w_gn_1_22), .in_pb(w_pn_1_22), .out_gnew(w_gn_2_21), .out_pnew(w_pn_2_21)); //gp(23:21)
    merge U53(.in_ga(w_gn_1_21), .in_pa(w_pn_1_21), .in_gb(w_gn_1_23), .in_pb(w_pn_1_23), .out_gnew(w_gn_2_22), .out_pnew(w_pn_2_22)); //gp(24:22)
    merge U54(.in_ga(w_gn_1_22), .in_pa(w_pn_1_22), .in_gb(w_gn_1_24), .in_pb(w_pn_1_24), .out_gnew(w_gn_2_23), .out_pnew(w_pn_2_23)); //gp(25:23)
    merge U55(.in_ga(w_gn_1_23), .in_pa(w_pn_1_23), .in_gb(w_gn_1_25), .in_pb(w_pn_1_25), .out_gnew(w_gn_2_24), .out_pnew(w_pn_2_24)); //gp(26:24)
    merge U56(.in_ga(w_gn_1_24), .in_pa(w_pn_1_24), .in_gb(w_gn_1_26), .in_pb(w_pn_1_26), .out_gnew(w_gn_2_25), .out_pnew(w_pn_2_25)); //gp(27:25)
    merge U57(.in_ga(w_gn_1_25), .in_pa(w_pn_1_25), .in_gb(w_gn_1_27), .in_pb(w_pn_1_27), .out_gnew(w_gn_2_26), .out_pnew(w_pn_2_26)); //gp(28:26)
    merge U58(.in_ga(w_gn_1_26), .in_pa(w_pn_1_26), .in_gb(w_gn_1_28), .in_pb(w_pn_1_28), .out_gnew(w_gn_2_27), .out_pnew(w_pn_2_27)); //gp(29:27)
    merge U59(.in_ga(w_gn_1_27), .in_pa(w_pn_1_27), .in_gb(w_gn_1_29), .in_pb(w_pn_1_29), .out_gnew(w_gn_2_28), .out_pnew(w_pn_2_28)); //gp(30:28)
    merge U60(.in_ga(w_gn_1_28), .in_pa(w_pn_1_28), .in_gb(w_gn_1_30), .in_pb(w_pn_1_30), .out_gnew(w_gn_2_29), .out_pnew(w_pn_2_29)); //gp(31:29)

    // third layer
    wire w_gn_3_0, w_gn_3_1, w_gn_3_2, w_gn_3_3, w_gn_3_4, w_gn_3_5, w_gn_3_6, w_gn_3_7, w_gn_3_8, w_gn_3_9, w_gn_3_10, w_gn_3_11, w_gn_3_12, w_gn_3_13, w_gn_3_14, w_gn_3_15, w_gn_3_16, w_gn_3_17, w_gn_3_18, w_gn_3_19, w_gn_3_20, w_gn_3_21, w_gn_3_22, w_gn_3_23, w_gn_3_24, w_gn_3_25, w_gn_3_26, w_gn_3_27;
    wire w_pn_3_0, w_pn_3_1, w_pn_3_2, w_pn_3_3, w_pn_3_4, w_pn_3_5, w_pn_3_6, w_pn_3_7, w_pn_3_8, w_pn_3_9, w_pn_3_10, w_pn_3_11, w_pn_3_12, w_pn_3_13, w_pn_3_14, w_pn_3_15, w_pn_3_16, w_pn_3_17, w_pn_3_18, w_pn_3_19, w_pn_3_20, w_pn_3_21, w_pn_3_22, w_pn_3_23, w_pn_3_24, w_pn_3_25, w_pn_3_26, w_pn_3_27;

    merge U61(.in_ga(w_g0), .in_pa(w_p0), .in_gb(w_gn_2_2), .in_pb(w_pn_2_2), .out_gnew(w_gn_3_0), .out_pnew(w_pn_3_0)); //gp(4:0)
    merge U62(.in_ga(w_gn_1_0), .in_pa(w_gn_1_0), .in_gb(w_gn_2_3), .in_pb(w_pn_2_3), .out_gnew(w_gn_3_1), .out_pnew(w_pn_3_1)); //gp(5:1)
    merge U63(.in_ga(w_gn_2_0), .in_pa(w_pn_2_0), .in_gb(w_gn_2_4), .in_pb(w_pn_2_4), .out_gnew(w_gn_3_2), .out_pnew(w_pn_3_2)); //gp(6:2)
    merge U64(.in_ga(w_gn_2_1), .in_pa(w_pn_2_1), .in_gb(w_gn_2_5), .in_pb(w_pn_2_5), .out_gnew(w_gn_3_3), .out_pnew(w_pn_3_3)); //gp(7:3)
    merge U65(.in_ga(w_gn_2_2), .in_pa(w_pn_2_2), .in_gb(w_gn_2_6), .in_pb(w_pn_2_6), .out_gnew(w_gn_3_4), .out_pnew(w_pn_3_4)); //gp(8:4)
    merge U66(.in_ga(w_gn_2_3), .in_pa(w_pn_2_3), .in_gb(w_gn_2_7), .in_pb(w_pn_2_7), .out_gnew(w_gn_3_5), .out_pnew(w_pn_3_5)); //gp(9:5)
    merge U67(.in_ga(w_gn_2_4), .in_pa(w_pn_2_4), .in_gb(w_gn_2_8), .in_pb(w_pn_2_8), .out_gnew(w_gn_3_6), .out_pnew(w_pn_3_6)); //gp(10:6)
    merge U68(.in_ga(w_gn_2_5), .in_pa(w_pn_2_5), .in_gb(w_gn_2_9), .in_pb(w_pn_2_9), .out_gnew(w_gn_3_7), .out_pnew(w_pn_3_7)); //gp(11:7)
    merge U69(.in_ga(w_gn_2_6), .in_pa(w_pn_2_6), .in_gb(w_gn_2_10), .in_pb(w_pn_2_10), .out_gnew(w_gn_3_8), .out_pnew(w_pn_3_8)); //gp(12:8)
    merge U70(.in_ga(w_gn_2_7), .in_pa(w_pn_2_7), .in_gb(w_gn_2_11), .in_pb(w_pn_2_11), .out_gnew(w_gn_3_9), .out_pnew(w_pn_3_9)); //gp(13:9)
    merge U71(.in_ga(w_gn_2_8), .in_pa(w_pn_2_8), .in_gb(w_gn_2_12), .in_pb(w_pn_2_12), .out_gnew(w_gn_3_10), .out_pnew(w_pn_3_10)); //gp(14:10)
    merge U72(.in_ga(w_gn_2_9), .in_pa(w_pn_2_9), .in_gb(w_gn_2_13), .in_pb(w_pn_2_13), .out_gnew(w_gn_3_11), .out_pnew(w_pn_3_11)); //gp(15:11)
    merge U73(.in_ga(w_gn_2_10), .in_pa(w_pn_2_10), .in_gb(w_gn_2_14), .in_pb(w_pn_2_14), .out_gnew(w_gn_3_12), .out_pnew(w_pn_3_12)); //gp(16:12)
    merge U74(.in_ga(w_gn_2_11), .in_pa(w_pn_2_11), .in_gb(w_gn_2_15), .in_pb(w_pn_2_15), .out_gnew(w_gn_3_13), .out_pnew(w_pn_3_13)); //gp(17:13)
    merge U75(.in_ga(w_gn_2_12), .in_pa(w_pn_2_12), .in_gb(w_gn_2_16), .in_pb(w_pn_2_16), .out_gnew(w_gn_3_14), .out_pnew(w_pn_3_14)); //gp(18:14)
    merge U76(.in_ga(w_gn_2_13), .in_pa(w_pn_2_13), .in_gb(w_gn_2_17), .in_pb(w_pn_2_17), .out_gnew(w_gn_3_15), .out_pnew(w_pn_3_15)); //gp(19:15)
    merge U77(.in_ga(w_gn_2_14), .in_pa(w_pn_2_14), .in_gb(w_gn_2_18), .in_pb(w_pn_2_18), .out_gnew(w_gn_3_16), .out_pnew(w_pn_3_16)); //gp(20:16)
    merge U78(.in_ga(w_gn_2_15), .in_pa(w_pn_2_15), .in_gb(w_gn_2_19), .in_pb(w_pn_2_19), .out_gnew(w_gn_3_17), .out_pnew(w_pn_3_17)); //gp(21:17)
    merge U79(.in_ga(w_gn_2_16), .in_pa(w_pn_2_16), .in_gb(w_gn_2_20), .in_pb(w_pn_2_20), .out_gnew(w_gn_3_18), .out_pnew(w_pn_3_18)); //gp(22:18)
    merge U80(.in_ga(w_gn_2_17), .in_pa(w_pn_2_17), .in_gb(w_gn_2_21), .in_pb(w_pn_2_21), .out_gnew(w_gn_3_19), .out_pnew(w_pn_3_19)); //gp(23:19)
    merge U81(.in_ga(w_gn_2_18), .in_pa(w_pn_2_18), .in_gb(w_gn_2_22), .in_pb(w_pn_2_22), .out_gnew(w_gn_3_20), .out_pnew(w_pn_3_20)); //gp(24:20)
    merge U82(.in_ga(w_gn_2_19), .in_pa(w_pn_2_19), .in_gb(w_gn_2_23), .in_pb(w_pn_2_23), .out_gnew(w_gn_3_21), .out_pnew(w_pn_3_21)); //gp(25:21)
    merge U83(.in_ga(w_gn_2_20), .in_pa(w_pn_2_20), .in_gb(w_gn_2_24), .in_pb(w_pn_2_24), .out_gnew(w_gn_3_22), .out_pnew(w_pn_3_22)); //gp(26:22)
    merge U84(.in_ga(w_gn_2_21), .in_pa(w_pn_2_21), .in_gb(w_gn_2_25), .in_pb(w_pn_2_25), .out_gnew(w_gn_3_23), .out_pnew(w_pn_3_23)); //gp(27:23)
    merge U85(.in_ga(w_gn_2_22), .in_pa(w_pn_2_22), .in_gb(w_gn_2_26), .in_pb(w_pn_2_26), .out_gnew(w_gn_3_24), .out_pnew(w_pn_3_24)); //gp(28:24)
    merge U86(.in_ga(w_gn_2_23), .in_pa(w_pn_2_23), .in_gb(w_gn_2_27), .in_pb(w_pn_2_27), .out_gnew(w_gn_3_25), .out_pnew(w_pn_3_25)); //gp(29:25)
    merge U87(.in_ga(w_gn_2_24), .in_pa(w_pn_2_24), .in_gb(w_gn_2_28), .in_pb(w_pn_2_28), .out_gnew(w_gn_3_26), .out_pnew(w_pn_3_26)); //gp(30:26)
    merge U88(.in_ga(w_gn_2_25), .in_pa(w_pn_2_25), .in_gb(w_gn_2_29), .in_pb(w_pn_2_29), .out_gnew(w_gn_3_27), .out_pnew(w_pn_3_27)); //gp(31:27)

    // fourth layer
    wire w_gn_4_0, w_gn_4_1, w_gn_4_2, w_gn_4_3, w_gn_4_4, w_gn_4_5, w_gn_4_6, w_gn_4_7, w_gn_4_8, w_gn_4_9, w_gn_4_10, w_gn_4_11, w_gn_4_12, w_gn_4_13, w_gn_4_14, w_gn_4_15, w_gn_4_16, w_gn_4_17, w_gn_4_18, w_gn_4_19, w_gn_4_20, w_gn_4_21, w_gn_4_22, w_gn_4_23;
    wire w_pn_4_0, w_pn_4_1, w_pn_4_2, w_pn_4_3, w_pn_4_4, w_pn_4_5, w_pn_4_6, w_pn_4_7, w_pn_4_8, w_pn_4_9, w_pn_4_10, w_pn_4_11, w_pn_4_12, w_pn_4_13, w_pn_4_14, w_pn_4_15, w_pn_4_16, w_pn_4_17, w_pn_4_18, w_pn_4_19, w_pn_4_20, w_pn_4_21, w_pn_4_22, w_pn_4_23;

    merge U89(.in_ga(w_g0), .in_pa(w_p0), .in_gb(w_gn_3_4), .in_pb(w_pn_3_4), .out_gnew(w_gn_4_0), .out_pnew(w_pn_4_0)); //gp(8:0)
    merge U90(.in_ga(w_gn_1_0), .in_pa(w_pn_1_0), .in_gb(w_gn_3_5), .in_pb(w_pn_3_5), .out_gnew(w_gn_4_1), .out_pnew(w_pn_4_1)); //gp(9:1)
    merge U91(.in_ga(w_gn_2_0), .in_pa(w_pn_2_0), .in_gb(w_gn_3_6), .in_pb(w_pn_3_6), .out_gnew(w_gn_4_2), .out_pnew(w_pn_4_2)); //gp(10:2)
    merge U92(.in_ga(w_gn_2_1), .in_pa(w_pn_2_1), .in_gb(w_gn_3_7), .in_pb(w_pn_3_7), .out_gnew(w_gn_4_3), .out_pnew(w_pn_4_3)); //gp(11:3)
    merge U93(.in_ga(w_gn_3_0), .in_pa(w_pn_3_0), .in_gb(w_gn_3_8), .in_pb(w_pn_3_8), .out_gnew(w_gn_4_4), .out_pnew(w_pn_4_4)); //gp(12:4)
    merge U94(.in_ga(w_gn_3_1), .in_pa(w_pn_3_1), .in_gb(w_gn_3_9), .in_pb(w_pn_3_9), .out_gnew(w_gn_4_5), .out_pnew(w_pn_4_5)); //gp(13:5)
    merge U95(.in_ga(w_gn_3_2), .in_pa(w_pn_3_2), .in_gb(w_gn_3_10), .in_pb(w_pn_3_10), .out_gnew(w_gn_4_6), .out_pnew(w_pn_4_6)); //gp(14:6)
    merge U96(.in_ga(w_gn_3_3), .in_pa(w_pn_3_3), .in_gb(w_gn_3_11), .in_pb(w_pn_3_11), .out_gnew(w_gn_4_7), .out_pnew(w_pn_4_7)); //gp(15:7)
    merge U97(.in_ga(w_gn_3_4), .in_pa(w_pn_3_4), .in_gb(w_gn_3_12), .in_pb(w_pn_3_12), .out_gnew(w_gn_4_8), .out_pnew(w_pn_4_8)); //gp(16:8)
    merge U98(.in_ga(w_gn_3_5), .in_pa(w_pn_3_5), .in_gb(w_gn_3_13), .in_pb(w_pn_3_13), .out_gnew(w_gn_4_9), .out_pnew(w_pn_4_9)); //gp(17:9)
    merge U99(.in_ga(w_gn_3_6), .in_pa(w_pn_3_6), .in_gb(w_gn_3_14), .in_pb(w_pn_3_14), .out_gnew(w_gn_4_10), .out_pnew(w_pn_4_10)); //gp(18:10)
    merge U100(.in_ga(w_gn_3_7), .in_pa(w_pn_3_7), .in_gb(w_gn_3_15), .in_pb(w_pn_3_15), .out_gnew(w_gn_4_11), .out_pnew(w_pn_4_11)); //gp(19:11)
    merge U101(.in_ga(w_gn_3_8), .in_pa(w_pn_3_8), .in_gb(w_gn_3_16), .in_pb(w_pn_3_16), .out_gnew(w_gn_4_12), .out_pnew(w_pn_4_12)); //gp(20:12)
    merge U102(.in_ga(w_gn_3_9), .in_pa(w_pn_3_9), .in_gb(w_gn_3_17), .in_pb(w_pn_3_17), .out_gnew(w_gn_4_13), .out_pnew(w_pn_4_13)); //gp(21:13)
    merge U103(.in_ga(w_gn_3_10), .in_pa(w_pn_3_10), .in_gb(w_gn_3_18), .in_pb(w_pn_3_18), .out_gnew(w_gn_4_14), .out_pnew(w_pn_4_14)); //gp(22:14)
    merge U104(.in_ga(w_gn_3_11), .in_pa(w_pn_3_11), .in_gb(w_gn_3_19), .in_pb(w_pn_3_19), .out_gnew(w_gn_4_15), .out_pnew(w_pn_4_15)); //gp(23:15)
    merge U105(.in_ga(w_gn_3_12), .in_pa(w_pn_3_12), .in_gb(w_gn_3_20), .in_pb(w_pn_3_20), .out_gnew(w_gn_4_16), .out_pnew(w_pn_4_16)); //gp(24:16)
    merge U106(.in_ga(w_gn_3_13), .in_pa(w_pn_3_13), .in_gb(w_gn_3_21), .in_pb(w_pn_3_21), .out_gnew(w_gn_4_17), .out_pnew(w_pn_4_17)); //gp(25:17)
    merge U107(.in_ga(w_gn_3_14), .in_pa(w_pn_3_14), .in_gb(w_gn_3_22), .in_pb(w_pn_3_22), .out_gnew(w_gn_4_18), .out_pnew(w_pn_4_18)); //gp(26:18)
    merge U108(.in_ga(w_gn_3_15), .in_pa(w_pn_3_15), .in_gb(w_gn_3_23), .in_pb(w_pn_3_23), .out_gnew(w_gn_4_19), .out_pnew(w_pn_4_19)); //gp(27:19)
    merge U109(.in_ga(w_gn_3_16), .in_pa(w_pn_3_16), .in_gb(w_gn_3_24), .in_pb(w_pn_3_24), .out_gnew(w_gn_4_20), .out_pnew(w_pn_4_20)); //gp(28:20)
    merge U110(.in_ga(w_gn_3_17), .in_pa(w_pn_3_17), .in_gb(w_gn_3_25), .in_pb(w_pn_3_25), .out_gnew(w_gn_4_21), .out_pnew(w_pn_4_21)); //gp(29:21)
    merge U111(.in_ga(w_gn_3_18), .in_pa(w_pn_3_18), .in_gb(w_gn_3_26), .in_pb(w_pn_3_26), .out_gnew(w_gn_4_22), .out_pnew(w_pn_4_22)); //gp(30:22)
    merge U112(.in_ga(w_gn_3_19), .in_pa(w_pn_3_19), .in_gb(w_gn_3_27), .in_pb(w_pn_3_27), .out_gnew(w_gn_4_23), .out_pnew(w_pn_4_23)); //gp(31:23)

    //fifth layer
    wire w_gn_5_0, w_gn_5_1, w_gn_5_2, w_gn_5_3, w_gn_5_4, w_gn_5_5, w_gn_5_6, w_gn_5_7, w_gn_5_8, w_gn_5_9, w_gn_5_10, w_gn_5_11, w_gn_5_12, w_gn_5_13, w_gn_5_14, w_gn_5_15;
    wire w_pn_5_0, w_pn_5_1, w_pn_5_2, w_pn_5_3, w_pn_5_4, w_pn_5_5, w_pn_5_6, w_pn_5_7, w_pn_5_8, w_pn_5_9, w_pn_5_10, w_pn_5_11, w_pn_5_12, w_pn_5_13, w_pn_5_14, w_pn_5_15;

    merge U113(.in_ga(w_g0), .in_pa(w_p0), .in_gb(w_gn_4_8), .in_pb(w_pn_4_8), .out_gnew(w_gn_5_0), .out_pnew(w_pn_5_0)); //gp(16:0)
    merge U114(.in_ga(w_gn_1_0), .in_pa(w_pn_1_0), .in_gb(w_gn_4_9), .in_pb(w_pn_4_9), .out_gnew(w_gn_5_1), .out_pnew(w_pn_5_1)); //gp(17:1)
    merge U115(.in_ga(w_gn_2_0), .in_pa(w_pn_2_0), .in_gb(w_gn_4_10), .in_pb(w_pn_4_10), .out_gnew(w_gn_5_2), .out_pnew(w_pn_5_2)); //gp(18:2)
    merge U116(.in_ga(w_gn_2_1), .in_pa(w_pn_2_1), .in_gb(w_gn_4_11), .in_pb(w_pn_4_11), .out_gnew(w_gn_5_3), .out_pnew(w_pn_5_3)); //gp(19:3)
    merge U117(.in_ga(w_gn_3_0), .in_pa(w_pn_3_0), .in_gb(w_gn_4_12), .in_pb(w_pn_4_12), .out_gnew(w_gn_5_4), .out_pnew(w_pn_5_4)); //gp(20:4)
    merge U118(.in_ga(w_gn_3_1), .in_pa(w_pn_3_1), .in_gb(w_gn_4_13), .in_pb(w_pn_4_13), .out_gnew(w_gn_5_5), .out_pnew(w_pn_5_5)); //gp(21:5)
    merge U119(.in_ga(w_gn_3_2), .in_pa(w_pn_3_2), .in_gb(w_gn_4_14), .in_pb(w_pn_4_14), .out_gnew(w_gn_5_6), .out_pnew(w_pn_5_6)); //gp(22:6)
    merge U120(.in_ga(w_gn_3_3), .in_pa(w_pn_3_3), .in_gb(w_gn_4_15), .in_pb(w_pn_4_15), .out_gnew(w_gn_5_7), .out_pnew(w_pn_5_7)); //gp(23:7)
    merge U121(.in_ga(w_gn_4_0), .in_pa(w_pn_4_0), .in_gb(w_gn_5_0), .in_pb(w_pn_5_0), .out_gnew(w_gn_5_8), .out_pnew(w_pn_5_8)); //gp(24:0)
    merge U122(.in_ga(w_gn_4_1), .in_pa(w_pn_4_1), .in_gb(w_gn_5_1), .in_pb(w_pn_5_1), .out_gnew(w_gn_5_9), .out_pnew(w_pn_5_9)); //gp(25:1)
    merge U123(.in_ga(w_gn_4_2), .in_pa(w_pn_4_2), .in_gb(w_gn_5_2), .in_pb(w_pn_5_2), .out_gnew(w_gn_5_10), .out_pnew(w_pn_5_10)); //gp(26:2)
    merge U124(.in_ga(w_gn_4_3), .in_pa(w_pn_4_3), .in_gb(w_gn_5_3), .in_pb(w_pn_5_3), .out_gnew(w_gn_5_11), .out_pnew(w_pn_5_11)); //gp(27:3)
    merge U125(.in_ga(w_gn_4_4), .in_pa(w_pn_4_4), .in_gb(w_gn_5_4), .in_pb(w_pn_5_4), .out_gnew(w_gn_5_12), .out_pnew(w_pn_5_12)); //gp(28:4)
    merge U126(.in_ga(w_gn_4_5), .in_pa(w_pn_4_5), .in_gb(w_gn_5_5), .in_pb(w_pn_5_5), .out_gnew(w_gn_5_13), .out_pnew(w_pn_5_13)); //gp(29:5)
    merge U127(.in_ga(w_gn_4_6), .in_pa(w_pn_4_6), .in_gb(w_gn_5_6), .in_pb(w_pn_5_6), .out_gnew(w_gn_5_14), .out_pnew(w_pn_5_14)); //gp(30:6)
    merge U128(.in_ga(w_gn_4_7), .in_pa(w_pn_4_7), .in_gb(w_gn_5_7), .in_pb(w_pn_5_7), .out_gnew(w_gn_5_15), .out_pnew(w_pn_5_15)); //gp(31:7)

    // generate C
    wire w_c1, w_c2, w_c3, w_c4, w_c5, w_c6, w_c7, w_c8, w_c9, w_c10, w_c11, w_c12, w_c13, w_c14, w_c15, w_c16, w_c17, w_c18, w_c19, w_c20, w_c21, w_c22, w_c23, w_c24, w_c25, w_c26, w_c27, w_c28, w_c29, w_c30, w_c31;

    carry C1(.in_g(w_g0), .in_p(w_p0), .in_cin(in_cin), .out_cout(w_c1));
    carry C2(.in_g(w_gn_1_0), .in_p(w_pn_1_0), .in_cin(in_cin), .out_cout(w_c2));
    carry C3(.in_g(w_gn_2_0), .in_p(w_pn_2_0), .in_cin(in_cin), .out_cout(w_c3));
    carry C4(.in_g(w_gn_2_1), .in_p(w_pn_2_1), .in_cin(in_cin), .out_cout(w_c4));
    carry C5(.in_g(w_gn_3_0), .in_p(w_pn_3_0), .in_cin(in_cin), .out_cout(w_c5));
    carry C6(.in_g(w_gn_3_1), .in_p(w_pn_3_1), .in_cin(in_cin), .out_cout(w_c6));
    carry C7(.in_g(w_gn_3_2), .in_p(w_pn_3_2), .in_cin(in_cin), .out_cout(w_c7));
    carry C8(.in_g(w_gn_3_3), .in_p(w_pn_3_3), .in_cin(in_cin), .out_cout(w_c8));
    carry C9(.in_g(w_gn_4_0), .in_p(w_pn_4_0), .in_cin(in_cin), .out_cout(w_c9));
    carry C10(.in_g(w_gn_4_1), .in_p(w_pn_4_1), .in_cin(in_cin), .out_cout(w_c10));
    carry C11(.in_g(w_gn_4_2), .in_p(w_pn_4_2), .in_cin(in_cin), .out_cout(w_c11));
    carry C12(.in_g(w_gn_4_3), .in_p(w_pn_4_3), .in_cin(in_cin), .out_cout(w_c12));
    carry C13(.in_g(w_gn_4_4), .in_p(w_pn_4_4), .in_cin(in_cin), .out_cout(w_c13));
    carry C14(.in_g(w_gn_4_5), .in_p(w_pn_4_5), .in_cin(in_cin), .out_cout(w_c14));
    carry C15(.in_g(w_gn_4_6), .in_p(w_pn_4_6), .in_cin(in_cin), .out_cout(w_c15));
    carry C16(.in_g(w_gn_4_7), .in_p(w_pn_4_7), .in_cin(in_cin), .out_cout(w_c16));
    carry C17(.in_g(w_gn_5_0), .in_p(w_pn_5_0), .in_cin(in_cin), .out_cout(w_c17));
    carry C18(.in_g(w_gn_5_1), .in_p(w_pn_5_1), .in_cin(in_cin), .out_cout(w_c18));
    carry C19(.in_g(w_gn_5_2), .in_p(w_pn_5_2), .in_cin(in_cin), .out_cout(w_c19));
    carry C20(.in_g(w_gn_5_3), .in_p(w_pn_5_3), .in_cin(in_cin), .out_cout(w_c20));
    carry C21(.in_g(w_gn_5_4), .in_p(w_pn_5_4), .in_cin(in_cin), .out_cout(w_c21));
    carry C22(.in_g(w_gn_5_5), .in_p(w_pn_5_5), .in_cin(in_cin), .out_cout(w_c22));
    carry C23(.in_g(w_gn_5_6), .in_p(w_pn_5_6), .in_cin(in_cin), .out_cout(w_c23));
    carry C24(.in_g(w_gn_5_7), .in_p(w_pn_5_7), .in_cin(in_cin), .out_cout(w_c24));
    carry C25(.in_g(w_gn_5_8), .in_p(w_pn_5_8), .in_cin(in_cin), .out_cout(w_c25));
    carry C26(.in_g(w_gn_5_9), .in_p(w_pn_5_9), .in_cin(in_cin), .out_cout(w_c26));
    carry C27(.in_g(w_gn_5_10), .in_p(w_pn_5_10), .in_cin(in_cin), .out_cout(w_c27));
    carry C28(.in_g(w_gn_5_11), .in_p(w_pn_5_11), .in_cin(in_cin), .out_cout(w_c28));
    carry C29(.in_g(w_gn_5_12), .in_p(w_pn_5_12), .in_cin(in_cin), .out_cout(w_c29));
    carry C30(.in_g(w_gn_5_13), .in_p(w_pn_5_13), .in_cin(in_cin), .out_cout(w_c30));
    carry C31(.in_g(w_gn_5_14), .in_p(w_pn_5_14), .in_cin(in_cin), .out_cout(w_c31));
    carry C32(.in_g(w_gn_5_15), .in_p(w_pn_5_15), .in_cin(in_cin), .out_cout(out_cout));

    // generate S
    sum S0(.in_p(w_p0), .in_cin(in_cin), .out_s(out_s[0]));
    sum S1(.in_p(w_p1), .in_cin(w_c1), .out_s(out_s[1]));
    sum S2(.in_p(w_p2), .in_cin(w_c2), .out_s(out_s[2]));
    sum S3(.in_p(w_p3), .in_cin(w_c3), .out_s(out_s[3]));
    sum S4(.in_p(w_p4), .in_cin(w_c4), .out_s(out_s[4]));
    sum S5(.in_p(w_p5), .in_cin(w_c5), .out_s(out_s[5]));
    sum S6(.in_p(w_p6), .in_cin(w_c6), .out_s(out_s[6]));
    sum S7(.in_p(w_p7), .in_cin(w_c7), .out_s(out_s[7]));
    sum S8(.in_p(w_p8), .in_cin(w_c8), .out_s(out_s[8]));
    sum S9(.in_p(w_p9), .in_cin(w_c9), .out_s(out_s[9]));
    sum S10(.in_p(w_p10), .in_cin(w_c10), .out_s(out_s[10]));
    sum S11(.in_p(w_p11), .in_cin(w_c11), .out_s(out_s[11]));
    sum S12(.in_p(w_p12), .in_cin(w_c12), .out_s(out_s[12]));
    sum S13(.in_p(w_p13), .in_cin(w_c13), .out_s(out_s[13]));
    sum S14(.in_p(w_p14), .in_cin(w_c14), .out_s(out_s[14]));
    sum S15(.in_p(w_p15), .in_cin(w_c15), .out_s(out_s[15]));
    sum S16(.in_p(w_p16), .in_cin(w_c16), .out_s(out_s[16]));
    sum S17(.in_p(w_p17), .in_cin(w_c17), .out_s(out_s[17]));
    sum S18(.in_p(w_p18), .in_cin(w_c18), .out_s(out_s[18]));
    sum S19(.in_p(w_p19), .in_cin(w_c19), .out_s(out_s[19]));
    sum S20(.in_p(w_p20), .in_cin(w_c20), .out_s(out_s[20]));
    sum S21(.in_p(w_p21), .in_cin(w_c21), .out_s(out_s[21]));
    sum S22(.in_p(w_p22), .in_cin(w_c22), .out_s(out_s[22]));
    sum S23(.in_p(w_p23), .in_cin(w_c23), .out_s(out_s[23]));
    sum S24(.in_p(w_p24), .in_cin(w_c24), .out_s(out_s[24]));
    sum S25(.in_p(w_p25), .in_cin(w_c25), .out_s(out_s[25]));
    sum S26(.in_p(w_p26), .in_cin(w_c26), .out_s(out_s[26]));
    sum S27(.in_p(w_p27), .in_cin(w_c27), .out_s(out_s[27]));
    sum S28(.in_p(w_p28), .in_cin(w_c28), .out_s(out_s[28]));
    sum S29(.in_p(w_p29), .in_cin(w_c29), .out_s(out_s[29]));
    sum S30(.in_p(w_p30), .in_cin(w_c30), .out_s(out_s[30]));
    sum S31(.in_p(w_p31), .in_cin(w_c31), .out_s(out_s[31]));

endmodule

```
### 32-bit Logic Unit

The logic unit contains bitwise AND, OR, and XOR operators.

```
module logic_unit32 (in_a, in_b, out_and, out_or, out_xor);
    input [31:0] in_a, in_b;
    output [31:0] out_and, out_or, out_xor;

    assign out_and = in_a & in_b;
    assign out_or = in_a | in_b;
    assign out_xor = in_a ^ in_b;
    
endmodule
```
### ALU Top Module

The top-level ALU module processes inputs in parallel through the 32-bit KSA and Logical Units, selecting the final output based on the 4-bit Opcode.

```
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
```
## Synthesis (Synopsys Design Compiler)

The Verilog source files were transferred to the school's Linux server environment via `scp` for logic synthesis. Using **Synopsys Design Compiler**, all sub-modules were compiled together in a single top-down flow to perform global timing and area optimization.

- **Target Technology Library:** Nangate 45nm Open Cell Library (`nangate.db`)
- **Synthesis Strategy:** Executed an integrated synthesis flow using a custom TCL script (`syn_alu.tcl`). The script loads all sub-modules simultaneously and applies `compile_ultra` with module ungrouping (flattening) to optimize critical paths and boundary logic across the entire ALU architecture.

```
# Set up the libraries
set link_library {./nangate.db}
set target_library {./nangate.db}

# Read all RTL source files
read_file -format verilog { \
    ./ksa32.v \
    ./logic_unit32.v \
    ./alu_top32.v \
}

# Set Top Module
current_design alu_top32
link

# Flatten hierarchy for boundary optimization (Method A)
set_ungroup [get_designs *] true

# Execute Ultra Synthesis
compile_ultra
```

## Place & Route (Synopsys Innovus)


## Toolchain & Implementation Flow
- **RTL:**  Verilog
- **Logic Synthesis:** Synopsys Design Compiler
- **Place & Route (P&R):** Cadence Innovus

## Future Plan
- Design efficient ALU using CSA
- Design Multiplier and Divider
