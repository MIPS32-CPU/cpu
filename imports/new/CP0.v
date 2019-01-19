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
	input wire tlbmiss_i,
	input wire load_i,
	
	output reg [31:0] readData_o,
	output reg [31:0] status_o,
	output reg [31:0] epc_o,
	output reg [31:0] cause_o,
	output reg [31:0] ebase_o,
	output reg [31:0] badVaddr_o,
	output reg [31:0] index_o,
	output reg [31:0] random_o,
	output reg [31:0] entrylo0_o,
	output reg [31:0] entrylo1_o,
	output reg [31:0] pagemask_o,
	output reg [31:0] config_o,
	output reg [31:0] entryhi_o,
	output reg [31:0] context_o
);
	
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			status_o <= {4'b0001, 28'b0}; //0001 means CP0 exists
			epc_o <= 32'b0;
			cause_o <= 32'b0;
			ebase_o <= 32'b0;
			index_o <= {1'bx, 23'b0, 4'bx};
			random_o <= {28'b0, 4'b1111};
			entrylo0_o <= {1'b0, 31'bx};
			entrylo1_o <= {1'b0, 31'bx};
			context_o <= {28'bx, 4'b0};
			pagemask_o <= {3'b0, 16'bx, 13'b0};
			badVaddr_o <= 32'bx;
			entryhi_o <= {19'bx, 5'b0, 8'bx};
			config_o <= 32'b0;
		end else begin
			cause_o[15:10] <= int_i;
			
			random_o[3:0] <= random_o[3:0] + 4'b1111;
			
			
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
					
					`INDEX: begin
						index_o[3:0] <= writeData_i[3:0];
					end 
					
					`ENTRYLO0: begin
						entrylo0_o[29:0] <= writeData_i[29:0];
					end
					
					`ENTRYLO1: begin
						entrylo1_o[29:0] <= writeData_i[29:0];
					end
					
					`CONTEXT: begin
						context_o[31:23] <= writeData_i[31:23];
					end
					
					`PAGEMASK: begin
						pagemask_o[28:13] <= writeData_i[28:13];
					end
					
					`ENTRYHI: begin
						entryhi_o[31:13] <= writeData_i[31:13];
						entryhi_o[7:0] <= writeData_i[7:0];
					end 
					
					`CONFIG: begin
					end 
					
					default: begin
					end
				endcase
			end 
		end

		case(exceptionType_i)
			32'h1: begin					//interruption
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
			

			32'h8: begin					//syscall
			
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
			
			
			32'h9: begin					//break
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
			

			32'ha: begin					//reserved instruction
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

			32'hc: begin					//ovassert
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

			32'he: begin					//eret
				status_o[1] <= 1'b0; //EXL bit
			end
			
			32'h10: begin					//interruption
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'd13;//ExcCode bits
			end
	
			32'h11: begin					//interruption
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'd14;//ExcCode bits
			end
	
			32'h12: begin					//interruption
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'd15;//ExcCode bits
			end
	
			32'h13: begin					//interruption
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
				status_o[1] <= 1'b1; //EXL bit
				cause_o[6:2] <= 5'd16;//ExcCode bits
			end

			default: begin
				//ebase_o <= 32'b0;
			end
		endcase
		
		if(tlbmiss_i == 1'b1) begin
			if(status_o[1] == 1'b0) begin
				if(in_delay_slot_i == 1'b1) begin
					epc_o <= exceptionAddr_i - 4;
					cause_o[31] <= 1'b1; //cause register BD(branch delay) bit
				end else begin 
					epc_o <= exceptionAddr_i;
					cause_o[31] <= 1'b0;
				end 
			end
			badVaddr_o <= badVaddr_i;
			entryhi_o[31:13] <= badVaddr_i[31:13];
			status_o[1] <= 1'b1; //EXL bit
			if(load_i == 1'b1) begin
				cause_o[6:2] <= 5'b10;//ExcCode bits
			end else begin
				cause_o[6:2] <= 5'b11;
			end
		end
	end
	
	always @(*) begin
		if(rst == 1'b1) begin
			readData_o <= 32'b0;
		end else if(writeEnable_i == 1'b1 && writeAddr_i == readAddr_i) begin
			if(readAddr_i == `CAUSE) begin
				readData_o <= {cause_o[31:24], writeData_i[23:22], cause_o[21:16], int_i, writeData_i[9:8], cause_o[7:0]};//cause register partly writable
			end else if(readAddr_i == `INDEX) begin
				readData_o <= {index_o[31:4], writeData_i[3:0]};
			end else if(readAddr_i == `RANDOM) begin
				readData_o <= random_o;
			end else if(readAddr_i == `ENTRYLO0) begin
				readData_o <= {entrylo0_o[31:30], writeData_i[29:0]};
			end else if(readAddr_i == `ENTRYLO1) begin
				readData_o <= {entrylo1_o[31:30], writeData_i[29:0]};
			end else if(readAddr_i == `CONTEXT) begin
				readData_o <= {writeData_i[31:23], context_o[22:0]};
			end else if(readAddr_i == `PAGEMASK) begin
				readData_o <= {3'b0, writeData_i[28:13], 13'b0};
			end else if(readAddr_i == `BADVADDR) begin
				readData_o <= badVaddr_o;
			end else if(readAddr_i == `ENTRYHI) begin
				readData_o <= {writeData_i[31:13], 5'b0, writeData_i[7:0]};
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
				
				`INDEX: begin
					readData_o <= index_o;
				end
				
				`RANDOM: begin
					readData_o <= random_o;
				end
				
				`ENTRYLO0: begin
					readData_o <= entrylo0_o;
				end
				
				`ENTRYLO1: begin
					readData_o <= entrylo1_o;
				end
				
				`CONTEXT: begin
					readData_o <= context_o;
				end
				
				`PAGEMASK: begin
					readData_o <= pagemask_o;
				end
				
				`ENTRYHI: begin
					readData_o <= entryhi_o;
				end
				
				`CONFIG: begin
					readData_o <= config_o;
				end
				
				default: begin
					readData_o <= 32'b0;
				end
				
			endcase
		end
	end	
	
endmodule