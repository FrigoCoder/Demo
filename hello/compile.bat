call clean.bat

gcc hello.c -c -fdata-sections -ffunction-sections -m16 -march=i386 -masm=intel -Os -std=gnu99 || exit /b
ld hello.o -o hello.tmp --file-alignment 0 --gc-sections --nmagic --section-alignment 0 --script=script.ld || exit /b
strip hello.tmp -o hello.com --output-target=binary --strip-all || exit /b
