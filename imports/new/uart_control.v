`include<defines.v>
module uart_control(
	input wire clk,
	input wire rst,
	input wire rxd,
	input wire [31:0] storeData,
	input wire [3:0] uartOp_i,
	input wire [3:0] EX_uartOp_i,
	input wire [31:0] EX_addr_i,
	
	output wire txd,
	output reg [31:0] loadData_o,
	output reg pauseRequest,
	output wire dataReady,
	output wire writeReady
);
	
	parameter IDLE = 4'd0,
			  READ = 4'd1,
			  WRITE = 4'd2,
			  WRITE_HOLD = 4'd3;
	reg [3:0] state;
	reg [3:0] nstate;
	wire [7:0] ext_uart_rx;
	reg  [7:0] ext_uart_tx;
	wire ext_uart_ready, ext_uart_busy;
	reg ext_uart_start, ext_uart_clear;
	assign dataReady = ext_uart_ready;
	assign writeReady = ~ext_uart_busy;

	/*always @(posedge clk) begin
		pauseRequest <= 1'b0;
		ext_uart_start <= 1'b0;
		ext_uart_clear <= 1'b0;
		loadData_o <= 32'b0;
		if(uartOp_i == `MEM_SB || uartOp_i == `MEM_LB) begin
			if(uartOp_i == `MEM_SB) begin
				if(~ext_uart_busy) begin
					if(~pauseRequest) begin
						ext_uart_tx <= storeData[7:0];
						ext_uart_start <= 1'b1;
						pauseRequest <= 1'b1;
					end
				end else begin
					ext_uart_start <= 1'b0;
					pauseRequest <= 1'b0;
				end
			end else begin
				if(ext_uart_ready) begin
					loadData_o <= {24'b0, 8'h31};
					ext_uart_clear <= 1'b1;
					pauseRequest <= 1'b0;
				end else begin
					pauseRequest <= 1'b1;
				end
			end
		
		end else begin
			pauseRequest <= 1'b0;
			ext_uart_start <= 1'b0;
			ext_uart_clear <= 1'b0;
			loadData_o <= 32'h0;
		end
	end*/
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			state <= IDLE;
		end else begin
			state <= nstate;
		end
	end
	
	always @(*) begin
		if(rst == 1'b1) begin
			nstate <= IDLE;
			pauseRequest <= 1'b0;
			loadData_o <= 32'b0;
			ext_uart_start <= 1'b0;
			ext_uart_clear <= 1'b0;
			ext_uart_tx <= 8'b0;
		end else begin
			case(state) 
				IDLE: begin
					pauseRequest <= 1'b0;
					loadData_o <= 32'h32;
					ext_uart_start <= 1'b0;
					ext_uart_clear <= 1'b0;
					ext_uart_tx <= 8'b0;
					if(EX_uartOp_i == `MEM_SB && EX_addr_i == 32'hBFD003F8) begin
						nstate <= WRITE;
					end else if(EX_uartOp_i == `MEM_LB && EX_addr_i == 32'hBFD003F8) begin
						nstate <= READ;
					end else begin
						nstate <= IDLE;
					end
				end
				
				READ: begin
					if(ext_uart_ready) begin
						loadData_o <= {24'b0, ext_uart_rx};
						ext_uart_start <= 1'b0;
						ext_uart_clear <= 1'b1;
						ext_uart_tx <= 8'b0;
						pauseRequest <= 1'b0;
						if(EX_uartOp_i == `MEM_SB && EX_addr_i == 32'hBFD003F8) begin
							nstate <= WRITE;
						end else if(EX_uartOp_i == `MEM_LB && EX_addr_i == 32'hBFD003F8) begin
							nstate <= READ;
						end else begin
							nstate <= IDLE;
						end
					end else begin
						loadData_o <= 32'h0;
						ext_uart_start <= 1'b0;
						ext_uart_clear <= 1'b0;
						ext_uart_tx <= 8'b0;
						pauseRequest <= 1'b1;
						nstate <= READ;
					end
				end
				
				WRITE: begin
					loadData_o <= 32'h33;
					pauseRequest <= 1'b1;
					if(~ext_uart_busy) begin		
						ext_uart_tx <= storeData[7:0];
						ext_uart_start <= 1'b1;
						nstate <= WRITE_HOLD;
					end else begin
						ext_uart_tx <= storeData[7:0];
						ext_uart_start <= 1'b0;
						nstate <= WRITE;
					end
				end
				
				WRITE_HOLD: begin
					loadData_o <= 32'h34;
					ext_uart_tx <= storeData[7:0];
					ext_uart_start <= 1'b0;
					pauseRequest <= 1'b0;
					if(EX_uartOp_i == `MEM_SB && EX_addr_i == 32'hBFD003F8) begin
						nstate <= WRITE;
					end else if(EX_uartOp_i == `MEM_LB && EX_addr_i == 32'hBFD003F8) begin
						nstate <= READ;
					end else begin
						nstate <= IDLE;
					end
				end
				
				default: begin
					nstate <= IDLE;
					pauseRequest <= 1'b0;
					loadData_o <= 32'b0;
					ext_uart_start <= 1'b0;
					ext_uart_clear <= 1'b0;
					ext_uart_tx <= 8'b0;
				end
			endcase
		end
	end
	
	async_receiver #(.ClkFrequency(50000000),.Baud(9600))
		ext_uart_r(
			.clk(clk),                       
			.RxD(rxd),                           
			.RxD_data_ready(ext_uart_ready), 
			.RxD_clear(ext_uart_clear),       
			.RxD_data(ext_uart_rx)             
		);
	
	async_transmitter #(.ClkFrequency(50000000),.Baud(9600)) 
		ext_uart_t(
			.clk(clk),                  
			.TxD(txd),                      
			.TxD_busy(ext_uart_busy),      
			.TxD_start(ext_uart_start),    
			.TxD_data(ext_uart_tx)       
		);
		
endmodule