
#include <math.h>

#define WIDTH 640
#define HEIGHT 480

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

double kaliset(vec3 p)
{
    double a = 0;
    double pa = 0;
    for (int i = 0; i < iterations; i++)
    {
        double dot = p.x * p.x + p.y * p.y + p.z * p.z;
        double length = sqrt(dot);
        p.x = abs(p.x) / dot - formuparam;
        p.y = abs(p.y) / dot - formuparam;
        p.z = abs(p.z) / dot - formuparam;
        a += abs(length - pa);
        pa = length;
    }
    return a * a * a;
}

vec3 camera(double seconds)
{
    double time = seconds / 60.0 - 0.5;
    vec3 result;
    result.x = 0 + 4 * time;
    result.y = 0 + 2 * time;
    result.z = -1.5;
    return result;
}

vec3 direction(int x, int y)
{
    vec3 result;
    result.x = ((double)x) / WIDTH - 0.5;
    result.y = (((double)y) / HEIGHT - 0.5) * HEIGHT / WIDTH;
    result.z = 1.0;
    return result;
}

vec3 add(vec3 u, vec3 v)
{
    vec3 result;
    result.x = u.x + v.x;
    result.y = u.y + v.y;
    result.z = u.z + v.z;
    return result;
}

vec3 mul(vec3 v, double s)
{
    vec3 result;
    result.x = v.x * s;
    result.y = v.y * s;
    result.z = v.z * s;
    return result;
}

vec3 volumetric(vec3 camera, vec3 direction)
{
    double fade = 1.0;
    vec3 v;
    v.x = 0;
    v.y = 0;
    v.z = 0;
    for (double s = smin; s <= smax; s += step)
    {
        vec3 p;
        p.x = camera.x + direction.x * s;
        p.y = camera.y + direction.y * s;
        p.z = camera.z + direction.z * s;
    }
    return v;
}

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
                setPixel(x, y, x + t, y + t, x + y + t);
            }
        }
    }
    setTextMode();
}
