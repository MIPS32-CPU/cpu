`timescale 1ns/1ps
`include<defines.v>

module inst_sram_control (
	input wire rst,
	input wire [19:0] ramAddr_i,
	
	output reg [31:0] loadData_o,
	output reg WE_n_o,
	output reg OE_n_o,
	output reg CE_n_o,
	output reg [3:0] be_n_o,
	output reg [19:0] ramAddr_o,
	
	inout wire [31:0] data_io
);	
	reg [31:0] data_io_reg;
	reg [1:0] state, nstate;
	assign data_io = data_io_reg;

		
    always @(*) begin
    	if(rst == 1'b1) begin
			WE_n_o <= 1'b1;
			CE_n_o <= 1'b0;
			OE_n_o <= 1'b0;
			be_n_o <= 4'b0;
			ramAddr_o <= 20'b0;
			loadData_o <= 32'b0;
			data_io_reg <= 32'bz;
		end else begin
			WE_n_o <= 1'b1;
			CE_n_o <= 1'b0;
			OE_n_o <= 1'b0;
			be_n_o <= 4'b0;
			data_io_reg <= 32'bz;
			loadData_o <= data_io;
			ramAddr_o <= ramAddr_i;
		end			
    end
	 
endmodule	
