#### Continuous vs Procedural Assignments
1. **Continuous assignment (`assign`)** is used with **nets/wires**, executes **concurrently**, and updates the value **whenever RHS changes** → e.g., `assign sum = a + b;`.  
2. It models **combinational logic** and does not need procedural blocks. Modeling pure combinational logic (AND, OR, adders, muxes).
3. **Procedural assignments** (`initial`, `always`, `final`, inside `task`/`function`) are used with **variables (`reg`/`logic`)**.  
   - `always` is part of the program that is continuously evaluated in simulation period
   - `initial` is used for one-time setup at the start of simulation
   - for multiple statements in initial/always block use `initial begin ... end`
4. They execute **sequentially inside time-ordered blocks**, not always concurrently.  
Modeling sequential/step by step/ time-ordered logic (flip-flops, registers, state machines) or testbench behavior (stimulus, loops, delays).
5. Example: `always @(posedge clk) q <= d;` (procedural) vs `assign y = a & b;` (continuous).  
6. In short → **`assign` = hardware wiring/combinational**, **procedural = behavior over time (sequential + clocking + simulation control)**.  


#### Verification Steps

1. In verification, we create a **testbench (TB)** to drive inputs and capture outputs of the **DUT (Device Under Test)** (here: `adder`).  
2. We declare **TB signals** (`logic [7:0] tb_a, tb_b; logic tb_c_in; logic [7:0] tb_sum; logic tb_c_out;`) to act as wires between TB and DUT.  
3. We then **instantiate the DUT** inside TB (like creating an object) → `adder adder1(.a(tb_a), .b(tb_b), .c_in(tb_c_in), .sum(tb_sum), .c_out(tb_c_out));`.  
4. This process is called **DUT instantiation and port mapping**, where each DUT port is connected to a TB signal (`.a(tb_a)` means DUT’s `a` uses TB’s `tb_a`).  
5. After this, TB can **drive inputs** (`tb_a=8'h05;`) and **observe outputs** (`$display(tb_sum);`), enabling **simulation-based verification**.  


```sv
// Adder DUT
module adder(a,b,c_in,sum,c_out);
  input [7:0] a, b;
  input c_in;
  output [7:0] sum;
  output c_out;
  logic [8:0] result;

  assign result = a + b + c_in;
  assign sum = result[7:0];
  assign c_out = result[8];
endmodule: adder 
```

```sv
// Testbench for Adder DUT
module test_bench; // declaring module
  logic [7:0] tb_a, tb_b;
  logic tb_c_in;
  logic [7:0] tb_sum;
  logic tb_c_out;

  // Instantiate DUT & connect ports (Maps DUT ports to TB signals using the above mentioned wires)
  adder dut(.a(tb_a), .b(tb_b), .c_in(tb_c_in), .sum(tb_sum), .c_out(tb_c_out));

  initial begin
    #1; // Wait for 1 time unit
    // Apply test vectors
    tb_a = 8'h05; tb_b = 8'h03; tb_c_in = 1'b0;

    #1; // driving maximum value
    tb_a = 8'hFF; tb_b = 8'h00; tb_c_in = 1'b1;
    $display("Sum: %h, Cout: %b", tb_sum, tb_c_out);

    #1;
    tb_a = 0;
    $finish();
  end
  initial begin
  $dumpfile("test_bench.vcd");
  $dumpvars;
  end
endmodule: test_bench
```
