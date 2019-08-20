#define WIDTH 640
#define HEIGHT 480
#define MODE 0x4112

void donothing()
{
    asm volatile("");
}

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

typedef struct
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
} ModeInfo;

void getModeInfo(ModeInfo *output)
{
    asm volatile(
        ".intel_syntax\n"
        "mov ax, 0x4f01\n"
        "int 0x10\n"
        :
        : "b"(MODE), "D"(output)
        : "ax");
}

int getLinearFrameBuffer()
{
    ModeInfo modeInfo;
    getModeInfo(&modeInfo);
    return modeInfo.physbaseptr;
}

typedef struct
{
    char r;
    char g;
    char b;
} Pixel;

void dosmain()
{
    //    setVesaMode();
    //    print("1$");
    //    Pixel *screen = (Pixel *)getLinearFrameBuffer();
    //    print("2$");
    int i = 0;
    for (int x = 0; x < WIDTH; x++)
    {
        //        print("3$");
        for (int y = 0; y < HEIGHT; y++)
        {
            donothing();
            i++;
            //            print("4$");
            // Pixel pixel;
            // pixel.r = x;
            // pixel.g = y;
            // pixel.b = x + y;
            // screen[x + y * WIDTH] = pixel;
        }
    }
    if (i == WIDTH * HEIGHT)
    {
        print("Correct!$");
    }
    else
    {
        print("Wrong!$");
    }
}
