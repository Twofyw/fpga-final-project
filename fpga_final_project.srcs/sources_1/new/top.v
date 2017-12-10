`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/08/2017 11:19:47 PM
// Design Name:
// Module Name: top
// Project Name:
// Target Devices:
// Tool Versions:
// Description: This is the top module mainly responsible for display signal generation
//              and submodules are connected here.
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

// ==============================================================================
// 										  Define Module
//                     Port Declarations
// ==============================================================================
module top(
      CLK100MHZ,
      vga_out_red, vga_out_green, vga_out_blue, vga_out_hsync, vga_out_vsync,
      switch, reset, reset_game,
      MISO,SCLK,MOSI,SS,
      SEG, AN
    );

  input  [1:0] switch; // select what to display
  input        CLK100MHZ;
  output [3:0] vga_out_red, vga_out_green, vga_out_blue;
  output       vga_out_hsync, vga_out_vsync;
  input MISO;
  output SCLK, MOSI, SS; // SPI signals

  // Seven segment display
  output [6:0] SEG;
  output [7:0] AN;

  input reset, reset_game; // Reset components such as clocks, reset_game to put cursor at center of screen

// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  wire CLK65MHZ, locked; // VGA pixel clock

  // generate basic XVGA video signals
  wire [10:0] hcount, vcount;
  wire hsync,vsync;

  // feed XVGA signals to control module
  wire [11:0] pixel, pixel_gameBoard;
  wire phsync,pvsync,pblank;

  // Accelerometer
  wire signed [11:0] ACCEL_X, ACCEL_Y;
  wire signed [7:0] ACCEL_X_8, ACCEL_Y_8;
  wire Data_Ready;

  wire [3:0] raw_speed, pspeed; // pspeed is raw_speed synchronized with CLK65MHZ

  genvar i;

// ==============================================================================
// 							  		         Game up!
// ==============================================================================
  assign raw_speed = 4'b0111;
  // Because pspeed is provided by modules driven by 100MHZ clock which might cause synchronization problem with
  // game input, it needs to be synchronized first.
  generate begin
    for (i = 0; i < 4; i=i+1) begin
      synchronize sync_speed (.clk(CLK65MHZ),.in(raw_speed[i]),.out(pspeed[i]));
    end
  end
  endgenerate
  display_8hex hex_display (CLK100MHZ, pspeed, SEG, AN);

  // Connect to game logic to update what shows on game board
  game gm(.vclock(CLK65MHZ),.reset(reset_game),.hcount(hcount),.vcount(vcount),.hsync(hsync),
          .vsync(vsync),.phsync(phsync),.pvsync(pvsync),.pixel(pixel_gameBoard),.pspeed(pspeed));

// ==============================================================================
// 							  		            Accelerometer
// ==============================================================================
  ADXL362Ctrl accel (.SYSCLK(CLK100MHZ),.RESET(reset),.ACCEL_X(ACCEL_X),.Data_Ready(Data_Ready),
                      .MISO(MISO),.SCLK(SCLK),.MOSI(MOSI),.SS(SS));
  AccelArithmetics aa (.SYSCLK(CLK100MHZ),.RESET(reset),.ACCEL_X_IN(ACCEL_X),
                      .ACCEL_X_OUT(ACCEL_X_8),.Data_Ready(Data_Ready));



// ==============================================================================
// 							  		            Gyroscope
// ==============================================================================
  //--------------------------------------
	//		Serial Port Interface Controller
	//--------------------------------------
	// master_interface C0(
	// 			.begin_transmission(begin_transmission),
	// 			.end_transmission(end_transmission),
	// 			.send_data(send_data),
	// 			.recieved_data(recieved_data),
	// 			.clk(clk),
	// 			.rst(sw[0]),
	// 			.slave_select(slave_select),
	// 			.start(sw[1]),
	// 			.temp_data(temp_data),
	// 			.x_axis_data(x_axis_data),
	// 			.y_axis_data(y_axis_data),
	// 			.z_axis_data(z_axis_data)
	// );
  //
  //
	// //--------------------------------------
	// //		    Serial Port Interface
	// //--------------------------------------
	// spi_interface C1(
	// 			.begin_transmission(begin_transmission),
	// 			.slave_select(slave_select),
	// 			.send_data(send_data),
	// 			.recieved_data(recieved_data),
	// 			.miso(JA[2]),
	// 			.clk(clk),
	// 			.rst(sw[0]),
	// 			.end_transmission(end_transmission),
	// 			.mosi(JA[1]),
	// 			.sclk(JA[3])
	// );







  // ==============================================================================
  // 							  		            Display
  // ==============================================================================

  // generate VGA pixel clock
  clk_wiz_0 CLK65 (.clk_out1(CLK65MHZ),.reset(reset),.clk_in1(CLK100MHZ),.locked(locked));
  xvga xvga1(.vclock(CLK65MHZ),.hcount(hcount),.vcount(vcount),
            .hsync(hsync),.vsync(vsync));
  // Alpha-blend pixels from gameBoard and dashBoard, and send to VGA output
  // But before implementing dashBoard, output gameBoard alone is fine
  // assign pixel = pixel_gameBoard;
  blend #(2,3) background2 (pixel_gameBoard, { vcount[8:5] + hcount[9:6], hcount[8:5], hcount[3:0] }, pixel);

  // switch[1:0] selects which video generator to use:
  //  00: the game
  //  01: 1 pixel outline of active video area (adjust screen controls)
  //  10: color bars
  reg [11:0] rgb;
  wire border = (hcount==0 | hcount==1023 | vcount==0 | vcount== 767);

  reg hs,vs; // hsync pipeline
  always @(posedge CLK65MHZ) begin
    hs <= phsync;
    vs <= pvsync;
    case (switch[1:0])
      2'b01: rgb <= { 11{border} };
      2'b10: rgb <= { vcount[4:1] + hcount[9:6], hcount[8:5], hcount[3:0] };
      2'b00: rgb <= pixel;
    endcase
  end

  assign vga_out_red = rgb[11:8];
  assign vga_out_green = rgb[7:4];
  assign vga_out_blue = rgb[3:0];
  assign vga_out_hsync = hs;
  assign vga_out_vsync = vs;

endmodule
