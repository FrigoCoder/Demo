static void print(char *string)
{
    asm volatile("mov   $0x09, %%ah\n"
                 "int   $0x21\n"
                 : /* no output */
                 : "d"(string)
                 : "ah");
}

int wrong1(void)
{
    print("Wrong1!\n$");
    return 0;
}

int dosmain(void)
{
    print("Hello, World!\n$");
    return 0;
}

int wrong2(void)
{
    print("Wrong2!\n$");
    return 0;
}
