library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;

entity DataMem is
  generic (
    ADDR_WIDTH : integer := C_MEM_ADDR_WIDTH;
    DATA_WIDTH : integer := C_MEM_DATA_WIDTH;
    CAPACITY   : integer := C_MEM_CAPACITY
  );
  port (
    clk      : in  std_logic;
    addr     : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
    we       : in  std_logic;
    data_in  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
    data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
  );
end entity;

architecture rtl of DataMem is
  type mem_t is array (0 to (CAPACITY / DATA_WIDTH) - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
  signal mem : mem_t := (others => (others => '0'));
begin

  sync_write: process (clk) is
  begin
    if rising_edge(clk) then
      if we = '1' then
        mem(to_integer(unsigned(addr))) <= data_in;
      end if;
    end if;
  end process;

  data_out <= mem(to_integer(unsigned(addr)));
end architecture;
