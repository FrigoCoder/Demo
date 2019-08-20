org 100h 

WIDTH EQU 640
HEIGHT EQU 480
MODE EQU 0x4112

section .text 

; switch to vesa display mode
mov ax, 0x4f02
mov bx, MODE
int 0x10

; get vbe mode information
mov ax, 0x4f01
mov bx, MODE
mov di, modeinfoblock
int 0x10

; set up linear frame buffer
mov edi, [.PhysBasePtr]

; main loop

mov word [y], 0
loopy:

mov word [x], 0
loopx:

; main loop core

mov ax, [x]
stosb
inc edi

mov ax, [y]
stosb
inc edi

add ax, [x]
stosb
inc edi

; end of main loop

inc word [x]
cmp word [x], WIDTH
jl loopx

inc word [y]
cmp word [y], HEIGHT
jl loopy

; switch to text mode
mov ax, 0x0003
int 0x10

; exit
int 20h


section .data 


section .bss 

x resw 1
y resw 1

modeinfoblock:

     ; Mandatory information for all VBE revisions
    .ModeAttributes      resw 1      ; mode attributes
    .WinAAttributes      resb 1      ; window A attributes
    .WinBAttributes      resb 1      ; window B attributes
    .WinGranularity      resw 1      ; window granularity
    .WinSize             resw 1      ; window size
    .WinASegment         resw 1      ; window A start segment
    .WinBSegment         resw 1      ; window B start segment
    .WinFuncPtr          resd 1      ; pointer to window function
    .BytesPerScanLine    resw 1      ; bytes per scan line

     ; Mandatory information for VBE 1.2 and above
    .XResolution         resw 1      ; horizontal resolution in pixels or chars
    .YResolution         resw 1      ; vertical resolution in pixels or chars
    .XCharSize           resb 1      ; character cell width in pixels
    .YCharSize           resb 1      ; character cell height in pixels
    .NumberOfPlanes      resb 1      ; number of memory planes
    .BitsPerPixel        resb 1      ; bits per pixel
    .NumberOfBanks       resb 1      ; number of banks
    .MemoryModel         resb 1      ; memory model type
    .BankSize            resb 1      ; bank size in KB
    .NumberOfImagePages  resb 1      ; number of images
    .Reserved            resb 1      ; reserved for page function

     ; Direct Color fields (required for direct/6 and YUV/7 memory models)
    .RedMaskSize         resb 1      ; size of direct color red mask in bits
    .RedFieldPosition    resb 1      ; bit position of lsb of red mask
    .GreenMaskSize       resb 1      ; size of direct color green mask in bits
    .GreenFieldPosition  resb 1      ; bit position of lsb of green mask
    .BlueMaskSize        resb 1      ; size of direct color blue mask in bits
    .BlueFieldPosition   resb 1      ; bit position of lsb of blue mask
    .RsvdMaskSize        resb 1      ; size of direct color reserved mask in bits
    .RsvdFieldPosition   resb 1      ; bit position of lsb of reserved mask
    .DirectColorModeInfo resb 1      ; direct color mode attributes

     ; Mandatory information for VBE 2.0 and above
    .PhysBasePtr         resd 1      ; physical address for flat frame buffer
    .OffScreenMemOffset  resd 1      ; pointer to start of off screen memory
    .OffScreenMemSize    resw 1      ; amount of off screen memory in 1k units
    .Reserved2           resb 206
