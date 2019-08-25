
#define WIDTH 640
#define HEIGHT 480

double abs(double x)
{
    return x >= 0.0 ? x : -x;
}

double sqrt(double x)
{
    double result;
    asm volatile(
        ".intel_syntax\n"
        "fsqrt\n"
        : "=t"(result)
        : "0"(x)
        :);
    return result;
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

// Star Nest code

#define iterations 15
#define formuparam 0.53

#define smin 0.1
#define smax 4.0
#define step 0.1

#define distfading 0.730

double length(vec3 v)
{
    return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

char clamp(double x)
{
    int i = x * 255.0 + 0.5;
    return min(max(x, 0), 255);
}

void dosmain()
{
    screen = (char *)0xa0000 - getds() * 16;
    setVesaMode();
    for (int t = 0; !escpressed(); t++)
    {
        // calculate camera
        vec3 cam;
        cam.x = 0 + 4 * (t / 60.0 - 0.5);
        cam.y = 0 + 2 * (t / 60.0 - 0.5);
        cam.z = -1.0;

        for (int y = 0; y < HEIGHT; y++)
        {
            for (int x = 0; x < WIDTH; x++)
            {
                // calculate direction
                vec3 dir;
                dir.x = ((double)x) / WIDTH - 0.5;
                dir.y = (((double)y) / HEIGHT - 0.5) * HEIGHT / WIDTH;
                dir.z = 1.0;

                // volumetric rendering
                vec3 v;
                v.x = 0;
                v.y = 0;
                v.z = 0;
                double fade = 1.0;
                for (double s = smin; s <= smax; s += step)
                {
                    // get point
                    vec3 p;
                    p.x = cam.x + dir.x * s;
                    p.y = cam.y + dir.y * s;
                    p.z = cam.z + dir.z * s;

                    // kaliset
                    double len = length(p);
                    double a = len;
                    for (int i = 0; i < iterations; i++)
                    {
                        double dot = len * len;
                        p.x = abs(p.x) / dot - formuparam;
                        p.y = abs(p.y) / dot - formuparam;
                        p.z = abs(p.z) / dot - formuparam;
                        double newlen = length(p);
                        //                        a += abs(newlen - len);
                        a += newlen * newlen;
                        len = newlen;
                    }
                    a *= a * a;

                    // coloring
                    v.x += s * a * fade;
                    v.y += s * s * a * fade;
                    v.z += s * s * s * s * a * fade;
                    fade *= distfading;
                }

                double scale = 0.001;
                setPixel(x, y, clamp(v.x * scale), clamp(v.y * scale), clamp(v.z * scale));
                // setPixel(x, y, x + t, y + t, x + y + t);
            }
        }
    }
    setTextMode();
}
