
#include <math.h>

#define WIDTH 640
#define HEIGHT 480
#define MODE 0x4112

void print(char *string)
{
    asm volatile(
        ".intel_syntax\n"
        "mov ah, 0x09\n"
        "int 0x21\n"
        :
        : "d"(string)
        : "ax");
}

char readchar()
{
    char result;
    asm volatile(
        ".intel_syntax\n"
        "mov ah, 0x01\n"
        "int 0x21\n"
        : "=al"(result)
        :
        : "ah");
    return result;
}

void setVesaMode()
{
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x4f02\n"
        "int 0x10\n"
        :
        : "b"(MODE)
        : "ax");
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

struct ModeInfo
{
    // Mandatory information for all VBE revision
    short modeattributes;   // Mode attributes
    char winaattributes;    // Window A attributes
    char winbattributes;    // Window B attributes
    short wingranularity;   // Window granularity
    short winsize;          // Window size
    short winasegment;      // Window A start segment
    short winbsegment;      // Window B start segment
    int winfuncptr;         // pointer to window function
    short bytesperscanline; // Bytes per scan line

    // Mandatory information for VBE 1.2 and above
    short xresolution;       // Horizontal resolution in pixel or chars
    short yresolution;       // Vertical resolution in pixel or chars
    char xcharsize;          // Character cell width in pixel
    char ycharsize;          // Character cell height in pixel
    char numberofplanes;     // Number of memory planes
    char bitsperpixel;       // Bits per pixel
    char numberofbanks;      // Number of banks
    char memorymodel;        // Memory model type
    char banksize;           // Bank size in KB
    char numberofimagepages; // Number of images
    char reserved1;          // Reserved for page function

    // Direct Color fields (required for direct/6 and YUV/7 memory models)
    char redmasksize;         // Size of direct color red mask in bits
    char redfieldposition;    // Bit position of lsb of red bask
    char greenmasksize;       // Size of direct color green mask in bits
    char greenfieldposition;  // Bit position of lsb of green bask
    char bluemasksize;        // Size of direct color blue mask in bits
    char bluefieldposition;   // Bit position of lsb of blue bask
    char rsvdmasksize;        // Size of direct color reserved mask in bits
    char rsvdfieldposition;   // Bit position of lsb of reserved bask
    char directcolormodeinfo; // Direct color mode attributes

    // Mandatory information for VBE 2.0 and above
    int physbaseptr;        // Physical address for flat frame buffer
    int offscreenmemoffset; // Pointer to start of off screen memory
    short offscreenmemsize; // Amount of off screen memory in 1Kb units
    char reserved2[206];    // Remainder of ModeInfoBlock
} modeInfo;

void getModeInfo()
{
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x4f01\n"
        "int 0x10\n"
        :
        : "b"(MODE), "D"(&modeInfo)
        : "ax");
}

typedef struct
{
    char r;
    char g;
    char b;
} Pixel;

void setPixel(int x, int y, char r, char g, char b)
{
    int address = modeInfo.physbaseptr + (x + y * WIDTH) * 3;
    asm volatile(
        ".intel_syntax\n"
        "mov es:[di], %1\n"
        "mov es:[di+1], %2\n"
        "mov es:[di+2], %3\n"
        :
        : "D"(address), [r] "r"(r), [g] "r"(g), [b] "r"(b)
        :);
}

int whatever(int x, int y)
{
    return x + y;
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
        p.x = camera.x + directino.x * s;
        p.y = camera.y + directino.y * s;
        p.z = camera.z + directino.z * s;
    }
}

void dosmain()
{
    char screen[WIDTH * HEIGHT * 4];
    double seconds = 10.0;
    vec3 cam = camera(seconds);
    for (int x = 0; x < WIDTH; x++)
    {
        for (int y = 0; y < HEIGHT; y++)
        {
            vec3 dir = direction(x, y);
            vec3 rgb = volumetric(cam, dir);
            int address = (x + y * WIDTH) * 4;
            screen[address + 0] = rgb.x * 0.0001;
            screen[address + 1] = rgb.y * 0.0001;
            screen[address + 2] = rgb.z * 0.0001;
        }
    }

    /*    setVesaMode();
    getModeInfo();
    for (int x = 0; x < WIDTH; x++)
    {
        for (int y = 0; y < HEIGHT; y++)
        {
            setPixel(x, y, x, y, x + y);
        }
    }
    readchar();
    setTextMode();*/
}
