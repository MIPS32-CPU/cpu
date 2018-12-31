
module flash_control(
    input wire clk,
    input wire rst,
    
    input wire vga_re,
    input wire [22:0] vga_addr,
    output reg [15:0] vga_data,
    output reg vga_success,

    output wire [22:0] flash_a,
    inout wire [15:0] flash_d,
    output wire flash_rp_n,
    output wire flash_vpen,
    output wire flash_ce_n,
    output wire flash_oe_n,
    output wire flash_we_n,
    output wire flash_byte_n
);

    reg [22:0] flash_addr;
    reg [15:0] flash_data;
    reg flash_rp;
    reg flash_vpe;
    reg flash_ce;
    reg flash_oe;
    reg flash_we;
    reg flash_byte;
    
    assign flash_a = flash_addr;
    assign flash_d = 16'bz;
    assign flash_rp_n = flash_rp;
    assign flash_vpen = flash_vpe;
    assign flash_ce_n = flash_ce;
    assign flash_oe_n = flash_oe;
    assign flash_we_n = flash_we;
    assign flash_byte_n = flash_byte;
    


    parameter waiting = 4'd0,
                read1 = 4'd1,
                read2 = 4'd2,
                read3 = 4'd3,
                read4 = 4'd4,
                done = 4'd5;
                
    reg[3:0] state, nstate;
    
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            state <= waiting;
        end
        else begin
            state <= nstate;
        end
    end
    
    always @(posedge clk) begin
    
        flash_addr <= 23'b0;
        vga_data <= 16'b0;
        flash_byte <= 1'b1;
        flash_vpe <= 1'b1;
        flash_ce <= 1'b1;
        flash_rp <= 1'b1;
        vga_success <= 1'b0;
    
        if (rst == 1'b1) begin
            flash_oe <= 1'b1;
            flash_we <= 1'b1;
            nstate <= waiting;
        end
        else begin
            case (state)
                waiting: begin
                    flash_oe <= 1'b1;
                    if (vga_re == 1'b1) begin
                       flash_we <= 1'b0;
                       nstate <= read1;
                    end
                    else begin
                       flash_we <= 1'b1;
                       nstate <= waiting;
                    end
                end
                read1: begin
                    flash_oe <= 1'b1;
                    flash_we <= 1'b0;
                    nstate <= read2;
                end
                read2: begin
                    flash_oe <= 1'b1;
                    flash_we <= 1'b1;
                    nstate <= read3;
                end
                read3: begin
                    flash_addr <= vga_addr;
                    flash_oe <= 1'b0;
                    flash_we <= 1'b1;
                    nstate <= read4;
                end
                read4: begin
                    vga_data <= flash_d;
                    flash_oe <= 1'b0;
                    flash_we <= 1'b1;
                    nstate <= done;
                    vga_success <= 1'b1;
                end
                default: begin
                    flash_oe <= 1'b1;
                    flash_we <= 1'b1;
                    nstate <= waiting;
                end
            endcase
        end
    end
 
endmodule
