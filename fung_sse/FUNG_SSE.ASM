;space fungus by frigo / SSE version by Kuemmel

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

WIDTH equ 640
HEIGHT equ 480
ITERATIONS equ 20

;init
mov si,data_stuff	;can be ommited if data moved to front and proves to be harmless
fninit	;Freedos needs that
fld1	;use float as frames timer => frames = 1

;init sse register for vec3 'u'
movups	xmm5,[si+8]					;1.0	1.0		0.1		?
;init sse register for colour multiplier
movups	xmm6,[si]					;12.75
shufps	xmm6,xmm6,0					;12.75	12.75	12.75	12.75
;init sse register for ABS() mask as there's no ABS() in SSE
pcmpeqd xmm7,xmm7		
psrld	xmm7,1						;0x7fffffff 0x7fffffff 0x7fffffff 0x7fffffff
;init sse register for MIN mask
movups	xmm3,[si+20]			
shufps	xmm3,xmm3,0					;255.0	255.0	255.0	255.0

;switch to 640x480x32Bit
mov ax, 0x4f02
mov bx, 0x112
int 10h
;init screen
push 0xa000
pop es

main:
    fld st0				;frames 	frames
    fidiv word[si+4]	;s=frames/fps	frames
	fld st0 			;s				s		frames
	fidiv word[si+6]	;m=s/spm		s		frames	
	fstp dword[si+bp]	;s				frames
	movups xmm4,[si+bp]	;m
	shufps xmm4,xmm4,0	;m	m	m	m
	mulps  xmm4,xmm5	;(1.0,1.0,0.1)*m
	
	xor dx,dx			;init bank  
    xor di,di			;init pixel
    mov bx,-(HEIGHT/2)
    loopy:
	mov ax,-(WIDTH/2)
	loopx:	     
	    push ax
	    push bx						;preserve coordinates	       
	    
		;p=(x/W-0.5, (y/H-0.5)*H/W, 0.1)
	    fld dword[si+16]			;0.1		s			frames		  
	    mov word[si+bp],bx
	    fild word[si+bp]			;y-H/2	    0.1 		s		frames
	    mov word[si+bp],ax
	    fild word[si+bp]			;x-W/2	    y-H/2		0.1		s		frames		 
	    fild word[si]				;W			x-W/2	    y-H/2   0.1 	s	    frames
	    fdiv st1,st0				;W			(x-W/2)/W	y-H/2	0.1		s		frames	
	    fdivp st2,st0				;(x-W/2)/W  (y-H/2)/W	0.1		s		frames			
	    ;p.xy*=s
	    fld st3						;s			p.x			p.y		p.z		s		frames
	    fmul st1,st0				;s			p.x*s		p.y		p.z		s		frames
	    fmulp st2,st0				;p.x*s	    p.y*s		p.z		s		frames
		fstp dword[si+bp]			;p.y*s	    p.z 		s		frames
		fstp dword[si+bp+4]			;p.z		s			frames
		fstp dword[si+bp+8]			;s			frames
		
		movups xmm0,[si+bp]			;get p
		movaps xmm1,xmm0			;c = p			
	    mov bx,ITERATIONS
	    kaliset_loop:
			movaps xmm2,xmm0			;d = old p
			dpps   xmm2,xmm2,01111111b  ;d = dot(p,p) of first 3 floats and put result in all 4 floats 
			andps  xmm0,xmm7			;p = abs(p) by mask
			rcpps  xmm2,xmm2			;reverse div+multiply is faster than divps, accuracy seems okay
			mulps  xmm0,xmm2			;p = abs(p)/dot(p,p)
			dec bx						;reordered, may be safes some cycles
			subps  xmm0,xmm4			;p = abs(p)/dot(p,p)-(1,1,0.1)*m
			addps  xmm1,xmm0			;c+=p
		jnz kaliset_loop				;loop clears also bx for screenbank loop
		mulps xmm1,xmm6 				;c /= iterations * 255

	    ;switch screenbank if needed
	    test di,di
	    jnz skip_bank_switch
	    mov ax,0x4f05
	    int 10h
	    inc dx
	    skip_bank_switch:
		
		shufps	 xmm1,xmm1,11000110b;switch Red and Blue like the original code, could be omitted if vectors a reordered 
		minps	 xmm1,xmm3			;clamp to a maximum of 255.0 
		cvtps2dq xmm1,xmm1	       	;int(c) conversion
		packuswb xmm1,xmm1	       	;unsigned saturated signed dword to word, word to byte works also die to clamp to 255 before
		packuswb xmm1,xmm1	       	;unsigned saturated signed word	to byte
		movd	 eax,xmm1
	    stosd						;plot pixel
	    
	    pop bx
	    pop ax
		inc ax
	    cmp ax,WIDTH/2
	    jl loopx
	inc bx
	cmp bx,HEIGHT/2
	jl loopy
		
	fstp st0			;frames 	get rid of s
	fld1				;1			frames
	faddp st1,st0		;frames +=1

;check keyboard
xchg ax,bx				;clear ax as bx is zero here
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
dd 1.0,1.0,0.1,255.0  	;vec3() u and MIN mask  ;+ 8,+12,+16,+20
