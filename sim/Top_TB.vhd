library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;
  use work.instr_rom_init.all;

entity Top_TB is
  generic (
    PC_WIDTH             : integer := C_MEM_ADDR_WIDTH;
    INSTR_DATA_WIDTH     : integer := C_INSTR_DATA_WIDTH;
    MEM_DATA_WIDTH       : integer := C_MEM_DATA_WIDTH;
    OPCODE_WIDTH         : integer := C_OPCODE_WIDTH;
    REG_ADDR_WIDTH       : integer := C_REG_ADDR_WIDTH;
    IMMEDIATE_DATA_WIDTH : integer := C_IMMEDIATE_DATA_WIDTH;
    MEM_ADDR_WIDTH       : integer := C_MEM_ADDR_WIDTH;
    REG_DATA_WIDTH       : integer := C_REG_DATA_WIDTH;
    LOAD_WIDTH           : integer := C_LOAD_WIDTH;
    ALU_RESULT_WIDTH     : integer := C_ARITH_RESULT_WIDTH
  );
end entity;

architecture sim of Top_TB is
  signal clk                                : std_logic := '0';
  signal dbg_pc                             : std_logic_vector(PC_WIDTH - 1 downto 0);
  signal dbg_acc                            : std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
  signal dbg_branch_en                      : std_logic;
  signal dbg_branch_offset                  : std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
  signal dbg_imm                            : std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
  signal dbg_reg1_data                      : std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
  signal dbg_reg2_data                      : std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
  signal dbg_reg_wr_data                    : std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
  signal dbg_alu_result                     : std_logic_vector(ALU_RESULT_WIDTH - 1 downto 0);
  signal dbg_flag_z, dbg_flag_s, dbg_flag_c : std_logic;
  signal dbg_mem_data_in                    : std_logic_vector(MEM_DATA_WIDTH - 1 downto 0);
  signal dbg_mem_data_out                   : std_logic_vector(MEM_DATA_WIDTH - 1 downto 0);
  signal dbg_mem_addr                       : std_logic_vector(MEM_ADDR_WIDTH - 1 downto 0);
  signal dbg_reg_wr_addr                    : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);

  component Top is
    generic (
      PC_WIDTH             : integer := C_MEM_ADDR_WIDTH;
      INSTR_DATA_WIDTH     : integer := C_INSTR_DATA_WIDTH;
      MEM_DATA_WIDTH       : integer := C_MEM_DATA_WIDTH;
      OPCODE_WIDTH         : integer := C_OPCODE_WIDTH;
      REG_ADDR_WIDTH       : integer := C_REG_ADDR_WIDTH;
      IMMEDIATE_DATA_WIDTH : integer := C_IMMEDIATE_DATA_WIDTH;
      MEM_ADDR_WIDTH       : integer := C_MEM_ADDR_WIDTH;
      REG_DATA_WIDTH       : integer := C_REG_DATA_WIDTH;
      LOAD_WIDTH           : integer := C_LOAD_WIDTH;
      ALU_RESULT_WIDTH     : integer := C_ARITH_RESULT_WIDTH
    );
    port (
      clk                                : in  std_logic;
      dbg_pc                             : out std_logic_vector(PC_WIDTH - 1 downto 0);
      dbg_acc                            : out std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
      dbg_branch_en                      : out std_logic;
      dbg_branch_offset                  : out std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
      dbg_imm                            : out std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
      dbg_reg1_data                      : out std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
      dbg_reg2_data                      : out std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
      dbg_reg_wr_data                    : out std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
      dbg_alu_result                     : out std_logic_vector(ALU_RESULT_WIDTH - 1 downto 0);
      dbg_flag_z, dbg_flag_s, dbg_flag_c : out std_logic;
      dbg_mem_data_in                    : out std_logic_vector(MEM_DATA_WIDTH - 1 downto 0);
      dbg_mem_data_out                   : out std_logic_vector(MEM_DATA_WIDTH - 1 downto 0);
      dbg_mem_addr                       : out std_logic_vector(MEM_ADDR_WIDTH - 1 downto 0);
      dbg_reg_wr_addr                    : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0)
    );
  end component;

begin
  -- clock 50 MHz (20 ns period) for simulation
  clk <= not clk after 10 ns;

  UUT: Top
    generic map (
      PC_WIDTH             => PC_WIDTH,
      INSTR_DATA_WIDTH     => INSTR_DATA_WIDTH,
      MEM_DATA_WIDTH       => MEM_DATA_WIDTH,
      OPCODE_WIDTH         => OPCODE_WIDTH,
      REG_ADDR_WIDTH       => REG_ADDR_WIDTH,
      IMMEDIATE_DATA_WIDTH => IMMEDIATE_DATA_WIDTH,
      MEM_ADDR_WIDTH       => MEM_ADDR_WIDTH,
      REG_DATA_WIDTH       => REG_DATA_WIDTH,
      LOAD_WIDTH           => LOAD_WIDTH,
      ALU_RESULT_WIDTH     => ALU_RESULT_WIDTH
    )
    port map (
      clk               => clk,
      dbg_pc            => dbg_pc,
      dbg_acc           => dbg_acc,
      dbg_branch_en     => dbg_branch_en,
      dbg_branch_offset => dbg_branch_offset,
      dbg_imm           => dbg_imm,
      dbg_reg1_data     => dbg_reg1_data,
      dbg_reg2_data     => dbg_reg2_data,
      dbg_reg_wr_data   => dbg_reg_wr_data,
      dbg_alu_result    => dbg_alu_result,
      dbg_flag_z        => dbg_flag_z,
      dbg_flag_s        => dbg_flag_s,
      dbg_flag_c        => dbg_flag_c,
      dbg_mem_data_in   => dbg_mem_data_in,
      dbg_mem_data_out  => dbg_mem_data_out,
      dbg_mem_addr      => dbg_mem_addr,
      dbg_reg_wr_addr   => dbg_reg_wr_addr
    );

  process
  begin

    -- run for enough cycles to exercise the program
    wait for 2000 ns;

    -- Example checks (adjust expected values according to your program)
    -- Suppose we expect ACC to be zero at some moment (after CLR)
    assert dbg_acc = x"0000" report "ACC not zero after CLR" severity failure;
    report "Simulation passed basic check" severity note;

    wait;
  end process;
end architecture;
