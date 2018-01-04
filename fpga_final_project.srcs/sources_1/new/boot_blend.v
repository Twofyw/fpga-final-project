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

module boot_blend
  (input      [11:0] pixel_bal, pixel_obj,
    input     [2:0]  m, n,
   output reg [11:0] pixel_blend
  );

  reg [11:0] tmp;
  reg [3:0] sft11, sft12;
  reg [6:0] sft111, sft121, sft211, sft221, sft311, sft321;
  reg [3:0] sft21, sft22;
  reg [3:0] sft31, sft32;
  reg [3:0] cst;

  always @ (m, n) begin
    cst = (2**n)-m;
  end

  always @ * begin //perform alpha blending
    tmp <= pixel_bal & pixel_obj;
    if (tmp != 0) //both on --> overlap
      begin
        sft111 <= pixel_bal[11:8] * m;
        sft11  <= sft111 >> n;
        sft121 <= cst * pixel_obj[11:8];
        sft12  <= sft121 >> n;
        sft211 <= pixel_bal[7:4] * m;
        sft21  <= sft211 >> n;
        sft221 <= cst * pixel_obj[7:4];
        sft22  <= sft221 >> n;
        sft311 <= pixel_bal[3:0] * m;
        sft31  <= sft311 >> n;
        sft321 <= cst * pixel_obj[3:0];
        sft32  <= sft321 >> n;

        pixel_blend[11:8] <= sft11 + sft12;
        pixel_blend[7:4]  <= sft21 + sft22;
        pixel_blend[3:0]  <= sft31 + sft32;
      end
    else //not overlapping
      begin
        pixel_blend <= pixel_bal | pixel_obj;
      end
  end

endmodule
