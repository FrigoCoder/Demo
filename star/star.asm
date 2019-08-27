org 100h 

%define int16 word
%define int32 dword
%define float dword
%define double qword

%define def_int16 dw
%define def_int32 dd
%define def_float dd
%define def_double dq

%define res_int16 resw
%define res_int32 resd
%define res_float resd
%define res_double resq

WIDTH EQU 640
HEIGHT EQU 480

ITERATIONS EQU 15

section .text 

; init time to 0
mov [t], ax

; switch to vesa
mov ax, 0x4f02
mov bx, 0x112
int 10h

; init screen
push 0xa000
pop es

; main loop
main:

    ; init bank
    xor dx, dx

    ; init pixel
    xor di, di

    mov int16 [y], HEIGHT
    loopy:

        mov int16 [x], WIDTH
        loopx:

            ; switch screenbank if needed
            test di, di
            jnz skip_bank_switch
            mov ax, 0x4f05
            xor bx, bx
            int 10h
            inc dx
            skip_bank_switch:

            ; volumetric rendering

            ; calculate camera based on time
            ; p.z stays -1.0
            ; p.y goes [-1;1] based on seconds [0;60] or time [0;3600] assuming 60Hz
            ; p.x goes [-2;2] based on seconds [0;60] or time [0;3600] assuming 60Hz
            fild int16 [t]              ;   t
            fidiv int16 [_1800]         ;   t/1800
            fldz                        ;   0           t/1800
            fld1                        ;   1           0           t/1800
            fsub                        ;   -1          t/1800
            fst double [p.z]            ;   -1          t/1800
            fadd                        ;   t/1800-1
            fst double [p.y]            ;   t/1800-1
            fadd st0                    ;   t/900-2
            fstp double [p.x]           ;   -

            loops:

            ; p.x += (x/W-0.5)*0.1
            fld double [p.x]
            fild int16 [x]
            fidiv int16 [width]
            fsub double [_0_5]
            fmul double [_0_1]
            faddp st1, st0
            fstp double [p.x]

            ; p.y += (y/H-0.5)*H/W*0.1
            fld double [p.y]
            fild int16 [y]
            fidiv int16 [height]
            fsub double [_0_5]
            fimul int16 [height]
            fidiv int16 [width]
            fmul double [_0_1]
            faddp st1, st0
            fstp double [p.y]

            ; p.z += 0.1
            fld double [p.z]
            fadd double [_0_1]
            fstp double [p.z]

            ; put pixel
            fld double [p.x]
            fimul int16 [_1800]
            fistp int32 [r]
            mov eax, [r]
            add al, 128
            stosb

            fld double [p.y]
            fimul int16 [_1800]
            fistp int32 [g]
            mov eax, [g]
            add al, 128
            stosb

            fld double [p.z]
            fimul int16 [_1800]
            fistp int32 [b]
            mov eax, [b]
            add al, 128
            stosb
            stosb

            dec int16 [x]
            jnz loopx

        dec int16 [y]
        jnz loopy

    ; increase time
    inc int16 [t]

    ; check keyboard
    in al, 0x60
    dec al
    jnz main

; switch to text mode
mov ax, 0x0003
int 0x10

; exit
ret

section .data 

width def_int16 WIDTH
height def_int16 HEIGHT
ratio def_double 1.3333333333333333333333333333333
formuparam def_double 0.53

_0_1  def_double 0.1
_0_5  def_double 0.5
_4    def_double 4.0
_1800 def_int16 1800

section .bss 

t res_int16 1
x res_int16 1
y res_int16 1

d.x res_double 1
d.y res_double 1
d.z res_double 1

p.x res_double 1
p.y res_double 1
p.z res_double 1

v.x res_double 1
v.y res_double 1
v.z res_double 1

a res_double 1

r res_int32 1
g res_int32 1
b res_int32 1
