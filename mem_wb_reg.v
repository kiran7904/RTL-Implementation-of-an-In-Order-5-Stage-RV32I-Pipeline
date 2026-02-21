module mem_wb_reg (
    input  logic clk,
    input  logic rst,
    input  logic [31:0] mem_out,
    input  logic [4:0] rd_mem,
    output logic [31:0] wb_data,
    output logic [4:0] rd_wb
);
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_data <= 0;
            rd_wb <= 0;
        end else begin
            wb_data <= mem_out;
            rd_wb <= rd_mem;
        end
    end
endmodule
