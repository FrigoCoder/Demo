call clean.bat

gcc hello.c -c -fdata-sections -ffreestanding -ffunction-sections -m32 -march=i386 -nostartfiles -nodefaultlibs -nostdinc -nostdlib -Os -s -std=gnu99 || exit /b
ld hello.o -o hello.tmp --gc-sections --nmagic --script=script.ld || exit /b
strip hello.tmp -o hello.com --output-target=binary || exit /b
