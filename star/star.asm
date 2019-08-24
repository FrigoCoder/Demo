org 100h 

WIDTH EQU 640
HEIGHT EQU 480

section .text 

; switch to vesa
mov ax, 0x4f02
mov bx, 0x112
int 10h

; init screen
push 0xa000
pop es

; init time
mov word [t], 0

; main loop
main:

     ; init bank
     mov word [bank], 0

     ; init pixel
     xor di, di

     mov word [y], 0
     loopy:

          mov word [x], 0
          loopx:

               ; switch screenbank if needed
               test di, di
               jnz skip_bank_switch
                    mov ax, 0x4f05
                    xor bx, bx
                    mov dx, [bank]
                    int 10h
                    inc word [bank]
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



               ; do the stuff
               
               fild word [t]            ; t
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
               fstp st0                 ;

               inc word [x]
               cmp word [x], WIDTH
               jl loopx

          inc word [y]
          cmp word [y], HEIGHT
          jl loopy

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

section .data 

width dw WIDTH
height dw HEIGHT

section .bss 

bank resw 1
t resw 1
x resw 1
y resw 1
result resw 1

dir resb 3*8
from resb 3*8
fade resb 1*8
