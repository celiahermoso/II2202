library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.convolution_pkg.ALL;

use IEEE.std_logic_arith.all;

entity top is
  generic(padding_d  :integer := padding_dim;
	           img_d :integer := img_dim;
             k_d  :integer := kernel_dim);
             
             
--if we want to test in the testbench, we need an input en signal
  port (clk, reset: IN std_logic;
          --en: IN std_logic;
          --img_in: IN img_type (0 to padding_d-1, 0 to padding_d-1); -- input image array
          --kernel_in: IN kernel_type (0 to k_d-1, 0 to k_d-1); -- input kernel array
          ready: OUT std_logic);
          --img_out: OUT integer_vector (0 to (img_d)*(img_d)-1));
end top;


architecture behave of top is
	type states is (reading, processing, writing, done);
	component input_ram is
	port(
		address		: IN STD_LOGIC_VECTOR (14 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		rden		: IN STD_LOGIC  := '1';
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;
	 
	 component out_ram is
	 port(
		address		: IN STD_LOGIC_VECTOR (13 DOWNTO 0);
		clock		: IN STD_LOGIC  := '1';
		data		: IN STD_LOGIC_VECTOR (15 DOWNTO 0);
		wren		: IN STD_LOGIC ;
		q		: OUT STD_LOGIC_VECTOR (15 DOWNTO 0));
	end component;


  component convolution is
    generic (padding_d  :integer;
	           img_d :integer;
             k_d  :integer);
    port (clk, en: IN std_logic;
          img_in: IN img_type (0 to padding_d-1, 0 to padding_d-1);
          kernel_in: IN kernel_type (0 to k_d-1, 0 to k_d-1);
          ready: OUT std_logic;
          new_img: OUT integer_vector (0 to (img_d)*(img_d)-1));
  end component;
  
  signal en: std_logic := '0';
  signal img_ready:std_logic := '0';
  
  signal input_image: img_type (0 to padding_d-1, 0 to padding_d-1) := (others => (others => 0));
  
  signal asd: img_type (0 to 14-1, 0 to 14-1) := (others => (others => 0));
  
  signal kernel_in: kernel_type (0 to k_d-1, 0 to k_d-1) := dog_kernel_1;
  signal output_image: integer_vector (0 to (img_d)*(img_d)-1) := (others => 0);
  
  signal asd2: integer_vector (0 to (10)*(10)-1) := (others => 0);
  
  signal input_image_read: std_logic_vector(15 downto 0);
  signal input_image_write: std_logic_vector(15 downto 0);
  
  signal output_image_read: std_logic_vector(15 downto 0);
  signal output_image_write: std_logic_vector(15 downto 0);
  
  signal input_image_address: std_logic_vector(14 downto 0);
  signal output_image_address: std_logic_vector(13 downto 0);
  
  signal iwren, irden, owren: std_logic := '0';
  
  signal top_state, next_state: states;
  signal conv_ready: std_logic := '0';
  signal y, x, idx: integer;
  signal ready_sig: std_logic := '0';
  
  begin
   
	 inram: input_ram
		port map(
			clock => clk,
			address => input_image_address,
			wren => iwren,
			rden => irden,
			data => input_image_write,
			q => input_image_read
		);
		
	 outram: out_ram
		port map(
			clock => clk,
			address => output_image_address,
			wren => owren,
			data => output_image_write,
			q => output_image_read
		);
  
  
    conv: convolution
        generic map(
          padding_d => 14,
          img_d => 10,
          k_d => k_d
        )
        port map(
          en => en,
          ready => conv_ready,
          clk => clk,
          new_img => asd2,
          img_in => asd,
          kernel_in => kernel_in
        );
		  
	ready <= ready_sig;
		  
	process(reset, clk) 
	begin
		if(reset = '1') then
			en <= '0';
			iwren <= '0';
			irden <= '1';
			owren <= '0';
			--conv_ready <= '0';
			--input_image_read <= (others => '0');
			input_image_write <= (others => '0');
			input_image_address <= (others => '0');
			output_image_read <= (others => '0');
			output_image_write <= (others => '0');
			output_image_address <= (others => '0');
		elsif(rising_edge(clk)) then
      
      
    		-- first we copy stuff from the input RAM to input_image until we reach the end of our image
		  if(y = padding_dim - 1 and x = padding_dim - 1) then -- probably y = padding_dim is the right condition
		      input_image_address <= input_image_address; 
		      input_image <= input_image;
		      en <= '1';
			else
					input_image_address <= std_logic_vector(to_unsigned(y*padding_dim + x, 15));
					input_image(y,x) <= conv_integer(IEEE.std_logic_arith.unsigned(input_image_read));
					en <= en;
			end if;
		  -- increase indexes
			if(x = padding_dim - 1) then
						y <= y + 1;
						x <= 0;
			else
						x <= x + 1;
			end if;

    --copying ends here
      
      --convolution
		  if(conv_ready = '0') then --here we set up the convoltuion
				  owren <= '1';
				  
		      output_image_address <= output_image_address;
		      output_image_write <= output_image_write;
		      idx <= idx;
		  elsif(idx = (img_dim*img_dim)-1) then -- here we are done with copying stuff to the output RAM
		      ready_sig <= '1';
		  
		  
		      output_image_address <= output_image_address;
		      output_image_write <= output_image_write;
		      idx <= idx;
		      owren <= owren;
		  else -- here we copy stuff to the output RAM
					output_image_address <= std_logic_vector(to_unsigned(idx, 14));
					output_image_write <= std_logic_vector(to_unsigned(output_image(idx), 16));
					idx <= idx + 1;
						
						
					owren <= owren;
					ready_sig <= ready_sig;
			end if;
			
			--conv_ready <= conv_ready;
			input_image_write <= input_image_write;
			--input_image_read <= input_image_read;
			iwren <= iwren;
			irden <= irden;
		end if;
	end process;
	
end behave;