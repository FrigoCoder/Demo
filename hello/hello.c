void print(char* string)
{
    asm volatile(
        ".intel_syntax\n"
        "mov ah, 0x09\n"
        "int 0x21\n"
        : /* no output */
        : "d"(string)
        : "ah");
}

void vesa () {
    int mode = 0x129 | (1 << 14);
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x4f02\n"
//        "mov bx, _mode\n"
        "int 0x10\n"
        :
        : "b"(mode)
        : "ax");
}

short current () {
    short result;
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x4f03\n"
        "int 0x10\n"
        : "=b" (result)
        :
        : "ax");
    return result;
}

void writechar (char c) {
    char* str = "x$";
    str[0] = c;
    print(str);
}

static void printnumber (int x){
    writechar('0' + 0);
    writechar('0' + 1);
    writechar('0' + 2);
    writechar('0' + 3);
    writechar('0' + 4);
    writechar('0' + 5);
    writechar('0' + 6);
    writechar('0' + 7);
    writechar('0' + 8);
    writechar('0' + 9);
    return;
}

int factorial (int x){
    if( x == 0 ){
        return 1;
    }
    return x * factorial(x - 1);
}

int dosmain(void) {
    writechar('0' + 0);
    writechar('0' + 1);
    writechar('0' + 2);
    writechar('0' + 3);
    writechar('0' + 4);
    writechar('0' + 5);
    writechar('0' + 6);
    writechar('0' + 7);
    writechar('0' + 8);
    writechar('0' + 9);
    return 0;
}
