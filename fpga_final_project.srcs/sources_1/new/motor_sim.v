`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/19/2017 12:51:24 AM
// Design Name:
// Module Name: motor_sim
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Model movement of motor by recording head coordinate on screen and
//              the head will trace for the movement of target. Implemented using
//              a state machine.
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
module motor_sim(
    ball_x, ball_y, vsync
  );
  input signed [10:0] ball_x;
  input signed [10:0] ball_y;
  input       vsync;  // Specify update frequency

// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  reg signed [10:0] head_x;
  reg signed [10:0] head_y;
  reg signed [10:0] d_x; // Distance x to move
  reg signed [10:0] d_y; // Distance y to move
  reg signed        speed_x;
  reg signed        speed_y;

  localparam State_idle = 0,
              State_running = 1;
  reg STATE = State_idle;

  reg freq = 60 / 60;

  integer counter = 0;

// ==============================================================================
// 							              Implementation
// ==============================================================================
  // always @ (posedge vsync) begin
  //   if (counter >= freq) begin
  //     counter = 0;
  //
  //     // Initiate moving
  //     if (STATE == State_idle) begin
  //       d_x = ball_x - head_x;
  //       d_y = ball_y - head_y;
  //       // To avoid fraction, use
  //       speed_x <= d_x / freq;
  //       speed_y <= d_y / freq;
  //
  //       State = State_running;
  //   end
  //   else begin
  //     counter = counter + 1;
  //
  //     if (STATE == State_running) begin
  //
  //     end
  //   end
  // end



endmodule
