
`timescale 1ns/1ps
module  threshold_binary#(
        parameter DW        = 24 ,
        parameter Y_TH      = 150,
        parameter Y_TL      = 40 ,
        parameter CB_TH     = 155,
        parameter CB_TL     = 100,
        parameter CR_TH     = 240,
        parameter CR_TL     = 160

)(
        input                            pixelclk   ,
        input                            reset_n    ,
        input [DW-1:0]                   i_ycbcr    ,
        input                            i_hsync    ,
        input                            i_vsync    ,
        input                            i_de       ,
    
        
        output[DW-1:0]                   o_binary   ,
        output                           o_hsync    ,
        output                           o_vsync    ,   
        output                           o_de                                                                                                
);


reg  [DW-1:0]           binary_r    ;
reg                     h_sync_r    ;
reg                     v_sync_r    ;
reg                     de_r        ;
wire                    en0         ;
wire                    en1         ;
wire                    en2         ;


assign o_binary = binary_r;  
assign o_hsync  = h_sync_r;
assign o_vsync  = v_sync_r;
assign o_de     = de_r;

////////////////////// threshold//////////////////////////////////////
assign en0      =i_ycbcr[23:16] >=Y_TL  && i_ycbcr[23:16] <= Y_TH;
assign en1      =i_ycbcr[15: 8] >=CB_TL && i_ycbcr[15: 8] <= CB_TH;
assign en2      =i_ycbcr[ 7: 0] >=CR_TL && i_ycbcr[ 7: 0] <= CR_TH;


/********************************************************************************************/

/***************************************timing***********************************************/

always @(posedge pixelclk)begin
    h_sync_r<= i_hsync;
    v_sync_r<= i_vsync;
    de_r    <= i_de;
end 



/********************************************************************************************/

/***************************************Binarization threshold*******************************/


always @(posedge pixelclk or negedge reset_n) begin
    if(!reset_n)begin 
        binary_r <= 24'd0;
    end 
    else begin 
        if(en0==1'b1 && en1 ==1'b1 && en2==1'b1) begin 
            binary_r <= 24'd0;
        end 
        else begin 
            binary_r <= 24'hffffff;
        end 
    end  
end 



endmodule 