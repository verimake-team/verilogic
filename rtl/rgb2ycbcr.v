`timescale 1ns / 1ps


/* RGBתYUV�㷨
			Y  =  0.183R + 0.614G + 0.062B + 16 ;
 			CB = -0.101R - 0.338G + 0.439B + 128;
			CR =  0.439R - 0.399G - 0.040B + 128;
			     		   |  |
			      		  \|  |/ 
			      		   \  / 
			                \/
			Y  =  (0.183R + 0.614G )+(0.062B +  16);
 			CB = -(0.101R + 0.338G )+(0.439B + 128);
			CR = -(0.399G + 0.040B )+(0.439R + 128);

*/

module	rgb2ycbcr(
    input                            pixelclk   ,
    input          [23:0]            i_rgb      ,
    input                            i_hsync    ,
    input                            i_vsync    ,
    input                            i_de       ,
    input                            i_de0      ,
    
    output            [23:0]         o_rgb      ,
    output            [23:0]         o_ycbcr    ,
    output                           o_hsync    ,
    output                           o_vsync    ,    
    output                           o_de0      ,                          
    output                           o_de                                                                                               
);


/***************************************parameters*******************************************/
//multiply 256
parameter    para_0183_10b = 10'd47     ;    
parameter    para_0614_10b = 10'd157    ;
parameter    para_0062_10b = 10'd16     ;
parameter    para_0101_10b = 10'd26     ;
parameter    para_0338_10b = 10'd86     ;
parameter    para_0439_10b = 10'd112    ;
parameter    para_0399_10b = 10'd102    ;
parameter    para_0040_10b = 10'd10     ;
parameter    para_16_18b   = 18'd4096   ;
parameter    para_128_18b  = 18'd32768  ;




/********************************************************************************************/
wire [7 : 0]        i_r_8b                  ;
wire [7 : 0]        i_g_8b                  ;
wire [7 : 0]        i_b_8b                  ;
wire [7 : 0]        o_y_8b                  ;
wire [7 : 0]        o_cb_8b                 ;
wire [7 : 0]        o_cr_8b                 ;
reg  [17: 0]        mult_r_for_y_18b =18'd0 ;
reg  [17: 0]        mult_r_for_cb_18b=18'd0 ;
reg  [17: 0]        mult_r_for_cr_18b=18'd0 ;
reg  [17: 0]        mult_g_for_y_18b =18'd0 ;
reg  [17: 0]        mult_g_for_cb_18b=18'd0 ;
reg  [17: 0]        mult_g_for_cr_18b=18'd0 ;
reg  [17: 0]        mult_b_for_y_18b =18'd0 ;
reg  [17: 0]        mult_b_for_cb_18b=18'd0 ;
reg  [17: 0]        mult_b_for_cr_18b=18'd0 ;
reg  [17: 0]        add_y_0_18b      =18'd0 ;
reg  [17: 0]        add_cb_0_18b     =18'd0 ;
reg  [17: 0]        add_cr_0_18b     =18'd0 ;
reg  [17: 0]        add_y_1_18b      =18'd0 ;
reg  [17: 0]        add_cb_1_18b     =18'd0 ;
reg  [17: 0]        add_cr_1_18b     =18'd0 ;
reg  [17: 0]        result_y_18b     =18'd0 ;
reg  [17: 0]        result_cb_18b    =18'd0 ;
reg  [17: 0]        result_cr_18b    =18'd0 ;
reg  [15:0]         y_tmp            =16'd0 ;
reg  [15:0]         cb_tmp           =16'd0 ;
reg  [15:0]         cr_tmp           =16'd0 ;
reg  [23:0]         o_rgb_delay_1           ;
reg  [23:0]         o_rgb_delay_2           ;
reg  [23:0]         o_rgb_delay_3           ;
reg                 i_de0_delay_1           ;
reg                 i_de0_delay_2           ;
reg                 i_de0_delay_3           ;
reg                 i_h_sync_delay_1        ;
reg                 i_v_sync_delay_1        ;
reg                 i_data_en_delay_1       ;
reg                 i_h_sync_delay_2        ;
reg                 i_v_sync_delay_2        ;
reg                 i_data_en_delay_2       ;
reg                 i_h_sync_delay_3        ;
reg                 i_v_sync_delay_3        ;
reg                 i_data_en_delay_3       ;



assign i_r_8b  = i_rgb[23:16];
assign i_g_8b  = i_rgb[15:8];
assign i_b_8b  = i_rgb[7:0];
assign o_ycbcr = {o_y_8b,o_cb_8b,o_cr_8b};
assign o_rgb   = o_rgb_delay_3; 
assign o_y_8b  = y_tmp[15 : 8];
assign o_cb_8b =cb_tmp[15 : 8];
assign o_cr_8b =cr_tmp[15 : 8];
assign o_hsync = i_h_sync_delay_3;
assign o_vsync = i_v_sync_delay_3;
assign o_de    = i_data_en_delay_3;
assign o_de0   = i_de0_delay_3;



/********************************************************************************************/

/********************************************************************************************/

//LV1 pipeline : mult
always @(posedge   pixelclk)begin
    mult_r_for_y_18b  <= i_r_8b * para_0183_10b;
    mult_r_for_cb_18b <= i_r_8b * para_0101_10b;
    mult_r_for_cr_18b <= i_r_8b * para_0439_10b;
end


always @(posedge   pixelclk)begin
    mult_g_for_y_18b  <= i_g_8b * para_0614_10b;
    mult_g_for_cb_18b <= i_g_8b * para_0338_10b;
    mult_g_for_cr_18b <= i_g_8b * para_0399_10b;
end


always @(posedge   pixelclk)begin
    mult_b_for_y_18b  <= i_b_8b * para_0062_10b;
    mult_b_for_cb_18b <= i_b_8b * para_0439_10b;
    mult_b_for_cr_18b <= i_b_8b * para_0040_10b;
end



//LV2 pipeline : add
always @(posedge   pixelclk)begin
    add_y_0_18b  <= mult_r_for_y_18b + mult_g_for_y_18b;
    add_y_1_18b  <= mult_b_for_y_18b + para_16_18b;
    
    add_cb_0_18b <= mult_b_for_cb_18b + para_128_18b;
    add_cb_1_18b <= mult_r_for_cb_18b + mult_g_for_cb_18b;
    
    add_cr_0_18b <= mult_r_for_cr_18b + para_128_18b;
    add_cr_1_18b <= mult_g_for_cr_18b + mult_b_for_cr_18b;
end


//LV3 pipeline : y + cb + cr
always @(posedge   pixelclk)begin
    y_tmp  <= add_y_0_18b + add_y_1_18b;
    cb_tmp <= add_cb_0_18b - add_cb_1_18b ;
    cr_tmp <= add_cr_0_18b - add_cr_1_18b ;
end




/********************************************************************************************/

/***************************************timing***********************************************/
always @(posedge    pixelclk)begin
    i_h_sync_delay_1  <= i_hsync;
    i_v_sync_delay_1  <= i_vsync;
    i_data_en_delay_1 <= i_de;
    o_rgb_delay_1     <= i_rgb;
    i_de0_delay_1     <=i_de0;
    
    i_h_sync_delay_2  <= i_h_sync_delay_1;
    i_v_sync_delay_2  <= i_v_sync_delay_1;
    i_data_en_delay_2 <= i_data_en_delay_1;
    o_rgb_delay_2     <= o_rgb_delay_1;
    i_de0_delay_2     <=i_de0_delay_1;
        
    i_h_sync_delay_3  <= i_h_sync_delay_2;
    i_v_sync_delay_3  <= i_v_sync_delay_2;
    i_data_en_delay_3 <= i_data_en_delay_2;
    o_rgb_delay_3     <= o_rgb_delay_2;
    i_de0_delay_3     <=i_de0_delay_2;

end	


endmodule 
