# Assembler for the Arma-2 encoding.
# Usage: python assemble_arma2.py program.asm -o instr_rom_init.vhd

import sys
import re
from pathlib import Path

OPCODES = {
    'ADD'  : '0000',
    'SUB'  : '0001',
    'ADDI' : '0010',
    'MOV'  : '0011',
    'CMP'  : '0100',
    'XOR'  : '0101',
    'AND'  : '0110',
    'SHL'  : '0111',
    'SHR'  : '1000',
    'COM'  : '1001',
    'INC'  : '1010',
    'CLR'  : '1011',
    'BR'   : '1100',
    'BZ'   : '1101',
    'BNZ'  : '1110',
    'MOVI' : '1111',
    'LD'   : '0', 
    'ST'   : '1',
}

REGS = { f'R{i}': i for i in range(8) }

def to_bin(value, bits):
    """Return two's complement binary string for signed value or unsigned if >=0."""
    if value < 0:
        value = (1 << bits) + value
    fmt = '{:0' + str(bits) + 'b}'
    return fmt.format(value & ((1<<bits)-1))

def parse_imm(s):
    """Parse immediate in decimal or hex (0x..) or binary (0b..)"""
    s = s.strip()
    if s.startswith('0x') or s.startswith('0X'):
        return int(s, 16)
    if s.startswith('0b') or s.startswith('0B'):
        return int(s, 2)
    if s.endswith('h') or s.endswith('H'):
        return int(s[:-1], 16)
    return int(s, 0)

if len(sys.argv) < 2:
    print("Usage: python assemble_arma2.py input.asm [output_prefix]")
    sys.exit(1)

asm_path = Path(sys.argv[1])
out_prefix = sys.argv[2] if len(sys.argv) > 2 else 'rom'

lines = asm_path.read_text().splitlines()

label_pattern = re.compile(r'^\s*([A-Za-z_]\w*):')
instructions = []
labels = {}
addr = 0

# capture labels and instruction lines
for raw in lines:
    line = raw.split(';',1)[0].strip()  # remove ';' comments
    if not line:
        continue
    m = label_pattern.match(line)
    if m:
        label = m.group(1)
        labels[label] = addr
        line = line[m.end():].strip()
        if not line:
            continue
    if line:
        instructions.append((addr, line))
        addr += 1  # one word per instruction

# encode instructions
words = []
for addr, text in instructions:
    # tokenize by spaces/commas
    parts = [p.strip() for p in re.split(r'[,\s]+', text) if p.strip()]
    op = parts[0].upper()
    if op not in OPCODES:
        raise ValueError(f"Unknown opcode {op} at addr {addr}: {text}")
    opcode = OPCODES[op]
    word = None

    if op in ('ADD','SUB','XOR','AND','CMP'):
        if len(parts) != 2:
            raise ValueError(f"{op} expects one register operand at addr {addr}")
        rd = parts[1].upper()
        r = REGS.get(rd)
        if r is None:
            raise ValueError(f"Unknown register {rd}")
        word = '0' + opcode + to_bin(r,3) + '00000000'  # bits 7..0 zero

    elif op == 'ADDI':
        if len(parts) != 2:
            raise ValueError(f"ADDI expects one immediate operand")
        imm = parse_imm(parts[1])
        word = '0' + opcode + '000' + to_bin(imm,8)

    elif op == 'MOV':
        if len(parts) != 3:
            raise ValueError("MOV expects two registers")
        dst = parts[1].upper(); src = parts[2].upper()
        if dst not in REGS or src not in REGS:
            raise ValueError("Unknown reg in MOV")
        word = '0' + opcode + to_bin(REGS[dst],3) + to_bin(REGS[src],3) + '00000'
        
    elif op == 'MOVI':
        if len(parts) != 3:
            raise ValueError("MOVI expects one registers and one immediate")
        dst = parts[1].upper(); imm = parse_imm(parts[2])
        if dst not in REGS:
            raise ValueError("Unknown reg in MOVI")
        word = '0' + opcode + to_bin(REGS[dst],3) + to_bin(imm,8)

    elif op in ('SHL','SHR','COM','INC','CLR'):
        word = '0' + opcode + '000' + '00000000'

    elif op == 'LD':
        m = re.match(r'LD\s+(\w+)\s*,\s*\[\s*(\w+)\s*,\s*([^\]]+)\s*\]\s*$', text, re.I)
        if not m:
            raise ValueError("LD syntax: LD Rdst, [Rbase, imm]")
        dst = m.group(1).upper(); base = m.group(2).upper(); imm_s = m.group(3)
        if dst not in REGS or base not in REGS:
            raise ValueError("Unknown register in LD")
        imm = parse_imm(imm_s)
        word = '1' + opcode + to_bin(REGS[dst],3) + to_bin(REGS[base],3) + to_bin(imm,8)

    elif op == 'ST':
        m = re.match(r'ST\s*\[\s*(\w+)\s*,\s*([^\]]+)\s*\]\s*,\s*(\w+)', text, re.I)
        if not m:
            raise ValueError("ST syntax: ST [Rbase, imm], Rsrc")
        base = m.group(1).upper(); imm_s = m.group(2); src = m.group(3).upper()
        if base not in REGS or src not in REGS:
            raise ValueError("Unknown register in ST")
        imm = parse_imm(imm_s)
        word = '1' + opcode + to_bin(REGS[base],3) + to_bin(REGS[src],3) + to_bin(imm,8)

    elif op in ('BR','BZ','BNZ'):
        if len(parts) != 2:
            raise ValueError(f"{op} expects one operand (label or offset)")
        target = parts[1]
        if target in labels:
            offset = labels[target] - (addr)
        else:
            # numeric
            try:
                offset = parse_imm(target)
            except:
                raise ValueError(f"Unknown label or number {target}")
        if offset < -128 or offset > 127:
            raise ValueError("Branch offset out of range (-128..127)")
        print(f"offset: {offset} | addr: {addr} | target: {target}")
        word = '0' + opcode + '000' + to_bin(offset, 8)

    else:
        raise ValueError(f"Unimplemented opcode: {op}")

    words.append(int(word,2))

rom_lines = []
for i, w in enumerate(words):
        rom_lines.append(f"  {i} => x\"{w:04X}\",")

for i in range(len(words), 256):
    if i != 255 :
        rom_lines.append(f"  {i} => x\"0000\",")
    else:
        rom_lines.append(f"  {i} => x\"0000\"")
        


vhdl = []
vhdl.append("library ieee; use ieee.std_logic_1164.all; use ieee.numeric_std.all;")
vhdl.append("package instr_rom_init is")
vhdl.append("  type rom_t is array (0 to 255) of std_logic_vector(15 downto 0);")
vhdl.append("  constant ROM_CONTENT : rom_t := (")
vhdl.extend(rom_lines)
vhdl.append("  );")
vhdl.append("end package;")

outvhd = Path(out_prefix + "_instr_pkg.vhd")
outvhd.write_text("\n".join(vhdl))
print("Wrote", outvhd)
