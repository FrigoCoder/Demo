org 100h 

WIDTH EQU 640
HEIGHT EQU 480

section .text 

; switch to vesa
mov bx, 0x121
video:
mov ax, 0x4f02
int 0x10
mov bl, 0x12
cmp ah, bh
je video

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

               ; do the stuff
               mov al, [x]
               add al, [t]
               stosb

               mov al, [y]
               add al, [t]
               stosb

               mov al, [x]
               add al, [y]
               add al, [t]
               stosb
               stosb

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

section .bss 

t resw 1
bank resw 1
x resw 1
y resw 1
