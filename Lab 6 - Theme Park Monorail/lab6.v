`define stop1 4'd1
`define stop2 4'd2
`define stop3 4'd3

`define STAY 4'd4
`define CLOCKWISE 4'd5
`define COUNTERCLOCKWISE 4'd6

module lab06(clk, rst, mode, LED, DISPLAY, DIGIT, PS2_CLK, PS2_DATA);
    input rst;
    input clk;
    input mode;
    inout PS2_DATA;
    inout PS2_CLK;
    output[6:0] DISPLAY;
    output[3:0] DIGIT;
    output[15:0] LED;
	
	wire rst;
    wire clk;
    wire mode;
    wire PS2_DATA;
    wire PS2_CLK;
    reg[6:0] DISPLAY;
    reg[3:0] DIGIT;
    wire[15:0] LED;
    
    wire clk_div_16;
    wire clk_div_26;
    wire rst_debounced;
    wire rst_one_pulse;
    wire mode_debounced;
    wire mode_one_pulse;
    
    reg[3:0] passenger_1 = 4'd0;
    reg[3:0] passenger_2 = 4'd0;
    reg[3:0] passenger_3 = 4'd0;
    
    reg[3:0] next_passenger_1 = 4'd0;
    reg[3:0] next_passenger_2 = 4'd0;
    reg[3:0] next_passenger_3 = 4'd0;
        
    reg[3:0] state = `STAY;
    reg[3:0] next_state = `STAY;
    
    reg[3:0] dir = `CLOCKWISE;
    
    reg[2:0] chg_state = 4'd0;
    
    reg[3:0] cur_pos = `stop1;
    reg[3:0] next_pos = `stop1;
    
    reg pos1 = 1'b0;
    reg pos2 = 1'b0;
    reg pos3 = 1'b0;
    
    reg start = 1'b0;
    reg auto = 1'b1;
    
    reg[3:0] monorail_animation = 4'd9;
    reg[3:0] movement = 4'd0;
    reg[3:0] movement_ctr = 4'd0;
    
    reg[3:0] display_num = 4'd0;
    reg[3:0] display_pos = 4'd1;
    reg[3:0] test = 4'd0;
    reg[3:0] test2 = 4'd0;
    
    reg[19:0] refresh_counter = 20'd0;
    wire[1:0] refresher;
    
    reg flag_100 = 1'b1;
    reg flag_26 = 1'b0;
    
    reg flag_movement = 1'b0;
    reg flag_movement_ctr = 1'b0;

    reg[3:0] cnt = 4'd0;
    reg[3:0] cnt_3 = 4'd0;
    reg start_count = 1'b0;
    reg start_count2 = 1'b0;
    reg start_count3 = 1'b0;
    reg hold = 1'b1;
    reg hold2 = 1'b1;
    reg hold3 = 1'b1;
    
    reg flag = 1'b0;
    reg flag_3 = 1'b0;
    
    reg first = 1'b0;
    reg flag_first = 1'b0;
    reg in_3 = 1'b0;
    
	parameter [8:0] LEFT_SHIFT_CODES  = 9'b0_0001_0010;
	parameter [8:0] RIGHT_SHIFT_CODES = 9'b0_0101_1001;
	parameter [8:0] KEY_CODES [0:19] = {
		9'b0_0100_0101,	// 0 => 45
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
		9'b0_0010_1110,	// 5 => 2E
		9'b0_0011_0110,	// 6 => 36
		9'b0_0011_1101,	// 7 => 3D
		9'b0_0011_1110,	// 8 => 3E
		9'b0_0100_0110,	// 9 => 46
		
		9'b0_0111_0000, // right_0 => 70
		9'b0_0110_1001, // right_1 => 69
		9'b0_0111_0010, // right_2 => 72
		9'b0_0111_1010, // right_3 => 7A
		9'b0_0110_1011, // right_4 => 6B
		9'b0_0111_0011, // right_5 => 73
		9'b0_0111_0100, // right_6 => 74
		9'b0_0110_1100, // right_7 => 6C
		9'b0_0111_0101, // right_8 => 75
		9'b0_0111_1101  // right_9 => 7D
	};
	
	reg [15:0] nums;
	reg [3:0] key_num;
	reg [9:0] last_key;
	
	wire shift_down;
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;
	
	assign shift_down = (key_down[LEFT_SHIFT_CODES] == 1'b1 || key_down[RIGHT_SHIFT_CODES] == 1'b1) ? 1'b1 : 1'b0;
	
	clock_divider_26 clkdiv26(.clk(clk), .clk_div_26(clk_div_26));
	clock_divider_16 clkdiv16(.clk(clk), .clk_div_16(clk_div_16));

    debounce debounce_rst(.pb_debounced(rst_debounced), .pb(rst), .clk(clk_div_16));
    one_pulse onepulse_rst(.pb_debounced(rst_debounced), .clk(clk_div_16), .pb_one_pulse(rst_one_pulse));
    debounce debounce_mode(.pb_debounced(mode_debounced), .pb(mode), .clk(clk_div_16));
    one_pulse onepulse_mode(.pb_debounced(mode_debounced), .clk(clk_div_16), .pb_one_pulse(mode_one_pulse));
		
	KeyboardDecoder key_de (
		.key_down(key_down),
		.last_change(last_change),
		.key_valid(been_ready),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	always@(posedge clk or posedge rst_one_pulse)
	begin
	   if(rst_one_pulse == 1'b1)
	       flag_100 <= 1'b1;
	       
       else
       begin
           if(flag_100 == flag_26)
               flag_100 <= ~flag_100;
       end
	end
	
	always@(posedge clk_div_26 or posedge rst_one_pulse)
    begin
        if(rst_one_pulse == 1'b1)
            flag_26 = 1'b0;
        else
            flag_26 <= ~flag_26;
    end
    
 	always@(posedge clk or posedge rst_one_pulse)
    begin
        if (rst_one_pulse == 1'b1)
        begin
            passenger_1 <= 4'd0; 
            passenger_2 <= 4'd0;
            passenger_3 <= 4'd0;
        end
        
        else
        begin
            passenger_1 <= next_passenger_1;
            passenger_2 <= next_passenger_2;
            passenger_3 <= next_passenger_3;
        end
    end
    
	always@(posedge clk or posedge rst_one_pulse)
	begin
	   if (rst_one_pulse)
	   begin
            next_passenger_1 <= 4'd0; 
            next_passenger_2 <= 4'd0;
            next_passenger_3 <= 4'd0;
	   end
	   
	   else
	   begin
            next_passenger_1 <= next_passenger_1;
            next_passenger_2 <= next_passenger_2;
            next_passenger_3 <= next_passenger_3;
            
            if (been_ready && key_down[last_change] == 1'b1)
            begin
                if (key_num != 4'b1111)
				begin
				    if (shift_down == 1'b1)
					begin
				        next_passenger_1 <= 4'd0; 
				        next_passenger_2 <= 4'd0;
				        next_passenger_3 <= 4'd0;
					end
					
					else
					begin
					   if(key_num == 4'b0001)
					   begin
					       if(passenger_1 == 4'b0000)
					           next_passenger_1 <= 4'b0001;
					       else if(passenger_1 == 4'b0001)
					           next_passenger_1 <= 4'b0011;
					       else if(passenger_1 == 4'b0011)
					           next_passenger_1 <= 4'b0111;
					       else if(passenger_1 == 4'b0111)
					           next_passenger_1 <= 4'b1111;
					       else
					           next_passenger_1 <= next_passenger_1;
                       end
                       
					   else if(key_num == 4'b00010)
					   begin
					       if(passenger_2 == 4'b0000)
					           next_passenger_2 <= 4'b0001;
					       else if(passenger_2 == 4'b0001)
					           next_passenger_2 <= 4'b0011;
					       else if(passenger_2 == 4'b0011)
					           next_passenger_2 <= 4'b0111;
					       else if(passenger_2 == 4'b0111)
					           next_passenger_2 <= 4'b1111;
					       else
					           next_passenger_2 <= next_passenger_2;
                       end
                       
					   else if(key_num == 4'b0011)
					   begin
					       if(passenger_3 == 4'b0000)
					           next_passenger_3 <= 4'b0001;
					       else if(passenger_3 == 4'b0001)
					           next_passenger_3 <= 4'b0011;
					       else if(passenger_3 == 4'b0011)
					           next_passenger_3 <= 4'b0111;
					       else if(passenger_3 == 4'b0111)
					           next_passenger_3 <= 4'b1111;
                           else
                               next_passenger_3 <= next_passenger_3;
                       end
					end
				end
			end
			
			if(flag_100 == flag_26)
			begin
			     if(state == `STAY)
			     begin
                    if(cur_pos == `stop1)
                    begin
                      if(passenger_1 == 4'b1111)
                           next_passenger_1 <= 4'b0111;
                       else if(passenger_1 == 4'b0111)
                           next_passenger_1 <= 4'b0011;
                       else if(passenger_1 == 4'b0011)
                           next_passenger_1 <= 4'b0001;
                       else if(passenger_1 == 4'b0001)
                           next_passenger_1 <= 4'b0000;
                        else
                           next_passenger_1 <= next_passenger_1;
                    end
                    
                     else
                       next_passenger_1 <= next_passenger_1;
                       
                   if(cur_pos == `stop2)
                   begin
                     if(passenger_2 == 4'b1111)
                           next_passenger_2 <= 4'b0111;
                       else if(passenger_2 == 4'b0111)
                           next_passenger_2 <= 4'b0011;
                       else if(passenger_2 == 4'b0011)
                           next_passenger_2 <= 4'b0001;
                       else if(passenger_2 == 4'b0001)
                           next_passenger_2 <= 4'b0000;
                        else
                           next_passenger_2 <= next_passenger_2;
                    end
                    
                   else
                       next_passenger_2 <= next_passenger_2;
                       
                    if(cur_pos == `stop3)
                    begin
                        if(passenger_3 == 4'b1111)
                            next_passenger_3 <= 4'b0111;
                       else if(passenger_3 == 4'b0111)
                           next_passenger_3 <= 4'b0011;
                       else if(passenger_3 == 4'b0011)
                           next_passenger_3 <= 4'b0001;
                       else if(passenger_3 == 4'b0001)
                           next_passenger_3 <= 4'b0000;
                        else
                           next_passenger_3 <= next_passenger_3;
                    end
                        
                   else
                       next_passenger_3 <= next_passenger_3;
			     end
			end
		end
	end
	
	assign LED[3:0] = passenger_1;
	assign LED[7:4] = passenger_2;
	assign LED[11:8] = passenger_3;
	assign LED[15] = (auto == 1'b1) ? 1'b0 : 1'b1;
	
	always@(posedge clk or posedge rst_one_pulse or posedge mode_one_pulse)
    begin
        if(rst_one_pulse == 1'b1)
        begin
            auto <= 1'b1;
        end
        
        else
        begin
            if(mode_one_pulse == 1'b1)
            begin
                if(start == 1'b1)
                    auto <= ~auto;
                
                else
                    auto <= auto;
            end
            
            else
                auto <= auto;
        end
	end
	
    always@(posedge clk or posedge rst_one_pulse)
    begin
        if(rst_one_pulse == 1'b1)
        begin
            state <= `STAY;
            cur_pos <= `stop1;
        end
        
        else
        begin
            state <= next_state;
            cur_pos <= next_pos;
        end
    end
    
    always@(*)
    begin
        if(rst_one_pulse == 1'b1)
        begin
            next_pos = `stop1;
            next_state = `STAY;
            start = 1'b0;
            start_count = 1'b0;
            start_count2 = 1'b0;
            start_count3 = 1'b0;
            first = 1'b0;
            flag_first = 1'b0;
        end
        
        else
        begin
            if(state == `STAY)
            begin
                 if(((cur_pos == `stop1 && passenger_1 > 4'd0) || (cur_pos == `stop2 && passenger_2 > 4'd0) || (cur_pos == `stop3 && passenger_3 > 4'd0)) || 
                    (passenger_1 == 4'd0 && passenger_2 == 4'd0 && passenger_3 == 4'd0))
                begin
                    next_pos = cur_pos;
                    next_state = `STAY;
                end
                
                else
                begin
                    if(auto == 1'b0)
                    begin
                        if((dir == `CLOCKWISE && cur_pos == `stop2 && passenger_1 > 4'b0000 && passenger_3 == 4'b0000) || in_3 == 1'b1)
                        begin
                            if(hold == 1'b0)
                            begin
                                next_state = dir;
                            end
                            
                            else if(hold3 == 1'b0)
                            begin
                                next_state = dir;
                            end
                            
                            else if(((dir == `CLOCKWISE && cur_pos == `stop2 && passenger_1 > 4'b0000 && passenger_3 == 4'b0000) || 
                            (dir == `COUNTERCLOCKWISE && cur_pos == `stop3 && passenger_1 > 4'b0000 && passenger_2 == 4'b0000) || 
                            (dir == `COUNTERCLOCKWISE && cur_pos == `stop1 && passenger_2 > 4'b0000 && passenger_3 == 4'b0000)) || flag_3 == 1'b1)
                            begin
                                start_count3 = 1'b1;
                                next_state = `STAY;
                            end
                                
                            else
                            begin
                                start_count = 1'b1;
                                next_state = `STAY;
                            end
                        end
                        
                        else //not clk21
                        begin
                            if(flag_first == 1'b0)
                            begin
                                if(((cur_pos == `stop1 && passenger_2 > 4'b0000) || (cur_pos == `stop2 && passenger_3 > 4'b0000) || (cur_pos == `stop3 && passenger_1 > 4'b0000)) || 
                                    ((cur_pos == `stop1 && passenger_3 > 4'b0000) || (cur_pos == `stop2 && passenger_1 > 4'b0000) || (cur_pos == `stop3 && passenger_2 > 4'b0000)))
                                    begin
                                        first = 1'b1;
                                        flag_first = 1'b1;
                                    end
                                
                                else
                                begin
                                    first = 1'b0;
                                    flag_first = 1'b1;
                                end
                                
                                if(hold == 1'b0)
                                begin
                                    next_state = dir;
                                end
                                
                                else if(hold2 == 1'b0)
                                begin
                                    next_state = dir;
                                end
                                
                                else if(((dir == `CLOCKWISE && cur_pos == `stop2 && passenger_1 > 4'b0000 && passenger_3 == 4'b0000) || 
                                (dir == `COUNTERCLOCKWISE && cur_pos == `stop3 && passenger_1 > 4'b0000 && passenger_2 == 4'b0000) || 
                                (dir == `COUNTERCLOCKWISE && cur_pos == `stop1 && passenger_2 > 4'b0000 && passenger_3 == 4'b0000)) || flag == 1'b1)
                                begin
                                    start_count2 = 1'b1;
                                    next_state = `STAY;
                                end
                                    
                                else
                                begin
                                    start_count = 1'b1;
                                    next_state = `STAY;
                                end
                            end
                            
                            else
                            begin
                                //first = 1'b0; //comment this to not show
                                if(hold == 1'b0)
                                begin
                                    next_state = dir;
                                end
                                
                                else if(hold2 == 1'b0)
                                begin
                                    next_state = dir;
                                end
                                
                                else if(((dir == `CLOCKWISE && cur_pos == `stop2 && passenger_1 > 4'b0000 && passenger_3 == 4'b0000) || 
                                (dir == `COUNTERCLOCKWISE && cur_pos == `stop3 && passenger_1 > 4'b0000 && passenger_2 == 4'b0000) || 
                                (dir == `COUNTERCLOCKWISE && cur_pos == `stop1 && passenger_2 > 4'b0000 && passenger_3 == 4'b0000)) || flag == 1'b1)
                                begin
                                    start_count2 = 1'b1;
                                    next_state = `STAY;
                                end
                                    
                                else
                                begin
                                    start_count = 1'b1;
                                    next_state = `STAY;
                                end
                            end
                        end
                    end
                    
                    else //auto == 1'b1
                    begin
                        start = 1'b1;
                        
                        if(dir == `CLOCKWISE)
                        begin
                            if((cur_pos == `stop1 && passenger_2 > 4'b0000) || (cur_pos == `stop2 && passenger_3 > 4'b0000) || (cur_pos == `stop3 && passenger_1 > 4'b0000))
                                next_state = `CLOCKWISE;
                                
                            else if((cur_pos == `stop1 && passenger_3 > 4'b0000) || (cur_pos == `stop2 && passenger_1 > 4'b0000) || (cur_pos == `stop3 && passenger_2 > 4'b0000))
                                next_state = `COUNTERCLOCKWISE;
                                
                            else
                                next_state = `STAY;
                        end
                        
                        else if(dir == `COUNTERCLOCKWISE)
                        begin
                            if((cur_pos == `stop1 && passenger_3 > 4'b0000) || (cur_pos == `stop2 && passenger_1 > 4'b0000) || (cur_pos == `stop3 && passenger_2 > 4'b0000))
                                next_state = `COUNTERCLOCKWISE;
                                
                            else if((cur_pos == `stop1 && passenger_2 > 4'b0000) || (cur_pos == `stop2 && passenger_3 > 4'b0000) || (cur_pos == `stop3 && passenger_1 > 4'b0000))
                                next_state = `CLOCKWISE;
                                
                            else
                                next_state = `STAY;
                        end
                                
                        else
                            next_state = `STAY;
                    end               
                end
            end
            
            else if(state == `CLOCKWISE)
            begin
                start_count = 1'b0;
                start_count2 = 1'b0;
                start_count3 = 1'b0;
                next_pos = (flag_movement == 1'b1) ? ((cur_pos == `stop3) ? `stop1 : (cur_pos + 4'd1)) : cur_pos;
                next_state = (flag_movement == 1'b1) ? `STAY : `CLOCKWISE;
            end
            
            else if(state == `COUNTERCLOCKWISE)
            begin
                start_count = 1'b0;
                start_count2 = 1'b0;
                start_count3 = 1'b0;
                next_pos = (flag_movement_ctr == 1'b1) ? ((cur_pos == `stop1) ? `stop3 : (cur_pos - 4'd1)) : cur_pos;
                next_state = (flag_movement_ctr == 1'b1) ? `STAY : `COUNTERCLOCKWISE;
            end
        end
    end

    always@(posedge clk_div_26 or posedge rst_one_pulse)
    begin
        if(rst_one_pulse == 1'b1)
        begin
            hold <= 1'b1;
            hold2 <= 1'b1;
            hold3 <= 1'b1;
            dir <= `CLOCKWISE;
            movement <= 4'd0;
            movement_ctr <= 4'd0;
            flag_movement <= 1'b0;
            flag_movement_ctr <= 1'b0;
            flag <= 1'b0;
            flag_3 <= 1'b0;
            cnt <= 4'd0;
            in_3 <= 1'b0;
        end
        
        else
        begin
            if(state == `CLOCKWISE)
            begin
                hold <= 1'b1;
                hold2 <= 1'b1;
                hold3 <= 1'b1;
                flag <= 1'b0;
                flag_3 <= 1'b0;
                dir <= `CLOCKWISE;
                cnt <= 4'd0;
                cnt_3 <= 4'd0;
                in_3 <= 1'b0;
                movement <= (flag_movement == 1'b0) ? (movement + 4'd1) : movement;
                flag_movement <= (movement == 4'd4) ? 1'b1 : 1'b0;
            end
            
            else if(state == `COUNTERCLOCKWISE)
            begin
                hold <= 1'b1;
                hold2 <= 1'b1;
                hold3 <= 1'b1;
                flag <= 1'b0;
                flag_3 <= 1'b0;
                dir <= `COUNTERCLOCKWISE;
                cnt <= 4'd0;
                cnt_3 <= 4'd0;
                in_3 <= 1'b0;
                movement_ctr <= (flag_movement_ctr == 1'b0) ? (movement_ctr + 4'd1) : movement_ctr;
                flag_movement_ctr <= (movement_ctr == 4'd4) ? 1'b1 : 1'b0;
            end
            
            else if(state == `STAY)
            begin
                if(start_count == 1'b1)
                begin
                    cnt <= cnt + 4'd1;
                    
                    if(cnt == 4'd1)
                        hold <= 1'b0;
                end
                
                else if(start_count2 == 1'b1)
                begin
                    cnt <= cnt + 4'd1;
                    flag <= 1'b1;
                    
                    if(cnt == 4'd2)
                        hold2 <= 1'b0;
                end
                
                else if(start_count3 == 1'b1)
                begin
                    in_3 <= 1'b1;
                    cnt_3 <= cnt_3 + 4'd1;
                    flag_3 <= 1'b1;
                    
                    if(cnt_3 == 4'd6)
                        hold3 <= 1'b0;
                end
                
                flag_movement <= 1'b0;
                flag_movement_ctr <= 1'b0;
                movement <= 4'd0;
                movement_ctr <= 4'd0;
            end
        end
    end

    always@(posedge clk)
    begin
        refresh_counter <= refresh_counter + 20'd1;
    end    
    assign refresher = refresh_counter[19:18];
    
    always@(*)
    begin
        case(refresher)
            2'b00:
            begin
                DIGIT <= 4'b1110;
                display_num <= cur_pos;
            end
            
            2'b01:
            begin
                DIGIT <= 4'b1101;
                
                if(state == `CLOCKWISE)
                    display_num <= 4'd4 + movement;
                
                else if(state == `COUNTERCLOCKWISE)
                    display_num <= 4'd9 + movement_ctr;
                    
                else
                begin
                    if(auto == 1'b0)
                    begin
                       if(dir == `CLOCKWISE)
                        begin
                            if((cur_pos == `stop1 && passenger_2 > 4'd0) || (cur_pos == `stop2 && passenger_3 > 4'd0) || (cur_pos == `stop3 && passenger_1 > 4'd0))
                                display_num <= (first == 1'b1) ? 4'd9 : 4'd8;
                            
                            else if((cur_pos == `stop1 && passenger_3 > 4'd0) || (cur_pos == `stop2 && passenger_1 > 4'd0) || (cur_pos == `stop3 && passenger_2 > 4'd0))
                                display_num <= (first == 1'b1) ? 4'd9 : 4'd8;
                                
                            else
                               display_num <= 4'd9;
                        end
                        
                        else if(dir == `COUNTERCLOCKWISE)
                        begin
                           if((cur_pos == `stop1 && passenger_2 > 4'd0) || (cur_pos == `stop2 && passenger_3 > 4'd0) || (cur_pos == `stop3 && passenger_1 > 4'd0))
                                display_num <= 4'd13;//(first == 1'b1) ? 4'd9 : 4'd13;
                            
                            else if((cur_pos == `stop1 && passenger_3 > 4'd0) || (cur_pos == `stop2 && passenger_1 > 4'd0) || (cur_pos == `stop3 && passenger_2 > 4'd0))
                                display_num <= 4'd13;//(first == 1'b1) ? 4'd9 : 4'd13;
                                
                            else
                               display_num <= 4'd9;
                        end
                    end
                    
                    else if(auto == 1'b1)
                    begin
                        if(dir == `CLOCKWISE)
                        begin
                           if((cur_pos == `stop1 && passenger_2 > 4'd0) || (cur_pos == `stop2 && passenger_3 > 4'd0) || (cur_pos == `stop3 && passenger_1 > 4'd0))
                                display_num <= 4'd8;
                            
                            else if((cur_pos == `stop1 && passenger_3 > 4'd0) || (cur_pos == `stop2 && passenger_1 > 4'd0) || (cur_pos == `stop3 && passenger_2 > 4'd0))
                                display_num <= 4'd13;
                                
                            else
                               display_num <= 4'd9;
                        end
                        
                        else if(dir == `COUNTERCLOCKWISE)
                        begin
                            if((cur_pos == `stop1 && passenger_3 > 4'd0) || (cur_pos == `stop2 && passenger_1 > 4'd0) || (cur_pos == `stop3 && passenger_2 > 4'd0))
                                display_num <= 4'd13;
                                
                            else if((cur_pos == `stop1 && passenger_2 > 4'd0) || (cur_pos == `stop2 && passenger_3 > 4'd0) || (cur_pos == `stop3 && passenger_1 > 4'd0))
                                display_num <= 4'd8;
                                
                            else
                               display_num <= 4'd9;
                        end
                    end
                end
            end
            
            2'b10:
            begin
                DIGIT <= 4'b1011;
                display_num <= 4'd9;
            end
            
            2'b11:
            begin
                DIGIT <= 4'b0111;
                display_num <= 4'd9;
            end
            
            default:
            begin
                DIGIT <= 4'b1111;
                display_num <= 4'd14;
            end        
        endcase
    end
    
    always @ (*) begin
    	case (display_num)
    		4'd0 : DISPLAY = 7'b1000000;	//0000
			4'd1 : DISPLAY = 7'b1111001;   //0001                                                
			4'd2 : DISPLAY = 7'b0100100;   //0010                                                
			4'd3 : DISPLAY = 7'b0110000;   //0011
			4'd4 : DISPLAY = 7'b1111111;
			4'd5 : DISPLAY = 7'b1101111;   //1st clockwise
			4'd6 : DISPLAY = 7'b1001111;
			4'd7 : DISPLAY = 7'b1001110;
			4'd8 : DISPLAY = 7'b1001100;
			4'd9 : DISPLAY = 7'b1111111;
			4'd10 : DISPLAY = 7'b1111011;   //1st counterclockwise
			4'd11 : DISPLAY = 7'b1111001;
			4'd12 : DISPLAY = 7'b1111000;
			4'd13 : DISPLAY = 7'b1011000;
			4'd14 : DISPLAY = 7'b1111111;
			default : DISPLAY = 7'b1111111;
    	endcase
    end
   
	always @ (*) begin
		case (last_change)
			KEY_CODES[00] : key_num = 4'b0000;
			KEY_CODES[01] : key_num = 4'b0001;
			KEY_CODES[02] : key_num = 4'b0010;
			KEY_CODES[03] : key_num = 4'b0011;
			KEY_CODES[04] : key_num = 4'b0100;
			KEY_CODES[05] : key_num = 4'b0101;
			KEY_CODES[06] : key_num = 4'b0110;
			KEY_CODES[07] : key_num = 4'b0111;
			KEY_CODES[08] : key_num = 4'b1000;
			KEY_CODES[09] : key_num = 4'b1001;
			KEY_CODES[10] : key_num = 4'b0000;
			KEY_CODES[11] : key_num = 4'b0001;
			KEY_CODES[12] : key_num = 4'b0010;
			KEY_CODES[13] : key_num = 4'b0011;
			KEY_CODES[14] : key_num = 4'b0100;
			KEY_CODES[15] : key_num = 4'b0101;
			KEY_CODES[16] : key_num = 4'b0110;
			KEY_CODES[17] : key_num = 4'b0111;
			KEY_CODES[18] : key_num = 4'b1000;
			KEY_CODES[19] : key_num = 4'b1001;
			default		  : key_num = 4'b1111;
		endcase
	end
endmodule

module clock_divider_16(clk, clk_div_16);
    parameter n = 16;
    input clk;
    output clk_div_16;
    
    reg[15:0] num = 16'd0;
    wire [15:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div_16 = num[n-1];
endmodule

module clock_divider_26(clk, clk_div_26);
    parameter n = 26;
    input clk;
    output clk_div_26;
    
    reg[25:0] num = 26'd0;
    wire [25:0] next_num;

    always @(posedge clk)
    begin
        num = next_num;
    end
    
    assign next_num = num+1;
    assign clk_div_26 = num[n-1];
endmodule

