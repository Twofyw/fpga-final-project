`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 12/08/2017 11:19:47 PM
// Design Name:
// Module Name: top
// Project Name:
// Target Devices:
// Tool Versions:
// Description: Top module.
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
module top(
  animate,
  test_led,
  CLK100MHZ,
  vga_out_red, vga_out_green, vga_out_blue, vga_out_hsync, vga_out_vsync,
  switch, reset_n, reset_game,
  MISO,SCLK,MOSI,SS,
  SEG, AN, state,
  // JA, // Gyroscope
  signal_x,
  gravity,
  accel_en,
  manual,

  // audio
  AUD_PWM,
  AUD_SD,
  route,

  // SD card
  SD_CD,
  SD_RESET,
  SD_SCK,
  SD_CMD,
  SD_DAT,
  sd_state
  );
  output [4:0]    sd_state; // debug
  input           animate;
  output          test_led;
  input    [2:0]  switch; // Select what to display on VGA
  input           route;  // Select to draw path in rom.
  input           CLK100MHZ;
  input    [2:0]  gravity;
  output   [3:0]  vga_out_red, vga_out_green, vga_out_blue;
  output          vga_out_hsync, vga_out_vsync;

  input           MISO;
  output          SCLK, MOSI, SS; // SPI signals

  // Seven segment display
  output   [6:0]  SEG;
  output   [7:0]  AN;
  output   [1:0]  state;

  // Stepper motors
  output   [3:0]  signal_x;
  wire     [3:0]  signal_y; // Second axis not mounted;

  input    [3:0]  manual;
  input           reset_n, reset_game; // Reset components such as clocks, reset_game to put cursor at center of screen
  input           accel_en;

  // Audio
  output AUD_PWM;
  output AUD_SD; // PWM audio enable

  // SD card
  input SD_CD;
  output SD_RESET;
  output SD_SCK;
  output SD_CMD;
  inout [3:0] SD_DAT;

// ==============================================================================
// 							  Parameters, Registers, and Wires
// ==============================================================================
  localparam          ballRadius = 16;
  localparam          planWidth = 10'd1023, planHeight = 10'd767;
  localparam          headWidth = 24, headHeight = 24;
  localparam          gemeCenter = 384;

  wire            reset = ~reset_n;

  wire            CLK65MHZ, locked; // VGA pixel clock

  // generate basic XVGA video signals
  wire     [10:0] hcount, vcount;
  wire            hsync,vsync;

  // feed XVGA signals to control module
  wire     [11:0] pixel, pixel_out, pixel_head, pixel_bal;

  // Accelerometer
  // wire [3:0] angle;
  wire     [4:0]  S_ACCEL_X, S_ACCEL_Y; // Stablized acceleration
  wire     [11:0] ACCEL_X, ACCEL_Y;

  wire            Data_Ready;

  wire     [10:0] head_x, head_y;
  // wire [3:0] raw_speed, pspeed; // pspeed is raw_speed synchronized with CLK65MHZ
  wire     [3:0]  manual_deb;

  genvar          i, j;
  reg      [26:0]         animation_counter = 0;


  wire     [10:0] ball_x, ball_y;
  reg      [20:0] distance;

  reg [2:0] system_status = 3;
  wire clk_1hz;
  clock_divider clk_1hz_module(.clk_in(CLK100MHZ), .clk_out(clk_1hz), .divider(32'd200_000_000), .reset(reset));

// ==============================================================================
// 							  		         Game up!
// ==============================================================================
  // pspeed is provided by modules driven by 100MHZ clock which might cause synchronization problem with
  // game input, so it needs to be synchronized first.
  generate begin
    for (i = 0; i < 5; i=i+1) begin
      synchronize sync_speed_x (.clk(CLK65MHZ),.in(ACCEL_X[i+7]),.out(S_ACCEL_X[i]));
      synchronize sync_speed_y (.clk(CLK65MHZ),.in(ACCEL_Y[i+7]),.out(S_ACCEL_Y[i]));
    end
  end
  endgenerate

  // Distance between head and ball
  always @ (head_x or head_y or ball_x or ball_y) begin
    distance = (head_x - ball_x)**2 + (head_y - ball_y)**2;
  end

  // Display distance
  display_8hex hex_display (CLK100MHZ, {11'b0, distance}, SEG, AN);

  // debounce manual buttons
  generate begin
    for (j = 0; j < 4; j = j+1) begin
      debounce deb (reset, CLK100MHZ, manual[j], manual_deb[j]);
    end
  end
  endgenerate
  // Connect to game logic
  game gm(.reset(reset_game),
          .vsync(vsync),.ACCEL_X_RAW(S_ACCEL_X),.ACCEL_Y_RAW(S_ACCEL_Y),.gravity(gravity),
          .ball_x(ball_x),.ball_y(ball_y),.accel_en(accel_en),.manual(manual));

  wire [10:0] target_x, target_y, point_x, point_y;
  draw_route dr (.vsync(vsync),.point_x(point_x),.point_y(point_y));
  assign target_x = route ? point_x : ball_x;
  assign target_y = route ? point_y : ball_y;

  motor_sim motor (.CLK100MHZ(CLK100MHZ), .reset(reset), .ball_x(ball_x), .ball_y(ball_y),
    .vsync(vsync), .head_x(head_x), .head_y(head_y),
    .signal_x(signal_x), .signal_y(signal_y), .state(state));









// ==============================================================================
// 							    Not working code with SD card and Audio
// ==============================================================================
  // AUDIO
  //////////////////////////////////////////////////////////////////////////////////
  // create all objects related to PWM audio output

  wire [7:0] pwm_audio_sample_data;
  reg pwm_en;
  assign AUD_SD = pwm_en;

  // use unsigned 8 bit uncompressed WAV file!
  audio_PWM audio_PWM_module(.clk(clk_100mhz), .reset(master_reset),
        .music_data(pwm_audio_sample_data), .PWM_out(AUD_PWM));

// SD CARD
//////////////////////////////////////////////////////////////////////////////////
// SD card objects

  // general SD signals
  reg sd_rd; // when ready is high, asserting rd will begin a read
  wire sd_wr = 0;
  wire sd_ready;
  // wire [4:0] sd_state; // for debug purposes; Set as output

  // set SPI mode
  assign SD_DAT[2] = 1;
  assign SD_DAT[1] = 1;
  assign SD_RESET = 0;

  // read SD signals
  reg [31:0] sd_adr; // address of read operation
  wire [7:0] sd_dout; // data output for read operation
  wire sd_byte_available; // signal that a new byte has been presented on dout

  // write SD signals
  wire [7:0] sd_din = 0;
  wire sd_ready_for_next_byte = 0;

  wire clk_25mhz;
  clk_wiz_1 clk25 (.clk_out1(clk_25mhz),.reset(reset),.clk_in1(CLK100MHZ));

  wire clk_32khz;
  clock_divider clk_32khz_module(.clk_in(clk_100mhz), .clk_out(clk_32khz), .divider(32'd1563), .reset(reset)); // 100_000_000 / (32_000*2) = 1563

  sd_controller sd_controller_module(.cs(SD_DAT[3]), .mosi(SD_CMD), .miso(SD_DAT[0]),
      .sclk(SD_SCK), .rd(sd_rd), .wr(sd_wr), .reset(reset),
      .din(sd_din), .dout(sd_dout), .byte_available(sd_byte_available),
      .ready(sd_ready), .address(sd_adr), .clk(clk_25mhz),
      .ready_for_next_byte(sd_ready_for_next_byte), .status(sd_state));

  reg fifo_wr_en;
  reg fifo_rd_en;

  wire [7:0] fifo_dout;

  wire [7:0] fifo_din;
  assign fifo_din = sd_dout;

  wire fifo_full;
  wire fifo_empty;
  wire fifo_almost_empty;
  wire [13:0] fifo_count;


  fifo_generator_0 audio_sample_buffer(.clk(clk_100mhz), .srst(reset), .din(fifo_din), .wr_en(fifo_wr_en),
        .rd_en(fifo_rd_en), .dout(fifo_dout), .full(fifo_full), .empty(fifo_empty),
        .data_count(fifo_count));


// UI FSM + AUDIO PLAYBACK LOGIC
//////////////////////////////////////////////////////////////////////////////////
  // Reg definitions
  reg last_clk_32khz;
  reg last_clk_1hz;
  reg last_system_status;

  reg last_sd_byte_available;
  reg [5:0] read_counter;
  reg [31:0] sample_increment;

  reg last_audio_playing;
  reg [3:0] audio_number_loop_count;
  reg audio_number_loop_playing;
  reg audio_playing_done;
  reg audio_playing;
  reg [15:0] exit_count;
  reg [15:0] audio_beep_counter;

  // SD module playback parameters
  // Addresses must be multiple of 512 (i.e., end in hex 200,400,600,800,a00,c00,e00)
  reg [31:0] sd_start_adr = 'hcd_000;
  reg [31:0] sd_stop_adr = 'h100_000;
  reg [31:0] internal_sd_stop_adr;

  reg [15:0] boot_counter;

  assign test_led = clk_1hz;
  always @ (posedge CLK100MHZ) begin
    if (reset) begin
      sd_rd <= 0;
      pwm_en <= 0;
      sd_adr <= 'hcd_000;
      sd_start_adr <= 'hcd_000;
      sd_stop_adr <= 'h100_000;
      system_status <= 3;
    end else begin
    // state machine check
    if (system_status == 3) begin // boot state
      // wait for SD card to initialize, then play tone when ready
      if (clk_1hz == 1 && last_clk_1hz == 0) begin
          boot_counter <= boot_counter + 1;
      end

      if (boot_counter == 0) begin
          sd_start_adr <= 'hcd_000;
          sd_stop_adr <= 'h100_000;
          audio_playing <= 1;
      end else if (boot_counter == 2) begin

      end else if (boot_counter >= 3) begin
          system_status <= 1;
          boot_counter <= 0;
      end
    end else begin
      system_status <= 1;
      // play windows startup tone
      if (state_anim == transition1) begin
          sd_start_adr <= 'hcd_000;
          sd_stop_adr <= 'h100_000;
          audio_playing <= 1;
      end
    end

      // used for continuous playback
      if (sample_increment >= 511) begin
         sd_adr <= sd_adr + 32'h200;
         sample_increment <= 0;
      end
      if (sd_adr >= internal_sd_stop_adr && pwm_en == 1) begin // not the best way to do this! but it works. in future use conditional fifo_empty check
        pwm_en <= 0;
      end

    // misc edge triggers
    last_audio_playing <= audio_playing;
    last_sd_byte_available <= sd_byte_available;
    last_clk_32khz <= clk_32khz;
    last_clk_1hz <= clk_1hz;
    last_system_status <= system_status;



    // WORKING CODE FOR AUDIO PLAYBACK
    // provide sd_start_addr, sd_stop_addr, audio_playing

     // sd_byte_available can trigger high multiple cycles for one byte
     // we use this to ensure a positive clock edge
     // do not use fifo_wr_en <= sd_byte_available
     if (last_sd_byte_available == 0 && sd_byte_available == 1) begin
           fifo_wr_en <= 1;
     end else begin
           fifo_wr_en <= 0;
     end


     if (audio_playing) begin

        // load correct start address if beginning playback
        if (last_audio_playing == 0) begin
           sd_adr <= sd_start_adr;
           internal_sd_stop_adr <= sd_stop_adr;
           pwm_en <= 1;
        end else begin

           // load samples from SD
          if (fifo_count < 'd50 && sd_adr <= internal_sd_stop_adr) begin // fifo_count < 'd50
              sd_rd <= 1;
          end else begin
              sd_rd <= 0;
          end

           // read samples from FIFO
           if (clk_32khz == 1 && last_clk_32khz == 0 && fifo_empty == 0) begin
               fifo_rd_en <= 1; // will output a new sample on fifo_dout
               sample_increment <= sample_increment + 1;
           end else begin
               fifo_rd_en <= 0;
           end

           // used for continuous playback
           if (sample_increment >= 511) begin
              sd_adr <= sd_adr + 32'h200;
              sample_increment <= 0;
           end

           if (sd_adr >= internal_sd_stop_adr && last_audio_playing == 1) begin // not the best way to do this! but it works. in future use conditional fifo_empty check
             pwm_en <= 0;
             audio_playing <= 0;
             audio_playing_done <= 1;
           end

         end

     end else begin

         sd_adr <= 0;
         pwm_en <= 0;
         audio_playing_done <= 0;

     end // audio_playing

    end // reset check
  end // always


// ==============================================================================
// 							  		            Display
// ==============================================================================
  // generate VGA pixel clock
  clk_wiz_0 CLK65 (.clk_out1(CLK65MHZ),.reset(reset),.clk_in1(CLK100MHZ),.locked(locked));
  xvga xvga1(.vclock(CLK65MHZ),.hcount(hcount),.vcount(vcount),
            .hsync(hsync),.vsync(vsync));

  // Reached detection
  reg reached;
  always @ (distance) begin
    reached = (distance <= ballRadius**2);
  end
  // Draw ball
  circle #(.RADIUS(ballRadius)) ball
    (.x(ball_x),.y(ball_y),.hcount(hcount),.vcount(vcount),.pixel(pixel_bal),
    .color(reached ? {4'b1111, 4'b0011, 4'b0011 } : { 4'b0000, 4'b0111, 4'b1111 })); // blue
  // Draw head
  blob_c #(.WIDTH(headWidth),.HEIGHT(headHeight)) head
    (.x(head_x - (headWidth >> 1)),                     // green
    .y(head_y - (headHeight >> 1)),.COLOR(reached ? {4'b1111, 4'b0011, 4'b0011 } : { 4'b0100, 4'b1110, 4'b0110 }),
    .hcount(hcount),.vcount(vcount),.pixel(pixel_head));

  // Blend head and ball
  blend #(1,1) motor_ball (pixel_bal, pixel_head, pixel_out);

  wire [11:0] background_pixel;
  line_background lb (.CLK65MHZ(CLK65MHZ),.hcount(hcount),.vcount(vcount),.background_pixel(background_pixel),
    .head_x(head_x),.head_y(head_y),
    .ball_x(ball_x),.ball_y(ball_y));

// module dashboard(
// distance,pixel_dashboard,hcount,vcount
// );
  wire [11:0] pixel_dashboard;
  dashboard db (.distance(distance), .pixel_dashboard(pixel_dashboard), .hcount(hcount), .vcount(vcount),.reached(reached));
  // Alpha-blend pixels from gameBoard and background, and send to VGA output
  wire [11:0] pixel_gameboard;
  blend #(1,0) background2 (pixel_out, background_pixel, pixel_gameboard);
  assign pixel = pixel_gameboard | pixel_dashboard;

  // pixel_bal       + pixel_head       --> pixel_out
  // pixel_out       + background_pixel --> pixel_gameboard
  // pixel_gameboard + pixel_dashboard  --> pixel
  // pixel           + piture           --> pixel_final

  // Boot animation
  wire [11:0] picture;
  reg [2:0] m, n;
  localparam  transition1 = { 3'd1, 3'd0 };
  localparam  transition2 = { 3'd3, 3'd2 };
  localparam  transition3 = { 3'd5, 3'd3 };
  localparam  transition4 = { 3'd1, 3'd1 };
  localparam  transition5 = { 3'd1, 3'd2 };
  localparam  transition6 = { 3'd0, 3'd1 };
  reg  [5:0] state_anim = transition1;
  always @ (posedge CLK100MHZ) begin
    if (animation_counter >= {1'b1, {25{1'b0}}}) begin // Approximate one second
      animation_counter <= 0;
      if (animate) begin
        state_anim <= transition1;
      end else begin
        case (state_anim)
          transition1: state_anim <= transition2;
          transition2: state_anim <= transition3;
          transition3: state_anim <= transition4;
          transition4: state_anim <= transition5;
          transition5: state_anim <= transition6;
          transition6: state_anim <= transition6;
        endcase
      end
    end else begin
      animation_counter <= animation_counter + 1;
    end
  end
  wire [11:0] pixel_final;
  boot_blend bl (picture, pixel, state_anim[5:3], state_anim[2:0], pixel_final);

  // module motor_sim(
  // CLK100MHZ, reset, vsync,
  // ball_x, ball_y, head_x, head_y,
  // signal_x, signal_y,
  // state
  // );
  wire [9:0] back1_x, back1_y;
  wire [9:0] back2_x, back2_y;
  motor_sim back1 (.CLK100MHZ(CLK100MHZ), .reset(reset), .vsync(vsync), .ball_x((planHeight>>1)-128), .ball_y((planHeight>>2)-128), .head_x(back1_x), .head_y(back1_y));
  motor_sim back2 (.CLK100MHZ(CLK100MHZ), .reset(reset), .vsync(vsync), .ball_x(planHeight>>2), .ball_y(planHeight>>1), .head_x(back2_x), .head_y(back2_y));

  // Provide picture
  reg [16:0] addra = 0;
  reg [17:0] addra1= 0;
  wire [11:0] douta, douta1;
  reg pic0, pic1;

  reg [11:0] picture_asce;
  reg [11:0] picture_back;
  blend pict (picture_asce, picture_back, picture);

  blk_mem_gen_0 mem (.addra(addra),.clka(CLK65MHZ),.douta(douta));  // ASCE logo
  blk_mem_gen_1 mem1(.addra(addra1),.clka(CLK65MHZ),.douta(douta1));// Cross section
  localparam picture_width = 256;
  localparam picture_height = 256;
  // Future improvement: Simulate HiDPI.
  // First without dealing with latency
  always @ (posedge CLK65MHZ) begin
    if (hcount == back1_x && vcount == back1_y) begin
      addra = 0;
    end

    if (hcount == back2_x && vcount == back2_y) begin
      addra1 = 0;
    end

    if (hcount >= back1_x && vcount >= back1_y &&
      hcount < back1_x + picture_width && vcount < back1_y + picture_height ) begin
      addra = addra + 1;
      picture_asce = { douta[11:8], douta[3:0], douta[7:4] };;
    end else begin
      picture_asce <= 0;
    end

    if (hcount >= back2_x && vcount >= back2_y &&
      hcount < back2_x + 384 && vcount < back2_y + 384 ) begin
      addra1 = addra1 + 1;
      picture_back = { douta1[11:8], douta1[3:0], douta1[7:4] };
    end else begin
      picture_back <= 0;
    end
  end

// ===============================  TEST  ====================================
  // switch[1:0] selects which video generator to use:
  //  00: the game
  //  01: 1 pixel outline of active video area (adjust screen controls)
  //  10: color bars
  reg [11:0] rgb;

  reg hs,vs; // hsync pipeline
  wire border = (hcount==0 | hcount==1023 | vcount==0 | vcount==767);
  always @(posedge CLK65MHZ) begin
    hs <= hsync;
    vs <= vsync;
    case (switch[2:0])
      3'b000: rgb <= { 12{border} };
      3'b001: rgb <= { vcount[4:1] + hcount[9:6], hcount[8:5], hcount[3:0] };
      3'b010: rgb <= pixel_gameboard;
      3'b011: rgb <= picture;
      3'b100: rgb <= pixel_dashboard;
      3'b110: rgb <= pixel;
      3'b111: rgb <= pixel_final;
    endcase
  end

  assign vga_out_red   = rgb[11:8];
  assign vga_out_green = rgb[7:4];
  assign vga_out_blue  = rgb[3:0];
  assign vga_out_hsync = hs;
  assign vga_out_vsync = vs;

// ==============================================================================
// 							  		            Accelerometer
// ==============================================================================
  ADXL362Ctrl accel (.SYSCLK(CLK100MHZ),.RESET(reset),.ACCEL_X(ACCEL_X),.ACCEL_Y(ACCEL_Y), // .Data_Ready(Data_Ready),
                      .MISO(MISO),.SCLK(SCLK),.MOSI(MOSI),.SS(SS));



// ==============================================================================
// 							  		            Gyroscope
// ==============================================================================

  // Gyroscope
  // wire            begin_transmission;
  // wire            end_transmission;
  // wire     [7:0]  send_data;
  // wire     [7:0]  recieved_data;
  // wire     [15:0] x_axis_data;
  // wire     [15:0] y_axis_data;
  // wire     [15:0] z_axis_data;
  // wire            slave_select;
  // wire     [3:0]  D4;
  // wire            dclk; // Refresh SSD

  // Stepper motors
  // wire            speedClock;

  // //--------------------------------------
	// //		Serial Port Interface Controller
	// //--------------------------------------
  // assign JA[3] = slave_select;
	// master_interface C0(
	// 			.begin_transmission(begin_transmission),
	// 			.end_transmission(end_transmission),
	// 			.send_data(send_data),
	// 			.recieved_data(recieved_data),
	// 			.clk(CLK100MHZ),
	// 			.rst(reset),
	// 			.slave_select(slave_select),
	// 			.start(1'b1),
	// 			.x_axis_data(x_axis_data),
	// 			.y_axis_data(y_axis_data),
	// 			.z_axis_data(z_axis_data)
	// );
  //
  //
	// //--------------------------------------
	// //		    Serial Port Interface
	// //--------------------------------------
	// spi_interface C1(
	// 			.begin_transmission(begin_transmission),
	// 			.slave_select(slave_select),
	// 			.send_data(send_data),
	// 			.recieved_data(recieved_data),
	// 			.miso(JA[1]),
	// 			.clk(CLK100MHZ),
	// 			.rst(reset),
	// 			.end_transmission(end_transmission),
	// 			.mosi(JA[0]),
	// 			.sclk(JA[2])
	// );
  // //---------------------------------------------------
	// // 		  Clock for display components
	// //---------------------------------------------------
	// display_clk display_counter(
	// 			.clk(CLK100MHZ),
	// 			.RST(rst),
	// 			.dclk(dclk)
	// );
  //
  // //---------------------------------------------------
	// // 		Formats data received from PmodGYRO
	// //---------------------------------------------------
	// data_controller hex(
	// 			.clk(CLK100MHZ),
	// 			.dclk(dclk),
	// 			.rst(reset),
	// 			.display_sel(1'b1), // 1 for decimal; 0 for hexadecimal. Opt for decimal here for speed control
	// 			.sel(2'b11), // 11 for decimal output
	// 			.data(x_axis_data), // We're only interested in y axis data. Feeding it in directely
	// 			// .D1(D1),
	// 			// .D2(D2),
	// 			// .D3(D3),
	// 			.D4(D4) // We're only interested in highest bits
	// );
  // assign raw_speed = x_axis_data[15:12];
endmodule
