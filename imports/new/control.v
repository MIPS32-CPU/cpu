module control(
	input wire rst,
	input wire stall_from_exe,//stall request from EXE
	input wire stall_from_id,
	input wire stall_from_mem,
	input wire stall_from_pc,
	
	input wire [31:0] exceptionType_i,
	input wire [31:0] CP0_epc_i,
	input wire [31:0] CP0_ebase_i,
	input wire tlbmiss_i,
	/*stall[0] pc stall
	stall[1] IF stall
	stall[2] ID stall
	stall[3] EXE stall
	stall[4] MEM stall
	stall[5] WB stall*/
	output reg [5:0] stall,
	output reg flush,
	output reg [31:0] exceptionHandleAddr_o
);

	always @(*) begin
		if(rst == 1'b1) begin
			stall <= 6'b0;
			flush <= 1'b0;
			exceptionHandleAddr_o <= 32'h80000000;
		end else if(tlbmiss_i == 1'b1) begin
			stall <= 6'b0;
			flush <= 1'b1;
			exceptionHandleAddr_o <= CP0_ebase_i;
		end else if(exceptionType_i != 32'b0) begin
			stall <= 6'b0;
			flush <= 1'b1;
			if(exceptionType_i == 32'h0000000e) begin
				exceptionHandleAddr_o <= CP0_epc_i;
			end else begin
				exceptionHandleAddr_o <= CP0_ebase_i + 32'h00000180;
			end
		end else if(stall_from_mem == 1'b1) begin
			stall <= 6'b011111;	
			flush <= 1'b0;
			exceptionHandleAddr_o <= 32'h80000000;
		end else if(stall_from_exe == 1'b1) begin
			stall <= 6'b001111;
			flush <= 1'b0;
			exceptionHandleAddr_o <= 32'h80000000;
		end else if(stall_from_id == 1'b1) begin
			stall <= 6'b000111;
			flush <= 1'b0;
			exceptionHandleAddr_o <= 32'h80000000;
		end else if(stall_from_pc == 1'b1) begin
			stall <= 6'b000011;
			flush <= 1'b0;
			exceptionHandleAddr_o <= 32'h80000000;
		end else begin
			stall <= 6'b0;
			flush <= 1'b0;
			exceptionHandleAddr_o <= 32'h80000000;
		end
	end
endmodule