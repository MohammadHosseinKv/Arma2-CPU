library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;

entity Control_Decoder is
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
end entity;

architecture behaviour of Control_Decoder is
  signal opcode           : std_logic_vector(OPCODE_WIDTH - 1 downto 0);
  signal opcode_key       : std_logic;
  signal opcode_mem_instr : std_logic;
  signal Reg1             : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
  signal imm_d            : std_logic_vector(IMMEDIATE_DATA_WIDTH - 1 downto 0);
begin
  opcode_key <= instr(INSTR_DATA_WIDTH - 1);
  -- opcode <= instr(14 downto 11);
  opcode           <= instr((INSTR_DATA_WIDTH - 1) - 1 downto (INSTR_DATA_WIDTH - 1) - (OPCODE_WIDTH - 1) - 1);
  opcode_mem_instr <= instr(INSTR_DATA_WIDTH - 1 - 1);
  -- opcode_mem_instr := instr(14);
  imm_d <= instr(IMMEDIATE_DATA_WIDTH - 1 downto 0);
  Reg1  <= instr((INSTR_DATA_WIDTH - 1 - OPCODE_WIDTH) - 1 downto (INSTR_DATA_WIDTH - 1 - OPCODE_WIDTH) - 1 - (REG_ADDR_WIDTH - 1));
  -- opcode_key <= instr(15);
  -- imm_d      <= instr(7 downto 0);
  -- Reg1        <= instr(10 downto 8);
  decode_proc: process (opcode, opcode_key, opcode_mem_instr, Reg1, imm_d, flag_z, reg1_data, reg2_data, mem_data) is
    variable base : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
    variable dst  : std_logic_vector(REG_ADDR_WIDTH - 1 downto 0);
  begin
    reg1_addr <= (others => '0');
    reg2_addr <= (others => '0');
    reg_wr_addr <= (others => '0');
    reg_we <= '0';
    reg_wr_data <= (others => '0');
    acc_we <= '0';
    imm <= (others => '0');
    mem_we <= '0';
    mem_wr_data <= (others => '0');
    mem_addr <= (others => '0');
    branch_en <= '0';
    branch_offset <= (others => '0');
    alu_op <= (others => 'Z');

    if opcode_key = '0' then
      case opcode is
        when OP_ADD =>
          reg1_addr <= Reg1;
          alu_op <= OP_ADD;
          acc_we <= '1';
        when OP_SUB =>
          reg1_addr <= Reg1;
          alu_op <= OP_SUB;
          acc_we <= '1';
        when OP_ADDI =>
          imm <= imm_d;
          alu_op <= OP_ADDI;
          acc_we <= '1';
        when OP_MOV =>
          reg2_addr <= imm_d(IMMEDIATE_DATA_WIDTH - 1 downto IMMEDIATE_DATA_WIDTH - 1 - (REG_ADDR_WIDTH - 1));
          -- reg2_addr <= imm_d(7 downto 5);
          reg_wr_addr <= Reg1;
          reg_wr_data <= reg2_data;
          reg_we <= '1';
        when OP_MOVI =>
          reg_wr_addr <= Reg1;
          imm <= imm_d;
          if REG_DATA_WIDTH > IMMEDIATE_DATA_WIDTH then
            reg_wr_data(IMMEDIATE_DATA_WIDTH - 1 downto 0) <= imm_d;
            reg_wr_data(REG_DATA_WIDTH - 1 downto IMMEDIATE_DATA_WIDTH) <= (others => '0');
          elsif REG_DATA_WIDTH < IMMEDIATE_DATA_WIDTH then
            reg_wr_data(REG_DATA_WIDTH - 1 downto 0) <= imm_d(IMMEDIATE_DATA_WIDTH - 1 downto IMMEDIATE_DATA_WIDTH - 1 - (REG_DATA_WIDTH - 1));
          else
            reg_wr_data <= imm_d;
          end if;
          reg_we <= '1';
        when OP_CMP =>
          reg1_addr <= Reg1;
          alu_op <= OP_CMP;
          acc_we <= '0';
        when OP_XOR =>
          reg1_addr <= Reg1;
          alu_op <= OP_XOR;
          acc_we <= '1';
        when OP_AND =>
          reg1_addr <= Reg1;
          alu_op <= OP_AND;
          acc_we <= '1';
        when OP_SHL =>
          alu_op <= OP_SHL;
          acc_we <= '1';
        when OP_SHR =>
          alu_op <= OP_SHR;
          acc_we <= '1';
        when OP_COM =>
          alu_op <= OP_COM;
          acc_we <= '1';
        when OP_INC =>
          alu_op <= OP_INC;
          acc_we <= '1';
        when OP_CLR =>
          alu_op <= OP_CLR;
          acc_we <= '1';
        when OP_BR =>
          branch_offset <= imm_d;
          branch_en <= '1';
        when OP_BZ =>
          branch_offset <= imm_d;
          if flag_z = '1' then
            branch_en <= '1';
          else
            branch_en <= '0';
          end if;
        when OP_BNZ =>
          branch_offset <= imm_d;
          if flag_z = '0' then
            branch_en <= '1';
          else
            branch_en <= '0';
          end if;
        when others =>
        -- do nothing
      end case;
    else -- ST and LD instructions
      if opcode_mem_instr = '0' then -- LD R1 , [R2, yy]; R1 <- M[R2 + yy]
        dst := opcode(OPCODE_WIDTH - 1 - 1 downto 0);
        -- dst := instr(13 downto 11);
        base := Reg1;
        reg1_addr <= base;
        imm <= imm_d;
        -- if REG_DATA_WIDTH > IMMEDIATE_DATA_WIDTH then
        --   if REG_DATA_WIDTH > MEM_ADDR_WIDTH then
        mem_addr <= std_logic_vector(resize(unsigned(reg1_data) + unsigned((REG_DATA_WIDTH - 1 downto IMMEDIATE_DATA_WIDTH => '0') & imm_d), MEM_ADDR_WIDTH));
        -- elsif REG_DATA_WIDTH < MEM_ADDR_WIDTH then
        --   mem_addr <= std_logic_vector((MEM_ADDR_WIDTH - 1 downto REG_DATA_WIDTH => '0') & (unsigned(reg1_data) + unsigned((REG_DATA_WIDTH - 1 downto IMMEDIATE_DATA_WIDTH => '0') & imm_d)));
        -- else
        --   mem_addr <= std_logic_vector(unsigned(reg1_data) + unsigned((REG_DATA_WIDTH - 1 downto IMMEDIATE_DATA_WIDTH => '0') & imm_d));
        -- end if;
        -- elsif REG_DATA_WIDTH < IMMEDIATE_DATA_WIDTH then
        --   if REG_DATA_WIDTH > MEM_ADDR_WIDTH then
        --     mem_addr <= std_logic_vector(resize(unsigned((IMMEDIATE_DATA_WIDTH - 1 downto REG_DATA_WIDTH => '0') & reg1_data) + unsigned(imm_d), MEM_ADDR_WIDTH));
        --   elsif REG_DATA_WIDTH < MEM_ADDR_WIDTH then
        --     mem_addr <= std_logic_vector((MEM_ADDR_WIDTH - 1 downto REG_DATA_WIDTH => '0') & (unsigned((IMMEDIATE_DATA_WIDTH - 1 downto REG_DATA_WIDTH => '0') & reg1_data) + unsigned(imm_d)));
        --   else
        --     mem_addr <= std_logic_vector(unsigned((IMMEDIATE_DATA_WIDTH - 1 downto REG_DATA_WIDTH => '0') & reg1_data) + unsigned(imm_d));
        --   end if;
        -- else
        --   if REG_DATA_WIDTH > MEM_ADDR_WIDTH then
        --     mem_addr <= std_logic_vector(resize(unsigned(reg1_data) + unsigned(imm_d), MEM_ADDR_WIDTH));
        --   elsif REG_DATA_WIDTH < MEM_ADDR_WIDTH then
        --     mem_addr <= std_logic_vector((MEM_ADDR_WIDTH - 1 downto REG_DATA_WIDTH => '0') & (unsigned(reg1_data) + unsigned(imm_d)));
        --   else
        --     mem_addr <= std_logic_vector(unsigned(reg1_data) + unsigned(imm_d));
        --   end if;
        -- end if;
        reg_wr_data(LOAD_WIDTH - 1 downto 0) <= mem_data(LOAD_WIDTH - 1 downto 0);
        reg_wr_data(REG_DATA_WIDTH - 1 downto LOAD_WIDTH) <= (others => '0');
        reg_wr_addr <= dst;
        reg_we <= '1';
      else -- ST [R2, yy], R1; M[R2 + yy] <- R1
        base := opcode(OPCODE_WIDTH - 1 - 1 downto 0);
        -- base := instr(13 downto 11);
        dst := Reg1;
        reg1_addr <= base;
        imm <= imm_d;
        mem_addr <= std_logic_vector(resize(unsigned(reg1_data) + unsigned((REG_DATA_WIDTH - 1 downto IMMEDIATE_DATA_WIDTH => '0') & imm_d), MEM_ADDR_WIDTH));
        reg2_addr <= dst;
        mem_wr_data <= reg2_data;
        mem_we <= '1';

      end if;
    end if;

  end process;

end architecture;
