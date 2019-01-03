`include<defines.v>

module MMU(
	input wire clk,
	input wire rst,
	input wire [31:0] data_ramAddr_i,
	input wire [31:0] inst_ramAddr_i,
	input wire [3:0] ramOp_i,
	input wire [31:0] storeData_i,
	input wire [31:0] load_data_i,
	input wire [31:0] load_inst_i,
	input wire [31:0] entrylo0_i,
	input wire [31:0] entrylo1_i,
	input wire [31:0] entryhi_i,
	input wire [3:0] index_i,
	input wire [3:0] random_i,
	input wire tlbwi,
	input wire tlbwr,
	input wire [31:0] EX_ramAddr_i,
	input wire [31:0] uart_load_data_i,
	input wire dataReady,
	input wire writeReady,
	
	output reg [3:0] ramOp_o,
	output reg [31:0] load_data_o,
	output reg [31:0] load_inst_o,
	output reg [31:0] storeData_o,
	output reg [19:0] instAddr_o,
	output reg [19:0] dataAddr_o,
	output reg [1:0] bytes_o,
	output reg [3:0] uartOp_o,
	output reg [31:0] uart_storeData_o,
	output wire tlbmiss,
	output wire EX_tlbmiss,
	output wire load_o,
	
	output reg vga_we,
	output reg [18:0] vga_addr,
	output reg [7:0] vga_data
);

	wire [18:0] vpn2 = entryhi_i[31:13];
	wire [7:0] asid = entryhi_i[7:0];
	wire [22:0] pfn0 = entrylo0_i[28:6];
	wire [22:0] pfn1 = entrylo1_i[28:6];
	wire [2:0] c0 = entrylo0_i[5:3];
	wire [2:0] c1 = entrylo1_i[5:3];
	wire d0 = entrylo0_i[2];
	wire d1 = entrylo1_i[2];
	wire v0 = entrylo0_i[1];
	wire v1 = entrylo1_i[1];
	wire g = entrylo0_i[0] & entrylo1_i[0];
	wire [3:0] index = (tlbwi == 1'b1) ? index_i : ((tlbwr == 1'b1) ? random_i : 4'b0);
	wire load = (ramOp_i == `MEM_LW || ramOp_i == `MEM_LB || ramOp_i == `MEM_LBU ||
				 ramOp_i == `MEM_LH || ramOp_i == `MEM_LHU) ? 1'b1 : 1'b0;
	wire store = (ramOp_i == `MEM_SW || ramOp_i == `MEM_SH || ramOp_i == `MEM_SB) ? 1'b1 : 1'b0;
	reg tlbmiss_reg;
	reg uart_enable;
	assign tlbmiss = tlbmiss_reg;
	assign load_o = load;

	always @(*) begin 
		if(rst == 1'b1) begin
			load_inst_o <= 32'b0;
			instAddr_o <= 20'b0;
		end else begin
			load_inst_o <= load_inst_i;
			instAddr_o <= inst_ramAddr_i[21:2];
		end
	end
	
	reg [83:0] tlb[0:15];
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			tlb[0] <= 83'b0;
		end else if(tlbwi == 1'b1 || tlbwr == 1'b1) begin
			tlb[index][`VPN2] <= vpn2;
			tlb[index][`ASID] <= asid;
			tlb[index][`PFN0] <= pfn0;
			tlb[index][`PFN1] <= pfn1;
			tlb[index][`C0] <= c0;
			tlb[index][`C1] <= c1;
			tlb[index][`D0] <= d0;
			tlb[index][`D1] <= d1;
			tlb[index][`V0] <= v0;
			tlb[index][`V1] <= v1;
			tlb[index][`G] <= g;
		end
	end
	
	
	always @(*) begin
		if(rst == 1'b1) begin
			uartOp_o <= `MEM_NOP;
			uart_storeData_o <= 32'b0;
			ramOp_o <= `MEM_NOP;
			storeData_o <= 32'b0;
			dataAddr_o <= 20'b0;
			bytes_o <= 2'b0;
			tlbmiss_reg <= 1'b0;
			uart_enable <= 1'b0;
			load_data_o <= 32'b0;
			vga_we <= 1'b0;
            vga_addr <= data_ramAddr_i[18:0];
            vga_data <= 8'b00000011;
			
		end else if(data_ramAddr_i < 32'h80000000) begin
			uart_enable <= 1'b0;
			uartOp_o <= `MEM_NOP;
			uart_storeData_o <= 32'b0;
			storeData_o <= storeData_i;
			if(load || store) begin
				if(tlb[0][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[0][`G] == 1'b1 || tlb[0][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[0][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[0][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[1][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[1][`G] == 1'b1 || tlb[1][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[1][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[1][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[2][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[2][`G] == 1'b1 || tlb[2][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[2][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[2][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[3][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[3][`G] == 1'b1 || tlb[3][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[3][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[3][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[4][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[4][`G] == 1'b1 || tlb[4][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[4][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[4][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[5][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[5][`G] == 1'b1 || tlb[5][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[5][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[5][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[6][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[6][`G] == 1'b1 || tlb[6][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[6][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[6][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[7][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[7][`G] == 1'b1 || tlb[7][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[7][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[7][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[8][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[8][`G] == 1'b1 || tlb[8][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[8][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[8][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[9][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[9][`G] == 1'b1 || tlb[9][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[9][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[9][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[10][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[10][`G] == 1'b1 || tlb[10][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[10][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[10][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[11][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[11][`G] == 1'b1 || tlb[11][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[11][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[11][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[12][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[12][`G] == 1'b1 || tlb[12][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[12][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[12][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[13][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[13][`G] == 1'b1 || tlb[13][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[13][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[13][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[14][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[14][`G] == 1'b1 || tlb[14][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[14][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[14][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else if(tlb[15][`VPN2] == data_ramAddr_i[31:13] &&
				   (tlb[15][`G] == 1'b1 || tlb[15][`ASID] == asid)) begin
					if(data_ramAddr_i[12] == 1'b0) begin
						dataAddr_o <= {tlb[15][`PFN0], data_ramAddr_i[11:2]};
					end else begin
						dataAddr_o <= {tlb[15][`PFN1], data_ramAddr_i[11:2]};
					end		
					ramOp_o <= ramOp_i;
					bytes_o <= data_ramAddr_i[1:0];
					tlbmiss_reg <= 1'b0;
				end else begin
					ramOp_o <= `MEM_NOP;
					dataAddr_o <= 20'b0;
					bytes_o <= 2'b0;
					tlbmiss_reg <= 1'b1;
				end
			end else begin
				ramOp_o <= `MEM_NOP;
				storeData_o <= 32'b0;
				dataAddr_o <= 20'b0;
				bytes_o <= 2'b0;
				tlbmiss_reg <= 1'b0;
			end
			load_data_o <= load_data_i;
			vga_we <= 1'b0;
            vga_addr <= data_ramAddr_i[18:0];
            vga_data <= 8'b00000011;
		end else if(data_ramAddr_i == 32'hBFD003F8) begin
			uart_enable <= 1'b1;
			uartOp_o <= ramOp_i;
			uart_storeData_o <= storeData_i;
			ramOp_o <= `MEM_NOP;
			storeData_o <= 32'b0;
			dataAddr_o <= 20'b0;
			bytes_o <= 2'b0;
			tlbmiss_reg <= 1'b0;
			load_data_o <= uart_load_data_i;	
			//load_data_o <= 32'h31;
			vga_we <= 1'b0;
            vga_addr <= data_ramAddr_i[18:0];
            vga_data <= 8'b00000011;
		end else if(data_ramAddr_i == 32'hBFD003FC) begin
			/*if(dataReady == 1'b1) begin
				load_data_o <= 32'h00000002;
			end else if(writeReady == 1'b1) begin
				load_data_o <= 32'h00000001;
			end else begin
				load_data_o <= 32'h0;
			end*/
			load_data_o <= {30'b0, dataReady, writeReady};
			
			uart_enable <= 1'b0;
			uartOp_o <= `MEM_NOP;
			uart_storeData_o <= 32'b0;
			ramOp_o <= `MEM_NOP;
			storeData_o <= 32'b0;
			dataAddr_o <= 20'b0;
			bytes_o <= 2'b0;
			tlbmiss_reg <= 1'b0;
			vga_we <= 1'b0;
            vga_addr <= data_ramAddr_i[18:0];
            vga_data <= 8'b00000011;
		end else if(data_ramAddr_i >= 32'h90000000) begin
		    uartOp_o <= `MEM_NOP;
            uart_storeData_o <= 32'b0;
            ramOp_o <= `MEM_NOP;
            storeData_o <= 32'b0;
            dataAddr_o <= 20'b0;
            bytes_o <= 2'b0;
            tlbmiss_reg <= 1'b0;
            uart_enable <= 1'b0;
            load_data_o <= 32'b0;
            if (ramOp_i == `MEM_SB) begin
                vga_we <= 1'b1;
                if (data_ramAddr_i[18:0]>480000) begin
                    vga_addr <= 10;
                end
                else begin
                    vga_addr <= data_ramAddr_i[18:0]+10;
                end
                vga_data <= 8'b00011100;
            end
		end else begin
			uartOp_o <= `MEM_NOP;
			uart_storeData_o <= 32'b0;
			ramOp_o <= ramOp_i;
			storeData_o <= storeData_i;
			dataAddr_o <= data_ramAddr_i[21:2];
			bytes_o <= data_ramAddr_i[1:0];
			tlbmiss_reg <= 1'b0;
			uart_enable <= 1'b0;
			load_data_o <= load_data_i;
			vga_we <= 1'b0;
            vga_addr <= data_ramAddr_i[18:0];
            vga_data <= 8'b00000011;
		end
	end
	
	reg EX_tlbmiss_reg;
	assign EX_tlbmiss = EX_tlbmiss_reg;
	always @(*) begin
		if(rst == 1'b1) begin
			EX_tlbmiss_reg <= 1'b0;
		end else if(EX_ramAddr_i < 32'h80000000)begin
			if(tlb[0][`VPN2] == EX_ramAddr_i[31:13] &&
			   (tlb[0][`G] == 1'b1 || tlb[0][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[1][`VPN2] == EX_ramAddr_i[31:13] &&
			   (tlb[1][`G] == 1'b1 || tlb[1][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[2][`VPN2] == EX_ramAddr_i[31:13] &&
			   (tlb[2][`G] == 1'b1 || tlb[2][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[3][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[3][`G] == 1'b1 || tlb[3][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[4][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[4][`G] == 1'b1 || tlb[4][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[5][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[5][`G] == 1'b1 || tlb[5][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[6][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[6][`G] == 1'b1 || tlb[6][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[7][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[7][`G] == 1'b1 || tlb[7][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[8][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[8][`G] == 1'b1 || tlb[8][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[9][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[9][`G] == 1'b1 || tlb[9][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[10][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[10][`G] == 1'b1 || tlb[10][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[11][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[11][`G] == 1'b1 || tlb[11][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[12][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[12][`G] == 1'b1 || tlb[12][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[13][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[13][`G] == 1'b1 || tlb[13][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[14][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[14][`G] == 1'b1 || tlb[14][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else if(tlb[15][`VPN2] == EX_ramAddr_i[31:13] &&
				(tlb[15][`G] == 1'b1 || tlb[15][`ASID] == asid)) begin
				EX_tlbmiss_reg <= 1'b0;
			end else begin
				EX_tlbmiss_reg <= 1'b1;
			end
		end else begin
			EX_tlbmiss_reg <= 1'b0;
		end
	end
	
endmodule