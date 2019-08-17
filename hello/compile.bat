call clean.bat

gcc hello.c -c -ffreestanding -m32 -march=i386 -nostdinc -nostdlib -Os -s -std=gnu99 || exit /b
ld hello.o -o hello.tmp --nmagic --script=script.ld || exit /b
objcopy -O binary hello.tmp hello.com || exit /b
