  ADDI 5          ; ACC = 0 + 5
  ADDI 5          ; ACC = 5 + 5
  ADD R0          ; ACC = 10 + 0
  MOV R1, R0      ; R1 = R0 (0)
  MOVI R1, 25     ; R1 = 25
  CLR             ; ACC = 0
  ADDI 8          ; ACC = 0 + 8
  MOVI R2, 8      ; R2 = 8
  ST [R1, 2], R2  ; M[R1 + 2] = R2 (8)
  LD R5, [R1, 2]  ; R5 = M[R1 + 2] (8)
  MOVI R3, 8      ; R3 = 8
  CMP R3          ; ACC (8) - R3 (8) => flag zero = 1
  CLR             ; ACC = 0
  CMP R3          ; ACC (0) - R3 (8) => flag zero = 0
  ADDI 8          ; ACC = 0 + 8
  CMP R5          ; ACC (8) - R5 (8) => flag zero = 1
  BZ skip         ; branch if flag zero = 1 (taken)
  INC             
  INC
  SHR
  INC
  SHL
  INC
  COM
  BR exit
skip:
  CLR             ; ACC = 0
  ADDI 7
  SHL
  INC
  SHR
  COM
  BR exit
  ADDI 50
  INC
  INC
  INC
exit:
  CLR