00000100  A30002            mov [0x200],ax
00000103  B8024F            mov ax,0x4f02
00000106  BB0F01            mov bx,0x10f
00000109  CD10              int 0x10
0000010B  6800A0            push word 0xa000
0000010E  07                pop es
0000010F  FF060002          inc word [0x200]
00000113  31D2              xor dx,dx
00000115  31FF              xor di,di
00000117  BB9CFF            mov bx,0xff9c
0000011A  B860FF            mov ax,0xff60
0000011D  50                push ax
0000011E  53                push bx
0000011F  89EE              mov si,bp
00000121  DF060002          fild word [0x200]
00000125  DE36F401          fidiv word [0x1f4]
00000129  D9E8              fld1
0000012B  DE36F601          fidiv word [0x1f6]
0000012F  891C              mov [si],bx
00000131  DF04              fild word [si]
00000133  8904              mov [si],ax
00000135  DF04              fild word [si]
00000137  DF06F801          fild word [0x1f8]
0000013B  DCF9              fdiv to st1
0000013D  DEFA              fdivp st2
0000013F  D9C3              fld st3
00000141  DCC1              fadd to st1
00000143  DCC2              fadd to st2
00000145  DECB              fmulp st3
00000147  D9C2              fld st2
00000149  D9C2              fld st2
0000014B  D9C2              fld st2
0000014D  B91400            mov cx,0x14
00000150  D91C              fstp dword [si]
00000152  D95C08            fstp dword [si+0x8]
00000155  D95C10            fstp dword [si+0x10]
00000158  D9E1              fabs
0000015A  D9C9              fxch st1
0000015C  D9E1              fabs
0000015E  D9C9              fxch st1
00000160  D9CA              fxch st2
00000162  D9E1              fabs
00000164  D9CA              fxch st2
00000166  D9C2              fld st2
00000168  D8C8              fmul st0
0000016A  D9C2              fld st2
0000016C  D8C8              fmul st0
0000016E  D9C2              fld st2
00000170  D8C8              fmul st0
00000172  DEC1              faddp st1
00000174  DEC1              faddp st1
00000176  DCF9              fdiv to st1
00000178  DCFA              fdiv to st2
0000017A  DEFB              fdivp st3
0000017C  D9C3              fld st3
0000017E  DCE9              fsub to st1
00000180  DCEA              fsub to st2
00000182  DE36F601          fidiv word [0x1f6]
00000186  DEEB              fsubp st3
00000188  D94410            fld dword [si+0x10]
0000018B  D8C3              fadd st3
0000018D  D94408            fld dword [si+0x8]
00000190  D8C3              fadd st3
00000192  D904              fld dword [si]
00000194  D8C3              fadd st3
00000196  E2B8              loop 0x150
00000198  D906FA01          fld dword [0x1fa]
0000019C  DCC9              fmul to st1
0000019E  DCCA              fmul to st2
000001A0  DECB              fmulp st3
000001A2  DB5C08            fistp dword [si+0x8]
000001A5  DB5C04            fistp dword [si+0x4]
000001A8  DB1C              fistp dword [si]
000001AA  DDD8              fstp st0
000001AC  DDD8              fstp st0
000001AE  DDD8              fstp st0
000001B0  DDD8              fstp st0
000001B2  85FF              test di,di
000001B4  7508              jnz 0x1be
000001B6  B8054F            mov ax,0x4f05
000001B9  31DB              xor bx,bx
000001BB  CD10              int 0x10
000001BD  42                inc dx
000001BE  B90300            mov cx,0x3
000001C1  66AD              lodsd
000001C3  6683F800          cmp eax,byte +0x0
000001C7  7F02              jg 0x1cb
000001C9  30C0              xor al,al
000001CB  663D00010000      cmp eax,0x100
000001D1  7C02              jl 0x1d5
000001D3  B0FF              mov al,0xff
000001D5  AA                stosb
000001D6  E2E9              loop 0x1c1
000001D8  AA                stosb
000001D9  5B                pop bx
000001DA  58                pop ax
000001DB  40                inc ax
000001DC  3DA000            cmp ax,0xa0
000001DF  0F8C3AFF          jl near 0x11d
000001E3  43                inc bx
000001E4  83FB64            cmp bx,byte +0x64
000001E7  0F8C2FFF          jl near 0x11a
000001EB  E460              in al,0x60
000001ED  FEC8              dec al
000001EF  0F851CFF          jnz near 0x10f
000001F3  C3                ret
000001F4  8403              test [bp+di],al
000001F6  0A00              or al,[bx+si]
000001F8  40                inc ax
000001F9  0100              add [bx+si],ax
000001FB  004C41            add [si+0x41],cl
