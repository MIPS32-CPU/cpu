module HILO(
	input wire clk,
	input wire rst,
	input wire [1:0] writeEnable_i,
	input wire [31:0] HI_data_i,
	input wire [31:0] LO_data_i,

	
	output reg [31:0] HI_data_o,
	output reg [31:0] LO_data_o
);
	reg [63:0] HILO;
	 
	//read HILO regisers
	always @(*) begin
		if(rst == 1'b1) begin
			HI_data_o <= 32'b0;
			LO_data_o <= 32'b0;
		end else if(writeEnable_i == 2'b10) begin
			HI_data_o <= HI_data_i;
		end else if(writeEnable_i == 2'b01) begin
			LO_data_o <= LO_data_i;
		end else if(writeEnable_i == 2'b11) begin
			HI_data_o <= HI_data_i;
			LO_data_o <= LO_data_i;	
		end else begin
			HI_data_o <= HILO[63:32];
			LO_data_o <= HILO[31:0];
		end
	end
	
	//write HILO registers
	always @(posedge clk) begin
		if(rst == 1'b0) begin 
			if(writeEnable_i == 2'b11) begin
				HILO <= {HI_data_i, LO_data_i};
			end else if(writeEnable_i == 2'b10) begin
				HILO[63:32] <= HI_data_i;
			end else if(writeEnable_i == 2'b01) begin
				HILO[31:0] <= LO_data_i;
			end
		end
	end
			
endmodule