
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

architecture fake_memory of out_ram is

  type memory_assembly is array(0 to 16383) of std_logic_vector(15 downto 0);
  signal memory : memory_assembly := (others => "0000000000000000");
  
  signal write_en_int: std_logic;
  signal address_int: std_logic_vector(13 downto 0);
  begin
    main : process(clock)
      begin
        if rising_edge(clock) then
          --read_en_int <= rden;
          address_int <= address;
          write_en_int <= wren;
          -- int_data <= data;
          if write_en_int = '1' then
            memory(to_integer(unsigned(address))) <= data;
          end if;
        end if;
      end process;
      q <= memory(to_integer(unsigned(address_int)));-- when read_en_int = '1' else (others => 'Z');
end architecture;