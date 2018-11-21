module div(
	input wire clk,
	input wire rst,
	input wire signed_i,
	input wire [31:0] dividend_i,
	input wire [31:0] divider_i,
	input wire concell_i,
	input wire start_i,
	
	output reg [63:0] result_o,
	output reg success_o
);

	wire [32:0] div_temp;
	reg [31:0] divider;
	reg [64:0] dividend;
	reg [5:0] cnt;
	reg [1:0] state, nstate;
	reg [31:0] temp_dividend;
	reg [31:0] temp_divider;
	
	assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divider};
	
	parameter DIV_FREE = 2'b00,
			  DIV_ZERO = 2'b01,
			  DIV_ON = 2'b10,
			  DIV_END = 2'b11;
	
	
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			state <= DIV_FREE;
		end else begin
			state <= nstate;
		end
	end
	
	always @(*) begin
		case(state) 
			DIV_FREE: begin
				if(start_i == 1'b1 && divider_i == 32'b0 && concell_i == 1'b0) begin
					nstate <= DIV_ZERO;
					
				end else if(start_i == 1'b1 && divider_i != 32'b0 && concell_i == 1'b0) begin
					nstate <= DIV_ON;
					
				end else begin
					nstate <= DIV_FREE;
				end
			end
			
			DIV_ZERO: begin
				nstate <= DIV_END;
			end
			
			DIV_ON: begin
				if(concell_i == 1'b0 && cnt[5] == 1'b0) begin
					nstate <= DIV_ON;
					
				end else if(concell_i == 1'b0 && cnt[5] == 1'b1) begin
					nstate <= DIV_END;
						
				end else begin
					nstate <= DIV_FREE;
				end
			end
			
			DIV_END: begin
				if(start_i == 1'b0) begin
					nstate <= DIV_FREE;
				end
			end
		endcase
	end
	
	always @(posedge clk) begin
		if(rst == 1'b1) begin
			result_o <= 64'b0;
			success_o <= 1'b0;
		end else begin
			case(state) 
				DIV_FREE: begin
				    if(start_i == 1'b1 && divider_i != 32'b0 && concell_i == 1'b0) begin
                        cnt <= 6'b0;
                        if(signed_i == 1'b1 && dividend_i[31] == 1'b1) begin
                            temp_dividend = ~dividend_i + 1'b1;
                        end else begin
                            temp_dividend = dividend_i;
                        end
                        
                        if(signed_i == 1'b1 && divider_i[31] == 1'b1) begin
                            temp_divider = ~divider_i + 1'b1;
                        end else begin
                            temp_divider = divider_i;
                        end
                        
                        dividend = 65'b0;
                        divider = temp_divider;
                        dividend[32:1] = temp_dividend; 
                    end
					success_o <= 1'b0;
					result_o <= 64'b0; 
				end
				
				DIV_ZERO: begin
					result_o <= 64'b0;
					success_o <= 1'b0;
				end
				
				DIV_ON: begin
				    if(concell_i == 1'b0 && cnt[5] == 1'b0) begin
                        if(div_temp[32] == 1'b1) begin
                            dividend <= {dividend[63:0], 1'b0};
                        end else begin
                            dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
                        end
                        cnt <= cnt + 1'b1;
                        
                    end else if(concell_i == 1'b0 && cnt[5] == 1'b1) begin
                        
                        if(signed_i == 1'b1 && dividend_i[31] != divider_i[31]) begin
                            dividend[31:0] <= ~dividend[31:0] + 1'b1;
                        end
                        if(signed_i == 1'b1 && dividend_i[31] ^ dividend[64] == 1'b1) begin
                            dividend[64:33] <= ~dividend[64:33] + 1'b1;
                        end 
                        cnt <= 6'b0;
                    end
					result_o <= 64'b0;
					success_o <= 1'b0;
				end
				
				DIV_END: begin
					result_o <= {dividend[64:33], dividend[31:0]};
					success_o <= 1'b1;
				end
			endcase	
		end	
	end			
	

endmodule
	