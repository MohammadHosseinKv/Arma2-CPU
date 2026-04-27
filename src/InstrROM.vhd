library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;
  use work.instr_rom_init.all;

entity InstrROM is
  generic (
    INSTR_DATA_WIDTH : integer := C_INSTR_DATA_WIDTH; -- 16 bit instruction
    ADDR_WIDTH       : integer := C_MEM_ADDR_WIDTH    -- 2 byte = 16 bit = 1 word
  );
  port (
    addr  : in  std_logic_vector(ADDR_WIDTH - 1 downto 0); -- PC
    instr : out std_logic_vector(INSTR_DATA_WIDTH - 1 downto 0)
  );
end entity;

architecture behaviour of InstrROM is
begin
  instr <= ROM_CONTENT(to_integer(unsigned(addr)));
end architecture;
