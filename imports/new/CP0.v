`include<defines.v>
module CP0(
	input wire clk,
	input wire rst,
	input wire writeEnable_i,
	input wire [4:0] writeAddr_i,
	input wire [31:0] writeData_i,
	input wire [4:0] readAddr_i,
	input wire [5:0] int_i, //hardware interuptions
	input wire [31:0] exceptionType_i,
	input wire [31:0] exceptionAddr_i,
	input wire in_delay_slot_i,
	input wire [31:0] badVaddr_i,
	
	output reg [31:0] readData_o,
	output reg [31:0] status_o,
	output reg [31:0] epc_o,
	output reg [31:0] cause_o,
	output reg [31:0] ebase_o,
	output reg [31:0] badVaddr_o
);
	
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			status_o <= {4'b0001, 28'b0}; //0001 means CP0 exists
			epc_o <= 32'b0;
			cause_o <= 32'b0;
			ebase_o <= 32'b0;
		end else begin
			cause_o[15:10] <= int_i;
			
			if(writeEnable_i == 1'b1) begin
				case(writeAddr_i)
					`STATUS: begin
						status_o <= writeData_i;
					end
					
					`EPC: begin
						epc_o <= writeData_i;
					end
					
					`CAUSE: begin
						cause_o[9:8] <= writeData_i[9:8];
						cause_o[23:22] <= writeData_i[23:22];
					end
					
					`EBASE: begin
						ebase_o <= writeData_i;
					end
					
					`BADVADDR: begin
						badVaddr_o <= writeData_i;
					end
					
					default: begin
					end
				endcase
			end 
		end

		case(exceptionType_i)
			32'h00000001: begin					//interruption
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'b0;//ExcCode bits
			end
			
			32'h4: begin				//addel
				if(status_o[1] == 1'b0) begin
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				
				if(badVaddr_i == 32'b0) begin
					badVaddr_o <= epc_o;
				end else begin
					badVaddr_o <= badVaddr_i;
				end
				end
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'b00100;//ExcCode bits
			end
			
			32'h5: begin					//addes
			if(status_o[1] == 1'b0) begin
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				badVaddr_o <= badVaddr_i;
				end
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'b00101;//ExcCode bits
			end
			

			32'h00000008: begin					//syscall
			
			if(status_o[1] == 1'b0) begin
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				end
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'b01000;//ExcCode bits
			end
			
			
			32'h00000009: begin					//break
			if(status_o[1] == 1'b0) begin
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				end
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'b01001;//ExcCode bits
			end
			

			32'h0000000a: begin					//reserved instruction
			if(status_o[1] == 1'b0) begin
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				end
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'b01010;//ExcCode bits
			end

			32'h0000000c: begin					//ovassert
			if(status_o[1] == 1'b0) begin
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				end
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'b01100;//ExcCode bits
			end

			32'h0000000e: begin					//eret
				status_o[1] <= 1'b0; //EXL bit
			end

			default: begin
				//ebase_o <= 32'b0;
			end
		endcase
	end
	
	always @(*) begin
		if(rst == 1'b1) begin
			readData_o <= 32'b0;
		end else if(writeEnable_i == 1'b1 && writeAddr_i == readAddr_i) begin
			if(readAddr_i == `CAUSE) begin
				readData_o <= {cause_o[31:24], writeData_i[23:22], cause_o[21:16], int_i, writeData_i[9:8], cause_o[7:0]};//cause register partly writable
			end else begin
				readData_o <= writeData_i;
			end
		end else begin
			case(readAddr_i) 
				`STATUS: begin
					readData_o <= status_o;
				end
				
				`CAUSE: begin
					readData_o <= cause_o;
				end
				
				`EPC: begin
					readData_o <= epc_o;
				end
				
				`EBASE: begin
					readData_o <= ebase_o;
				end
				
				`BADVADDR: begin
					readData_o <= badVaddr_o;
				end
				
				default: begin
					readData_o <= 32'b0;
				end
				
			endcase
		end
	end	
	
endmodule