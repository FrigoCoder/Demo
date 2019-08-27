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
            ; p.x goes [-2;2] based on seconds [0;60] or time [0;3600] assuming 60Hz
            ; p.y goes [-1;1] based on seconds [0;60] or time [0;3600] assuming 60Hz
            ; p.z stays -1.0
            fldz                        ;   0
            fld1                        ;   1           0
            fsub                        ;   -1
            fild int16 [t]              ;   t           -1
            fidiv int16 [_1800]         ;   t/1800      -1
            fadd st0, st1               ;   t/1800-1    -1
            fld st0                     ;   t/1800-1    t/1800-1    -1
            fadd st0, st0               ;   t/900-2     t/1800-1    -1

            loops:

                ; p.x += (x/W-0.5)*0.1
                fild int16 [x]          ;   x                   p.x     p.y     p.z
                fidiv int16 [width]     ;   x/W                 p.x     p.y     p.z
                fsub float [_0_5]       ;   x/W-0.5             p.x     p.y     p.z
                fmul float [_0_1]       ;   (x/W-0.5)*0.1       p.x     p.y     p.z
                faddp st1, st0          ;   p.x'                p.y     p.z

                ; p.y += (y/H-0.5)*H/W*0.1
                fild int16 [y]          ;   y                   p.x'    p.y     p.z
                fidiv int16 [height]    ;   y/H                 p.x'    p.y     p.z
                fsub float [_0_5]       ;   y/H-0.5             p.x'    p.y     p.z
                fimul int16 [height]    ;   (y/H-0.5)*H         p.x'    p.y     p.z
                fidiv int16 [width]     ;   (y/H-0.5)*H/W       p.x'    p.y     p.z
                fmul float [_0_1]       ;   (y/H-0.5)*H/W*0.1   p.x'    p.y     p.z
                faddp st2, st0          ;   p.x'                p.y'    p.z

                ; p.z += 0.1
                fld float [_0_1]        ;   0.1                 p.x'    p.y'    pz
                faddp st3, st0          ;   p.x'                p.y'    p.z'

                ; kaliset

            ; put pixel
            fld st0
            fimul int16 [_1800]
            fistp int32 [b]
            mov eax, [b]
            add al, 128
            stosb

            fld st1
            fimul int16 [_1800]
            fistp int32 [g]
            mov eax, [g]
            add al, 128
            stosb

            fld st2
            fimul int16 [_1800]
            fimul int16 [_1800]
            fistp int32 [r]
            mov eax, [r]
            add al, 128
            stosb
            stosb

            ; pop remaining values
            fstp st0
            fstp st0
            fstp st0
            
            ; end of loop x
            dec int16 [x]
            jnz loopx

        ; end of loop y
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
formuparam def_float 0.53

_0_1  def_float 0.1
_0_5  def_float 0.5
_1800 def_int16 1800

section .bss 

t res_int16 1
x res_int16 1
y res_int16 1

a res_float 1

r res_int32 1
g res_int32 1
b res_int32 1
