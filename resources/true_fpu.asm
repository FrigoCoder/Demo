
;"---set screenmode by TomCatAbaddon
mov bx,121h		;set screen 640*480*32 true colour
video:
mov ax,4f02h
int 10h
mov bl,12h
cmp ah,bh
je video		;safety, skipping this works for XP but not for DOSBox
;;

fld1			;1
main_loop:

xor dx,dx		;dx is the screen bank address =>640*480*4/65565 = 18.75 banks needed
xor di,di		;init first pixel
mov ax,res_y
y_loop:
	push ax
	sub ax,240					;st0			|st1	|st2	|st3	|st4	|st5	|st6	|st7	
	mov word[bp+si],ax			;1
	fild word[bp+si]			;y				|1
	fld  st0					;y				|y		|1
	fmul st0,st0				;y*y			|y		|1	
	mov ax,res_x
	x_loop:
		push ax
		sub ax,320
		test di,di
		mov word[bp+si],ax
		jnz skip_bank_switch
			xor bx,bx			;needs to be clear !
			mov ax,4F05h
			int 10h				;next 64 KByte bank, bx needs to be zero !
			inc dx	
		skip_bank_switch:

		fild word[bp+si]		;x				|y*y	|y		|1
		fld st0					;x				|x		|y*y	|y		|1	
		fmul st0,st0			;x*x			|x		|y*y	|y		|1	
		fadd st0,st2			;x*x+y*y		|x		|y*y	|y		|1	
		fmul dword[si-4]		;(x*x+y*y)*mu	|x		|y*y	|y		|1	
		fsubr st0,st4			;1-(x*x+y*y)*mu	|x		|y*y	|y		|1	
		fabs					;t=abs(1-...)	|x		|y*y	|y		|1	
		fst st5					;t				|x		|y*y	|y		|1		|t	
		fsqrt					;e=sqrt(t)		|x		|y*y	|y		|1		|t
		fsubr st0,st4			;1-e			|x		|y*y	|y		|1		|t
		fadd st0,st4			;2-e			|x		|y*y	|y		|1		|t
		fmul st1,st0			;2-e			|x*(2-e)|y*y	|y		|1		|t
		fmul st0,st3			;y*(2-e)		|x*(2-e)|y*y	|y		|1		|t
		fistp word[bp+si]		;x*(2-e)		|y*y	|y		|1		|t
		fistp word[bp+si+1]		;y*y			|y		|1		|t
		xor ax,ax				;clear offset for xlatb and ah
		mov bx,word[bp+si]		;y=bl; x=bh
		sub bl,cl				;inc x_movement
		add bh,cl				;inc y_movement
		fs xlatb

		shld bx,ax,18			;get texel RGBx colour address from palette into bx
		
		mov eax,dword[si+bx]
		
		mov ch,3 
		rgb_loop:
			movzx bx,al
			mov word[bp+si],bx
			fild word[bp+si]	;c				|y*y	|y		|1		|t	
			fmul st0,st0		;c*c			|y*y	|y		|1		|t	
			fmul st0,st4		;c*c*t			|y*y	|y		|1		|t
			fsqrt				;sqrt(c*c*t)	|y*y	|y		|1		|t
			fistp word[bp+si]	;y*y			|y		|1		|t
			mov al,byte[bp+si]
			cmp word[bp+si],0xff
			jna no_sat
			  mov al,0xff 
			no_sat:
			stosb
			shr eax,8
		dec ch
		jnz rgb_loop
		inc di	
		pop ax
		dec ax
	jnz x_loop
	fcompp						;|1				|t
	pop ax
	dec ax
jnz y_loop

inc cx		;update global movement counter
