
#define WIDTH 640
#define HEIGHT 480

double abs(double x)
{
    return x >= 0.0 ? x : -x;
}

int max(int x, int y)
{
    return x > y ? x : y;
}

int min(int x, int y)
{
    return x < y ? x : y;
}

int escpressed()
{
    char c;
    asm volatile(
        ".intel_syntax\n"
        "in al, 0x60"
        : "=al"(c)
        :
        :);
    return c == 1;
}

void setVesaMode()
{
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x4f02\n"
        "mov bx, 0x112\n"
        "int 0x10\n"
        :
        :
        : "ax", "bx");
}

void setTextMode()
{
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x0003\n"
        "int 0x10"
        :
        :
        : "ax");
}

int currentBank = 0;

void setBank()
{
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x4f05\n"
        "xor bx, bx\n"
        "int 0x10\n"
        :
        : "d"(currentBank)
        : "ax", "bx");
}

short getds()
{
    short result;
    asm volatile(
        ".intel_syntax\n"
        "mov ax, ds\n"
        : "=a"(result)::);
    return result;
}

char *screen;

void setPixel(int x, int y, char r, char g, char b)
{
    int address = (x + y * WIDTH) * 4;
    int bank = address >> 16;
    if (currentBank != bank)
    {
        currentBank = bank;
        setBank();
    }
    int offset = address & 0xffff;
    screen[offset + 0] = r;
    screen[offset + 1] = g;
    screen[offset + 2] = b;
}

typedef struct
{
    double x;
    double y;
    double z;
} vec3;

void dosmain()
{
    screen = (char *)0xa0000 - getds() * 16;
    setVesaMode();
    for (int t = 0; !escpressed(); t++)
    {
        for (int y = 0; y < HEIGHT; y++)
        {
            for (int x = 0; x < WIDTH; x++)
            {
                // p=(u, v, 0.02)
                vec3 p;
                p.x = ((double)x) / WIDTH - 0.5;
                p.y = (((double)y) / HEIGHT - 0.5) * HEIGHT / WIDTH;
                p.z = 0.02;

                // p*=time in seconds
                p.x *= t / 60.0;
                p.y *= t / 60.0;
                p.z *= t / 60.0;

                // formula parameter
                float u = 0.02 * t / 60.0;

                // kaliset
                vec3 c;
                c.x = 0.0;
                c.y = 0.0;
                c.z = 0.0;

                for (int i = 0; i < 20; i++)
                {
                    float dot = p.x * p.x + p.y * p.y + p.z * p.z;
                    p.x = abs(p.x) / dot - u;
                    p.y = abs(p.y) / dot - u;
                    p.z = abs(p.z) / dot - u;
                    c.x += p.x;
                    c.y += p.y;
                    c.z += p.z;
                }

                c.x /= 20.0;
                c.y /= 20.0;
                c.z /= 20.0;

                int r = min(max(c.x * 255.0, 0), 255);
                int g = min(max(c.y * 255.0, 0), 255);
                int b = min(max(c.z * 255.0, 0), 255);

                setPixel(x, y, r, g, b);
            }
        }
    }
    setTextMode();
}
