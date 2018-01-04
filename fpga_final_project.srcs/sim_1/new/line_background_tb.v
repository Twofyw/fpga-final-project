`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/31/2017 07:48:00 PM
// Design Name:
// Module Name: line_background_tb
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


module line_background_tb;
// ==============================================================================
// 										  Define Module
//                     Port Declarations
// ==============================================================================
  reg  signed [10:0]   hcount;
  reg         [10:0]   vcount;
  reg         [10:0]   ball_x;
  reg         [10:0]   ball_y;
  reg         [10:0]   head_x;
  reg         [10:0]   head_y;
  wire        [11:0]   background_pixel;
// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  localparam     [11:0]  LINE_COLOR = { 4'b1111, 4'b1001, 4'b0000 };
  // localparam      BACKGROUND_COLOR = { 3{4'b1001} };
  localparam     [11:0]  BACKGROUND_COLOR = { {2{4'b1111}}, 4'b0000 };
  localparam             thickness = 4; // Many pixels thick
  localparam             half_thickness = thickness >> 1;

  // Calculations
  wire           [10:0]  x_s, x_l, y_s, y_l; // Smaller; Larger.
  wire           [10:0]  d_x, d_y;
  reg            [10:0]  y_c, t_y;                // y of middle line relative to x_s; Thickness in y direction

// ==============================================================================
// 							              Implementation
// ==============================================================================
  assign x_s = (ball_x > head_x ? head_x : ball_x);
  assign x_l = (ball_x > head_x ? ball_x : head_x);
  assign y_s = (ball_y > head_y ? head_y : ball_y);
  assign y_l = (ball_y > head_y ? ball_y : head_y);
  assign d_x = x_l - x_s;
  assign d_y = y_l - y_s;

  reg light = 0;
  always @ (*) begin
    if (hcount >= x_s - half_thickness & hcount <= x_l + half_thickness &
       vcount >= y_s - half_thickness & vcount <= y_l + half_thickness) begin // Only work in the rectangular region between head and ball
      // Perpendicular.
      if (x_l - x_s <= thickness) begin
        //  Draw vertical line.
        light = 1;
      end else begin
        y_c = d_y * (hcount - x_s) / d_x;
        t_y = thickness * d_y / d_x;
        if ($signed(vcount) - $signed(y_s) - $signed(y_c) <= t_y && $signed(vcount) - $signed(y_s) - $signed(y_c) >= 0) begin
          light = 1;
        end else begin
          light = 0;
        end
      end
    end else begin
      light = 0;
    end
  end
  assign background_pixel = light ? LINE_COLOR : BACKGROUND_COLOR;

  // reg  signed [10:0]   hcount;
  // reg         [10:0]   vcount;
  // reg         [10:0]   ball_x;
  // reg         [10:0]   ball_y;
  // reg         [10:0]   head_x;
  // reg         [10:0]   head_y;
  initial begin
    hcount = 0;
    vcount = 0;

    // Perpendicular
    // ball_x = 20;
    // ball_y = 20;
    // head_x = 20;
    // head_y = 40;

    // 45 degrees
    ball_x = 20;
    ball_y = 20;
    head_x = 40;
    head_y = 40;

  end

  always begin
    #1 hcount = hcount + 1;

    if (hcount == 320) begin
      hcount <= 0;
      vcount <= vcount + 1;
    end

    if (vcount == 240) begin
      vcount <= 0;
      $finish;
    end

  end

  always @ (light) begin
    $display("x_s%d y_s%d x_l%d y_l%d hcount%d vcount%d y_c%d t_y%d", x_s, y_s, x_l, y_s, hcount, vcount, y_c, t_y);
  end

endmodule
