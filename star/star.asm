org 100h 

WIDTH EQU 640
HEIGHT EQU 480

ITERATIONS EQU 15

section .text 

; switch to vesa
mov ax, 0x4f02
mov bx, 0x112
int 10h

; init screen
push 0xa000
pop es

; init time
fldz                    ;   t

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
    fld st0             ;   t           t
    fidiv word [_1800]  ;   t/1800      t
    fldz                ;   0           t/1800      t
    fld1                ;   1           0           t/1800      t
    fsub                ;   -1          t/1800      t
    fst dword [cam+16]
    fadd                ;   t/1800-1    t
    fst dword [cam+8]
    fadd st0            ;   t/900-2     t
    fstp dword [cam]    ;   t

    mov word [y], HEIGHT
    loopy:

        mov word [x], WIDTH
        loopx:

            ; switch screenbank if needed
            test di, di
            jnz skip_bank_switch
            mov ax, 0x4f05
            xor bx, bx
            int 10h
            inc dx
            skip_bank_switch:

            ; get uv coordinates and direction
            fild word [x]
            fidiv word [width]

            fstp dword [dir]

            fild word [y]
            fidiv word [height]
            fstp dword [dir+8]

            fld1
            fstp dword [dir+16]

            ; calculate shift
            



            ; do the stuff
            fild word [x]            ; x t
            fadd st0, st1            ; x+t t
            fistp word [result]      ; t
            mov ax, [result]
            stosb

            fild word [y]            ; y t
            fadd st0, st1            ; y+t t
            fistp word [result]      ; t
            mov ax, [result]
            stosb

            fild word [x]            ; x t
            fild word [y]            ; y x t
            fadd st0, st1            ; x+y x t
            fadd st0, st2            ; x+y+t x t
            fistp word [result]      ; x t
            mov ax, [result]
            stosb
            stosb
            fstp st0                 ; t

            dec word [x]
            jnz loopx

        dec word [y]
        jnz loopy

    ; increase time
    fld1                            ;   1   t
    faddp                           ;   t+1

    ; check keyboard
    in al, 0x60
    dec al
    jnz main

; switch to text mode
mov ax, 0x0003
int 0x10

; exit
ret

;   x   |y  |z
kaliset:

    fldz    ;   0   x   y   z
    fldz    ;   0   0   x   y   z

    mov cx, ITERATIONS

    kaliteration:       ;   x           y   z
        call dot        ;   dot(p)  x   y   z
        fdiv st1, st0   ;   dot(p)  x/   y   z


        fld st2             ;   x   0   0   x   y   z
        fmul st0            ;   x*x 0   0   x   y   z
        fld 

        dec cx
        jnz kaliteration

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
    ret;

section .data 

width dw WIDTH
height dw HEIGHT

_1800 dw 1800

section .bss 

t resw 1
x resw 1
y resw 1
result resw 1

a resb 8
pa resb 8

cam resb 3*8
dir resb 3*8
fade resb 1*8
