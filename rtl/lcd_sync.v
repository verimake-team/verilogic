`timescale 1ns/ 1ps

module lcd_sync
#(
    //display image at pos
    parameter IMG_W = 200,  
    parameter IMG_H = 164,
    parameter IMG_X = 0  ,
    parameter IMG_Y = 0
)
(
    input                       clk         ,
    input                       rest_n      ,
    
    output  wire                lcd_clk     ,
    output  wire                lcd_pwm     ,
    output  wire                lcd_hsync   , 
    output  wire                lcd_vsync   , 
    output  wire                lcd_de      ,
    output  wire [10:0]         hsync_cnt   ,
    output  wire [10:0]         vsync_cnt   ,
    output  wire                img_ack     ,
    output  wire                img_ack0    ,
    output  wire [15:0]         addr
);



//640*480
localparam TFT_H = 640;  
localparam TFT_V = 480; 

////////////60hz////////////////////
localparam THB   = 160;
localparam TH    = TFT_H + THB;
localparam TVB   = 45;
localparam TV    = TFT_V + TVB;

////////////70hz////////////////////
/* localparam THB 	 = 200;
localparam TH 	 = TFT_H + THB;

localparam TVB   = 20;
localparam TV    = TFT_V + TVB; */

reg [10:0]           counter_hs       ;
reg [10:0]           counter_vs       ;
reg [15:0]           read_addr        ;   
reg [10:0]           img_hbegin =11'd0;   
reg [10:0]           img_vbegin =11'd0;   




assign lcd_clk   = (rest_n == 1'b1) ? clk  : 1'b0;
assign lcd_pwm   = (rest_n == 1'b1) ? 1'b1 : 1'b0;
assign lcd_hsync = ( counter_hs >= 5'd16 && counter_hs < 7'd112 ) ?1'b1 :1'b0;
assign lcd_vsync = ( counter_vs >= 4'd10 && counter_vs < 4'd12 ) ?1'b1:1'b0;
assign lcd_de    = ( counter_hs >= THB && counter_hs <= TH && counter_vs >= TVB  && counter_vs < TV) ?1'b1:1'b0;
assign hsync_cnt = counter_hs;
assign vsync_cnt = counter_vs;
assign img_ack   = lcd_de &&((counter_hs - THB) >= IMG_X && (counter_hs - THB) < (IMG_X + IMG_W)) && 
                 ((counter_vs - TVB) >= IMG_Y && (counter_vs - TVB) < (IMG_Y + IMG_H)) ? 1'b1 : 1'b0;
assign img_ack0  = lcd_de &&((counter_hs - THB) >= IMG_X && (counter_hs - THB) < (IMG_X + IMG_W)) && 
                 ((counter_vs - TVB) >= IMG_Y+8'd200 && (counter_vs - TVB) < (IMG_Y + IMG_H+8'd200 )) ? 1'b1 : 1'b0;               
assign addr      = read_addr;




always@(posedge clk or negedge rest_n)begin
    if(rest_n == 1'b0)begin 
        counter_hs <= 11'd0;
    end 
    else if(counter_hs == TH )begin 
        counter_hs <= 11'd0;
    end 
    else begin 
        counter_hs <= counter_hs + 1'b1;
    end 
end



always@(posedge clk or negedge rest_n)begin
    if(rest_n == 1'b0)begin 
        counter_vs <= 11'd0;
    end 
    else if(counter_hs == TH && counter_vs == TV)begin 
        counter_vs <= 11'd0;
    end 
    else if(counter_hs == TH && counter_vs != TV)begin 
        counter_vs <= counter_vs +1'b1;
    end 
end



always@(posedge clk or negedge rest_n)begin
    if(!rest_n)begin 
        read_addr <= 16'd0;
    end 
    else if(img_ack)begin 
        read_addr <= (counter_hs - IMG_X - THB) + (counter_vs - IMG_Y - TVB) * IMG_W;
    end 
    else if(img_ack0)begin 
        read_addr <= (counter_hs - IMG_X - THB) + (counter_vs - IMG_Y - TVB-8'd200) * IMG_W;
    end 
    else begin 
        read_addr <= 16'd0;  
    end 
end



endmodule
