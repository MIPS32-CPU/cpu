`include<defines.v>
module uart_control(
	input wire clk,
	input wire rst,
	input wire tbre,
	input wire tsre,
	input wire data_ready,
	input wire storeData,
	input wire [3:0] uartOp_i,
	input wire [3:0] EX_uartOp_i,
	input wire [31:0] EX_addr_i,
	
	
	output reg rdn,
	output reg wrn,
	output reg [31:0] loadData_o,
	output reg pauseRequest,
	output wire [31:0] data_o,
	inout wire [31:0] data_io
);
	assign data_o = (uartOp_i == `MEM_SB) ? storeData : 32'bz;
	reg [3:0] state, nstate;
	parameter INIT = 4'd0,
			  READ1 = 4'd1,
			  READ2 = 4'd2,
			  READ3 = 4'd3,
			  WRITE1 = 4'd4,
			  WRITE2 = 4'd5,
			  WRITE3 = 4'd6,
			  WRITE4 = 4'd7;
		
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			state <= INIT;
		end else begin
			state <= nstate;
		end
	end
	
	always @(*) begin
		if(rst == 1'b1) begin
			wrn <= 1'b1;
			rdn <= 1'b1;
			pauseRequest <= 1'b0;
			loadData_o <= 32'b0;
			
			nstate <= INIT;
			
		end else begin
			case(state)
				INIT: begin
					wrn <= 1'b1;
					rdn <= 1'b1;
					pauseRequest <= 1'b0;
					loadData_o <= 32'b0;
					
					if(EX_uartOp_i == `MEM_SB && EX_addr_i == 32'hBFD003F8) begin
						nstate <= WRITE1;
					end else if(EX_uartOp_i == `MEM_LB && EX_addr_i == 32'hBFD003F8) begin
						nstate <= READ1;
					end else begin
						nstate <= INIT;
					end
					
				end
				
				WRITE1: begin
					
					wrn <= 1'b0;
					rdn <= 1'b1;
					pauseRequest <= 1'b1;
					loadData_o <= 32'b0;
					nstate <= WRITE2;
					
				end
				
				WRITE2: begin
					wrn <= 1'b1;
					rdn <= 1'b1;
					
					pauseRequest <= 1'b1;
					loadData_o <= 32'b0;
					nstate <= WRITE3;
					
				end
				
				WRITE3: begin
					wrn <= 1'b1;
					rdn <= 1'b1;
					
					pauseRequest <= 1'b1;
					loadData_o <= 32'b0;
					if(tbre == 1'b1) begin
						nstate <= WRITE4;
					end else begin
						nstate <= WRITE3;
					end
					
				end
				
				WRITE4: begin
					wrn <= 1'b1;
					rdn <= 1'b1;
					
					pauseRequest <= 1'b1;
					loadData_o <= 32'b0;
					if(tsre == 1'b1) begin
						nstate <= INIT;
					end else begin
						nstate <= WRITE4;
					end 
					
				end
				
				READ1: begin
					rdn <= 1'b1;
					wrn <= 1'b1;
					loadData_o <= 32'b0;
					
					pauseRequest <= 1'b1;
					nstate <= READ2;
					
				end 
				
				READ2: begin
					wrn <= 1'b1;
					
					loadData_o <= 32'b0;
					pauseRequest <= 1'b1;
					if(data_ready == 1'b1) begin
						rdn <= 1'b0;
						nstate <= READ3;
					end else begin
						rdn <= 1'b1;
						nstate <= READ1;
					end 
					
				end
				
				READ3: begin
					rdn <= 1'b1;
					wrn <= 1'b1;
					
					pauseRequest <= 1'b1;
					loadData_o <= {{24{data_io[7]}}, data_io[7:0]};
					nstate <= INIT;
					
				end
				
				default: begin
					wrn <= 1'b1;
					rdn <= 1'b1;
					pauseRequest <= 1'b0;
					loadData_o <= 32'b0;
					
					nstate <= INIT;
					
				end
			
			endcase
		end
	end

endmodule