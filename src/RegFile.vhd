library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;

entity RegFile is
  generic (
    REG_COUNT      : integer := C_REG_COUNT;
    REG_ADDR_WIDTH : integer := C_REG_ADDR_WIDTH;
    REG_DATA_WIDTH : integer := C_REG_DATA_WIDTH
  );
  port (
    clk         : in  std_logic;
    we          : in  std_logic;
    acc_we      : in  std_logic;
    acc_wr_data : in  std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
    wr_addr     : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    wr_data     : in  std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
    reg1_addr   : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    reg2_addr   : in  std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    reg1_data   : out std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
    reg2_data   : out std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
    acc_data    : out std_logic_vector(REG_DATA_WIDTH - 1 downto 0)
  );
end entity;

architecture rtl of RegFile is
  type reg_t is array (0 to REG_COUNT - 1) of std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
  signal regs : reg_t := (others => (others => '0'));

  signal acc_reg : std_logic_vector(REG_DATA_WIDTH - 1 downto 0) := (others => '0');
begin
  sync_reg_write: process (clk) is
  begin
    if rising_edge(clk) then
      if we = '1' then
        regs(to_integer(unsigned(wr_addr))) <= wr_data;
      end if;
    end if;
  end process;

  sync_acc_write: process (clk) is
  begin
    if rising_edge(clk) then
      if acc_we = '1' then
        acc_reg <= acc_wr_data;
      end if;
    end if;
  end process;

  reg1_data <= regs(to_integer(unsigned(reg1_addr)));
  reg2_data <= regs(to_integer(unsigned(reg2_addr)));
  acc_data  <= acc_reg;

end architecture;
