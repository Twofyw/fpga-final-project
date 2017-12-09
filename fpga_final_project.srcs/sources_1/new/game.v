`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/08/2017 08:33:40 PM
// Design Name:
// Module Name: game
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module game (
  input vclock,	// 65MHz clock
  input reset,		// 1 to initialize module
  input [3:0] pspeed,  // puck speed in pixels/tick
  input [10:0] hcount,	// horizontal index of current pixel (0..1023)
  input [9:0] vcount, // vertical index of current pixel (0..767)
  input hsync,		// XVGA horizontal sync signal (active low)
  input vsync,		// XVGA vertical sync signal (active low)

  output phsync,	// pong game's horizontal sync
  output pvsync,	// pong game's vertical sync
  output [11:0] pixel	// pong game's pixel  // r=11:8, g=7:4, b=3:0
  );
  // Reserve segment on the right for dashboard (205, one fifth for dashboard)

  // Local parameters
  localparam planWidth = 10'd819, planHeight = 10'd768;
  localparam ballWidth = 64, ballHeight = 64;
  localparam ballRadius = 64 >> 2;

  assign phsync = hsync;
  assign pvsync = vsync;

  // Start ball at the center
  reg signed [9:0] ball_x;
  reg signed [9:0] ball_y;

  wire [11:0] pixel_bal;
  reg signed [3:0] speed_x, speed_y;
  reg signed [2:0] direction_x = 3'sd1, direction_y = 3'sd1;
  // blob #(.WIDTH(ballWidth),.HEIGHT(ballHeight),.COLOR(12'h74D)) ball(.x(ball_x),.y(ball_y),.hcount(hcount),.vcount(vcount),.pixel(pixel_bal));
  circle #(.RADIUS(ballRadius),.COLOR(12'h74D)) ball (.x(ball_x),.y(ball_y),.hcount(hcount),.vcount(vcount),.pixel(pixel_bal));
  blend blend_inst (pixel_bal, { 12{1'b0} }, pixel);

  // Update speed based on user input
  always @(vclock) begin
    speed_x <= $signed(pspeed);
    speed_y <= $signed(pspeed);
  end



  // Game logic
  always @(posedge vsync or posedge reset)
  begin
    if (reset) begin
      ball_x <= planWidth >> 1;
      ball_y <= planHeight >> 1;
      end
    else begin // If not reset, continiously check for boundry
      if ((ball_x + speed_x > planWidth - ballRadius) || (ball_x - speed_x < 0))
        direction_x = -direction_x;
      if ((ball_y + speed_y > planHeight) || (ball_y - speed_y < 0))
        direction_y = -direction_y;

      ball_x <= ball_x + speed_x  * direction_x;
      ball_y <= ball_y + speed_y  * direction_y;
      end

  end






endmodule
