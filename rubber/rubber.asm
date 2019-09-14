; #define ITERATIONS 20

; vec3 kaliset(vec3 p, vec3 u){
;     vec3 c=p;
;     for(int i=0;i<ITERATIONS;i++){
;         float len=length(p);
;         p=abs(p)/(len*len)-u;
;         c+=p;
;     }
; 	return c/float(ITERATIONS);
; }

; void mainImage(out vec4 col, in vec2 xy)
; {
;     float m=iTime/60.0;
;     vec2 uv=vec2(xy.x/iResolution.x-0.5,(xy.y-iResolution.y*0.5)/iResolution.x);
;     vec3 p=vec3(uv+m, 1.0/60.0);
;     vec3 u=vec3(0.5,0.5,0.1)*sin(m*3.14);
;     vec3 c=kaliset(p,u);
;     col.xyz=c;
; }

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
mov int16 [frames], ax

; switch to vesa
mov ax, 0x4f02
mov bx, 0x10f
int 10h

; init screen
push 0xa000
pop es

; main loop
main:

    ; progress time
    inc int16 [frames]

    ; init bank
    xor dx, dx

    ; init pixel
    xor di, di

    mov bx, -(HEIGHT/2)
    loopy:

        mov ax, -(WIDTH/2)
        loopx:

            ; preserve coordinates
            push ax
            push bx

            ; free real estate
            mov si, bp

            ; calculate minutes
            fild int16 [frames]         ;   frames
            fidiv int16 [fpm]           ;   m

            ; p=(x/W-0.5, (y/H-0.5)*H/W, 0.1)
            fld1                        ;   1               m
            fidiv int16 [_60]           ;   1/60            m

            mov [si], bx
            fild int16 [si]             ;   y-H/2           1/60            m

            mov [si], ax
            fild int16 [si]             ;   x-W/2           y-H/2           1/60            m

            fild int16 [width]          ;   W               x-W/2           y-H/2           1/60       m
            fdiv st1, st0               ;   W               (x-W/2)/W       y-H/2           1/60       m
            fdivp st2, st0              ;   (x-W/2)/W       (y-H/2)/W       1/60            m

            ; p.xy+=m
            fld st3                     ;   m               p.x             p.y             p.z         m
            fadd st1, st0               ;   m               p.x+m           p.y             p.z         m
            faddp st2, st0              ;   p.x+m           p.y+m           p.z             m

            ; kaliset

            ; c=p
            fld st2                     ;   c.z p.x p.y p.z m
            fld st2                     ;   c.y c.z p.x p.y p.z m
            fld st2                     ;   c.x c.y c.z p.x p.y p.z m

            mov cx, ITERATIONS
            kaliset:

                ; store c, either from initialization or update, otherwise we run out of stack registers
                fstp float [si]         ;   c.y c.z p.x p.y p.z m
                fstp float [si+8]       ;   c.z p.x p.y p.z m
                fstp float [si+16]      ;   p.x p.y p.z m

                ; p=abs(p)
                fabs                    ;   |p.x|   p.y     p.z     m
                fxch st1                ;   p.y     |p.x|   p.z     m
                fabs                    ;   |p.y|   |p.x|   p.z     m
                fxch st1                ;   |p.x|   |p.y|   p.z     m
                fxch st2                ;   p.z     |p.y|   |p.x|   m
                fabs                    ;   |p.z|   |p.y|   |p.x|   m
                fxch st2                ;   |p.x|   |p.y|   |p.z|   m

                ; dot=dot(p,p)
                fld st2                 ;   p.z                         p.x         p.y         p.z m
                fmul st0                ;   p.z*p.z                     p.x         p.y         p.z m
                fld st2                 ;   p.y                         p.z*p.z     p.x         p.y p.z m
                fmul st0                ;   p.y*p.y                     p.z*p.z     p.x         p.y p.z m
                fld st2                 ;   p.x                         p.y*p.y     p.z*p.z     p.x p.y p.z m
                fmul st0                ;   p.x*p.x                     p.y*p.y     p.z*p.z     p.x p.y p.z m
                faddp st1, st0          ;   p.x*p.x+p.y*p.y             p.z*p.z     p.x         p.y p.z m
                faddp st1, st0          ;   p.x*p.x+p.y*p.y+p.z*p.z     p.x         p.y         p.z m

                ; abs(p)/dot(p,p)
                fdiv st1, st0           ;   dot                         p.x/dot     p.y         p.z m
                fdiv st2, st0           ;   dot                         p.x/dot     p.y/dot     p.z m
                fdivp st3, st0          ;   p.x/dot                     p.y/dot     p.z/dot     m

                ; p=abs(p)/dot(p,p)-(0.5,0.5,0.1)*sin(m*pi)
                fld st3                 ;   m                           p.x/dot     p.y/dot         p.z/dot     m
                fldpi                   ;   pi                          m           p.x/dot         p.y/dot     p.z/dot     m
                fmulp st1, st0          ;   m*pi                        p.x/dot     p.y/dot         p.z/dot     m
                fsin                    ;   sin(m*pi)                   p.x/dot     p.y/dot         p.z/dot     m
                fidiv int16 [_2]        ;   sin(m*pi)/2                 p.x/dot     p.y/dot         p.z/dot     m
                fsub st1, st0           ;   sin(m*pi)/2                 p.x/dot-... p.y/dot         p.z/dot     m
                fsub st2, st0           ;   sin(m*pi)/2                 p.x/dot-... p.y/dot-...     p.z/dot     m
                fidiv int16 [_5]        ;   sin(m*pi)/10                p.x/dot-... p.y/dot-...     p.z/dot     m
                fsubp st3, st0          ;   p.x/dot-...                 p.y/dot-... p.z/dot-...

                ; c+=p
                fld float [si+16]       ;   c.z                         p.x         p.y         p.z         m
                fadd st0, st3           ;   c.z+p.z                     p.x         p.y         p.z         m
                fld float [si+8]        ;   c.y                         c.z+p.z     p.x         p.y         p.z         m
                fadd st0, st3           ;   c.y+p.y                     c.z+p.z     p.x         p.y         p.z         m
                fld float [si]          ;   c.x                         c.y+p.y     c.z+p.z     p.x         p.y         p.z         m
                fadd st0, st3           ;   c.x+p.x                     c.y+p.y     c.z+p.z     p.x         p.y         p.z         m

                ; end of kaliset loop
                loop kaliset

            ; c /= iterations
            ; c *= 255.0
            fld float [_255_per_iterations]
            fmul st1, st0
            fmul st2, st0
            fmulp st3, st0

            ; calculate rgb values
            fistp int32 [si+8]
            fistp int32 [si+4]
            fistp int32 [si]

            ; unload p
            fstp st0
            fstp st0
            fstp st0

            ; unload m
            fstp st0

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
_2 def_int16 2
_5 def_int16 5
_60 def_int16 60
fpm def_int16 900

section .bss

frames res_int16 1
u res_float 1
