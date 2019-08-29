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

            ; calculate p
            fild int16 [t]              ;   t
            fmul float [_0_02]          ;   0.02t

            fild int16 [y]              ;   y                   0.02t
            fidiv int16 [height]        ;   y/H                 0.02t
            fsub float [_0_5]           ;   y/H-0.5             0.02t
            fimul int16 [height]        ;   (y/H-0.5)*H         0.02t
            fidiv int16 [width]         ;   (y/H-0.5)*H/W       0.02t
            fmul float [_0_02]          ;   0.02(y/H-0.5)*H/W   0.02t

            fild int16 [x]              ;   x                   0.02(y/H-0.5)*H/W   0.02t
            fidiv int16 [width]         ;   x/W                 0.02(y/H-0.5)*H/W   0.02t
            fsub float [_0_5]           ;   x/W-0.5             0.02(y/H-0.5)*H/W   0.02t
            fmul float [_0_02]          ;   0.02(x/W-0.5)       0.02(y/H-0.5)*H/W   0.02t

            ; kaliset
            fldz                        ;   0   p.x p.y p.z
            fst float [c.x]             ;   0   p.x p.y p.z
            fst float [c.y]             ;   0   p.x p.y p.z
            fstp float [c.z]            ;   p.x p.y p.z

            mov cx, 20
            kaliset:

                ; calculate dot(p, p)
                fld st0                 ;   p.x p.x p.y p.z



                ; end of kaliset loop
                loop kaliset




            mov bx, 40
            loops:

                ; kaliset

                dec bx
                jnz loops


            ; put pixel

            fld float [c.z]
            fistp int32 [b]
            mov eax, [b]
            stosb

            fld float [c.y]
            fistp int32 [g]
            mov eax, [g]
            stosb

            fld float [c.x]
            fistp int32 [r]
            mov eax, [r]
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

_0_02 def_float 0.02
_0_5  def_float 0.5

section .bss 

t res_int16 1
x res_int16 1
y res_int16 1

c.x res_float 1
c.y res_float 1
c.z res_float 1

r res_int32 1
g res_int32 1
b res_int32 1
