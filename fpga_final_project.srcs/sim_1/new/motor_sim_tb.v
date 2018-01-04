`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/23/2017 03:20:58 AM
// Design Name:
// Module Name: motor_sim_tb
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
module motor_sim_tb;
  localparam            planWidth  = 10'd1023,
                        planHeight = 10'd767;

  reg           reset = 0, vsync = 0;
  reg  [10:0]   ball_x, ball_y;
  wire [10:0]   head_x, head_y;

  always begin
    #1 vsync = ~vsync;
  end

  initial begin
    ball_x = planWidth;
    ball_y = planHeight;

    #360
    ball_x = ball_x - 200; ball_y = ball_y - 100;
    //
    // #360
    // ball_x = 100; ball_y = planHeight;

  end

  motor_sim sim (
      .reset(reset), .ball_x(ball_x), .ball_y(ball_y), .vsync(vsync),
      .head_x(head_x), .head_y(head_y)
    );

endmodule
