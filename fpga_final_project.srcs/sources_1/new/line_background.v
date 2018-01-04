`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/31/2017 07:25:53 PM
// Design Name:
// Module Name: line_background
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
module line_background(
  CLK65MHZ,hcount,vcount,background_pixel,ball_x,ball_y,head_x,head_y
  );
  input                  CLK65MHZ;
  input  signed [10:0]   hcount;
  input         [10:0]   vcount;
  input         [10:0]   ball_x;
  input         [10:0]   ball_y;
  input         [10:0]   head_x;
  input         [10:0]   head_y;
  output        [11:0]   background_pixel;
// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  localparam     [11:0]  LINE_COLOR = { 4'b1111, 4'b1001, 4'b0000 };
  // localparam     [11:0]  LINE_COLOR = 12'b0101_0100_1101;
  localparam      BACKGROUND_COLOR = { 12{1'b0} };
  // localparam     [11:0]  BACKGROUND_COLOR = { {2{4'b1111}}, 4'b0000 };
  // localparam     [11:0]  BACKGROUND_COLOR = {4'b1011, 4'b0101, 4'b0011 };
  localparam             thickness = 4; // Many pixels thick
  localparam             half_thickness = thickness >> 1;

  // Calculations
  wire           [10:0]  x_s, x_l, y_s, y_l; // Smaller; Larger.
  wire           [10:0]  d_x, d_y;
  reg            [20:0]  y_c, t_y;                // y of middle line relative to x_s; Thickness in y direction

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
  always @ (posedge CLK65MHZ) begin
    if (hcount >= x_s - half_thickness & hcount <= x_l + half_thickness &
       vcount >= y_s - half_thickness & vcount <= y_l + half_thickness & !(ball_x == head_x && ball_y == head_y)) begin // Only work in the rectangular region between head and ball
      // Perpendicular.
      if (x_l - x_s <= thickness) begin
        //  Draw vertical line.
        light <= 1;
      end else begin
        y_c = (d_y * (hcount - x_s)) / d_x;
        if (!((ball_x >= head_x && ball_y >= head_y) || (ball_x <= head_x && ball_y <= head_y))) begin
          y_c = d_y - y_c;
        end

        t_y <= thickness * d_y / d_x;
        if ($signed(vcount) - $signed(y_s) - $signed(y_c) <= t_y && $signed(vcount) - $signed(y_s) - $signed(y_c) >= 0) begin
          light <= 1;
        end else begin
          light <= 0;
        end
      end
    end else begin
      light <= 0;
    end
  end

  assign background_pixel = light ? LINE_COLOR : BACKGROUND_COLOR;

endmodule
