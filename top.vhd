library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.convolution_pkg.ALL;
use work.all;

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
    generic (--padding_d  :integer;
	           --img_d :integer;
             k_d  :integer); -- kernel dimension
    port (clk, en: IN std_logic;
          img_in: IN img_type (0 to k_d-1, 0 to k_d-1); -- input image array
          kernel_in: IN kernel_type (0 to k_d-1, 0 to k_d-1); -- input kernel array
          ready: OUT std_logic;
          --new_img: OUT integer_vector (0 to (img_d)*(img_d)-1)); -- output image
          new_img: OUT integer);
  end component;
  
  signal en: std_logic := '0';
  signal img_ready:std_logic := '0';
  
  signal input_image: img_type (0 to padding_d-1, 0 to padding_d-1) := (others => (others => 0));
  
  
  signal kernel_in: kernel_type (0 to k_d-1, 0 to k_d-1) := laplacian_kernel;
  signal output_image: integer_vector (0 to (img_d)*(img_d)-1) := (others => 0);
  signal image_slice: img_type (0 to k_d-1, 0 to k_d-1) := (others => (others => 0));
  
  signal output_pixel: integer;
  
  
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
  signal halt: std_logic := '0';
  signal write_output: std_logic:= '0';
  
  begin
   
    inram: entity work.input_ram(syn)
	 --inram: entity work.input_ram(fake_memory)
		port map(
			clock => clk,
			address => input_image_address,
			wren => iwren,
			rden => irden,
			data => input_image_write,
			q => input_image_read
		);
		
	 outram: entity work.out_ram(syn)
	 --outram: entity work.out_ram(fake_memory)
		port map(
			clock => clk,
			address => output_image_address,
			wren => owren,
			data => output_image_write,
			q => output_image_read
		);
  
  
    conv: convolution
        generic map(
          k_d => k_d
        )
        port map(
          en => en,
          ready => conv_ready,
          clk => clk,
          new_img => output_pixel,
          img_in => image_slice,
          kernel_in => kernel_in
        );
		  
	ready <= ready_sig;
		  
	process(reset, clk) 
		variable slice_x, slice_y, output_idx: integer := 0;
		variable i: integer := 0 + slice_y;
		variable j: integer := 0 + slice_x;
		variable img_i, img_j: integer := 0;
	begin
		if(reset = '1') then
			en <= '0';
			iwren <= '0';
			irden <= '1';
			owren <= '0';
			ready_sig <= '0';
			--conv_ready <= '0';
			--input_image_read <= (others => '0');
			input_image_write <= (others => '0');
			input_image_address <= (others => '0');
			output_image_read <= (others => '0');
			output_image_write <= (others => '0');
			output_image_address <= (others => '0');
		elsif(rising_edge(clk)) then
      --i := 0 + slice_y;
      --j := 0 + slice_x;
  --	for i in 0 + slice_y to (k_d + slice_y) - 1 loop
	--		for j in 0 + slice_x to (k_d + slice_x) - 1 loop
		    input_image_address <= std_logic_vector(to_unsigned((i + slice_y)*padding_dim + (j+slice_x), 15));
				image_slice(img_i,img_j) <= conv_integer(IEEE.std_logic_arith.unsigned(input_image_read));
	--		end loop;
	--	end loop;
	  --if
	  if(ready_sig = '1') then
	     slice_y := slice_y;
			 slice_x := slice_x;
			 en <= '0';
			 i := i;
       j := j;
		elsif(i = k_d - 1 and j = k_d - 1) then
		  if(slice_y = img_dim) then
			 slice_y := slice_y;
			 slice_x := slice_x;
		  elsif(slice_x = img_dim-1) then
			 slice_y := slice_y + 1;
			 slice_x := 0;
		  	else
			 	slice_x := slice_x + 1;
		  end if;
		
		  
		  en <= '1';
      i := 0;
      j := 0;
		elsif(j = k_d - 1)  then
		  i := i + 1;
		  j := 0;
		else
		  j := j + 1;
		  if(j = k_d - 1) then
		    halt <= '1';
		  end if;
		end if;
		
		
		if(ready_sig = '1') then
		 img_i := img_i;
		 img_j := img_j;
		elsif(halt = '1') then
		  if(img_i = k_d - 1 and j = k_d - 1) then
		    img_i := 0;
		    img_j := 0;
		    write_output <= '1';
		  elsif(img_j = k_d - 1) then
		    img_i := img_i + 1;
		    img_j := 0;
		  else
		    img_j := img_j + 1;
		  end if;
		end if;
		
		if(ready_sig = '1') then
			output_image_address <= output_image_address;
			output_image_write <= output_image_write;
			owren <= '0';
		elsif(conv_ready = '1') then
			output_image_address <= std_logic_vector(to_unsigned(output_idx, 14));
			output_image_write <= std_logic_vector(to_signed(output_pixel, 16));
		else
			output_image_address <= output_image_address;
			output_image_write <= output_image_write;
			owren <= '1';
		end if;
		
		if(output_idx = img_dim) then
		  ready_sig <= ready_sig;
		end if;

		
		--if(output_idx = (img_dim)*(img_dim)-1) then
			--output_idx := 0;
		--	ready_sig <= '1';
		--else
		  if(write_output = '1') then
		    if(output_idx = (img_dim)*(img_dim)-1) then
		       output_idx := output_idx;
			     ready_sig <= '1';
		      else
		        output_idx := output_idx+1;
		        ready_sig <= ready_sig;
			  
		      end if;
			 
			 
--			 if(output_idx = img_dim-1) then
	--	    ready_sig <= ready_sig;
		 -- 	end if;
          write_output <= '0';
			else
			   ready_sig <= ready_sig;
			   output_idx := output_idx;
			   --write_output <= write_output;
			end if;
		--end if;
		

    	
		end if;
	end process;
	
end behave;