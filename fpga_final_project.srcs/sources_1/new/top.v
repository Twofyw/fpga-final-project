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
      SEG, AN,
      JA,
      signal_x
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

  inout [3:0]  JA;

  input reset, reset_game; // Reset components such as clocks, reset_game to put cursor at center of screen

  // Stepper motors
  output [3:0] signal_x;

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
  wire [3:0] angle;
  wire [11:0] ACCEL_X;

  wire Data_Ready;

  wire [3:0] raw_speed, pspeed; // pspeed is raw_speed synchronized with CLK65MHZ

  genvar i, j;

  // Gyroscope
  wire         begin_transmission;
  wire         end_transmission;
  wire [7:0]   send_data;
  wire [7:0]   recieved_data;
  wire [15:0]  x_axis_data;
  wire [15:0]  y_axis_data;
  wire [15:0]  z_axis_data;
  wire         slave_select;
  wire [3:0]   D4;
  wire         dclk; // Refresh SSD

  // Stepper motors
  wire         speedClock;

// ==============================================================================
// 							  		         Game up!
// ==============================================================================
  // assign raw_speed = 4'b0111;
  // Because pspeed is provided by modules driven by 100MHZ clock which might cause synchronization problem with
  // game input, it needs to be synchronized first.
  generate begin
    for (i = 0; i < 4; i=i+1) begin
      synchronize sync_speed (.clk(CLK65MHZ),.in(raw_speed[i]),.out(pspeed[i]));
    end
  end
  endgenerate

  // Display hexadecimal reading from raw gyroscope data
  display_8hex hex_display (CLK100MHZ, y_axis_data, SEG, AN);

  // Connect to game logic to update what shows on game board
  game gm(.vclock(CLK65MHZ),.reset(reset_game),.hcount(hcount),.vcount(vcount),.hsync(hsync),
          .vsync(vsync),.phsync(phsync),.pvsync(pvsync),.pixel(pixel_gameBoard),.pspeed(pspeed));

// ==============================================================================
// 							  		            Accelerometer
// ==============================================================================
  ADXL362Ctrl accel (.SYSCLK(CLK100MHZ),.RESET(reset),.ACCEL_X(ACCEL_X), // .Data_Ready(Data_Ready),
                      .MISO(MISO),.SCLK(SCLK),.MOSI(MOSI),.SS(SS));
  for (j = 0; j < 4; j = j + i) begin
    assign angle[i] = ACCEL_X[i+8];
  end


// ==============================================================================
// 							  		            Stepper moters
// ==============================================================================
// module pmod_step_driver(
//     input rst,
//     input [1:0]dir,
//     input clk,
//     input en,
//     output reg [3:0] signal
//     );
// module clock_div(
//     input clk,
//     input rst,
//     output reg new_clk
//     );
  clock_div speedClock (.clk(CLK100MHZ),.rst(reset),.new_clk(speedClock));
  pmod_step_driver x (.rst(reset),.dir(2'b01),.clk(speedClock),.en(reset_game),.signal(signal_x));


// ==============================================================================
// 							  		            Gyroscope
// ==============================================================================
  // //--------------------------------------
	// //		Serial Port Interface Controller
	// //--------------------------------------
  // assign JA[3] = slave_select;
	// master_interface C0(
	// 			.begin_transmission(begin_transmission),
	// 			.end_transmission(end_transmission),
	// 			.send_data(send_data),
	// 			.recieved_data(recieved_data),
	// 			.clk(CLK100MHZ),
	// 			.rst(reset),
	// 			.slave_select(slave_select),
	// 			.start(1'b1),
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
	// 			.miso(JA[1]),
	// 			.clk(CLK100MHZ),
	// 			.rst(reset),
	// 			.end_transmission(end_transmission),
	// 			.mosi(JA[0]),
	// 			.sclk(JA[2])
	// );
  // //---------------------------------------------------
	// // 		  Clock for display components
	// //---------------------------------------------------
	// display_clk display_counter(
	// 			.clk(CLK100MHZ),
	// 			.RST(rst),
	// 			.dclk(dclk)
	// );
  //
  // //---------------------------------------------------
	// // 		Formats data received from PmodGYRO
	// //---------------------------------------------------
	// data_controller hex(
	// 			.clk(CLK100MHZ),
	// 			.dclk(dclk),
	// 			.rst(reset),
	// 			.display_sel(1'b1), // 1 for decimal; 0 for hexadecimal. Opt for decimal here for speed control
	// 			.sel(2'b11), // 11 for decimal output
	// 			.data(x_axis_data), // We're only interested in y axis data. Feeding it in directely
	// 			// .D1(D1),
	// 			// .D2(D2),
	// 			// .D3(D3),
	// 			.D4(D4) // We're only interested in highest bits
	// );
  // assign raw_speed = x_axis_data[15:12];


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
  blend #(1,1) background2 (pixel_gameBoard, { vcount[8:5] + hcount[9:6], hcount[8:5], hcount[3:0] }, pixel);

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
