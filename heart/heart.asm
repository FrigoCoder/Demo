org 100h 

section .text 

; switch display mode
mov ax, 0x4f02
mov bx, 0x112
int 0x10

; call print
mov ah, 9
mov dx, hello
int 21h

; exit
int 20h

section .data 
hello: db "Hello world!$"

section .bss 
whatever: resb 100
