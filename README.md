# Arma2-CPU

A 16-bit educational CPU implemented as part of the **Computer Architecture** course project at **Guilan University** (Fall 2024).  
The design includes a complete datapath, control unit, register file, ALU, memory interface, and a custom instruction set.

> 📄 See the [project assignment (PDF)](https://github.com/MohammadHosseinKv/Arma2-CPU/raw/refs/heads/main/ProjectCA14041.pdf) for the original requirements (Persian).

---

## 📐 Specifications

| Parameter              | Description                                                                 |
|------------------------|-----------------------------------------------------------------------------|
| **Data width**         | 16-bit (all arithmetic/logic operations)                                   |
| **Register file**      | 8 general-purpose registers: `R0` - `R7`, each 16-bit                      |
| **Accumulator (ACC)**  | Dedicated 16-bit register for ALU results                                  |
| **Instruction width**  | 16-bit fixed length                                                        |
| **Memory**             | 512 bytes, byte‑addressable, supports 2‑byte (16‑bit) accesses             |
| **Address bus**        | 9 bits (2⁹ = 512 bytes)                                                    |
| **Flags**              | Carry (C), Zero (Z), Sign (S) - updated by `CMP` instruction               |
| **Instruction cycle**  | 1 clock pulse per instruction (fetch + decode + execute)                   |
| **Clock edge usage**    | Instruction fetch on **falling edge**<br>Register/memory writes on **rising edge** |
| **Decoding & ALU**      | Combinational (asynchronous) 

### Fetch & Decode Overview

- **Fetch (falling edge)**: The program counter (`pc_reg`) drives the instruction ROM address. The ROM outputs a 16‑bit instruction.
- **Decode (combinational)**: The `Control_Decoder` examines the instruction’s most significant bit (`opcode_key`) to separate ALU/branch instructions from memory instructions. It generates all control signals: register read/write addresses, ALU operation, immediate value, branch offset, memory address/we, etc.
- **Execute (rising edge)**: The `ALU` computes its result combinatorially. On the rising clock edge, the `RegFile` writes the ALU result to `ACC` (if `acc_we = 1`) or writes data to a register (if `reg_we = 1`). The `DataMem` also writes on the rising edge when `mem_we = 1`. Meanwhile, the `PC_Unit` computes the next PC value, which is latched into `pc_reg` on the next falling edge.

---

## 📖 Instruction Set

The processor supports the following instructions (grouped by type).  

### Arithmetic & Logical

| Instruction | Operands                     | Operation                                 | 
|-------------|------------------------------|-------------------------------------------|
| `ADD`       | `R3`                         | `ACC ← ACC + R3`                          |
| `SUB`       | `R3`                         | `ACC ← ACC + R3' + 1` (2's complement)    |
| `ADDI`      | `xx` (8‑bit immediate)       | `ACC ← ACC + xx`                          |
| `MOV`       | `R1, R2`                     | `R1 ← R2`                                 |
| `MOVI`       | `R1, xx`                     | `R1 ← xx`                                 |
| `CMP`       | `R1`                         | `ACC - R1` → update C, Z, S flags         |
| `XOR`       | `R3`                         | `ACC ← ACC XOR R3`                        |
| `AND`       | `R3`                         | `ACC ← ACC AND R3`                        |
| `SHL`       | -                            | `ACC ← shift left ACC`                    |
| `SHR`       | -                            | `ACC ← shift right ACC`                   |
| `COM`       | -                            | `ACC ← NOT ACC`                           |
| `INC`       | -                            | `ACC ← ACC + 1`                           |
| `CLR`       | -                            | `ACC ← 0`                                 |

> [!NOTE]
> 
> `SUB` uses two's complement addition: `ACC + (NOT R3) + 1`.  
>

### Memory

| Instruction | Operands                     | Operation                                 | 
|-------------|------------------------------|-------------------------------------------|
| `LD`        | `R1, [R2, yy]`               | `R1 ← M[R2 + yy]` (yy: 8‑bit offset)      |
| `ST`        | `[R2, yy], R1`               | `M[R2 + yy] ← R1`                         |

> [!NOTE]
>
> `LD` and `ST` use base+offset addressing where the offset `yy` is an 8‑bit unsigned value.  
>

### Branching

| Instruction | Operands                     | Operation                                 | 
|-------------|------------------------------|-------------------------------------------|
| `BR`        | `zz` (8‑bit relative)        | `PC ← PC + zz` (unconditional branch)     |
| `BZ`        | `zz` (8‑bit relative)        | `if Z=1 then PC ← PC + zz`                |
| `BNZ`       | `zz` (8‑bit relative)        | `if Z=0 then PC ← PC + zz`                |

> [!NOTE]
>
>`BR`/`BZ`/`BNZ` offsets are signed values relative to the next instruction’s PC.
>

## Encode 

### Register-type (R-type)

<table>
  <tbody>
    <tr>
      <th scope="row">Field</th>
      <td>Key</td>
      <td>opcode</td>
      <td>Reg1 addr</td>
      <td>Reg2 addr</td>
      <td>0</td>
    </tr>
    <tr>
      <th scope="row">Bit Positions (15:0)</th>
      <td>15:15</td>
      <td>14:11</td>
      <td>10:8</td>
      <td>7:5</td>
      <td>4:0</td>
    </tr>
  </tbody>
</table>


### Branch-type & Immediate-type (ADDI, MOVI)

<table>
  <tbody>
    <tr>
      <th scope="row">Field</th>
      <td>Key</td>
      <td>opcode</td>
      <td>0 (Branch) / Reg1 addr (MOVI)</td>
      <td>address (Branch) / immediate (ADDI, MOVI)</td>
    </tr>
    <tr>
      <th scope="row">Bit Positions (15:0)</th>
      <td>15:15</td>
      <td>14:11</td>
      <td>10:8</td>
      <td>7:0</td>
    </tr>
  </tbody>
</table>

### Memory-type (LD, ST)

<table>
  <tbody>
    <tr>
      <th scope="row">Field</th>
      <td>Key</td>
      <td>opcode</td>
      <td>Reg1 addr</td>
      <td>Reg2 addr</td>
      <td>immediate (offset)</td>
    </tr>
    <tr>
      <th scope="row">Bit Positions (15:0)</th>
      <td>15:15</td>
      <td>14:14</td>
      <td>13:11</td>
      <td>10:8</td>
      <td>7:0</td>
    </tr>
  </tbody>
</table>

> [!NOTE]
>
> For `non memory-type instructions` bits 15..12: is `opcode`; bit 15 (`Key`) = `0`.  
>
> For `LD`/`ST` (`Memory-type instructions`), bit 15 (`Key`) = `1`. Bit 14 (`opcode`) selects load (`0`) or store (`1`).  
>

---

## 💻 Python Assembler

The file `assemble_arma2.py` translates Arma2 assembly source code into a VHDL package (`*_instr_pkg.vhd`) that initializes the instruction ROM.

### How it works

1. Reads the assembly file line by line. Comments after `;` are ignored.  
2. Detects labels (e.g., `loop:`) and stores their instruction word addresses.  
3. For each instruction:
   - Splits mnemonic and operands.
   - Looks up the opcode from the `OPCODES` dictionary (matches `Arma2_Consts.vhd`).
   - Encodes registers (0‑7) into 3‑bit fields.
   - Encodes immediates (decimal, hex `0x…`, binary `0b…`).
   - For branch instructions, computes the relative offset (label address minus current address) and checks it stays within -128…127.
   - Packs all fields into a 16‑bit word, then converts to an integer.
4. Produces a VHDL package with an array of 256 16‑bit words. Unused locations are filled with `x"0000"`.  
5. Writes to a file (e.g., `rom_instr_pkg.vhd`), ready to be used by `InstrROM`.

### Usage

```bash
python assemble_arma2.py program.asm [output_prefix]
```

- `output_prefix` is optional; defaults to `rom`.
- The generated VHDL file will be named `output_prefix_instr_pkg.vhd`.

### Example

```asm
; test.asm
    ADDI 5
    MOVI R1, 25
    ST [R1, 2], R2
    LD R5, [R1, 2]
    CMP R3
    BZ skip
    INC
skip:
    CLR
```
Run:
```bash
python assemble_arma2.py test.asm my_cpu
```
This creates `my_cpu_instr_pkg.vhd` containing the ROM content.

## 🧪 Testing

### 🧰 Synthesis

You can synthesize the design using any VHDL tool that supports IEEE standard logic and numeric packages. Recommended options:

- **Xilinx ISE** (older, but works)
- **Xilinx Vivado**
- **GHDL** (open‑source, command‑line)
- **Intel Quartus**

Simply add all `.vhd` files from the `src/` folder to your project, include the generated `rom_instr_pkg.vhd`, and set `Top.vhd` as the top‑level entity.

### 📈 Simulation

1. **Open your simulator** - e.g.,
   - `GHDL` + `GTKWave` (free)  
   - `Xilinx iSim` (in ISE)  
   - `Vivado Simulator`  
   - `ModelSim` / `QuestaSim`

2. **Compile the files** - Make sure to compile in this order (due to dependencies):  
   - `Arma2_Consts.vhd`  
   - `rom_instr_pkg.vhd` (generated by the assembler)  
   - All other source files except `Top.vhd` (any order, because they use the package)  
   - `Top.vhd`
   - `Top_TB.vhd`

3. **Run the simulation** - The testbench `Top_TB.vhd` applies a `50 MHz` clock (`20 ns period`) for simulation to the `Top` entity and monitors the debug ports.  
   - Default simulation time is enough to execute the example `program.asm`.  
   - You can modify `Top_TB.vhd` to extend runtime, change clock frequency or change the program.

4. **Inspect waveforms**  
   - Look at `dbg_pc` to see the program counter advance.  
   - `dbg_acc` shows the accumulator value after each instruction.  
   - Flags (`dbg_flag_z`, `dbg_flag_c`, `dbg_flag_s`) update on `CMP`.  
   - `dbg_mem_addr`, `dbg_mem_data_in/out` verify memory operations.  

   Export the waveform to **GTKWave** (if using GHDL) or use the built‑in viewer of your simulator.

## Contact

For any questions or feedback, please feel free to reach out:

- **Name**: MohammadHossein Keyvanfar
- **Email:** [Mohammadhossein.kv@gmail.com](mailto:Mohammadhossein.Kv@gmail.com)
- **GitHub:** [https://github.com/MohammadHosseinKv](https://github.com/MohammadHosseinKv)
- **LinkedIn**: [https://linkedin.com/in/mohammadhossein-keyvanfar/](https://linkedin.com/in/mohammadhossein-keyvanfar/)
