; #define iterations 20

; vec3 kaliset(vec3 p, vec3 u){
;     vec3 c=p;
;     for(int i=0;i<iterations;i++){
;         float len=length(p);
;         p=abs(p)/(len*len)-u;
;         c+=p;
;     }
; 	return c/float(iterations);
; }

; void mainImage(out vec4 c, in vec2 xy)
; {
;     vec2 uv=vec2(xy.x/iResolution.x-0.5,(xy.y-iResolution.y*0.5)/iResolution.x);
;     float m=iTime/60.0;
;     vec3 p=vec3(uv*iTime,0.1);
;     vec3 u=vec3(1.0,1.0,0.1)*m;
;     c.xyz=kaliset(p,u);
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

WIDTH EQU 640
HEIGHT EQU 480
ITERATIONS EQU 20

section .text

; init time
mov int16 [frames], ax

; switch to vesa
mov ax, 0x4f02
mov bx, 0x112
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

            ; calculate seconds
            fild int16 [frames]         ;   frames
            fidiv int16 [fps]           ;   s

            ; p=(x/W-0.5, (y/H-0.5)*H/W, 0.1)
            fld1                        ;   1               s
            fidiv int16 [_10]           ;   0.1             s

            mov [si], bx
            fild int16 [si]             ;   y-H/2           0.1             s

            mov [si], ax
            fild int16 [si]             ;   x-W/2           y-H/2           0.1             s

            fild int16 [width]          ;   W               x-W/2           y-H/2           0.1        s
            fdiv st1, st0               ;   W               (x-W/2)/W       y-H/2           0.1        s
            fdivp st2, st0              ;   (x-W/2)/W       (y-H/2)/W       0.1             s

            ; p.xy*=sec
            fld st3                     ;   s               p.x             p.y             p.z         s
            fmul st1, st0               ;   s               p.x*s           p.y             p.z         s
            fmulp st2, st0              ;   p.x*s           p.y*s           p.z             s

            ; kaliset

            ; c=p
            fld st2                     ;   c.z p.x p.y p.z s
            fld st2                     ;   c.y c.z p.x p.y p.z s
            fld st2                     ;   c.x c.y c.z p.x p.y p.z

            mov cx, ITERATIONS
            kaliset:

                ; store c, either from initialization or update, otherwise we run out of stack registers
                fstp float [si]         ;   c.y c.z p.x p.y p.z s
                fstp float [si+8]       ;   c.z p.x p.y p.z s
                fstp float [si+16]      ;   p.x p.y p.z s

                ; p=abs(p)
                fabs                    ;   |p.x|   p.y     p.z     s
                fxch st1                ;   p.y     |p.x|   p.z     s
                fabs                    ;   |p.y|   |p.x|   p.z     s
                fxch st1                ;   |p.x|   |p.y|   p.z     s
                fxch st2                ;   p.z     |p.y|   |p.x|   s
                fabs                    ;   |p.z|   |p.y|   |p.x|   s
                fxch st2                ;   |p.x|   |p.y|   |p.z|   s

                ; dot=dot(p,p)
                fld st2                 ;   p.z                         p.x         p.y         p.z s
                fmul st0                ;   p.z*p.z                     p.x         p.y         p.z s
                fld st2                 ;   p.y                         p.z*p.z     p.x         p.y p.z s
                fmul st0                ;   p.y*p.y                     p.z*p.z     p.x         p.y p.z s
                fld st2                 ;   p.x                         p.y*p.y     p.z*p.z     p.x p.y p.z s
                fmul st0                ;   p.x*p.x                     p.y*p.y     p.z*p.z     p.x p.y p.z s
                faddp st1, st0          ;   p.x*p.x+p.y*p.y             p.z*p.z     p.x         p.y p.z s
                faddp st1, st0          ;   p.x*p.x+p.y*p.y+p.z*p.z     p.x         p.y         p.z s

                ; abs(p)/dot(p,p)
                fdiv st1, st0           ;   dot                         p.x/dot     p.y         p.z s
                fdiv st2, st0           ;   dot                         p.x/dot     p.y/dot     p.z s
                fdivp st3, st0          ;   p.x/dot                     p.y/dot     p.z/dot     s

                ; p=abs(p)/dot(p,p)-(1,1,0.1)*m
                fld st3                 ;   s                           p.x/dot     p.y/dot         p.z/dot     s
                fidiv int16 [spm]       ;   m                           p.x/dot     p.y/dot         p.z/dot     s
                fsub st1, st0           ;   m                           p.x/dot-m   p.y/dot         p.z/dot     s
                fsub st2, st0           ;   m                           p.x/dot-m   p.y/dot-m       p.z/dot     s
                fidiv int16 [_10]       ;   0.1                         p.x/dot-m   p.y/dot-m       p.z/dot     s
                fsubp st3, st0          ;   p.x/dot-m                   p.y/dot-m   p.z/dot-0.1m    s

                ; c+=p
                fld float [si+16]       ;   c.z                         p.x         p.y         p.z         s
                fadd st0, st3           ;   c.z+p.z                     p.x         p.y         p.z         s
                fld float [si+8]        ;   c.y                         c.z+p.z     p.x         p.y         p.z         s
                fadd st0, st3           ;   c.y+p.y                     c.z+p.z     p.x         p.y         p.z         s
                fld float [si]          ;   c.x                         c.y+p.y     c.z+p.z     p.x         p.y         p.z         s
                fadd st0, st3           ;   c.x+p.x                     c.y+p.y     c.z+p.z     p.x         p.y         p.z         s

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

            ; unload s
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

    jmp main

;     ; check keyboard
;     in al, 0x60
;     dec al
;     jnz main

; ; switch to text mode
; mov ax, 0x0003
; int 0x10

; ; exit
; ret


section .data

width def_int16 WIDTH
_255_per_iterations def_float 12.75
_10 def_int16 10
fps def_int16 15
spm def_int16 60


section .bss

frames res_int16 1
u res_float 1
