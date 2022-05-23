----------------------------------------------------------------------------------
--Name: Seyyed Adel Mirsharji
--Student ID: 9730653
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
----------------------------------------------------------------------------------

entity CarParkingEntranceController is											 -- car Parking Entrance Controller system in VHDL
	port 
	(
			clk,reset: in std_logic;														 -- clock and reset of the car parking system
			front_sensor, back_sensor: in std_logic;									 -- two sensor in front and behind the gate of the car parking system
			password_1, password_2: in std_logic_vector(1 downto 0);				 -- input password 
			GREEN_LED,RED_LED: out std_logic;											 -- signaling LEDs
			HEX_1, HEX_2: out std_logic_vector(6 downto 0)							 -- 7-segment Display 
	);
end CarParkingEntranceController;

----------------------------------------------------------------------------------

architecture Behavioral of CarParkingEntranceController is

	type FSM_States is (IDLE,WAIT_PASSWORD,WRONG_PASS,RIGHT_PASS,STOP);		--finite State Machines states: 1-Idle 2-Wait for password 3-Wrong entered password 4-Right entered password 5-Stop 	
	signal current_state,next_state: FSM_States;										--two signals to define current state and next state that system should be in
	signal counter_wait: std_logic_vector(31 downto 0);							--counter to count clocks to wait in waiting state for password to be entered
	signal red_tmp, green_tmp: std_logic;												--led light 

	begin

	----------------------------------------------sequential circuit to change current state
	P1:process(clk,reset)
	begin
	
		if(reset='0') then
		current_state <= IDLE;
		elsif(rising_edge(clk)) then
		current_state <= next_state;
		end if;
		
	end process;
	----------------------------------------------


	----------------------------------------------combinational logic
	P2:process(current_state,front_sensor,password_1,password_2,back_sensor,counter_wait)
	begin
	
		case current_state is 
			when IDLE =>
				if(front_sensor = '1') then 												-- If the front sensor is on,there is a car going to the gate																				
					next_state <= WAIT_PASSWORD;										   -- wait for password
				else
					next_state <= IDLE;
				end if;
				
			when WAIT_PASSWORD =>
				if(counter_wait <= x"00000003") then
					next_state <= WAIT_PASSWORD;
				else 																				-- check password after 4 clock cycles
					if((password_1="01")and(password_2="10")) then
						next_state <= RIGHT_PASS;									 		-- if password is correct, let them in
					else
						next_state <= WRONG_PASS;											-- if not, tell them wrong pass by blinking Green LED,let them input the password again
					end if;
				end if;
				
			when WRONG_PASS =>
				if((password_1="01")and(password_2="10")) then
					next_state <= RIGHT_PASS;												-- if password is correct, let them in
				else
					next_state <= WRONG_PASS;												-- if not, they cannot get in until the password is right
				end if;
				
			when RIGHT_PASS =>
				if(front_sensor='1' and back_sensor = '1') then						-- if the gate is opening for the current car, and the next car come, STOP the next car and require password
					next_state <= STOP; 														-- the current car going into the car park													
				elsif(back_sensor= '1') then												
					next_state <= IDLE;														-- if the current car passed the gate an going into the car park, and there is no next car, go to IDLE
				else
					next_state <= RIGHT_PASS;												
				end if;
				
			when STOP =>
				if((password_1="01")and(password_2="10"))then						-- check password of the next car, if the pass is correct, let them in
					next_state <= RIGHT_PASS;
				else
					next_state <= STOP;
				end if;
				
			when others => next_state <= IDLE;
		end case;
		
	end process;
	
	
	process(clk,reset)																		-- wait for password
	begin
	
		if(reset='0') then
			counter_wait <= (others => '0');
		elsif(rising_edge(clk))then
			if(current_state=WAIT_PASSWORD)then
				counter_wait <= counter_wait + x"00000001";
			else 
				counter_wait <= (others => '0');
			end if;
		end if;
		
	end process;
	
																									-- output 
	process(clk) 																				-- change this clock to change the LED blinking period
	begin
	
		if(rising_edge(clk)) then
			case(current_state) is
				when IDLE => 
					green_tmp <= '0';
					red_tmp <= '0';
					HEX_1 <= "1111111";														-- off
					HEX_2 <= "1111111";														-- off
					
				when WAIT_PASSWORD =>
					green_tmp <= '0';
					red_tmp <= '1'; 															-- red LED turn on and Display 7-segment LED as EN to let the car know they need to input password																			
					HEX_1 <= "0000110";													   -- E 
					HEX_2 <= "0101011"; 														-- n 
					
				when WRONG_PASS =>
					green_tmp <= '0'; 														-- if password is wrong, RED LED blinking 
					red_tmp <= not red_tmp;
					HEX_1 <= "0000110"; 														-- E
					HEX_2 <= "0000110"; 														-- E 
					
				when RIGHT_PASS =>
					green_tmp <= not green_tmp;
					red_tmp <= '0'; 															-- if password is correct, GREEN LED blinking
					HEX_1 <= "0000010"; 														-- 6
					HEX_2 <= "1000000";													   -- 0 
					
				when STOP =>
					green_tmp <= '0';
					red_tmp <= not red_tmp; 												-- Stop the next car and RED LED blinking
					HEX_1 <= "0010010"; 														-- 5
					HEX_2 <= "0001100"; 														-- P 
					
				when others => 
					green_tmp <= '0';
					red_tmp <= '0';
					HEX_1 <= "1111111"; 														-- off
					HEX_2 <= "1111111"; 														-- off
			end case;
		end if;
		
	end process;
	
	RED_LED <= red_tmp  ;
	GREEN_LED <= green_tmp;

end Behavioral;

----------------------------------------------------------------------------------

