org 100h 

section .text 

; call print
mov ah, 9
mov dx, str
int 21h

; exit
int 20h

section .data 
str: db "Hello world!$"

section .bss 
