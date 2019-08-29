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
mov [frames], ax

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

            ; p=(x/W-0.5, (y/H-0.5)*H/W, 0.02)
            fld float [_0_02]           ;   0.02
            fild int16 [y]              ;   y               0.02
            fild int16 [x]              ;   x               y               0.02
            fild int16 [width]          ;   W               x               y               0.02
            fdiv st1, st0               ;   W               x/W             y               0.02
            fild int16 [height]         ;   H               W               x/W             y               0.02
            fdiv st3, st0               ;   H               W               x/W             y/H             0.02
            fld float [_0_5]            ;   0.5             H               W               x/W             y/H             0.02
            fsub st3, st0               ;   0.5             H               W               x/W-0.5         y/H             0.02
            fsubp st4, st0              ;   H               W               x/W-0.5         y/H-0.5         0.02
            fmulp st3, st0              ;   W               x/W-0.5         (y/H-0.5)*H     0.02
            fdivp st2, st0              ;   x/W-0.5         (y/H-0.5)*H/W   0.02

            ; p*=t
            fild int16 [frames]         ;   frames          p.x             p.y             p.z
            fidiv int16 [_60]           ;   t               p.x             p.y             p.z
            fmul st1, st0               ;   t               p.x*t           p.y             p.z
            fmul st2, st0               ;   t               p.x*t           p.y*t           p.z
            fmulp st3, st0              ;   p.x*t           p.y*t           p.z*t

            ; u=0.02t
            fld st2                     ;   0.02t           p.x             p.y             p.z
            fstp float [u]              ;   p.x             p.y             p.z

            ; kaliset

            ; c=vec3(0,0,0)
            fldz                        ;   0   p.x p.y p.z
            fst float [c.x]             ;   0   p.x p.y p.z
            fst float [c.y]             ;   0   p.x p.y p.z
            fstp float [c.z]            ;   p.x p.y p.z

            mov cx, 20
            kaliset:

                ; p=abs(p)
                fabs                    ;   |p.x|   p.y     p.z
                fxch st1                ;   p.y     |p.x|   p.z
                fabs                    ;   |p.y|   |p.x|   p.z
                fxch st1                ;   |p.x|   |p.y|   p.z
                fxch st2                ;   p.z     |p.y|   |p.x|
                fabs                    ;   |p.z|   |p.y|   |p.x|
                fxch st2                ;   |p.x|   |p.y|   |p.z|

                ; dot=dot(p, p)
                fld st2                 ;   p.z                         p.x         p.y         p.z
                fmul st0                ;   p.z*p.z                     p.x         p.y         p.z
                fld st2                 ;   p.y                         p.z*p.z     p.x         p.y p.z
                fmul st0                ;   p.y*p.y                     p.z*p.z     p.x         p.y p.z
                fld st2                 ;   p.x                         p.y*p.y     p.z*p.z     p.x p.y p.z
                fmul st0                ;   p.x*p.x                     p.y*p.y     p.z*p.z     p.x p.y p.z
                faddp st1, st0          ;   p.x*p.x+p.y*p.y             p.z*p.z     p.x         p.y p.z
                faddp st1, st0          ;   p.x*p.x+p.y*p.y+p.z*p.z     p.x         p.y         p.z

                ; abs(p)/dot(p,p)
                fdiv st1, st0           ;   dot                         p.x/dot     p.y         p.z
                fdiv st2, st0           ;   dot                         p.x/dot     p.y/dot     p.z
                fdivp st3, st0          ;   p.x/dot                     p.y/dot     p.z/dot

                ; p=abs(p)/dot(p,p)-u
                fld float [u]           ;   u                           p.x/dot     p.y/dot     p.z/dot
                fsub st1, st0           ;   u                           p.x/dot-u   p.y/dot     p.z/dot
                fsub st2, st0           ;   u                           p.x/dot-u   p.y/dot-u   p.z/dot
                fsubp st3, st0          ;   p.x/dot-u                   p.y/dot-u   p.z/dot-u

                ; c+=p
                fld float [c.x]         ;   c.x                         p.x         p.y         p.z
                fadd st0, st1           ;   c.x+p.x                     p.x         p.y         p.z
                fstp float [c.x]        ;   p.x                         p.y         p.z
                fld float [c.y]         ;   c.y                         p.x         p.y         p.z
                fadd st0, st2           ;   c.y+p.y                     p.x         p.y         p.z
                fstp float [c.y]        ;   p.x                         p.y         p.z
                fld float [c.z]         ;   c.z                         p.x         p.y         p.z
                fadd st0, st3           ;   c.z+p.z                     p.x         p.y         p.z
                fstp float [c.z]        ;   p.z                         p.y         p.z

                ; end of kaliset loop
                loop kaliset

            fld float [c.z]
            fistp int32 [b]
            mov eax, [b]
            cmp eax, 0
            jg b_above_0
            xor al, al
            b_above_0:
            cmp eax, 256
            jg b_below_256
            mov al, 255
            b_below_256:
            stosb

            fld float [c.y]
            fistp int32 [g]
            mov eax, [g]
            cmp eax, 0
            jg g_above_0
            xor al, al
            g_above_0:
            cmp eax, 256
            jg g_below_256
            mov al, 255
            g_below_256:
            stosb

            fld float [c.x]
            fistp int32 [r]
            mov eax, [r]
            cmp eax, 0
            jg r_above_0
            xor al, al
            r_above_0:
            cmp eax, 256
            jg r_below_256
            mov al, 255
            r_below_256:
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
    inc int16 [frames]

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
_60   def_int16 60

section .bss 

frames res_int16 1
x res_int16 1
y res_int16 1

u res_float 1

c.x res_float 1
c.y res_float 1
c.z res_float 1

r res_int32 1
g res_int32 1
b res_int32 1
