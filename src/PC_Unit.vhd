library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;

entity PC_Unit is
  generic (
    PC_WIDTH             : integer := C_MEM_ADDR_WIDTH;
    IMMEDIATE_DATA_WIDTH : integer := C_IMMEDIATE_DATA_WIDTH
  );
  port (
    pc_current    : in  std_logic_vector(PC_WIDTH - 1 downto 0);
    branch_en     : in  std_logic;
    branch_offset : in  std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
    pc_next       : out std_logic_vector(PC_WIDTH - 1 downto 0)
  );
end entity;

architecture behaviour of PC_Unit is
  signal pc_u            : unsigned(PC_WIDTH - 1 downto 0);
  signal branch_offset_s : signed(IMMEDIATE_DATA_WIDTH downto 0);
  signal pc_extended     : signed(PC_WIDTH downto 0);
  signal pc_sum          : signed(PC_WIDTH downto 0);
begin
  pc_u            <= unsigned(pc_current);
  branch_offset_s <= signed(branch_offset(IMMEDIATE_DATA_WIDTH - 1) & branch_offset);
  pc_extended     <= signed('0' & std_logic_vector(pc_u));
  pc_sum          <= pc_extended + branch_offset_s;

  compute_pc_next: process (branch_en, pc_u, pc_sum) is
  begin
    if branch_en = '1' then
      pc_next <= std_logic_vector(unsigned(pc_sum(PC_WIDTH - 1 downto 0)));
    else
      pc_next <= std_logic_vector(pc_u + 1);
    end if;
  end process;
end architecture;
