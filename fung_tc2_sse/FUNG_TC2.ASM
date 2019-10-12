;space fungus by frigo / SSE version by Kuemmel / FPU optimizations by TomCat

; #define iterations 20

; vec3 kaliset(vec3 p, vec3 u){
;     vec3 c=p;
;     for(int i=0;i<iterations;i++){
;	  float len=length(p);
;	  p=abs(p)/(len*len)-u;
;	  c+=p;
;     }
;	return c/float(iterations);
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
use16

WIDTH=640
HEIGHT=480
ITERATIONS=20

;init
mov si,data_stuff	;can be ommited if data moved to front and proves to be harmless
fninit	;Freedos needs that
fld1	;use float as frames timer => frames = 1

;init sse register for ABS() mask as there's no ABS() in SSE
pcmpeqd xmm7,xmm7		
psrld	xmm7,1						;0x7fffffff 0x7fffffff 0x7fffffff 0x7fffffff

;switch to 640x480x32Bit
mov ax, 0x4f02
mov bx, 0x112
int 10h
;init screen
push 0xa000
pop es

main:
 fld st0			;frames frames
 fidiv word[si+4]	;s=frames/fps frames
 fld st0			;s s frames
 fidiv word[si+6]	;m=s/spm s frames
 fstp dword[si+bp]	;s frames
 fidiv word[si] 	;s/W frames

	movups xmm0,[si+8]	;1.0	1.0		0.1		?
	movups xmm6,[si+bp]	;m
	shufps xmm6,xmm6,0	;m	m	m	m
	mulps  xmm6,xmm0	;(1.0,1.0,0.1)*m
	
    cwd 				;init bank
    xor di,di			;init pixel
    mov cx,-(HEIGHT/2)
    loopy:
	mov ax,-(WIDTH/2)
	loopx:
	    push ax						;preserve coordinates

	;p=(x/W-0.5, (y/H-0.5)*H/W, 0.1)
	fld dword[si+16]	;0.1 s/W frames
	fstp dword[si+bp+8]	;s/W frames

	nextaxis:
		mov word[si+bp],ax	;1st pixel in x-row
		fld st0				;s/W s/W frames
		fimul word[si+bp]	;p.x s/W frames
		xchg ax,cx
		fstp dword[si+bp]	;s/W frames
	xor bp,4
	jpe nextaxis
	movups xmm0,[si+bp]		;get p(x,...)
 
	inc ax 					;2nd pixel in x-row
	mov word[si+bp],ax
	fld st0					;s/W s/W frames
	fimul word[si+bp]		;p.x s/W frames
	fstp dword[si+bp]		;s/W frames
	movups xmm3,[si+bp]		;get p(x+1,...)

	movaps xmm1,xmm0		;c1 = p1 (x,...)
	movaps xmm4,xmm3		;c2 = p2 (x+1,...) 

	    mov bl,ITERATIONS
	    kaliset_loop:
				movaps xmm2,xmm0			;d1 = old p1
				movaps xmm5,xmm3			;d2 = old p2
				dpps   xmm2,xmm2,01111111b  ;d1 = dot(p1,p1) of first 3 floats and put result in all 4 floats 
				andps  xmm0,xmm7			;abs(p1)
				dpps   xmm5,xmm5,01111111b	;d2 = dot(p2,p2)
				andps  xmm3,xmm7			;abs(p2)
				rcpps  xmm2,xmm2			;reverse div+multiply is faster than divps, accuracy seems okay
				dec bx						;reordered, may be safes some cycles
				rcpps  xmm5,xmm5
				mulps  xmm0,xmm2			;p1 = abs(p1)/dot(p2,p2)
				mulps  xmm3,xmm5			;p2 = abs(p2)/dot(p2,p2)
				subps  xmm0,xmm6			;p1 = abs(p1)/dot(p1,p1)-(1,1,0.1)*m
				subps  xmm3,xmm6			;p2 = abs(p2)/dot(p2,p2)-(1,1,0.1)*m
				addps  xmm1,xmm0			;c1+=p1
				addps  xmm4,xmm3			;c2+=p2
	    jnz kaliset_loop				    ;loop clears also bx for screenbank loop
			
			movups xmm0,[si]				;12.75
			shufps xmm0,xmm0,0				;12.75	12.75	12.75	12.75
			;init sse register for MIN mask
			movups	xmm2,[si+20]			
			shufps	xmm2,xmm2,0				;255.0	255.0	255.0	255.0		

	    ;switch screenbank if needed
	    test di,di
	    jnz skip_bank_switch
	    mov ax,0x4f05
	    int 10h
	    inc dx
	    skip_bank_switch:
	      
		;carry is zero here for looping twice
		two_pixel_loop:
			mulps	 xmm1,xmm0	    	;c /= iterations * 255
			shufps	 xmm1,xmm1,11000110b;switch Red and Blue like the original code, could be omitted if vectors a reordered 
			minps	 xmm1,xmm2			;clamp to a maximum of 255.0 
			cvtps2dq xmm1,xmm1			;int(c) conversion
			packuswb xmm1,xmm1			;unsigned saturated signed dword to word, word to byte works also die to clamp to 255 before
			packuswb xmm1,xmm1			;unsigned saturated signed word to byte
			movd	 eax,xmm1
			movaps	 xmm1,xmm4			;move 2nd result/pixel for 2nd loop
			stosd						;plot pixel
	    cmc
		jc two_pixel_loop
			
	    pop ax
	    inc ax
		inc ax ;2 pixels per x_loop
	    cmp ax,WIDTH/2
	    jl loopx
	inc cx
	cmp cx,HEIGHT/2
	jne loopy
		
 fdiv st0,st0
 faddp st1,st0		;frames +=1

;check keyboard
xchg ax,cx				;clear ax as cx is zero here
in al,0x60
dec ax
jnz main

;switch to text mode
exito:
mov al,3
int 0x10
ret

data_stuff:
dw WIDTH										;  0
dw 0x414c				;_255_per_iterations	;+ 2	0x414c is almost 12.75 together with WIDTH
dw 15					;fps					;+ 4
dw 60					;spm					;+ 6
dd 1.0,1.0,0.1,255.0	;vec3() u and MIN mask	;+ 8,+12,+16,+20
