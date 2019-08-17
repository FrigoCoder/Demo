static void print(char *string)
{
    asm volatile(
        ".intel_syntax\n"
        "mov ah,0x09\n"
        "int 0x21\n"
        : /* no output */
        : "d"(string)
        : "ah");
}

int dosmain(void)
{
    print("Hello, World!\n$");
    return 0;
}