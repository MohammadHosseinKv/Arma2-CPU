library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;

entity Top is
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
end entity;

architecture rtl of Top is
  component InstrROM is
    generic (
      INSTR_DATA_WIDTH : integer := C_INSTR_DATA_WIDTH;
      ADDR_WIDTH       : integer := C_MEM_ADDR_WIDTH
    );
    port (
      addr  : in  std_logic_vector(ADDR_WIDTH - 1 downto 0);
      instr : out std_logic_vector(INSTR_DATA_WIDTH - 1 downto 0)
    );
  end component;

  component RegFile is
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
  end component;

  component ALU is
    generic (
      OPCODE_WIDTH         : integer := C_OPCODE_WIDTH;
      REG_DATA_WIDTH       : integer := C_REG_DATA_WIDTH;
      IMMEDIATE_DATA_WIDTH : integer := C_IMMEDIATE_DATA_WIDTH;
      RESULT_WIDTH         : integer := C_ARITH_RESULT_WIDTH
    );
    port (
      op     : in  std_logic_vector(OPCODE_WIDTH - 1 downto 0);
      acc    : in  std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
      reg    : in  std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
      imm    : in  std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
      result : out std_logic_vector(RESULT_WIDTH - 1 downto 0);
      flag_z : out std_logic;
      flag_c : out std_logic;
      flag_s : out std_logic
    );
  end component;

  component DataMem is
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
  end component;

  component Control_Decoder is
    generic (
      INSTR_DATA_WIDTH     : integer := C_INSTR_DATA_WIDTH;
      MEM_DATA_WIDTH       : integer := C_MEM_DATA_WIDTH;
      OPCODE_WIDTH         : integer := C_OPCODE_WIDTH;
      REG_ADDR_WIDTH       : integer := C_REG_ADDR_WIDTH;
      IMMEDIATE_DATA_WIDTH : integer := C_IMMEDIATE_DATA_WIDTH;
      MEM_ADDR_WIDTH       : integer := C_MEM_ADDR_WIDTH;
      REG_DATA_WIDTH       : integer := C_REG_DATA_WIDTH;
      LOAD_WIDTH           : integer := C_LOAD_WIDTH
    );
    port (
      instr                             : in  std_logic_vector(INSTR_DATA_WIDTH - 1 downto 0);
      flag_z                            : in  std_logic;
      reg1_data, reg2_data              : in  std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
      mem_data                          : in  std_logic_vector(MEM_DATA_WIDTH - 1 downto 0);
      reg1_addr, reg2_addr, reg_wr_addr : out std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
      reg_we, acc_we                    : out std_logic;
      reg_wr_data                       : out std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
      imm                               : out std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
      mem_we                            : out std_logic;
      mem_wr_data                       : out std_logic_vector(MEM_DATA_WIDTH - 1 downto 0);
      mem_addr                          : out std_logic_vector(MEM_ADDR_WIDTH - 1 downto 0);
      branch_en                         : out std_logic;
      branch_offset                     : out std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
      alu_op                            : out std_logic_vector(OPCODE_WIDTH - 1 downto 0)
    );
  end component;

  component PC_Unit is
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
  end component;

  -- Signals
  signal pc_reg  : std_logic_vector(PC_WIDTH - 1 downto 0) := (others => '0');
  signal pc_next : std_logic_vector(PC_WIDTH - 1 downto 0);
  signal instr   : std_logic_vector(INSTR_DATA_WIDTH - 1 downto 0);

  -- control signals in control decoder
  signal dec_reg1_addr, dec_reg2_addr : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
  signal dec_reg_wr_addr              : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
  signal dec_reg_we                   : std_logic;
  signal dec_acc_we                   : std_logic;
  signal dec_alu_op                   : std_logic_vector(OPCODE_WIDTH - 1 downto 0);
  signal dec_reg_wr_data              : std_logic_vector(REG_DATA_WIDTH - 1 downto 0);
  signal dec_imm                      : std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
  signal dec_mem_we                   : std_logic;
  signal dec_mem_wr_data              : std_logic_vector(MEM_DATA_WIDTH - 1 downto 0);
  signal dec_mem_addr                 : std_logic_vector(MEM_ADDR_WIDTH - 1 downto 0);
  signal dec_branch_en                : std_logic;
  signal dec_branch_offset            : std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);

  -- register file outputs + ACC
  signal rf_reg1_data, rf_reg2_data, rf_acc_data : std_logic_vector(REG_DATA_WIDTH - 1 downto 0);

  -- alu
  signal alu_z, alu_c, alu_s : std_logic;
  signal alu_result          : std_logic_vector(C_ARITH_RESULT_WIDTH - 1 downto 0);

  -- Data memory
  signal mem_data_out : std_logic_vector(MEM_DATA_WIDTH - 1 downto 0);

