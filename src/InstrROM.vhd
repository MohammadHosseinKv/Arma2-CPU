library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;

entity InstrROM is
  generic (
    INSTR_DATA_WIDTH : integer := C_INSTR_DATA_WIDTH; -- 16 bit instruction
    CAPACITY         : integer := C_MEM_CAPACITY;     -- 512 byte
    ADDR_WIDTH       : integer := C_MEM_ADDR_WIDTH    -- 2 byte = 16 bit = 1 word
  );
  port (
    addr  : in  std_logic_vector(ADDR_WIDTH - 1 downto 0); -- PC
    instr : out std_logic_vector(INSTR_DATA_WIDTH - 1 downto 0)
  );
end entity;

architecture behaviour of InstrROM is
  type rom_t is array (0 to (CAPACITY / INSTR_DATA_WIDTH) - 1) of std_logic_vector(INSTR_DATA_WIDTH - 1 downto 0);
  constant ROM_CONTENT : rom_t := (
    0      => x"A105",
    1      => x"A20A",
    others => (others => '0')
  );
begin
  instr <= ROM_CONTENT(to_integer(unsigned(addr)));
end architecture;
