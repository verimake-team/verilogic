`timescale 1ns/ 1ps

module i2c_module(
    input                   clk             ,
    input                   reset_n         ,
    input[7:0]              writedata       ,
    input                   write           ,
    input[2:0]              address         ,
    input                   sda_in          ,
                                            
    output reg              sda        =1'b1,
    output reg              scl_out         ,
    output reg              sda_oe     =1'b1,
    output reg              ready      =1'b1,
    output reg              success_out=1'b0

);


localparam STATE_IDLE            =0  ;
localparam STATE_ADDRESS_START   =1  ;
localparam STATE_ADDRESS_START_2 =111;
localparam STATE_ADDRESS_START_3 =112;
localparam STATE_ADDRESS_BIT_1   =2  ;
localparam STATE_ADDRESS_BIT_2   =3  ;
localparam STATE_ADDRESS_BIT_3   =4  ;
localparam STATE_ADDRESS_BIT_4   =5  ;
localparam STATE_ADDRESS_BIT_5   =6  ;
localparam STATE_ADDRESS_BIT_6   =7  ;
localparam STATE_ADDRESS_BIT_7   =8  ;
localparam STATE_ADDRESS_BIT_8   =9  ;
localparam STATE_ADDRESS_ACK     =10 ;
//localparam STATE_ADDRESS_ACK_2 = 101;
localparam STATE_TRANSIT_1       =102;
localparam STATE_REG_BIT_1       =11 ;
localparam STATE_REG_BIT_2       =12 ;
localparam STATE_REG_BIT_3       =13 ;
localparam STATE_REG_BIT_4       =14 ;
localparam STATE_REG_BIT_5       =15 ;
localparam STATE_REG_BIT_6       =16 ;
localparam STATE_REG_BIT_7       =17 ;
localparam STATE_REG_BIT_8       =18 ;
localparam STATE_REG_ACK         =19 ;
//localparam STATE_REG_ACK_2 = 191;
localparam STATE_TRANSIT_2       =192;
localparam STATE_DATA_BIT_1      =20 ;
localparam STATE_DATA_BIT_2      =21 ;
localparam STATE_DATA_BIT_3      =22 ;
localparam STATE_DATA_BIT_4      =23 ;
localparam STATE_DATA_BIT_5      =24 ;
localparam STATE_DATA_BIT_6      =25 ;
localparam STATE_DATA_BIT_7      =26 ;
localparam STATE_DATA_BIT_8      =27 ;
localparam STATE_DATA_ACK        =28 ;
//localparam STATE_DATA_ACK_2 = 32;
localparam STATE_STOP            =29 ;
localparam STATE_STOP_1          =30 ;
localparam STATE_STOP_2          =31 ;


reg [7:0]        state_next       =8'd0 ;
reg              clk_div          =1'b0 ;
wire             clk_div_2              ;
reg [7:0]        divider2         =8'd0 ;
reg [7:0]        control_reg      =8'd0 ;
reg [7:0]        slave_address    =8'd0 ;
reg [7:0]        slave_reg_address=8'd0 ;
reg [7:0]        slave_data_1     =8'd0 ;
reg [7:0]        slave_data_2     =8'd0 ;
reg              scl_output_enable=1'b0 ;
reg              scl_output_zero  =1'b0 ;
reg              success          =1'b0 ;
reg              ack_ok           =1'b0 ;


assign clk_div_2 = divider2[7];




always@(posedge clk_div_2)begin
    clk_div <= ~clk_div;
end


always@(posedge clk)begin
    divider2 <= divider2 + 8'b1;
end



always@(posedge clk)begin
    if(reset_n ==1'b0)begin
        control_reg       <=8'd0;
        slave_address     <=8'd0;
        slave_reg_address <=8'd0;
        slave_data_1      <=8'd0;
        slave_data_2      <=8'd0;
    end
    else begin
        if(write == 1'b1)begin
            case(address)
                3'b000: control_reg       <= writedata;
                3'b001: slave_address     <= writedata;
                3'b010: slave_reg_address <= writedata;
                3'b011: slave_data_1      <= writedata;
                3'b100: slave_data_2      <= writedata;
            endcase
        end
        if(state_next != STATE_IDLE)begin 
            control_reg <=8'd0;
        end 
    end
end




always@(posedge clk_div_2)begin
    if(scl_output_enable ==1'b1)begin
        scl_out <= ~scl_out;
    end
    else begin
         if(scl_output_zero ==1'b0)begin 
            scl_out <= 1'b1;
         end 
         else begin 
            scl_out <= 1'b0;
         end 
    end
end





always@(posedge clk_div_2)begin
    if( (state_next == STATE_ADDRESS_ACK || state_next == STATE_REG_ACK || state_next == STATE_DATA_ACK) && sda_in == 1'b0 && clk_div ==1'b1)begin
        ack_ok <= 1'b1;
    end
    else begin 
        ack_ok <= 1'b0;
    end 
end


always@(negedge clk_div_2)begin
    if(clk_div ==1'b1)begin
        if(state_next == STATE_STOP && success == 1'b1)begin 
            success_out <= 1'b1;
        end 
        else begin 
            if(state_next == STATE_ADDRESS_START)begin 
                success_out <= 1'b0;
            end 
        end 
    end
end


always@(negedge clk_div_2)begin
    if(reset_n ==1'b0)begin
        state_next <= STATE_IDLE;
    end
    else begin
        case(state_next)
        STATE_IDLE:begin
                if(control_reg[0] == 1'b1 )begin
                    state_next <= STATE_ADDRESS_START;
                end
       end

        STATE_ADDRESS_START:begin
                if(clk_div ==1'b0)begin
                    state_next <= STATE_ADDRESS_START_2;
                end
        end

        STATE_ADDRESS_START_2:begin
                if(clk_div ==1'b1)begin
                    state_next <= STATE_ADDRESS_START_3;
                end
        end

        STATE_ADDRESS_START_3:begin
                if(clk_div ==1'b0)begin
                    state_next <= STATE_ADDRESS_BIT_1;
                end
        end
    
        STATE_ADDRESS_BIT_1:begin
                if(clk_div ==1'b0)begin
                    state_next <= STATE_ADDRESS_BIT_2;
                end
        end

        STATE_ADDRESS_BIT_2:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_ADDRESS_BIT_3;
                end
        end
    
        STATE_ADDRESS_BIT_3:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_ADDRESS_BIT_4;
                end
        end

        STATE_ADDRESS_BIT_4:begin
                if(clk_div == 1'b0) begin
                    state_next <= STATE_ADDRESS_BIT_5;
                end
        end
            
        STATE_ADDRESS_BIT_5:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_ADDRESS_BIT_6;
                end
        end
            
        STATE_ADDRESS_BIT_6:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_ADDRESS_BIT_7;
                end
        end
            
        STATE_ADDRESS_BIT_7:begin
                if(clk_div == 1'b0) begin
                    state_next <= STATE_ADDRESS_BIT_8;
                end
        end
            
        STATE_ADDRESS_BIT_8:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_ADDRESS_ACK;
                end
        end
            
        STATE_ADDRESS_ACK:begin
                if(clk_div == 1'b0)begin
                    if(ack_ok == 1'b1) begin
                        state_next <= STATE_TRANSIT_1;
                    end
                    else begin
                        state_next <= STATE_STOP;
                    end
                end
        end
            
        STATE_TRANSIT_1:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_BIT_1;
                end
        end
            
        STATE_REG_BIT_1:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_BIT_2;
                end
        end
            
        STATE_REG_BIT_2:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_BIT_3;
                end
        end
            
        STATE_REG_BIT_3:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_BIT_4;
                end
        end
            
        STATE_REG_BIT_4:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_BIT_5;
                end
        end
            
        STATE_REG_BIT_5:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_BIT_6;
                end
        end
            
        STATE_REG_BIT_6:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_BIT_7;
                end
        end
            
        STATE_REG_BIT_7:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_BIT_8;
                end
        end
            
        STATE_REG_BIT_8:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_REG_ACK;
                end
        end
            
        STATE_REG_ACK:begin
                if(clk_div == 1'b0)begin
                    if(ack_ok == 1'b1)begin
                        state_next <= STATE_TRANSIT_2;
                    end
                    else begin
                        state_next <= STATE_STOP;
                    end
                end
        end
            
        STATE_TRANSIT_2:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_DATA_BIT_1;
                end
        end
            
        STATE_DATA_BIT_1: begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_DATA_BIT_2;
                end
        end
            
        STATE_DATA_BIT_2:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_DATA_BIT_3;
                end
        end
            
        STATE_DATA_BIT_3:begin
                if(clk_div == 1'b0) begin
                    state_next <= STATE_DATA_BIT_4;
                end
        end
            
        STATE_DATA_BIT_4:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_DATA_BIT_5;
                end
        end
            
        STATE_DATA_BIT_5:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_DATA_BIT_6;
                end
        end
            
        STATE_DATA_BIT_6:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_DATA_BIT_7;
                end
        end
            
        STATE_DATA_BIT_7:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_DATA_BIT_8;
                end
        end
            
        STATE_DATA_BIT_8:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_DATA_ACK;
                end
        end
            
        STATE_DATA_ACK:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_STOP;
                end
        end
            
        STATE_STOP:begin
                if(clk_div == 1'b1)begin
                    state_next <= STATE_STOP_1;
                end
        end
            
        STATE_STOP_1:begin
                if(clk_div == 1'b0)begin
                    state_next <= STATE_IDLE;
                end
        end
            
        STATE_STOP_2:begin
                if(clk_div == 1'b1)begin
                    state_next <= STATE_IDLE;
                end
        end
                        
        endcase
    end
end



always@(negedge clk_div_2)begin
    if(reset_n == 1'b0)begin
        sda               <= 1'b1;
        sda_oe            <= 1'b1;
        scl_output_enable <= 1'b0;
        ready             <= 1'b1;
        success           <= 1'b0;
    end
    else begin
        case(state_next)
            STATE_IDLE:begin
                sda               <= 1'b1;
                sda_oe            <= 1'b1;
                scl_output_enable <= 1'b0;
                ready             <= 1'b1;
                success           <= 1'b0;
                scl_output_zero   <= 1'b0;
            end
            
            STATE_ADDRESS_START:begin
                if(clk_div ==1'b0)begin
                    scl_output_zero   <= 1'b0;
                    scl_output_enable <= 1'b0;
                    sda_oe            <= 1'b1;
                    sda               <= 1'b0;
                    ready             <= 1'b0;
                    success           <= 1'b0;
                end
            end
            
            STATE_ADDRESS_START_2:begin
                if(clk_div == 1'b1)begin
                    scl_output_zero   <= 1'b1;
                    scl_output_enable <= 1'b0;
                    sda_oe            <= 1'b1;
                    sda               <= 1'b0;
                    ready             <= 1'b0;
                    success           <= 1'b0;
                end
            end
            
            STATE_ADDRESS_START_3:begin
                if(clk_div == 1'b0) begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_address[7];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_ADDRESS_BIT_1:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_address[6];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_ADDRESS_BIT_2:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_address[5];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_ADDRESS_BIT_3:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_address[4];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_ADDRESS_BIT_4:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_address[3];
                    ready               <= 1'b0;
                    success             <= 1'b0; 
                end
            end
            
            STATE_ADDRESS_BIT_5:begin
                if(clk_div == 1'b0)
                begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_address[2];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_ADDRESS_BIT_6:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_address[1];
                    ready               <= 1'b0;
                    success             <= 1'b0; 
                end
            end
            
            STATE_ADDRESS_BIT_7:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_address[0];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_ADDRESS_BIT_8:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    ready               <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b0;
                    sda                 <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_ADDRESS_ACK: begin
                if(clk_div == 1'b0)begin
                    if(ack_ok == 1'b1)begin
                        scl_output_zero     <= 1'b1;
                        ready               <= 1'b0;
                        sda_oe              <= 1'b1;
                        scl_output_enable   <= 1'b0;
                        sda                 <= 1'b0;
                        success             <= 1'b0;
                    end
                    else begin
                        sda_oe              <= 1'b1;
                        sda                 <= 1'b0;
                        scl_output_enable   <= 1'b0;
                        ready               <= 1'b0;
                        success             <= 1'b0;
                        scl_output_zero     <= 1'b1;
                    end
                end
            end
            
            STATE_TRANSIT_1:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_reg_address[7];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_REG_BIT_1:begin
                if(clk_div == 1'b0)begin
                    scl_output_zero     <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_reg_address[6];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_REG_BIT_2:begin
                if(clk_div == 1'b0)begin
                scl_output_zero         <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_reg_address[5];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                end
            end
            
            STATE_REG_BIT_3:begin
                if(clk_div == 1'b0)
                begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_reg_address[4];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_REG_BIT_4:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_reg_address[3];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_REG_BIT_5:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_reg_address[2];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_REG_BIT_6:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_reg_address[1];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_REG_BIT_7:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_reg_address[0];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_REG_BIT_8:begin
                if(clk_div == 1'b0)begin
                    ready               <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b0;
                    sda                 <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 01'b0;
                end
            end
            
            STATE_REG_ACK:begin
                if(clk_div == 1'b0)begin
                    if(ack_ok == 1'b1)begin
                        ready               <= 1'b0;
                        sda_oe              <= 1'b1;
                        scl_output_enable   <= 1'b0;
                        sda                 <= 1'b0;
                        success             <= 1'b0;
                        scl_output_zero     <= 1'b1;
                    end
                    else begin
                        sda_oe              <= 1'b1;
                        sda                 <= 1'b0;
                        scl_output_enable   <= 1'b0;
                        ready               <= 1'b0;
                        success             <= 1'b0;
                        scl_output_zero     <= 1'b1;
                    end
                end
            end

            STATE_TRANSIT_2:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_data_1[7];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_BIT_1:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_data_1[6];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_BIT_2:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_data_1[5];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_BIT_3:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_data_1[4];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_BIT_4:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_data_1[3];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_BIT_5:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_data_1[2];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_BIT_6:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_data_1[1];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_BIT_7:begin
                if(clk_div == 1'b0)begin
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b1;
                    sda                 <= slave_data_1[0];
                    ready               <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_BIT_8:begin
                if(clk_div == 1'b0)begin
                    ready               <= 1'b0;
                    scl_output_enable   <= 1'b1;
                    sda_oe              <= 1'b0;
                    sda                 <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_DATA_ACK:begin
                if(clk_div == 1'b0)begin
                    if(ack_ok == 1'b1) begin
                        sda_oe              <= 1'b1;
                        sda                 <= 1'b0;
                        scl_output_enable   <= 1'b1;
                        ready               <= 1'b0;
                        scl_output_zero     <= 1'b1;
                        success             <= 1'b1;
                    end
                    else  begin
                        sda_oe              <= 1'b1;
                        sda                 <= 1'b0;
                        scl_output_enable   <= 1'b0;
                        ready               <= 1'b0;
                        success             <= 1'b0;
                        scl_output_zero     <= 1'b1;
                    end
                end
            end

            STATE_STOP:begin
                if(clk_div == 1'b1)begin
                    ready               <= 1'b0;
                    sda_oe              <= 1'b1;
                    sda                 <= 1'b0;
                    scl_output_enable   <= 1'b0;
                    success             <= 1'b0;
                    scl_output_zero     <= 1'b0;
                end
            end
            
            STATE_STOP_1:begin
                if(clk_div == 1'b0)begin
                    ready             <= 1'b0;
                    sda               <= 1'b1;
                    sda_oe            <= 1'b1;
                    scl_output_enable <= 1'b0;
                    success           <= 1'b0;
                    scl_output_zero   <= 1'b0;
                end
            end
            
            STATE_STOP_2:begin
                    if(clk_div == 1'b1) begin
                        
                    end
            end
            
            default: begin
                sda                 <= 1'b1;
                sda_oe              <= 1'b1;
                scl_output_enable   <= 1'b0;
                ready               <= 1'b1;
                scl_output_zero     <= 1'b0;
                success             <= 1'b0;
            end
        endcase
    end
end


endmodule
