org 100h 

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

    ; calculate camera based on time
    ; cam.z stays -1.0
    ; cam.y goes [-1;1] based on seconds [0;60] or time [0;3600] assuming 60Hz
    ; cam.x goes [-2;2] based on seconds [0;60] or time [0;3600] assuming 60Hz
    fild word [t]               ;   t
    fidiv word [_1800]          ;   t/1800
    fldz                        ;   0           t/1800
    fld1                        ;   1           0           t/1800
    fsub                        ;   -1          t/1800
    fst qword [cam.z]           ;   -1          t/1800
    fadd                        ;   t/1800-1
    fst qword [cam.y]           ;   t/1800-1
    fadd st0                    ;   t/900-2
    fstp qword [cam.x]          ;   -

    ; get uv coordinates and direction for z
    fld1                        ;   1
    fstp qword [dir.z]          ;   -

    mov word [y], HEIGHT
    loopy:

        ; get uv coordinates and direction for y
        fild word [y]           ;   y
        fidiv word [height]     ;   y/H
        fsub qword [_0_5]       ;   y/H-0.5
        fdiv qword [ratio]      ;   (y/H-0.5)*H/W    
        fstp qword [dir.y]      ;   -

        mov word [x], WIDTH
        loopx:

            ; get uv coordinates and direction for x
            fild word [x]       ;   x
            fidiv word [width]  ;   x/W
            fsub qword [_0_5]   ;   x/W-0.5
            fstp qword [dir.x]  ;   -

            ; switch screenbank if needed
            test di, di
            jnz skip_bank_switch
            mov ax, 0x4f05
            xor bx, bx
            int 10h
            inc dx
            skip_bank_switch:

            ; volumetric rendering



            ; ; initialize v and s
            ; fldz                ;   0
            ; fst qword [v]       ;   0
            ; fst qword [v+8]     ;   0
            ; fst qword [v+16]    ;   0
            ; fstp qword [s]      ;   -

            ; loops:

            ;     ; p = cam+dir*s
            ;     fld qword [cam+16]  ;   c.z
            ;     fld qword [cam+8]   ;   c.y         c.z
            ;     fld qword [cam]     ;   c.x         c.y         c.z
            ;     fld qword [dir+16]  ;   d.z         c.x         c.y         c.z
            ;     fld qword [dir+8]   ;   d.y         d.z         c.x         c.y c.z
            ;     fld qword [dir]     ;   d.x         d.y         d.z         c.x c.y c.z
            ;     fld qword [s]       ;   s           d.x         d.y         d.z c.x c.y c.z
            ;     fmul st1, st0       ;   s           d.x*s       d.y         d.z c.x c.y c.z
            ;     fmul st2, st0       ;   s           d.x*s       d.y*s       d.z c.x c.y c.z
            ;     fmulp st3, st0      ;   d.x*s       d.y*s       d.z*s       c.x c.y c.z
            ;     faddp st3, st0      ;   d.y*s       d.z*s       c.x+d.x*s   c.y c.z
            ;     faddp st3, st0      ;   d.z*s       c.x+d.x*s   c.y+d.y*s   c.z
            ;     faddp st3, st0      ;   c.x+d.x*s   c.y+d.y*s   c.z+d.z*s

            ;     ; kaliset(p)        ;   p.x         p.y         p.z

            ;     ; a=0
            ;     fldz                ;   0           p.x         p.y         p.z
            ;     fstp qword [a]      ;   p.x         p.y         p.z

            ;     mov cx, ITERATIONS

            ;     kaliteration:

            ;         ; len=length(p)     ;   dot(p)      p.x         p.y         p.z
            ;         call dot
            ;         fsqrt               ;   len(p)      p.x         p.y         p.z
            ;         fstp st0

            ;         dec cx
            ;         jnz kaliteration

            ;     ; TODO CHECK S AND LOOP

            dec word [x]
            jnz loopx

        dec word [y]
        jnz loopy

    ; increase time
    inc word [t]

    ; check keyboard
    in al, 0x60
    dec al
    jnz main

; switch to text mode
mov ax, 0x0003
int 0x10

; exit
ret
            
dot:            ;   x           y   z
    fld st0     ;   x           x   y   z
    fmul st0    ;   x*x         x   y   z
    fld st2     ;   y           x*x x   y   z
    fmul st0    ;   y*y         x*x x   y   z
    fld st4     ;   z           y*y x*x x   y   z
    fmul st0    ;   z*z         y*y x*x x   y   z
    faddp st1   ;   y*y+z*z     x*x x   y   z
    faddp st1   ;   x*x+y*y+z*z x   y   z
    ret


section .data 

width dw WIDTH
height dw HEIGHT
ratio dq 1.3333333333333333333333333333333

_0_5  dq 0.5
_1800 dw 1800


section .bss 

t resw 1
x resw 1
y resw 1

cam.x resq 1
cam.y resq 1
cam.z resq 1

dir.x resq 1
dir.y resq 1
dir.z resq 1

v.x resq 1
v.y resq 1
v.z resq 1

s resq 1
a resq 1
pa resq 1
