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
// ==============================================================================
// 										  Define Module
//                     Port Declarations
// ==============================================================================
module game (
  input vclock,	// 65MHz clock
  input reset,		// 1 to initialize module
  input signed [4:0] ACCEL_X,
  input signed [4:0] ACCEL_Y, // (-2g, 2g) -> (MIN, 01111). Pragmatically: (-1g, 1g) -> (MIN, 00111)
  input [10:0] hcount,	// horizontal index of current pixel (0..1023)
  input [9:0] vcount, // vertical index of current pixel (0..767)
  input hsync,		// XVGA horizontal sync signal (active low)
  input vsync,		// XVGA vertical sync signal (active low)
  input [2:0] gravity,

  output phsync,	// pong game's horizontal sync
  output pvsync,	// pong game's vertical sync
  output [11:0] pixel	// pong game's pixel  // r=11:8, g=7:4, b=3:0
  );

// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  // Reserve segment on the right for dashboard (205, one fifth for dashboard)

  // Local parameters
  localparam planWidth = 10'd919, planHeight = 10'd768;
  // localparam ballWidth = 64, ballHeight = 64;
  localparam ballRadius = 16;

  // Overflow and underflow detection
  reg extra;
  reg [1:0] overflow = 0, underflow = 0;

  reg signed [10:0] ball_x;
  reg signed [10:0] ball_y;

  wire [11:0] pixel_bal;

  wire signed [3:0] speed_x, speed_y;
  reg signed [5:0] speed_x_accu, speed_y_accu; // Speed accumulators for aid of higher accuracy

  genvar i;

  integer update_freq = 0;
  reg [5:0] pipe_freq;
// ==============================================================================
// 							              Implementation
// ==============================================================================
  // Game logic
  for (i = 0; i < 4; i = i + 1) begin
    assign speed_x[i] = speed_x_accu[i + 2];
    assign speed_y[i] = speed_y_accu[i + 2];
  end

  always @ (gravity)
    // pipe_freq = 60 / { gravity, {3{1'b0}} };
    pipe_freq = 1;

  always @(posedge vsync or posedge reset)
  begin
    if (reset) begin
      ball_x <= planWidth >> 1;
      ball_y <= planHeight >> 1;
      end
    else
    begin // If not reset
      if (update_freq >= pipe_freq) begin
        update_freq = 0;

        // update speed and restrict with in boundries
        {extra, speed_x_accu} = $signed({speed_x_accu[5], speed_x_accu}) + ACCEL_X;
        overflow = ({extra, speed_x_accu[5]} == 2'b01);
        underflow = ({extra, speed_x_accu[5]} == 2'b10);
        if (overflow) begin
          speed_x_accu = 6'b01_1111;
          overflow = 0;
        end
        else if (underflow) begin
          speed_x_accu = 6'b10_0001;
          underflow = 0;
        end

        {extra, speed_y_accu} = $signed({speed_y_accu[5], speed_y_accu}) + ACCEL_Y;
        overflow = ({extra, speed_y_accu[5]} == 2'b01);
        underflow = ({extra, speed_y_accu[5]} == 2'b10);
        if (overflow) begin
          speed_y_accu = 6'b01_1111;
          overflow = 0;
        end
        else if (underflow) begin
          speed_y_accu = 6'b10_0001;
          underflow = 0;
        end
      end
      else begin
        update_freq = update_freq + 1;
      end

      // continiously check for board boundry
      if (ball_x + speed_x + ballRadius > 1023 || ball_x + speed_x - ballRadius < 0)
        begin speed_x_accu[5] = ~speed_x_accu[5]; end
      else if (ball_y + speed_y + ballRadius > 767 || ball_y + speed_y - ballRadius < 0)
        begin speed_y_accu[5] = ~speed_y_accu[5]; end
      else begin
        ball_x = ball_x + speed_x;
        ball_y = ball_y + speed_y;
      end
    end
  end






  // Signal output
  // blob #(.WIDTH(ballWidth),.HEIGHT(ballHeight),.COLOR(12'h74D)) ball(.x(ball_x),.y(ball_y),.hcount(hcount),.vcount(vcount),.pixel(pixel_bal));
  // blend background (pixel_bal, { vcount[8:5] + hcount[9:6], hcount[8:5], hcount[3:0] }, pixel);

  assign phsync = hsync;
  assign pvsync = vsync;
  circle #(.RADIUS(ballRadius),.COLOR(12'h74D)) ball
    (.x(ball_x),.y(ball_y),.hcount(hcount),.vcount(vcount),.pixel(pixel_bal));

  assign pixel = pixel_bal;







endmodule
