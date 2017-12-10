`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/08/2017 08:32:51 PM
// Design Name:
// Module Name: drawing
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Display elements drawing library
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////
//
// blob: generate rectangle on screen
//
//////////////////////////////////////////////////////////////////////
module blob
   #(parameter WIDTH = 64,            // default width: 64 pixels
               HEIGHT = 64,           // default height: 64 pixels
               COLOR = 12'hFFF)  // default color: white
   (input [10:0] x,hcount,
    input [9:0] y,vcount,
    output reg [11:0] pixel);

   always @ * begin
      if ((hcount >= x && hcount < (x+WIDTH)) &&
	       (vcount >= y && vcount < (y+HEIGHT)))
	      pixel = COLOR;
      else pixel = 0;
   end
endmodule

//////////////////////////////////////////////////////////////////////
//
// circle: generate solid circle on screen
//
//////////////////////////////////////////////////////////////////////
module circle
  #(parameter RADIUS = 32,
              COLOR = 12'h74D)
  (input [10:0] x,hcount,
   input [9:0] y,vcount,
   output reg [11:0] pixel);

   // Experimenting with pipeline
   reg [19:0] s_hx, s_vy, s_r;

  initial begin
    s_r = RADIUS**2;
  end

  always @* begin
    s_hx <= (hcount - x)**2;
    s_vy <= (vcount - y)**2;
    if (s_hx + s_vy < s_r)
      pixel <= COLOR;
    else pixel <= 0;
  end
endmodule
