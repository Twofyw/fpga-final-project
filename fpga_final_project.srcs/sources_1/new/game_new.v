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
// Description: Re-written game itself. Outputs the coordinate of the ball
// given user control from accelerometer or buttons
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
  input                     reset,
  input      signed  [4:0]  ACCEL_X_RAW,
  input      signed  [4:0]  ACCEL_Y_RAW,
  input              [2:0]  gravity,
  input                     vsync,
  input                     accel_en,
  input              [3:0]  manual,
  output reg signed  [10:0] ball_x,
  output reg signed  [10:0] ball_y
  );
// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  // Local parameters
  localparam                planWidth = 10'd767, planHeight = 10'd767;
  localparam                ballRadius = 16;
  // localparam  signed        STEP = 20;
  reg                 [4:0] STEP = (gravity == 3'b001 ? 10 : 20);

  // Overflow and underflow detection
  reg                       extra_x, extra_y;
  reg                 [1:0] overflow_x = 0, underflow_x = 0;
  reg                 [1:0] overflow_y = 0, underflow_y = 0;

  wire        signed  [4:0] ACCEL_X, ACCEL_Y;
  reg         signed  [3:0] speed_x, speed_y;
  reg         signed  [5:0] speed_x_accu, speed_y_accu; // Speed accumulators for aid of higher accuracy
  reg                 [5:0] SPEED_MAX, SPEED_MIN;

  reg                 [5:0] counter = 0, update_freq = 0;

// ==============================================================================
// 							              Implementation
// ==============================================================================
  // Precise control using accelerometer
  assign ACCEL_X = (gravity == 3'b001 ? ACCEL_X_RAW >>> 2 : ACCEL_X_RAW);
  assign ACCEL_Y = (gravity == 3'b001 ? ACCEL_Y_RAW >>> 2 : ACCEL_Y_RAW);

  // Ball speed
  always @ (gravity) begin
    update_freq = (gravity == 0 ? 6'b0 : 60 / { gravity, {3{1'b0}} });
    // Precise control
    if (gravity == 3'b001) begin
      SPEED_MAX <= 6'b00_0010;
      SPEED_MIN <= 6'b11_1110;
    end else begin
      SPEED_MAX <= 6'b01_1111;
      SPEED_MIN <= 6'b10_0001;
    end
  end

  always @ (posedge vsync or posedge reset) begin
    if (reset) begin
      ball_x <= planWidth >> 1;
      ball_y <= planHeight >> 1;
    end else begin
      counter = counter + 1;
      // Update speed and restrict within MIN and MAX speed
      if (counter >= update_freq) begin
        counter = 0;
        {extra_x, speed_x_accu} = $signed({speed_x_accu[5], speed_x_accu}) + ACCEL_X;
        speed_x = speed_x_accu[5:2];
        overflow_x              = ({extra_x, speed_x_accu[5]} == 2'b01);
        underflow_x             = ({extra_x, speed_x_accu[5]} == 2'b10);
        {extra_y, speed_y_accu} = $signed({speed_y_accu[5], speed_y_accu}) + ACCEL_Y;
        speed_y = speed_y_accu[5:2];
        overflow_y              = ({extra_y, speed_y_accu[5]} == 2'b01);
        underflow_y             = ({extra_y, speed_y_accu[5]} == 2'b10);

        if (overflow_x) begin
          speed_x_accu = SPEED_MAX;
          speed_x = speed_x_accu[5:2];
          overflow_x = 0;
        end
        else if (underflow_x) begin
          speed_x_accu = SPEED_MIN;
          speed_x = speed_x_accu[5:2];
          underflow_x = 0;
        end

        if (overflow_y) begin
          speed_y_accu = SPEED_MAX;
          speed_y = speed_y_accu[5:2];
          overflow_y = 0;
        end
        else if (underflow_y) begin
          speed_y_accu = SPEED_MIN;
          speed_y = speed_y_accu[5:2];
          underflow_y = 0;
        end

        // Continiously check for board boundries
        if ($signed(ball_x + speed_x + ballRadius) > planWidth || $signed(ball_x + speed_x - ballRadius) < 0)
          begin if (speed_x_accu != 0) begin
              speed_x_accu = ~speed_x_accu + 1'b1;
              speed_x = speed_x_accu[5:2];
            end
          end

        if ($signed(ball_y + speed_y + ballRadius) > planHeight || $signed(ball_y + speed_y - ballRadius) < 0)
          begin if (speed_y_accu != 0) begin
              speed_y_accu = ~speed_y_accu + 1'b1;
              speed_y = speed_y_accu[5:2];
              end
          end

        // Update location
        if (accel_en) begin
          ball_x = ball_x + speed_x;
          ball_y = ball_y + speed_y;
        end else begin
          if (manual[0]) begin
            if ($signed(ball_y) - $signed(STEP) <= $signed(ballRadius))
              ball_y <= ballRadius;
            else
              ball_y <= ball_y - STEP;
          end
          else if (manual[1]) begin
            if ($signed(ball_x) - $signed(STEP) <= $signed(ballRadius))
              ball_x <= ballRadius;
            else
              ball_x <= ball_x - STEP;
          end
          else if (manual[2]) begin
            if (ball_x + STEP >= planWidth - ballRadius)
              ball_x <= planWidth - ballRadius;
            else
              ball_x <= ball_x + STEP;
          end
          else if (manual[3]) begin
            if (ball_y + STEP >= planHeight - ballRadius)
              ball_y <= planHeight - ballRadius;
            else
              ball_y <= ball_y + STEP;
          end
        end
      end
    end


  end











endmodule
