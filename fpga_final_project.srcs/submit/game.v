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
  input                    reset,		   // 1 to initialize module
  input signed      [4:0]  ACCEL_X_RAW,
  input signed      [4:0]  ACCEL_Y_RAW, // (-2g, 2g) -> (MIN, 01111). Pragmatically: (-1g, 1g) -> (MIN, 00111)
  input             [2:0]  gravity,
  input                    vsync,		   // XVGA vertical sync signal (active low)
  input                    accel_en,    // Low to disable accelerometer and use arrow keys instead.
  input             [3:0]  manual,
  output reg signed [10:0] ball_x,
  output reg signed [10:0] ball_y
  );

// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  // Local parameters
  localparam          planWidth = 10'd1023, planHeight = 10'd767;
  localparam          ballRadius = 16;
  localparam  signed  STEP = 1; // pixels shifted when using manual mode


  // Overflow and underflow detection
  reg                 extra_x, extra_y;
  reg          [1:0]  overflow_x = 0, underflow_x = 0, overflow_y = 0, underflow_y = 0;

  wire signed  [4:0]  ACCEL_X, ACCEL_Y;

  // wire         [11:0] pixel_bal, pixel_head, pixel_out;
  reg signed   [3:0]  speed_x, speed_y;
  reg signed   [5:0]  speed_x_accu, speed_y_accu; // Speed accumulators for aid of higher accuracy
  reg          [5:0]  SPEED_MAX, SPEED_MIN;

  genvar i, j;

  integer             update_freq = 0;
  reg          [5:0]  pipe_freq;

  // wire         [10:0] head_x, head_y;
// ==============================================================================
// 							              Implementation
// ==============================================================================
  // always @ (ball_x or ball_y or ball_y_man or ball_x_man or accel_en) begin
  //   if (accel_en) begin
  //     ball_x_out <= ball_x;
  //     ball_y_out <= ball_y;
  //   end else begin
  //     ball_x_out <= ball_x_man;
  //     ball_y_out <= ball_y_man;
  //   end
  // end

  // Manual movement
  // always @ (manual[0] or manual[1] or manual[2] or manual[3]) begin
  //   if (reset_man) begin
  //     ball_x_man <= planWidth >> 1;
  //     ball_y_man <= planHeight >> 1;
  //     have_reset <= 1;
  //   end else begin
  //     if (~accel_en) begin
        // if (manual[0]) begin
        //   if (ball_y_man - STEP <= ballRadius)
        //     ball_y_man <= ballRadius;
        //   else
        //     ball_y_man <= ball_y_man - STEP;
        // end
        // else if (manual[1]) begin
        //   if (ball_x_man - STEP <= ballRadius)
        //     ball_x_man <= ballRadius;
        //   else
        //     ball_x_man <= ball_x_man - STEP;
        // end
        // else if (manual[2]) begin
        //   if (ball_x_man + STEP >= planWidth - ballRadius)
        //     ball_x_man <= planWidth - ballRadius;
        //   else
        //     ball_x_man <= ball_x_man + STEP;
        // end
        // else if (manual[3]) begin
        //   if (ball_y_man + STEP <= planHeight + ballRadius)
        //     ball_y_man <= planHeight + ballRadius;
        //   else
        //     ball_y_man <= ball_y_man + STEP;
        // end
  //     end
  //     have_reset = 0;
  //   end
  // end

  // Game logic
  assign ACCEL_X = (gravity == 3'b001 ? ACCEL_X_RAW >>> 2 : ACCEL_X_RAW);
  assign ACCEL_Y = (gravity == 3'b001 ? ACCEL_Y_RAW >>> 2 : ACCEL_Y_RAW);

  always @ (gravity) begin
    pipe_freq = 60 / { gravity, {3{1'b0}} };
    // Micro adjustment
    if (gravity == 3'b001) begin
      SPEED_MAX <= 6'b00_0011;
      SPEED_MIN <= 6'b11_1100;
    end
    else begin
      SPEED_MAX <= 6'b01_1111;
      SPEED_MIN <= 6'b10_0001;
    end
  end

  always @(posedge vsync or posedge reset) begin
    if (reset) begin
      ball_x <= planWidth >> 1;
      ball_y <= planHeight >> 1;
    end else begin // If not reset
      if (update_freq >= pipe_freq - 1) begin
        // update speed
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

        update_freq = 0;
      end
      else begin
        update_freq = update_freq + 1;
      end

      // continiously check for board boundries
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

      if (accel_en) begin
        ball_x = ball_x + speed_x;
        ball_y = ball_y + speed_y;
      end else begin
        if (manual[0]) begin
          if (ball_y - STEP <= ballRadius)
            ball_y <= ballRadius;
          else
            ball_y <= ball_y - STEP;
        end
        else if (manual[1]) begin
          if (ball_x - STEP <= ballRadius)
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
          if (ball_y + STEP <= planHeight + ballRadius)
            ball_y <= planHeight + ballRadius;
          else
            ball_y <= ball_y + STEP;
        end
      end
    end
  end
endmodule
