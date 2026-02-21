module if_id_reg (
    input  logic clk,
    input  logic rst,
    input  logic stall,
    input  logic [31:0] pc_if,
    input  logic [31:0] instr_if,
    output logic [31:0] pc_id,
    output logic [31:0] instr_id
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            pc_id    <= 0;
            instr_id <= 32'h00000013;
        end else if (!stall) begin
            pc_id    <= pc_if;
            instr_id <= instr_if;
        end
    end
endmodule
