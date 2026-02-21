module if_stage (
    input  logic clk,
    input  logic rst,
    input  logic stall,
    output logic [31:0] pc_if,
    output logic [31:0] instr_if
);
    logic [31:0] instr_mem [0:255];
    logic [31:0] pc;

    initial $readmemh("program.hex", instr_mem);

    always_ff @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 0;
        else if (!stall)
            pc <= pc + 4;
    end

    assign instr_if = instr_mem[pc[9:2]];
    assign pc_if    = pc;
endmodule
