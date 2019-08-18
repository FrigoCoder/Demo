void print(char *string)
{
    asm volatile(
        ".intel_syntax\n"
        "mov ah, 0x09\n"
        "int 0x21\n"
        : /* no output */
        : "d"(string)
        : "ah");
}

void vesa()
{
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

short current()
{
    short result;
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x4f03\n"
        "int 0x10\n"
        : "=b"(result)
        :
        : "ax");
    return result;
}

void writechar(char c)
{
    asm volatile(
        ".intel_syntax\n"
        "mov ah, 0x02\n"
        "int 0x21\n"
        : /* no output */
        : "dl"(c)
        : "ax");
}

void printnumber(int x)
{
    if (x >= 10)
    {
        printnumber(x / 10);
    }
    writechar('0' + (x % 10));
}

int dosmain(void)
{
    printnumber(123456789);
    return 0;
}
