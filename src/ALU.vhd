library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use work.Arma2_Consts.all;

entity ALU is
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
end entity;

architecture behaviour of ALU is

begin

  arithmetic_execution: process (op, acc, reg, imm) is
    variable temp            : unsigned(RESULT_WIDTH downto 0);
    variable res             : unsigned(RESULT_WIDTH - 1 downto 0);
    variable imm_zero_extend : unsigned(RESULT_WIDTH - 1 downto 0);
    variable acc_u, reg_u    : unsigned(RESULT_WIDTH - 1 downto 0);

    variable zero_flag  : std_logic := '0';
    variable sign_flag  : std_logic := '0';
    variable carry_flag : std_logic := '0';
  begin

    imm_zero_extend := unsigned((RESULT_WIDTH - 1 downto IMMEDIATE_DATA_WIDTH => '0') & imm);
    acc_u := unsigned(acc);
    reg_u := unsigned(reg);

    case op is
      when OP_ADD =>
        temp := ("0" & acc_u) + ("0" & reg_u);
        res := temp(RESULT_WIDTH - 1 downto 0);
      when OP_SUB =>
        temp := ("0" & acc_u) + (not("0" & reg_u)) + 1;
        res := temp(RESULT_WIDTH - 1 downto 0);
      when OP_ADDI =>
        temp := ("0" & acc_u) + ("0" & imm_zero_extend);
        res := temp(RESULT_WIDTH - 1 downto 0);
      when OP_CMP =>
        temp := ("0" & acc_u) + (not("0" & reg_u)) + 1;
        res := temp(RESULT_WIDTH - 1 downto 0);
        carry_flag := temp(RESULT_WIDTH);
        sign_flag := temp(RESULT_WIDTH - 1);
        if temp(RESULT_WIDTH - 1 downto 0) = 0 then
          zero_flag := '1';
        else
          zero_flag := '0';
        end if;
      when OP_XOR =>
        res := acc_u xor reg_u;
      when OP_AND =>
        res := acc_u and reg_u;
      when OP_SHL =>
        res := acc_u(RESULT_WIDTH - 2 downto 0) & '0';
      when OP_SHR =>
        res := '0' & acc_u(RESULT_WIDTH - 1 downto 1);
      when OP_COM =>
        res := not(acc_u);
      when OP_INC =>
        res := acc_u + 1;
      when OP_CLR =>
        res := (others => '0');
      when others =>

    end case;

    flag_z <= zero_flag;
    flag_s <= sign_flag;
    flag_c <= carry_flag;
    result <= std_logic_vector(res);

  end process;

end architecture;