begin

  dbg_pc            <= pc_reg;
  dbg_acc           <= rf_acc_data;
  dbg_branch_en     <= dec_branch_en;
  dbg_branch_offset <= dec_branch_offset;
  dbg_imm           <= dec_imm;
  dbg_reg1_data     <= rf_reg1_data;
  dbg_reg2_data     <= rf_reg2_data;
  dbg_reg_wr_data   <= dec_reg_wr_data;
  dbg_flag_z        <= alu_z;
  dbg_flag_s        <= alu_s;
  dbg_flag_c        <= alu_c;
  dbg_alu_result    <= alu_result;
  dbg_mem_data_in   <= dec_mem_wr_data;
  dbg_mem_data_out  <= mem_data_out;
  dbg_mem_addr      <= dec_mem_addr;
  dbg_reg_wr_addr   <= dec_reg_wr_addr;

  pc_unit_inst: PC_Unit
    port map (
      pc_current    => pc_reg,
      branch_en     => dec_branch_en,
      branch_offset => dec_branch_offset,
      pc_next       => pc_next
    );

  instrrom_inst: InstrROM
    port map (
      addr  => pc_reg,
      instr => instr
    );

  control_decoder_inst: Control_Decoder
    port map (
      instr         => instr,
      flag_z        => alu_z,
      reg1_data     => rf_reg1_data,
      reg2_data     => rf_reg2_data,
      mem_data      => mem_data_out,
      reg1_addr     => dec_reg1_addr,
      reg2_addr     => dec_reg2_addr,
      reg_wr_addr   => dec_reg_wr_addr,
      reg_we        => dec_reg_we,
      acc_we        => dec_acc_we,
      reg_wr_data   => dec_reg_wr_data,
      imm           => dec_imm,
      mem_we        => dec_mem_we,
      mem_wr_data   => dec_mem_wr_data,
      mem_addr      => dec_mem_addr,
      branch_en     => dec_branch_en,
      branch_offset => dec_branch_offset,
      alu_op        => dec_alu_op
    );

  regfile_inst: RegFile
    port map (
      clk         => clk,
      we          => dec_reg_we,
      acc_we      => dec_acc_we,
      acc_wr_data => alu_result,
      wr_addr     => dec_reg_wr_addr,
      wr_data     => dec_reg_wr_data,
      reg1_addr   => dec_reg1_addr,
      reg2_addr   => dec_reg2_addr,
      reg1_data   => rf_reg1_data,
      reg2_data   => rf_reg2_data,
      acc_data    => rf_acc_data
    );

  alu_inst: ALU
    port map (
      op     => dec_alu_op,
      acc    => rf_acc_data,
      reg    => rf_reg1_data,
      imm    => dec_imm,
      result => alu_result,
      flag_z => alu_z,
      flag_c => alu_c,
      flag_s => alu_s
    );

  datamem_inst: DataMem
    port map (
      clk      => clk,
      addr     => dec_mem_addr,
      we       => dec_mem_we,
      data_in  => dec_mem_wr_data,
      data_out => mem_data_out
    );

  seq_update: process (clk) is
  begin
    if falling_edge(clk) then
      pc_reg <= pc_next;
    end if;
  end process;

end architecture;
