`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 01/01/2018 04:57:51 AM
// Design Name:
// Module Name: dashboard
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

// distance from 0 to 100_000
module dashboard(
  distance,pixel_dashboard,hcount,vcount,reached
  );
  input reached;
  input [20:0] distance;
  input [10:0] hcount;
  input [10:0] vcount;
  output [11:0] pixel_dashboard;

  localparam  dashboard_left = 767;
  localparam  dashboard_height = 767;
  localparam  dashboard_right = 1023;
  localparam  thickness = 20;
  reg [11:0]  border_color = reached ? 12'b0101_0100_1101 : { 4'b0100, 4'b1110, 4'b0110 };
  localparam  height = 130;
  localparam  gap = (dashboard_height - 2 * thickness - 5 * height) / 6;
  localparam  width = dashboard_right - dashboard_left - 2 * thickness - 2 * gap;
  localparam  base = thickness + gap;
  localparam  increment = height + gap;


  // Draw frame
  wire [11:0] pixel_1, pixel_2, pixel_3, pixel_4, pixel_l;
  blob_c #(thickness, dashboard_height)                                            b1 (dashboard_left, hcount, 0, vcount, border_color, pixel_1); // left
  blob_c #(dashboard_right - dashboard_left, thickness)                            b2 (dashboard_left, hcount, 0, vcount, border_color, pixel_2); // up
  blob_c #(thickness, dashboard_height)                               b3 (dashboard_right - thickness, hcount, 0, vcount, border_color, pixel_3); // left
  blob_c #(dashboard_right - dashboard_left, thickness) b4 (dashboard_left, hcount, dashboard_height - thickness, vcount, border_color, pixel_4); // down
  blob_c #(thickness >> 1, dashboard_height) left (0, hcount, 0, vcount, border_color, pixel_l);
  assign pixel_dashboard = pixel_1 | pixel_2 | pixel_3 | pixel_4 | pixel_se1 | pixel_se2 | pixel_se3 | pixel_se4 | pixel_se5 | pixel_l;

  wire [11:0] pixel_s1, pixel_s2, pixel_s3, pixel_s4, pixel_s5;
  wire [11:0] pixel_se1, pixel_se2, pixel_se3, pixel_se4, pixel_se5;

  // assign se to enabled color
  reg [4:0] en;
  integer i, counter;
  always @(posedge vcount) begin
    counter <= counter + 1;
    en[4] <= 1;
    if (counter >= 30 - 1) begin // Update every half second
      counter <= 0;
      for (i = 1; i < 5; i = i + 1) begin
        // Scale quadratic distance to avoid sqare root
        en[4-i] <= (distance >= 2**(4 * i + 1));
      end
    end
  end

  assign pixel_se1 = en[0] ? pixel_s1 : 0;
  assign pixel_se2 = en[1] ? pixel_s2 : 0;
  assign pixel_se3 = en[2] ? pixel_s3 : 0;
  assign pixel_se4 = en[3] ? pixel_s4 : 0;
  assign pixel_se5 = en[4] ? pixel_s5 : 0;

  blob #(width, height, {4'b1111, 4'b0011, 4'b0011 }) bs1 (dashboard_left + gap + thickness, hcount, base,                 vcount, pixel_s1);
  blob #(width, height, {4'b0111, 4'b0100, 4'b0011 }) bs2 (dashboard_left + gap + thickness, hcount, base + increment,     vcount, pixel_s2);
  blob #(width, height, {4'b0011, 4'b0101, 4'b0011 }) bs3 (dashboard_left + gap + thickness, hcount, base + 2 * increment, vcount, pixel_s3);
  blob #(width, height, {4'b0001, 4'b0110, 4'b0011 }) bs4 (dashboard_left + gap + thickness, hcount, base + 3 * increment, vcount, pixel_s4);
  blob #(width, height, {4'b0001, 4'b1111, 4'b0011 }) bs5 (dashboard_left + gap + thickness, hcount, base + 4 * increment, vcount, pixel_s5);



endmodule
