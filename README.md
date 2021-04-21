/*******************************************************************************************
****************************run on the Anlogic FPGA EG4S20BG256*****************************
*******************************************************************************************/
/*
Date:20210416
Author: Mengru Lin
*/

/*******************************************************************************************
*__      __       _ __  __       _          __   __                   _             _      *
*\ \    / /      (_)  \/  |     | |         \ \ / /       /\         | |           (_)     *
* \ \  / /__ _ __ _| \  / | __ _| | _____    \ V /       /  \   _ __ | | ___   __ _ _  ___ *
*  \ \/ / _ \ '__| | |\/| |/ _` | |/ / _ \    > <       / /\ \ | '_ \| |/ _ \ / _` | |/ __|*
*   \  /  __/ |  | | |  | | (_| |   <  __/   / . \     / ____ \| | | | | (_) | (_| | | (__ *
*    \/ \___|_|  |_|_|  |_|\__,_|_|\_\___|  /_/ \_\   /_/    \_\_| |_|_|\___/ \__, |_|\___|*
*                                                                              __/ |       *
*                                                                             |___/        *
*******************************************************************************************/

This project talks about a simple color tracer system based on Anlogic FPGA. FPGA has to be 
used for the key function, includes camera driver, color recognition, VGA driver, and communicating 
with Arduino. Arduino used to drive a car to follow the target color based on recognition result from 
FPGA.Document link https://verimake.com/topics/191

doc：

    ov2640 camera datasheet
    
rtl：


    FPGA is the slave and Arduino is the master

    test_camera.v:The processed image resolution can be modified in the lcd_sync module（IMG_W、IMG_H）;
                  The threshold parameter can be modified in the threshold_binary module（Y_TH、Y_TL、CB_TH、CB_TL、CR_TH、CR_TL）;
                  In the HVCOUNT module, some requirements for framing the target object can be modified（cnt_x0 、cnt_x1 、
                  cnt_y0 、cnt_y1 、pixel）;
                  And can be modified into its own camera, RAM, PLL and data transmitted to the master
                 
   
    lcd_sync.v:Can modify the display resolution
    
    I2C_slave.v:Can modify the slave address

Arduino：
    
    The loop() function can modify the parameters that control the movement of the car

sdc：

    Pin  and clock constraints



Enjoy yourself!
