/*
 * a simple snake game implemented in verilog
 *
 * @author 王承揚, 陳冠廷, 林晉德, 黃柏仁, 葉惟欣, 吳柏霖, 陳均哲, 盧湧恩, 郭立鴻
 *
 */

/**
 * a clock divider
 * @input	clk	the system clk
 * @input	reset	the reset signal
 * @output	divided_clk	the divided clk(25MHz)
 */
module clk_divider_25MHz
(
	input clk,
	input reset,
	output reg divided_clk
);

always@(posedge clk or negedge reset) begin
	if(!reset) begin
		divided_clk <= 1'b0;
	end
	else begin
		divided_clk <= ~divided_clk;
	end
end
endmodule


/**
 * a clock divider
 * @input	clk	the system clk
 * @input	reset	the reset signal
 * @output	divided_clk	the divided clk(4Hz)
 */
module clk_divider_4Hz
(
	input clk,
	input reset,
	output reg divided_clk
);

reg [31:0] counter=31'd0;
always@(posedge clk or negedge reset) begin
	if(!reset) begin
		counter <= 31'd0;
		divided_clk <= 1'd0;
	end
	else begin
		if(counter == 31'd6250000) begin
			counter <= 31'd0;
			divided_clk <= ~divided_clk;
		end
		else begin
			counter <= counter + 31'd1;
		end
	end

end
endmodule


/**
 * a clock divider
 * @input	clk	the system clk
 * @input	reset	the reset signal
 * @output	divided_clk	the divided clk(100Hz)
 */
module clk_divider_100Hz
(
	input clk,
	input reset,
	output reg divided_clk
);

reg [31:0] counter=31'd0;
always@(posedge clk or negedge reset) begin
	if(!reset) begin
		counter <= 31'd0;
		divided_clk <= 1'd0;
	end
	else begin
		if(counter == 31'd250000) begin
			counter <= 31'd0;
			divided_clk <= ~divided_clk;
		end
		else begin
			counter <= counter + 31'd1;
		end
	end

end
endmodule


/**
 * output h sync signal according to `h_count_value`
 * @input	h_count_value	the horizontal pixel clock counter value
 * @output	h_sync	hsync signal for vga
 */
module h_sync_signal #
(
	parameter h_sync_pulse = 96
)
(
	input [15:0] h_count_value,
	output h_sync
);


assign h_sync = (h_count_value < h_sync_pulse);
endmodule


/**
 * a counter which counts the horizontal pixel time from 0 to 799
 * @input	clk_25MHz
 * @input	reset
 * @output	h_count_value
 * @output	enable_v_counter	enable vertical counter only when horizontal counter is done counting
 */
module horizontal_counter
(
	input clk_25MHz,
	input reset,
	output reg [15:0] h_count_value = 16'd0,
	output enable_v_counter
);

assign enable_v_counter = (h_count_value == 16'd799);
always@(posedge clk_25MHz or negedge reset) begin
	if(!reset) begin
		h_count_value <= 16'd0;
	end
	else if(h_count_value == 16'd799) begin
		h_count_value <= 16'd0;
	end
	else begin
		h_count_value <= h_count_value + 16'd1;
	end
end
endmodule


/**
 * output v sync signal according to `v_count_value`
 * @input	v_count_value	the vertical pixel clock counter value
 * @output	v_sync	vsync signal for vga
 */
module v_sync_signal #
(
	parameter v_sync_pulse = 2
)
(
	input [16:0] v_count_value,
	output v_sync
);

	
assign v_sync = (v_count_value<v_sync_pulse);
endmodule


/**
 * a counter which counts the vertical pixel time from 0 to 524
 * @input	clk_25MHz
 * @input	reset
 * @input	enable_v_counter	count only when horizontal counter is done counting
 * @output	h_count_value
 */
module vertical_counter
(
	input clk_25MHz,
	input reset,
	input enable_v_counter,
	output reg [15:0] v_count_value = 16'd0
);

always@(posedge clk_25MHz or negedge reset) begin
	if(!reset) begin
		v_count_value <= 16'd0;
	end
	else begin
		if(enable_v_counter) begin
			if(v_count_value == 16'd524) begin
				v_count_value <= 16'd0;
			end
			else begin
				v_count_value <= v_count_value + 16'd1;
			end
		end
	end
end
endmodule


/**
 * check the pixel timing and decide wheather to enable the output for the rgb signal
 * @input	h_count_value
 * @input	v_count_value
 * @ouput	on_display	`1'b1` when the rgb values can be output
 */
module check_on_display #
(
	parameter h_pixel = 640,
	parameter h_front_porch = 16,
	parameter h_sync_pulse = 96,
	parameter h_back_porch = 48,
	parameter h_wait_time = h_sync_pulse + h_back_porch,
	parameter h_display_over_time = h_wait_time + h_pixel - 1,
	parameter v_pixel = 480,
	parameter v_front_porch = 10,
	parameter v_sync_pulse = 2,
	parameter v_back_porch = 33,
	parameter v_wait_time = v_sync_pulse + v_back_porch,
	parameter v_display_over_time = v_wait_time + v_pixel - 1
)
(
	input [15:0] h_count_value,
	input [15:0] v_count_value,
	output on_display
);

assign on_display = (h_count_value >= h_wait_time && h_count_value <= h_display_over_time && v_count_value >= v_wait_time && v_count_value <= v_display_over_time);
endmodule


/**
 * a module which assert that the rgb value can only output to the monitor when it could. eg: can not output rgb value when h sync
 * @input	on_display
 * @input	red_input
 * @input	green_input
 * @input	blue_input
 * @output	red_output
 * @output	green_output
 * @output	blue_output
 */
module output_rgb_signal
(
	input on_display,
	input [3:0] red_input,
	input [3:0] green_input,
	input [3:0] blue_input,
	output [3:0] red_output,
	output [3:0] green_output,
	output [3:0] blue_output
);

assign red_output = (on_display) ? red_input:4'h0;
assign green_output = (on_display) ? green_input:4'h0;
assign blue_output = (on_display) ? blue_input:4'h0;
endmodule


/*
    A keypad controller that outputs a direction.
    Input:
        keypad 6 -> UP
        keypad 4 -> DOWN
        keypad 8 -> RIGHT
        keypad 2 -> LEFT
        other buttons or no pressed button -> previous direction
    Output:
        direction: UP(00), DOWN(01), RIGHT(10), LEFT(11)
*/
module KeypadController(clk_100Hz, reset, keypadCol, keypadRow, direction);
    input clk_100Hz, reset;
    input [3:0]keypadCol;
    output reg [3:0]keypadRow;
    
    output reg [1:0]direction;
    parameter UP = 2'd0, DOWN = 2'd1, RIGHT = 2'd2, LEFT = 2'd3;
    
    always@(posedge clk_100Hz or negedge reset)
    begin
        if(!reset)
        begin
            keypadRow = 4'b1110;
            direction = RIGHT;// default direction: right
        end
        else
        begin
            case({keypadRow, keypadCol})
                8'b1011_1101:begin
						if (direction != DOWN)
                    direction <= UP;
                end// press 6
                8'b1110_1101:begin
					 if (direction != UP)
                    direction <= DOWN;
                end// press 4
                8'b1101_1110:begin
					 if (direction != LEFT)
                    direction <= RIGHT;
                end// press 8
                8'b1101_1011:begin
					 if (direction != RIGHT)
                    direction <= LEFT;
                end// press 2
                default:begin
                    direction <= direction;// maintain previous direction
                end// press invalid buttons
            endcase
            // decide direction
            
            case(keypadRow)
                4'b1110:begin
                    keypadRow <= 4'b1101;
                end
                4'b1101:begin
                    keypadRow <= 4'b1011;
                end
                4'b1011:begin
                    keypadRow <= 4'b0111;
                end
                4'b0111:begin
                    keypadRow <= 4'b1110;
                end
                default:begin
                    keypadRow <= 4'b1110;
                end
            endcase
            // next row
        end
    end
endmodule


/**
 * render a 8x8 pixel red dot according to the `apple_x_position` and `apple_y_position`
 * @input	clk_25MHz
 * @input	reset
 * @input	h_count_value
 * @input	v_count_value
 * @input	apple_x_position
 * @input	apple_y_position
 * @output	red_reg
 */
module render_apple #
(
	parameter h_pixel = 640,
	parameter h_front_porch = 16,
	parameter h_sync_pulse = 96,
	parameter h_back_porch = 48,
	parameter h_wait_time = h_sync_pulse + h_back_porch,
	parameter h_display_over_time = h_wait_time + h_pixel - 1,
	parameter v_pixel = 480,
	parameter v_front_porch = 10,
	parameter v_sync_pulse = 2,
	parameter v_back_porch = 33,
	parameter v_wait_time = v_sync_pulse + v_back_porch,
	parameter v_display_over_time = v_wait_time + v_pixel - 1
)
(
	input clk_25MHz,
	input reset,
	input [15:0] h_count_value,
	input [15:0] v_count_value,
	input [6:0] apple_x_position,
	input [6:0] apple_y_position,
	output reg [3:0] red_reg
);


always@(posedge clk_25MHz or negedge reset) begin
	if(!reset) begin
		red_reg <= 4'h0;
	end
	else begin
		if((h_count_value > h_wait_time + apple_x_position * 10) && (h_count_value < h_wait_time + (apple_x_position + 1) * 10) && (v_count_value > v_wait_time + apple_y_position * 10) && (v_count_value < v_wait_time + (apple_y_position + 1) * 10)) begin
			red_reg <= 4'hf;
		end
		else begin
			red_reg <= 4'h0;
		end
	end
end
endmodule


/**
 * render a blue border on the display with width 10
 * @input	clk_25MHz
 * @input	reset
 * @input	h_count_value
 * @input	v_count_value
 * @output	blue_reg
 */
module render_border #
(
	parameter h_pixel = 640,
	parameter h_front_porch = 16,
	parameter h_sync_pulse = 96,
	parameter h_back_porch = 48,
	parameter h_wait_time = h_sync_pulse + h_back_porch,
	parameter h_display_over_time = h_wait_time + h_pixel - 1,
	parameter v_pixel = 480,
	parameter v_front_porch = 10,
	parameter v_sync_pulse = 2,
	parameter v_back_porch = 33,
	parameter v_wait_time = v_sync_pulse + v_back_porch,
	parameter v_display_over_time = v_wait_time + v_pixel - 1,
	parameter border_width = 10
)
(
	input clk_25MHz,
	input reset,
	input [15:0] h_count_value,
	input [15:0] v_count_value,
	output reg [3:0] blue_reg
);


wire left_border;
wire right_border;
wire top_border;
wire bottom_border;
assign left_border = ((h_count_value > h_wait_time) && (h_count_value < h_wait_time + border_width) && (v_count_value > v_wait_time) && (v_count_value < v_display_over_time));
assign right_border = ((h_count_value > h_display_over_time - border_width) && (h_count_value < h_display_over_time) && (v_count_value > v_wait_time) && (v_count_value < v_display_over_time));
assign top_border = ((v_count_value > v_wait_time) && (v_count_value < v_wait_time + border_width) && (h_count_value > h_wait_time) && (h_count_value < h_display_over_time));
assign bottom_border = ((v_count_value > v_display_over_time - border_width) && (v_count_value < v_display_over_time) && (h_count_value > h_wait_time) && (h_count_value < h_display_over_time));
always@(posedge clk_25MHz or negedge reset) begin
	if(!reset) begin
		blue_reg <= 4'h0;
	end
	else begin
		if(left_border || right_border || top_border || bottom_border) begin
			blue_reg <= 4'hf;
		end
		else begin
			blue_reg <= 4'h0;
		end
	end
end
endmodule


/**
 * generate random position x,y with x range from 2~61 and y range from 2~45
 * @input clk
 * @input gen_new_position_signal	when `1'b1`, generate a new position
 * @input reset
 * @output apple_x_position
 * @output apple_y_position
 */
module gen_rand_apple_position
(
	input clk,
	input gen_new_position_signal,
	input reset,
	output reg [6:0] apple_x_position=7'd20,
	output reg [6:0] apple_y_position=7'd20
);


wire [5:0] output_x;
wire [5:0] output_y;
simple_lfsr_6bit my_simple_lfsr_6bit_x(clk,reset,output_x);
simple_lfsr_6bit my_simple_lfsr_6bit_y(clk,reset,output_y);
 
always@(posedge gen_new_position_signal or negedge reset) begin
	if(!reset) begin
		apple_x_position <= 7'd20;
		apple_y_position <= 7'd20;
	end
	else if(gen_new_position_signal)begin
		apple_x_position <= output_x % 60 + 7'd2;
		apple_y_position <= output_y % 44 + 7'd2;
	end
end

endmodule


/**
 * a simple lfsr
 * @input	clk
 * @input	reset
 * @output	data
 */
module simple_lfsr_6bit
(
	input clk,
	input reset,
	output reg [5:0] data
);

reg [5:0] data_next=6'h1f;

always @* begin
	data_next[5] = data[5]^data[3];
	data_next[4] = data[4]^data[1];
	data_next[3] = data[3]^data[0];
	data_next[2] = data[2]^data_next[4];
	data_next[1] = data[1]^data_next[3];
	data_next[0] = data[0]^data_next[2];
end

always @(posedge clk or negedge reset)
  if(!reset)
    data <= 6'h1f;
  else
    data <= data_next;

endmodule


/**
 * a seven segment display
 * @input	value	the value that will be output to the display
 * @output	display_value the value that the seven segment display will get
 */
module seven_segment_display
(
	input [3:0]value,
	output reg [6:0]display_value
);

always@(value) begin
	case (value)
		4'h0: display_value = 7'b1000000;
		4'h1: display_value = 7'b1111001;
		4'h2: display_value = 7'b0100100;
		4'h3: display_value = 7'b0110000;
		4'h4: display_value = 7'b0011001;
		4'h5: display_value = 7'b0010010;
		4'h6: display_value = 7'b0000010;
		4'h7: display_value = 7'b1111000;
		4'h8: display_value = 7'b0000000;
		4'h9: display_value = 7'b0010000;
		4'ha: display_value = 7'b0001000;
		4'hb: display_value = 7'b0000011;
		4'hc: display_value = 7'b1000110;
		4'hd: display_value = 7'b0100001;
		4'he: display_value = 7'b0000110;
		4'hf: display_value = 7'b0001110;
	endcase
end
endmodule


/**
 * the main module of the snake game
 * @input	clk
 * @input	reset
 * @input	keypadCol
 * @output	keypadRow
 * @output	H_sync
 * @output	V_sync
 * @output	red
 * @output	green
 * @output	blue
 * @output	ten_seven_segment_display
 * @output	one_seven_segment_display
 */
module snake #
(
	parameter h_pixel = 640,
	parameter h_front_porch = 16,
	parameter h_sync_pulse = 96,
	parameter h_back_porch = 48,
	parameter h_wait_time = h_sync_pulse + h_back_porch,
	parameter h_display_over_time = h_wait_time + h_pixel - 1,
	parameter v_pixel = 480,
	parameter v_front_porch = 10,
	parameter v_sync_pulse = 2,
	parameter v_back_porch = 33,
	parameter v_wait_time = v_sync_pulse + v_back_porch,
	parameter v_display_over_time = v_wait_time + v_pixel - 1
)
(
	input clk,
	input reset,
	input [3:0] keypadCol,
	output [3:0] keypadRow,
	output H_sync,
	output V_sync,
	output [3:0] red,
	output [3:0] green,
	output [3:0] blue,
	output [6:0] ten_seven_segment_display,
	output [6:0] one_seven_segment_display
);



wire [1:0] direction;

/**
 *	this section contains all the clock divider
 */
wire clk_25MHz;
wire clk_4Hz;
wire clk_100Hz;
clk_divider_4Hz my_clk_divider_4Hz(clk,reset,clk_4Hz);
clk_divider_25MHz my_clk_divider_25MHz(clk,reset,clk_25MHz);
clk_divider_100Hz my_clk_divider_100Hz(clk,reset,clk_100Hz);


/**
 * the modules for vga signal output
 */
wire [15:0] h_count_value;
wire [15:0] v_count_value;
wire enable_v_counter;
wire on_display;
wire [3:0] red_wire;
wire [3:0] green_wire;
wire [3:0] blue_wire;
horizontal_counter my_horizontal_counter(clk_25MHz,reset,h_count_value,enable_v_counter);
vertical_counter my_vertical_counter(clk_25MHz,reset,enable_v_counter,v_count_value);
h_sync_signal my_h_sync_signal(h_count_value,H_sync);
v_sync_signal my_v_sync_signal(v_count_value,V_sync);
check_on_display my_check_on_display(h_count_value,v_count_value,on_display);
output_rgb_signal my_output_rgb_signal(on_display,red_wire,green_wire,blue_wire,red,green,blue);


/**
 * the keypad controller module
 */
KeypadController my_KeypadController(clk_100Hz, reset, keypadCol, keypadRow, direction);


/**
 * generate the apple position
 */
wire [6:0] apple_x_position;
wire [6:0] apple_y_position;
gen_rand_apple_position my_gen_rand_apple_position(clk,gen_new_position_signal,reset,apple_x_position,apple_y_position);



/**
 * the modules for rendering objects on the display
 */
render_apple my_render_apple(clk_25MHz,reset,h_count_value,v_count_value,apple_x_position,apple_y_position,red_wire);
render_border my_render_border(clk_25MHz,reset,h_count_value,v_count_value,blue_wire);




/**
 * the modules for displaying info on the seven_segment_display
 */
wire [3:0] ten_wire;
wire [3:0] one_wire;

seven_segment_display my_ten_seven_segment_display(ten_wire,ten_seven_segment_display); 
seven_segment_display my_one_seven_segment_display(one_wire,one_seven_segment_display);

			 
			 
/**
 * this code block renders the snake positions according to the array `array_of_snake_x_position`, `array_of_snake_y_position` and `snake_body_len`
 */
reg [6:0] snake_body_len=7'd0;
reg [6:0] array_of_snake_x_position[127:0];
reg [6:0] array_of_snake_y_position[127:0];
reg [3:0] green_reg;
reg found;
integer len_counter_s;
assign green_wire = green_reg;
initial begin
	array_of_snake_x_position[0]<=7'd32;
	array_of_snake_y_position[0]<=7'd24;
	array_of_snake_x_position[1]<=7'd31;
	array_of_snake_y_position[1]<=7'd24;
end
always@(posedge clk_25MHz or negedge reset) begin
	if(!reset) begin
	end
	else begin
		found = 1'd0;
		for(len_counter_s = 0;len_counter_s < 128;len_counter_s = len_counter_s + 1) begin
			if(!found && len_counter_s <= snake_body_len) begin
				if((h_count_value > h_wait_time + array_of_snake_x_position[len_counter_s] * 10) && (h_count_value < h_wait_time + (array_of_snake_x_position[len_counter_s] + 1) * 10) && (v_count_value > v_wait_time + array_of_snake_y_position[len_counter_s] * 10) && (v_count_value < v_wait_time + (array_of_snake_y_position[len_counter_s] + 1) * 10)) begin
					green_reg <= 4'hf;
					found = 1'd1;
				end
				else begin
					green_reg <= 4'h0;
				end
			end
		end
	end
end

/**
 * treat `tmp_array` as a array of bit and use it to store info of whether the index position of snake has collide with it's head
 */
genvar i;
wire [126:0] tmp_array;
generate
	for(i=0;i <127;i=i+1) begin : generate_tmp_array
		assign tmp_array[i] = ((snake_body_len > 3) && (i < snake_body_len) && (array_of_snake_x_position[0] == array_of_snake_x_position[i+1]) && (array_of_snake_y_position[0] == array_of_snake_y_position[i+1]));
	end
endgenerate
wire collision_with_body;
assign collision_with_body = (tmp_array) ? 1'b1: 1'b0;


/**
 * this code block shifts the array `array_of_snake_x_position` and `array_of_snake_y_position` and add new positin to `array_of_snake_x_position[0]` and `array_of_snake_y_position[0]` according to `direction`
 * this code also checks whether the snake head had collide with the border or apple and increase `score` when the it collide with the apple
 */ 
integer len_counter_p;
reg gen_new_position_signal=1'd1;
parameter UP = 2'd0, DOWN = 2'd1, RIGHT = 2'd2, LEFT = 2'd3;
reg [6:0] score=7'd0;
assign collision_with_border = ((array_of_snake_x_position[0] == 7'd0) || (array_of_snake_x_position[0] == 63) || (array_of_snake_y_position[0] == 7'd0) || (array_of_snake_y_position[0] == 47));
assign collision_with_apple = ((array_of_snake_x_position[0] == apple_x_position) && (array_of_snake_y_position[0] == apple_y_position));
assign ten_wire = (score % 10);
assign one_wire = (score / 10);
always@(posedge clk_4Hz or negedge reset) begin
	if(!reset) begin
		array_of_snake_x_position[0]<=7'd32;
		array_of_snake_y_position[0]<=7'd24;
		array_of_snake_x_position[1]<=7'd31;
		array_of_snake_y_position[1]<=7'd24;
		score <= 7'd0;
		snake_body_len <= 7'd0;
		gen_new_position_signal <=1'd1;
	end
	else begin
		for(len_counter_p = 127;len_counter_p > 0;len_counter_p=len_counter_p - 1) begin
			if(len_counter_p <= snake_body_len + 1) begin
				array_of_snake_x_position[len_counter_p] <= array_of_snake_x_position[len_counter_p-1];
				array_of_snake_y_position[len_counter_p] <= array_of_snake_y_position[len_counter_p-1];
			end
		end
		
		case(direction)
			2'd0: 
				begin
						array_of_snake_y_position[0] <= array_of_snake_y_position[0] - 7'd1;
				end
			2'd1: 
				begin
						array_of_snake_y_position[0] <= array_of_snake_y_position[0] + 7'd1;
				end
			2'd2: 
				begin
						array_of_snake_x_position[0] <= array_of_snake_x_position[0] + 7'd1;
				end
			2'd3: 
				begin
						array_of_snake_x_position[0] <= array_of_snake_x_position[0] - 7'd1;
				end
		endcase
		if(collision_with_apple) begin
			snake_body_len <= snake_body_len + 7'd1;
			gen_new_position_signal <= 1'd1;
			score <= score + 7'd1;
		end
		else begin
			gen_new_position_signal <= 1'd0;
		end
		if(collision_with_border | collision_with_body) begin
			snake_body_len <= 7'd0;
			score <= 7'd0;
			array_of_snake_x_position[0]<=7'd32;
			array_of_snake_y_position[0]<=7'd24;
			array_of_snake_x_position[1]<=7'd31;
			array_of_snake_y_position[1]<=7'd24;
			gen_new_position_signal <= 1'b1;
		end
	end
end


endmodule
