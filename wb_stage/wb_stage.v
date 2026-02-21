module wb_stage (
    input  logic [31:0] wb_data,
    input  logic [4:0] rd_wb,
    output logic reg_write_wb
);
    assign reg_write_wb = (rd_wb != 0);
endmodule
