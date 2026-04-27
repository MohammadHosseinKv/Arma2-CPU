library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;
  use ieee.math_real.all;

package Arma2_Consts is
  constant OP_ADD  : std_logic_vector(3 downto 0) := "0000";
  constant OP_SUB  : std_logic_vector(3 downto 0) := "0001";
  constant OP_ADDI : std_logic_vector(3 downto 0) := "0010";
  constant OP_MOV  : std_logic_vector(3 downto 0) := "0011";
  constant OP_CMP  : std_logic_vector(3 downto 0) := "0100";
  constant OP_XOR  : std_logic_vector(3 downto 0) := "0101";
  constant OP_AND  : std_logic_vector(3 downto 0) := "0110";
  constant OP_SHL  : std_logic_vector(3 downto 0) := "0111";
  constant OP_SHR  : std_logic_vector(3 downto 0) := "1000";
  constant OP_COM  : std_logic_vector(3 downto 0) := "1001";
  constant OP_INC  : std_logic_vector(3 downto 0) := "1010";
  constant OP_CLR  : std_logic_vector(3 downto 0) := "1011";
  constant OP_BR   : std_logic_vector(3 downto 0) := "1100";
  constant OP_BZ   : std_logic_vector(3 downto 0) := "1101";
  constant OP_BNZ  : std_logic_vector(3 downto 0) := "1110";
  constant OP_MOVI : std_logic_vector(3 downto 0) := "1111";

  constant OP_LD : std_logic := '0';
  constant OP_ST : std_logic := '1';

  constant C_MEM_CAPACITY         : integer := 512 * 8;
  constant C_MEM_DATA_WIDTH       : integer := 2 * 8;
  constant C_MEM_ADDR_WIDTH       : integer := integer(ceil(log2(real(C_MEM_CAPACITY / C_MEM_DATA_WIDTH))));
  constant C_INSTR_DATA_WIDTH     : integer := 2 * 8;
  constant C_IMMEDIATE_DATA_WIDTH : integer := 8;
  constant C_LOAD_WIDTH           : integer := 8;
  constant C_ARITH_WIDTH          : integer := 2 * 8;
  constant C_REG_COUNT            : integer := 8;
  constant C_REG_ADDR_WIDTH       : integer := integer(ceil(log2(real(C_REG_COUNT))));
  constant C_REG_DATA_WIDTH       : integer := 2 * 8;
  constant C_OPCODE_WIDTH         : integer := 4;
  constant C_ARITH_RESULT_WIDTH   : integer := 2 * 8;
end package;
