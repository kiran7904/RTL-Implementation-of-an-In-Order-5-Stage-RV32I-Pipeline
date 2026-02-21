module ex_mem_reg (
    input  logic clk,
    input  logic rst,
    input  logic [31:0] alu_out_ex,
    input  logic [4:0] rd_ex,
    output logic [31:0] alu_out_mem,
    output logic [4:0] rd_mem
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            alu_out_mem <= 0;
            rd_mem <= 0;
        end else begin
            alu_out_mem <= alu_out_ex;
            rd_mem <= rd_ex;
        end
    end
endmodule
