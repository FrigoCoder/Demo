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

            ; initialize v and s
            fldz                ;   0
            fst qword [v.x]     ;   0
            fst qword [v.y]     ;   0
            fst qword [v.z]     ;   0
            fstp qword [s]      ;   -

            loops:

                ; p = cam+dir*s
                
                fld qword [s]       ;   s

                fld qword [dir.x]   ;   d.x         s
                fmul st0, st1       ;   d.x*s       s
                fadd qword [cam.x]  ;   c.x+d.x*s   s
                fstp qword [p.x]    ;   s

                fld qword [dir.y]   ;   d.y         s
                fmul st0, st1       ;   d.y*s       s
                fadd qword [cam.y]  ;   c.y+d.y*s   s
                fstp qword [p.y]    ;   s

                fld qword [dir.z]   ;   d.z         s
                fmul st0, st1       ;   d.z*s       s
                fadd qword [cam.z]  ;   c.z+d.z*s   s
                fstp qword [p.z]    ;   s
                fstp st0            ;   -

                ; kaliset(p)

                fldz                ;   0
                fstp qword [a]      ;   -

                mov cx, ITERATIONS

                call dotpp                      ;   dot(p)

                kaliteration:

                    fld qword [p.x]             ;   p.x                 dot(p)
                    fabs                        ;   |p.x|               dot(p)
                    fdiv st0, st1               ;   |p.x|/dot(p)        dot(p)
                    fsub qword [formuparam]     ;   [p.x|/dot(p)-u      dot(p)
                    fstp qword [p.x]            ;   dot(p)

                    fld qword [p.y]             ;   p.y                 dot(p)
                    fabs                        ;   |p.y|               dot(p)
                    fdiv st0, st1               ;   |p.y|/dot(p)        dot(p)
                    fsub qword [formuparam]     ;   [p.y|/dot(p)-u      dot(p)
                    fstp qword [p.y]            ;   dot(p)

                    fld qword [p.z]             ;   p.y                 dot(p)
                    fabs                        ;   |p.y|               dot(p)
                    fdiv st0, st1               ;   |p.y|/dot(p)        dot(p)
                    fsub qword [formuparam]     ;   [p.y|/dot(p)-u      dot(p)
                    fstp qword [p.z]            ;   dot(p)

                    call dotpp                  ;   dot(p')             dot(p)
                    fsub st1, st0               ;   dot(p')             dot(p)-dot(p')
                    fxch st0, st1               ;   dot(p)-dot(p')      dot(p')
                    fabs                        ;   |dot(p)-dot(p')|    dot(p')
                    fadd qword [a]              ;   a+|dot(p)-dot(p')|  dot(p')
                    fstp qword [a]              ;   dot(p')

                    dec cx
                    jnz kaliteration

                fstp st0                        ;   -
                fld qword [s]                   ;   s
                fld1                            ;   1   s
                fadd                            ;   s+1
                fst qword [s]                   ;   s+1
                fld qword [_4]                  ;   4   s+1
                fcomp st1                       ;   s+1
                fstsw ax                        ;
                fstp st0                        ;
                sahf                            ;
                ja loops

                

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

dotpp:
    fld qword [p.x]     ;   x
    fmul st0, st0       ;   x*x
    fld qword [p.y]     ;   y           x*x
    fmul st0, st0       ;   y*y         x*x
    fld qword [p.z]     ;   z           y*y     x*x
    fmul st0, st0       ;   z*z         y*y     x*x
    fadd                ;   y*y+z*z     x*x
    fadd                ;   x*x+y*y+z*z
    ret

section .data 

width dw WIDTH
height dw HEIGHT
ratio dq 1.3333333333333333333333333333333
formuparam dq 0.53

_0_5  dq 0.5
_4    dq 4.0
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

p.x resq 1
p.y resq 1
p.z resq 1

s resq 1
a resq 1
pa resq 1
