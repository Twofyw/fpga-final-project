`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/08/2017 11:51:00 PM
// Design Name:
// Module Name: blend
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Alpha blend with two signals
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////

module blend
  #(parameter m = 1,
              n = 2)
  (input [11:0] pixel_bal, pixel_obj,
    output reg [11:0] pixel_blend
  );

  always @ * begin //perform alpha blending
   if (pixel_bal || pixel_obj) //both on --> overlap
    begin
      pixel_blend[11:8] = ((pixel_bal[11:8] * m) >> n) + ((((2**n)-m)* pixel_obj[11:8] ) >> n);
      pixel_blend[7:4]  = ((pixel_bal[7:4] * m) >> n) + ((((2**n)-m)* pixel_obj[7:4] ) >> n);
      pixel_blend[3:0]   = ((pixel_bal[3:0] * m) >> n) + ((((2**n)-m)* pixel_obj[3:0] ) >> n);
    end
   else //not overlapping
     begin
     pixel_blend = pixel_bal | pixel_obj;
    end
  end

endmodule
