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

WIDTH EQU 320
HEIGHT EQU 200
ITERATIONS EQU 20

section .text

; init time
mov [frames], ax

; switch to vesa
mov ax, 0x4f02
mov bx, 0x10f
int 10h

; init screen
push 0xa000
pop es

; main loop
main:

    ; increase time
    inc int16 [frames]

    ; init bank
    xor dx, dx

    ; init pixel
    xor di, di

    mov bx, 65536-HEIGHT/2
    loopy:

        mov ax, 65536-WIDTH/2
        loopx:

            ; p=(x/W-0.5, (y/H-0.5)*H/W, 0.02)
            fld float [_0_02]           ;   0.02

            mov [bp+si], bx
            fild int16 [bp+si]          ;   y-H/2           0.02

            mov [bp+si], ax
            fild int16 [bp+si]          ;   x-W/2           y-H/2           0.02

            fild int16 [width]          ;   W               x-W/2           y-H/2           0.02
            fdiv st1, st0               ;   W               (x-W/2)/W       y-H/2           0.02
            fdivp st2, st0              ;   (x-W/2)/W       (y-H/2)/W       0.02

            ; p*=t
            fild int16 [frames]         ;   frames          p.x             p.y             p.z
            fidiv int16 [fps]           ;   t               p.x             p.y             p.z
            fmul st1, st0               ;   t               p.x*t           p.y             p.z
            fmul st2, st0               ;   t               p.x*t           p.y*t           p.z
            fmulp st3, st0              ;   p.x*t           p.y*t           p.z*t

            ; u=0.02t
            fld st2                     ;   0.02t           p.x             p.y             p.z
            fstp float [u]              ;   p.x             p.y             p.z

            ; kaliset

            ; c=vec3(0,0,0)
            fldz                        ;   0   p.x p.y p.z
            fst float [bp+si]           ;   0   p.x p.y p.z
            fst float [bp+si+8]         ;   0   p.x p.y p.z
            fstp float [bp+si+16]       ;   p.x p.y p.z

            mov cx, ITERATIONS
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
                fld float [bp+si]       ;   c.x                         p.x         p.y         p.z
                fadd st0, st1           ;   c.x+p.x                     p.x         p.y         p.z
                fstp float [bp+si]      ;   p.x                         p.y         p.z
                fld float [bp+si+8]     ;   c.y                         p.x         p.y         p.z
                fadd st0, st2           ;   c.y+p.y                     p.x         p.y         p.z
                fstp float [bp+si+8]    ;   p.x                         p.y         p.z
                fld float [bp+si+16]    ;   c.z                         p.x         p.y         p.z
                fadd st0, st3           ;   c.z+p.z                     p.x         p.y         p.z
                fstp float [bp+si+16]   ;   p.z                         p.y         p.z

                ; end of kaliset loop
                loop kaliset

            ; unload p
            fstp st0
            fstp st0
            fstp st0

            ; c /= iterations
            fld float [bp+si]
            fld float [bp+si+8]
            fld float [bp+si+16]
            fld float [_255_per_iterations]
            fmul st1, st0
            fmul st2, st0
            fmulp st3, st0

            ; calculate rgb values
            fistp int32 [r]
            fistp int32 [g]
            fistp int32 [b]

            ; preserve coordinates
            push ax
            push bx

            ; switch screenbank if needed
            test di, di
            jnz skip_bank_switch
            mov ax, 0x4f05
            xor bx, bx
            int 10h
            inc dx
            skip_bank_switch:

            ; store pixel
            mov cx, 3
            mov si, r
            looppixel:
            lodsd
            cmp eax, 0
            jg above
            xor al, al
            above:
            cmp eax, 256
            jl below
            mov al, 255
            below:
            stosb
            loop looppixel
            stosb

            ; reserve coordinates
            pop bx
            pop ax

            ; end of loop x
            inc ax
            cmp ax, WIDTH/2
            jl loopx

        ; end of loop y
        inc bx
        cmp bx, HEIGHT/2
        jl loopy

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
_255_per_iterations def_float 12.75

_0_02 def_float 0.02
fps def_int16 15


section .bss 

frames res_int16 1

u res_float 1

r res_int32 1
g res_int32 1
b res_int32 1
