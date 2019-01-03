module vga_control(
    input wire clk,
    input wire rst,
    
    // VGA
    output wire[2:0] video_red,
    output wire[2:0] video_green,
    output wire[1:0] video_blue,
    output wire video_hsync,
    output wire video_vsync,
    output wire video_clk,
    output wire video_de,
    
    
    output reg vga_re,
    output reg [22:0] vga_addr,
    input wire [15:0] vga_data,
    input wire vga_success,
    
    
    input wire write_enable,
    input wire [18:0] write_address,
    input wire [7:0] write_data
);
    
    //图像输出演示，分辨率800x600@75Hz，像素时钟为50MHz
    wire [11:0] hdata;
    wire [11:0] vdata;
    reg[2:0] red;
    reg[2:0] green;
    reg[1:0] blue;
    
    assign video_red = red;
    assign video_green = green;
    assign video_blue = blue;
     //assign video_red = hdata < 266 ? 3'b111 : 0; //红色竖条
     //assign video_green = hdata < 532 && hdata >= 266 ? 3'b111 : 0; //绿色竖条
     //assign video_blue = hdata >= 532 ? 2'b11 : 0; //蓝色竖条
    assign video_clk = clk;
    
    vga #(12, 800, 856, 976, 1040, 600, 637, 643, 666, 1, 1) vga800x600at75 (
      .clk(clk), 
      .hdata(hdata), //横坐标
      .vdata(vdata), //纵坐标
      .hsync(video_hsync),
      .vsync(video_vsync),
      .data_enable(video_de)
    );
    
    reg ena;
    reg[0:0] wea;
    reg[18:0] addra;
    reg[7:0] dina;
    reg enb;
    reg[18:0] addrb;
    wire[7:0] doutb;
    
blk_mem_gen_0 your_instance_name (
      .clka(clk),    // input wire clka
      .ena(ena),      // input wire ena
      .wea(wea),      // input wire [0 : 0] wea
      .addra(addra),  // input wire [18 : 0] addra
      .dina(dina),    // input wire [7 : 0] dina
      
      .clkb(clk),    // input wire clkb
      .enb(enb),      // input wire enb
      .addrb(addrb),  // input wire [18 : 0] addrb
      .doutb(doutb)  // output wire [7 : 0] doutb
    );
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            red = 3'b0;
            green = 3'b0;
            blue = 2'b0;
        end
        else if (hdata < 800 && vdata < 600) begin
            red = doutb[7:5];
            green = doutb[4:2];
            blue = doutb[1:0];
        end
        else begin
            red = 3'b0;
            green = 3'b0;
            blue = 2'b0;
        end
    end
    
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            ena <= 1'b0;
            enb <= 1'b0;
        end
        else begin
            ena <= 1'b1;
            enb <= 1'b1;
        end
    end
    
    wire[11:0] hh;
    wire[11:0] vv0;
    wire[11:0] vv;
    assign hh = (hdata == 1039) ? 0 : hdata + 1;
    assign vv0 = (hdata == 1039) ? vdata + 1: vdata;
    assign vv = (vv0 == 666)? 0 : vv0;
    
    always @ (posedge clk) begin
        if (rst == 1'b1) begin
            addrb <= 1;
        end
        else begin
            if (hh < 800 && vv < 600) begin
                addrb <= (vv >> 3) * 100 + (hh >> 3) + 1;
            end
            else begin
                addrb <= 1;
            end
        end
    end
    
    reg init_end;
    reg write1, write2;
    
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            init_end <= 1'b1;
            wea <= 1'b0;
            addra <= 9;
            dina <= 8'b0;
            vga_re <= 1'b0;
            vga_addr <= 23'b0;
            write1 <= 1'b0;
            write2 <= 1'b0;
        end
        else if (init_end == 1'b1) begin
            init_end <= 1'b1;
            if (write_enable == 1'b1) begin
                wea <= 1'b1;
                addra <= write_address;
                dina <= write_data;
            end
            else begin
                wea <= 1'b0;
                addra <= 9;
                dina <= 8'b0;
            end
            vga_re <= 1'b0;
            vga_addr <= 23'b0;
            write1 <= 1'b0;
            write2 <= 1'b0;
        end
        else begin
            if (vga_addr == 480000) begin
                init_end <= 1'b1;
            end
            else begin
                init_end <= 1'b0;
            end
            vga_re <= 1'b1;
            if (vga_success == 1'b1) begin
                if (write1 == 1'b0) begin
                    wea <= 1'b1;
                    write1 <= 1'b1;
                    write2 <= 1'b0;
                    addra <= addra + 1;
                    vga_addr <= vga_addr + 2;
                    dina <= vga_data[7:0];
                end
                else if (write2 == 1'b0) begin
                    wea <= 1'b1;
                    write1 <= 1'b1;
                    write2 <= 1'b1;
                    addra <= addra + 1;
                    vga_addr <= vga_addr;
                    dina <= vga_data[15:8];
                end
                else begin
                    wea <= 1'b0;
                    write1 <= 1'b1;
                    write2 <= 1'b1;
                    addra <= addra;
                    vga_addr <= vga_addr;
                    dina <= 8'b0;
                end
            end
            else begin
                wea <= 1'b0;
                write1 <= 1'b0;
                write2 <= 1'b0;
                addra <= addra;
                vga_addr <= vga_addr;
                dina <= dina;
            end
        end
    end
    
    
endmodule
