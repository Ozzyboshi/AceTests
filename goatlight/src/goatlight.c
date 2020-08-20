#include "goatlight.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>                  // for blitwait
#include <fixmath/fix16.h>

#include "simplebuffertest.h"

//#define COLORDEBUG
//#define STARTWITHBLACKBARS
#define AUTOSCROLLING
#define BITPLANES 4 // 4 bitplanes

#define copSetWaitBackAndFront(var, var2)                    \
    copSetWait(&pCmdListBack[ubCopIndex].sWait, var, var2);  \
    copSetWait(&pCmdListFront[ubCopIndex].sWait, var, var2); \
    ubCopIndex++;

#define copSetMoveBackAndFront(var, var2)                    \
    copSetMove(&pCmdListBack[ubCopIndex].sMove, var, var2);  \
    copSetMove(&pCmdListFront[ubCopIndex].sMove, var, var2); \
    ubCopIndex++;

#define copSetMoveBack(var, var2)                           \
    copSetMove(&pCmdListBack[ubCopIndex].sMove, var, var2); \
    ubCopIndex++;

static tView *s_pView;    // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferTestManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs = 0;
static fix16_t sg_tVelocity;
static fix16_t sg_tVelocityIncrementer;

//void updateCamera(UBYTE);
void updateCamera2(BYTE);
UWORD getBarColor(const UBYTE);
UWORD getBarColorPerspective(const UBYTE);
UWORD getBarColorPerspectiveBack(const UBYTE);

void MaskScreen(UBYTE);
void unMaskScreen(UBYTE);
UBYTE unMaskIntro(UBYTE, UBYTE);
void printPerspectiveRow2(tSimpleBufferTestManager *s_pMainBuffer, const UWORD, const UWORD, const UWORD);

UBYTE buildPerspectiveCopperlist(UBYTE);

#define MAXCOLORS 12

// Color sequence palette for non perspective vertical rectangles
static UWORD s_pBarColors2[MAXCOLORS] = {
    0x0C87, // color of first col
    0x0AE8, // color of the second col
    0x08BC, // color of the third col
    0x0000, // color of the fourth col

    0x0C87, // color of first col
    0x0AE8, // color of the second col
    0x08BC, // color of the third col
    0x0000, // color of the fourth col

    0x0C87, // color of first col
    0x0AE8, // color of the second col
    0x08BC, // color of the third col
    0x0000, // color of the fourth col
};

// Color sequence palette for perspective rectangles
static UWORD s_pBarColorsPerspective2[MAXCOLORS] = {
    0x095A, // color of first col
    0x0694, // color of the second col
    0x087D, // color of the third col
    0x0000, // color of the fourth col

    0x095A, // color of first col
    0x0694, // color of the second col
    0x087D, // color of the third col
    0x0000, // color of the fourth col

    0x095A, // color of first col
    0x0694, // color of the second col
    0x087D, // color of the third col
    0x0000, // color of the fourth col
};

// Color sequence palette for perspective back rectangles
static UWORD s_pBarColorsPerspectiveBack2[MAXCOLORS] = {
    0x0733, // color of first col
    0x0463, // color of the second col
    0x0338, // color of the third col
    0x0000, // color of the fourth col

    0x0733, // color of first col
    0x0463, // color of the second col
    0x0338, // color of the third col
    0x0000, // color of the fourth col

    0x0733, // color of first col
    0x0463, // color of the second col
    0x0338, // color of the third col
    0x0000, // color of the fourth col
};

#ifdef STARTWITHBLACKBARS

// Actual Palette for non perspective vertical rectangles - first time they are all black for intro
static UWORD s_pBarColors[MAXCOLORS] = {
    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col

    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col

    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col
};

// Actual Palette for perspective rectangles - first time they are all black for intro
static UWORD s_pBarColorsPerspective[MAXCOLORS] = {
    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col

    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col

    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col
};

// Actual Palette for perspective rectangles - first time they are all black for intro
static UWORD s_pBarColorsPerspectiveBack[MAXCOLORS] = {
    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col

    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col

    0x0000, // color of first col
    0x0000, // color of the second col
    0x0000, // color of the third col
    0x0000, // color of the fourth col
};

#else
static UWORD s_pBarColors[MAXCOLORS] = {
    0x0C87, // color of first col
    0x0AE8, // color of the second col
    0x08BC, // color of the third col 0x08BC
    0x0000, // color of the fourth col

    0x0C87, // color of first col
    0x0AE8, // color of the second col
    0x08BC, // color of the third col
    0x0000, // color of the fourth col

    0x0C87, // color of first col
    0x0AE8, // color of the second col
    0x08BC, // color of the third col
    0x0000, // color of the fourth col
};

// Color sequence palette for perspective rectangles
static UWORD s_pBarColorsPerspective[MAXCOLORS] = {
    0x095A, // color of first col
    0x0694, // color of the second col
    0x087D, // color of the third col
    0x0000, // color of the fourth col

    0x095A, // color of first col
    0x0694, // color of the second col
    0x087D, // color of the third col
    0x0000, // color of the fourth col

    0x095A, // color of first col
    0x0694, // color of the second col
    0x087D, // color of the third col
    0x0000, // color of the fourth col
};

// Color sequence palette for perspective rectangles
static UWORD s_pBarColorsPerspectiveBack[MAXCOLORS] = {
    0x0733, // color of first col
    0x0463, // color of the second col
    0x0338, // color of the third col
    0x0000, // color of the fourth col

    0x0733, // color of first col
    0x0463, // color of the second col
    0x0338, // color of the third col
    0x0000, // color of the fourth col

    0x0733, // color of first col
    0x0463, // color of the second col
    0x0338, // color of the third col
    0x0000, // color of the fourth col
};
#endif

static UBYTE s_ubBarColorsCopPositions[MAXCOLORS];
static UBYTE s_ubBarColorsCopPositionsBorder[MAXCOLORS];
static UBYTE s_ubBarColorsCopPositionsPerspective[MAXCOLORS];
static UBYTE s_ubBarColorsCopPositionsPerspectiveBack[MAXCOLORS];

static UBYTE s_ubColorIndex = 0;

#define SETBARCOLORSFRONTANDBACK                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                         \
    {                                                                                     \
        s_ubBarColorsCopPositions[ubCounter] = ubCopIndex;                                \
        copSetMoveBackAndFront(&g_pCustom->color[ubCounter + 1], getBarColor(ubCounter)); \
    }

#define SETBARCOLORSFRONTANDBACKBORDER                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                         \
    {                                                                                     \
        s_ubBarColorsCopPositionsBorder[ubCounter] = ubCopIndex;                                \
        copSetMoveBackAndFront(&g_pCustom->color[ubCounter + 1], getBarColor(ubCounter)); \
    }

#define SETBARCOLORSFRONTANDBACKPERSPECTIVE                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                         \
    {                                                                                     \
        s_ubBarColorsCopPositionsPerspective[ubCounter] = ubCopIndex;                                \
        copSetMoveBackAndFront(&g_pCustom->color[ubCounter + 1], getBarColorPerspective(ubCounter)); \
    }

#define SETBARCOLORSFRONTANDBACKPERSPECTIVEBACK                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                         \
    {                                                                                     \
        s_ubBarColorsCopPositionsPerspectiveBack[ubCounter] = ubCopIndex;                                \
        copSetMoveBackAndFront(&g_pCustom->color[ubCounter + 1], getBarColorPerspectiveBack(ubCounter)); \
    }

#define SETBARCOLORSBACK                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                 \
    {                                                                             \
        copSetMoveBack(&g_pCustom->color[ubCounter + 1], getBarColor(ubCounter)); \
    }

#define SETBARCOLORSBACKPERSPECTIVE                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                 \
    {                                                                             \
        copSetMoveBack(&g_pCustom->color[ubCounter + 1], getBarColorPerspective(ubCounter)); \
    }

#define SETBARCOLORSBACKPERSPECTIVEBACK                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                 \
    {                                                                             \
        copSetMoveBack(&g_pCustom->color[ubCounter + 1], getBarColorPerspectiveBack(ubCounter)); \
    }

#define PERSECTIVEBARHEIGHT 3
#define PERSPECTIVEBARSNUMBER 12    // How many perspective bars?
#define PERSPECTIVEBARSNUMBERBACK 4 // How many back perspective bars?
#define PERSPECTIVEBLOCKSIZE 7      // how many copper instruction for each perspective block?
typedef struct _tPerspectiveBar
{
    UBYTE ubCopIndex;
    UBYTE pScrollFlags[32];
    UBYTE ubScrollCounter;
    UBYTE pScrollFlags2[32];
    UBYTE ubCopIndex2;
} tPerspectiveBar;

static tPerspectiveBar tPerspectiveBarArray[PERSPECTIVEBARSNUMBER + PERSPECTIVEBARSNUMBERBACK];

UBYTE ubCopIndexFirstLine = 0;

#define INITSCROLLFLAG(var, var0, var1, var2, var3, var4, var5, var6, var7, var8, var9, var10, var11, var12, var13, var14, var15, var16, var17, var18, var19, var20, var21, var22, var23, var24, var25, var26, var27, var28, var29, var30, var31) \
    tPerspectiveBarArray[var].pScrollFlags2[0] = var0;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[1] = var1;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[2] = var2;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[3] = var3;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[4] = var4;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[5] = var5;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[6] = var6;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[7] = var7;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[8] = var8;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[9] = var9;                                                                                                                                                                                            \
    tPerspectiveBarArray[var].pScrollFlags2[10] = var10;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[11] = var11;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[12] = var12;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[13] = var13;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[14] = var14;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[15] = var15;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[16] = var16;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[17] = var17;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[18] = var18;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[19] = var19;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[20] = var20;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[21] = var21;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[22] = var22;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[23] = var23;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[24] = var24;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[25] = var25;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[26] = var26;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[27] = var27;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[28] = var28;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[29] = var29;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[30] = var30;                                                                                                                                                                                          \
    tPerspectiveBarArray[var].pScrollFlags2[31] = var31;

//static UBYTE s_ubPerspectiveBarCopPositions[PERSPECTIVEBARSNUMBER];

//void copyToMainBplFromFast(const unsigned char* pData,const UBYTE ubSlot,const UBYTE ubMaxBitplanes);

void gameGsCreate(void)
{
    ULONG ulRawSize = (SimpleBufferTestGetRawCopperlistInstructionCount(BITPLANES) + 12 + MAXCOLORS*4 + PERSPECTIVEBLOCKSIZE * (PERSPECTIVEBARSNUMBER + PERSPECTIVEBARSNUMBERBACK) + 1
                       /*                   3 * 3 + // 32 bars - each consists of WAIT + 3 MOVE instruction
        1 +     // Final WAIT
        1       // Just to be sure*/
    );

    // Create a view - first arg is always zero, then it's option-value
    s_pView = viewCreate(0,
                         TAG_VIEW_GLOBAL_CLUT, 1, // Same Color LookUp Table for all viewports
                         TAG_VIEW_COPLIST_MODE, VIEW_COPLIST_MODE_RAW,
                         TAG_VIEW_COPLIST_RAW_COUNT, ulRawSize,
                         TAG_END); // Must always end with TAG_END or synonym: TAG_DONE

    // Now let's do the same for main playfield
    s_pVpMain = vPortCreate(0,
                            TAG_VPORT_VIEW, s_pView,
                            TAG_VPORT_BPP, BITPLANES, // 4 bits per pixel, 16 colors
                            // We won't specify height here - viewport will take remaining space.
                            TAG_END);
    s_pMainBuffer = SimpleBufferTestCreate(0,
                                           TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
                                           TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
                                           TAG_SIMPLEBUFFER_BOUND_WIDTH, 320 + 32 * 2,
                                           TAG_SIMPLEBUFFER_USE_X_SCROLLING, 0,
                                           TAG_SIMPLEBUFFER_COPLIST_OFFSET, 0,
                                           TAG_SIMPLEBUFFER_IS_DBLBUF, 0,
                                           TAG_END);

    s_uwCopRawOffs = simpleBufferGetRawCopperlistInstructionCount(BITPLANES);

    /*Enable this in double blf mode
    CopyMemQuick(
        s_pView->pCopList->pBackBfr->pList,
        s_pView->pCopList->pFrontBfr->pList,
        s_pView->pCopList->pBackBfr->uwAllocSize
      );*/

    // Since we've set up global CLUT, palette will be loaded from first viewport
    // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
    s_pVpMain->pPalette[0] = 0x0000; // Background color

    s_pVpMain->pPalette[1] = 0x0888; // Gray
    s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
    s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red
    s_pVpMain->pPalette[4] = 0x0008;

    // Second set of colors
    /* s_pVpMain->pPalette[5] = 0x00FF;
    s_pVpMain->pPalette[6] = 0x00FF;
    s_pVpMain->pPalette[7] = 0x00FF;
    s_pVpMain->pPalette[8] = 0x00FF;

    s_pVpMain->pPalette[9] = 0x0FF0;
    s_pVpMain->pPalette[10] = 0x0FF0;
    s_pVpMain->pPalette[11] = 0x0FF0;
    s_pVpMain->pPalette[12] = 0x0FF0;*/

    // palette for 8 to 15 is for masking entrance and exit
    /*s_pVpMain->pPalette[8] = 0x0000;
    s_pVpMain->pPalette[9] = 0x0000;
    s_pVpMain->pPalette[10] = 0x0000;
    s_pVpMain->pPalette[11] = 0x0000;
    s_pVpMain->pPalette[12] = 0x0000;
    s_pVpMain->pPalette[13] = 0x0000;
    s_pVpMain->pPalette[14] = 0x0000;
    s_pVpMain->pPalette[15] = 0x0000;*/

    // We don't need anything from OS anymore
    systemUnuse();

    //s_pCamera = s_pMainBuffer->pCamera;

    // Draw rectangles

    // Build perspective row function: scheme following
    /*
ColUMN            0   1   2   3        4   5   6   7        8   9   10   11

Bitplane 0 -      1   0   1   0        1   0   1   0        1   0    1    0
Bitplane 1 -      0   1   1   0        0   1   1   0        0   1    1    0
Bitplane 2 -      0   0   0   1        1   1   1   0        0   0    0    1
Bitplane 3 -      0   0   0   0        0   0   0   1        1   1    1    1


*/

    UBYTE *p_ubBitplanePointer;
    UWORD uwRowCounter = 0;

    UBYTE ubContBitplanes = 0;
    while (ubContBitplanes < BITPLANES)
    {

        p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[ubContBitplanes]);
        uwRowCounter = 0;
        while (uwRowCounter < 208)
        {
            UBYTE ubCounter = 0;
            for (ubCounter = 0; ubCounter < 12; ubCounter++)
            {
                UBYTE ubCode = 0xFF;

                //list possibilities for zero
                // Bitplane 0 - set to 0 for 2 3 6 7 10 11
                //if (ubContBitplanes == 0 && (ubCounter == 2 || ubCounter == 3 || ubCounter == 6 || ubCounter == 7 || ubCounter == 10 || ubCounter == 11))
                if (ubContBitplanes == 0 && ubCounter % 2 == 1)
                    ubCode = 0x00;

                // Bitplane 1
                // odd colon must have color code 01
                if (ubContBitplanes == 1 && (ubCounter % 4 == 0 || ubCounter % 4 == 3))
                    ubCode = 0x00;

                //Bitplane 2
                // old else if (ubContBitplanes == 2 && ubCounter % 4 != 3)
                else if (ubContBitplanes == 2 && (ubCounter < 3 || ubCounter == 7 || ubCounter == 8 || ubCounter == 9 || ubCounter == 10))
                    ubCode = 0x00;

                else if (ubContBitplanes == 3 && ubCounter < 7)
                    ubCode = 0x00;

                *p_ubBitplanePointer = ubCode;
                p_ubBitplanePointer++;

                *p_ubBitplanePointer = ubCode;
                p_ubBitplanePointer++;

                if (ubCounter == 1)
                    *p_ubBitplanePointer = ubCode;
                else
                    *p_ubBitplanePointer = ubCode;
                p_ubBitplanePointer++;

                *p_ubBitplanePointer = 0x00;
                p_ubBitplanePointer++;
            }
            uwRowCounter++;
        }
        ubContBitplanes++;
    }

    // Start building/drawing perspective rows
    UWORD uwRowWidth = 25;
    for (UWORD uwCounter = 208; uwCounter < 208 + PERSPECTIVEBARSNUMBER * PERSECTIVEBARHEIGHT; uwCounter++)
    {
        //printPerspectiveRow(s_pMainBuffer, uwCounter, 48, uwRowWidth, 1);
        printPerspectiveRow2(s_pMainBuffer, uwCounter, 48, uwRowWidth);
        if ((uwCounter % PERSECTIVEBARHEIGHT) == 0)
            uwRowWidth += 3;
    }
    uwRowWidth -= 3;
    for (UWORD uwCounter = 244; uwCounter < 244 + PERSPECTIVEBARSNUMBERBACK * PERSECTIVEBARHEIGHT; uwCounter++)
    {
        printPerspectiveRow2(s_pMainBuffer, uwCounter, 48, uwRowWidth - 3);
        if ((uwCounter % PERSECTIVEBARHEIGHT) == 0)
            uwRowWidth -= 3;
    }

    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
    tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];

    UBYTE ubCopIndex = 0;

    copSetWaitBackAndFront(0, 43);

    SETBARCOLORSFRONTANDBACK;

    copSetWaitBackAndFront(0, 200);
    copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);

    ubCopIndex = buildPerspectiveCopperlist(ubCopIndex);

    copSetWaitBackAndFront(7, 43);
    copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);

    // set default velocity to 1
    sg_tVelocity = fix16_div(fix16_from_int(1), fix16_from_int(10));
    sg_tVelocityIncrementer = fix16_div(fix16_from_int(1), fix16_from_int(10));

    // MaskScreen(0);
    // unMaskScreen(36);

    // Load the view
    viewLoad(s_pView);
}

void gameGsLoop(void)
{
#ifdef COLORDEBUG
    g_pCustom->color[0] = 0x00FF0;
#endif
    static BYTE bIsExiting = 0;
    static BYTE bXCamera = 0;
    //static fix16_t bXCamera = 0;
#ifdef AUTOSCROLLING
    static fix16_t tCameraFrame = 0;

    tCameraFrame = fix16_add(tCameraFrame, sg_tVelocity);

    bXCamera = (BYTE)fix16_to_int(tCameraFrame);

    if (bXCamera >= 32)
    {
        bXCamera = 0;
        tCameraFrame = 0;
        s_ubColorIndex++;
        if (s_ubColorIndex >= MAXCOLORS)
            s_ubColorIndex = 0;
    }
    updateCamera2(bXCamera);
#endif

    if (keyCheck(KEY_ESCAPE))
    {
        gameExit();
        return;
    }

    if (keyCheck(KEY_Q))
    {
        bIsExiting = 1;
    }

    if (keyUse(KEY_V))
    {
        bXCamera = 0;
        s_ubColorIndex = 0;
        updateCamera2(bXCamera);
    }
    if (keyUse(KEY_B))
    {
        bXCamera++;

        if (bXCamera >= 32)
        {
            bXCamera = 0;
            s_ubColorIndex++;
            if (s_ubColorIndex >= MAXCOLORS)
                s_ubColorIndex = 0;
        }

        updateCamera2(bXCamera);
        /*if (bXCamera == 0)
          switchCopColors();*/
    }

    if (keyUse(KEY_C))
    {
        bXCamera--;
        if (bXCamera < 0)
            bXCamera = 31;
        updateCamera2(bXCamera);
    }

    if (keyUse(KEY_D))
    {
        tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
        copDumpBfr(pCopBfr);

        pCopBfr = s_pView->pCopList->pFrontBfr;
        copDumpBfr(pCopBfr);
    }

    if (keyUse(KEY_O))
    {
        sg_tVelocity = fix16_add(sg_tVelocity, sg_tVelocityIncrementer);
    }
    if (keyUse(KEY_P))
    {
        if (sg_tVelocity > 0)
            sg_tVelocity = fix16_sub(sg_tVelocity, sg_tVelocityIncrementer);
    }

#ifdef COLORDEBUG
    g_pCustom->color[0] = 0x0000;
#endif

    vPortWaitForEnd(s_pVpMain);

    static BYTE bIntroColorIndex = 11;
    static UBYTE lastBx = 0;
    if (bXCamera > 0)
        lastBx = 1;
    if (bXCamera == 0 && bIntroColorIndex >= 0 && lastBx == 1)
    {
        BYTE bColorIndex = 11 + s_ubColorIndex;
        while (bColorIndex > 11)
            bColorIndex -= 12;
#ifdef ACE_DEBUG
        logWrite("Setting intro color %u to index number %u\n", s_pBarColors2[bColorIndex], bColorIndex);
#endif
        s_pBarColors[bColorIndex] = s_pBarColors2[bColorIndex];
        s_pBarColorsPerspective[bColorIndex] = s_pBarColorsPerspective2[bColorIndex];
        s_pBarColorsPerspectiveBack[bColorIndex] = s_pBarColorsPerspectiveBack2[bColorIndex];
        bIntroColorIndex--;
        lastBx = 0;
    }

    // Manage exit
    static BYTE bExitSequence = 11;
    if (bXCamera == 0 && bIsExiting && lastBx == 1)
    {
        BYTE bColorIndex = 11 + s_ubColorIndex;
        while (bColorIndex > 11)
            bColorIndex -= 12;
        s_pBarColors[bColorIndex] = 0x0000;
        s_pBarColorsPerspective[bColorIndex] = 0x0000;
        s_pBarColorsPerspectiveBack[bColorIndex] = 0x0000;
#ifdef ACE_DEBUG
        logWrite("Setting intro color to zero to index number %u\n", bColorIndex);
#endif

        if (bExitSequence < 0)
        {
            gameExit();
            return;
        }
        bExitSequence--;
        lastBx = 0;
    }
}

void gameGsDestroy(void)
{

    // Cleanup when leaving this gamestate
    systemUse();

    // This will also destroy all associated viewports and viewport managers
    viewDestroy(s_pView);
}

void updateCamera2(BYTE bX)
{
#ifdef ACE_DEBUG
    logWrite("UpdateCamera2 input %u\n", bX);
#endif
    UBYTE ubCopIndex;
    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdList = &pCopList->pBackBfr->pList[s_pMainBuffer->uwCopperOffset];
    tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];

    UWORD uwShift = (16 - (bX & 0xF)) & 0xF;
    uwShift = (uwShift << 4) | uwShift;
#ifdef ACE_DEBUG
    logWrite("UpdateCamera2 shift  %u\n", uwShift);
#endif

    UBYTE isBitplanesShifted = 0;

    ULONG ulPlaneAddr = (ULONG)((ULONG)s_pMainBuffer->pBack->Planes[0]);
    ULONG ulPlaneAddr2 = (ULONG)((ULONG)s_pMainBuffer->pBack->Planes[1]);
    ULONG ulPlaneAddr3 = (ULONG)((ULONG)s_pMainBuffer->pBack->Planes[2]);
    ULONG ulPlaneAddr4 = (ULONG)((ULONG)s_pMainBuffer->pBack->Planes[3]);

    if (bX > 16)
    {
#ifdef ACE_DEBUG
        logWrite("Aggiungo 2\n");
#endif
        ulPlaneAddr += 2;
        ulPlaneAddr2 += 2;
        ulPlaneAddr3 += 2;
        ulPlaneAddr4 += 2;
        isBitplanesShifted = 1;
    }

    // Move the upper vertical bars
    copSetMove(&pCmdList[6].sMove, &g_pBplFetch[0].uwHi, ulPlaneAddr >> 16);
    copSetMove(&pCmdList[7].sMove, &g_pBplFetch[0].uwLo, ulPlaneAddr & 0xFFFF);

    copSetMove(&pCmdList[8].sMove, &g_pBplFetch[1].uwHi, ulPlaneAddr2 >> 16);
    copSetMove(&pCmdList[9].sMove, &g_pBplFetch[1].uwLo, ulPlaneAddr2 & 0xFFFF);

    copSetMove(&pCmdList[10].sMove, &g_pBplFetch[2].uwHi, ulPlaneAddr3 >> 16);
    copSetMove(&pCmdList[11].sMove, &g_pBplFetch[2].uwLo, ulPlaneAddr3 & 0xFFFF);

    copSetMove(&pCmdList[12].sMove, &g_pBplFetch[3].uwHi, ulPlaneAddr4 >> 16);
    copSetMove(&pCmdList[13].sMove, &g_pBplFetch[3].uwLo, ulPlaneAddr4 & 0xFFFF);

    if (bX > 0)
    {
#ifdef ACE_DEBUG
        logWrite("Caso con fetch modificato a 30\n");
#endif
        copSetMove(&pCmdList[2].sMove, &g_pCustom->ddfstrt, 0x0030);
        copSetMove(&pCmdList[3].sMove, &g_pCustom->bpl1mod, 0x0006);
        copSetMove(&pCmdList[4].sMove, &g_pCustom->bpl2mod, 0x0006);
        copSetMove(&pCmdList[5].sMove, &g_pCustom->bplcon1, uwShift);

        // start of perspective
        UWORD uwBplMods = 0x0006;
        UWORD uwShiftPerspective;

#if 0

       
#else

        UBYTE ubLastBplMods = 0;

        // Each perspective row must be modifield in its copperlist block - cycle each of them
        for (UBYTE ubPerspectiveRowCounter = 0; ubPerspectiveRowCounter < PERSPECTIVEBARSNUMBER+PERSPECTIVEBARSNUMBERBACK; ubPerspectiveRowCounter++)
        {
            struct _tPerspectiveBar *tBar = &tPerspectiveBarArray[ubPerspectiveRowCounter];
            struct _tPerspectiveBar *tBarPrev = &tPerspectiveBarArray[ubPerspectiveRowCounter - 1];

            tBar->ubScrollCounter = tBar->pScrollFlags2[bX];
#ifdef ACE_DEBUG
            logWrite("pscrollflags set to %u\n", tBar->ubScrollCounter);
#endif

            // }

            // This will contain the left shift position absolute
            UBYTE ubAbsShift = bX - 1 + tBar->ubScrollCounter;
            if (isBitplanesShifted)
                ubAbsShift = bX - 16 - 1 + tBar->ubScrollCounter;

            // Now we must calculate how many words we are left shifting because eventually we must change bplmods and then the remainder for bplcon1
            UBYTE ubAbsBplMods = ubAbsShift >> 4;
            UBYTE ubAbsRemainder = ubAbsShift % 16;

            // Now it's time to calculate the reg values - to get the new mod we must take into account what was the last mod and subtract it
            // For the bplcon1 we must take FF (max shifting) and subtract for the remainder
            UWORD uwFinalMods = 0x0006 + ubAbsBplMods * 2 - ubLastBplMods;
            UWORD uwFinalBplCon1 = 0x00FF - ubAbsRemainder * 17;

            // Save ubLastBplMods
            ubLastBplMods = ubAbsBplMods * 2;

#ifdef ACE_DEBUG
            logWrite("abs - Processing row %u\n", ubPerspectiveRowCounter);
            logWrite("abs - Ok now we are on position %u so we must absolute shift this perspective bar to the left for %u positions: mods %u and bpl1con to %u\n", bX, ubAbsShift, ubAbsBplMods, ubAbsRemainder);
            logWrite("abs - New registers : mods : %u, bplcon1: %u\n", uwFinalMods, uwFinalBplCon1);
#endif

            copSetMove(&pCmdListBack[0 + tBar->ubCopIndex].sMove, &g_pCustom->bplcon1, uwFinalBplCon1);
            copSetMove(&pCmdListBack[1 + tBar->ubCopIndex].sMove, &g_pCustom->bpl1mod, uwBplMods);
            copSetMove(&pCmdListBack[2 + tBar->ubCopIndex].sMove, &g_pCustom->bpl2mod, uwBplMods);
            if (ubPerspectiveRowCounter > 0)
            {
                /*copSetMove(&pCmdListBack[4 + tBarPrev->ubCopIndex].sMove, &g_pCustom->bpl1mod, uwFinalMods);
                copSetMove(&pCmdListBack[5 + tBarPrev->ubCopIndex].sMove, &g_pCustom->bpl2mod, uwFinalMods);*/

                copSetMove(&pCmdListBack[0 + tBarPrev->ubCopIndex2].sMove, &g_pCustom->bpl1mod, uwFinalMods);
                copSetMove(&pCmdListBack[1 + tBarPrev->ubCopIndex2].sMove, &g_pCustom->bpl2mod, uwFinalMods);
            }
            else
            {
#ifdef ACE_DEBUG
                logWrite("abs - Here i should be moving the first chunk and in am not doing it!!!!!\n");
#endif

                copSetMove(&pCmdListBack[ubCopIndexFirstLine].sMove, &g_pCustom->bpl1mod, uwFinalMods);
                copSetMove(&pCmdListBack[ubCopIndexFirstLine + 1].sMove, &g_pCustom->bpl2mod, uwFinalMods);
            }

            if (0)
            {
                if (uwShift > 0)
                {
                    uwShiftPerspective = uwShift - tBar->ubScrollCounter * 17;
                }
                else
                    uwShiftPerspective = 0;

#ifdef ACE_DEBUG
                logWrite("abs - uwShiftPerspective: %u\n", uwShiftPerspective);
                logWrite("uwModPerspective: %u\n", uwBplMods);
#endif

                // Update copperlist
                //if (s_ubPerspectiveBarCopPositions[1]!=tBarNext->ubCopIndex) gameExit();
                copSetMove(&pCmdListBack[0 + tBar->ubCopIndex].sMove, &g_pCustom->bplcon1, uwShiftPerspective);
                copSetMove(&pCmdListBack[1 + tBar->ubCopIndex].sMove, &g_pCustom->bpl1mod, uwBplMods);
                copSetMove(&pCmdListBack[2 + tBar->ubCopIndex].sMove, &g_pCustom->bpl2mod, uwBplMods);

                
            }
        }
#endif

       
    }
    else
    {
        copSetMove(&pCmdList[2].sMove, &g_pCustom->ddfstrt, 0x0038);
        copSetMove(&pCmdList[3].sMove, &g_pCustom->bpl1mod, 0x0008);
        copSetMove(&pCmdList[4].sMove, &g_pCustom->bpl2mod, 0x0008);
        copSetMove(&pCmdList[5].sMove, &g_pCustom->bplcon1, uwShift);

        for (UBYTE ubPerspectiveRowCounter = 0; ubPerspectiveRowCounter < PERSPECTIVEBARSNUMBER+PERSPECTIVEBARSNUMBERBACK; ubPerspectiveRowCounter++)
        {
            struct _tPerspectiveBar *tBar = &tPerspectiveBarArray[ubPerspectiveRowCounter];
            struct _tPerspectiveBar *tBarPrev = &tPerspectiveBarArray[ubPerspectiveRowCounter - 1];

            copSetMove(&pCmdListBack[0 + tBar->ubCopIndex].sMove, &g_pCustom->bplcon1, 0x0000);
            copSetMove(&pCmdListBack[1 + tBar->ubCopIndex].sMove, &g_pCustom->bpl1mod, 0x0008);
            copSetMove(&pCmdListBack[2 + tBar->ubCopIndex].sMove, &g_pCustom->bpl2mod, 0x0008);

            tPerspectiveBarArray[ubPerspectiveRowCounter].ubScrollCounter = 0;

            if (ubPerspectiveRowCounter > 0)
            {
                /*copSetMove(&pCmdListBack[4 + tBarPrev->ubCopIndex].sMove, &g_pCustom->bpl1mod, 0x0008);
                copSetMove(&pCmdListBack[5 + tBarPrev->ubCopIndex].sMove, &g_pCustom->bpl2mod, 0x0008);*/

                copSetMove(&pCmdListBack[0 + tBarPrev->ubCopIndex2].sMove, &g_pCustom->bpl1mod, 0x0008);
                copSetMove(&pCmdListBack[1 + tBarPrev->ubCopIndex2].sMove, &g_pCustom->bpl2mod, 0x0008);
            }
            else
            {
                copSetMove(&pCmdListBack[ubCopIndexFirstLine].sMove, &g_pCustom->bpl1mod, 0x0008);
                copSetMove(&pCmdListBack[ubCopIndexFirstLine + 1].sMove, &g_pCustom->bpl2mod, 0x0008);
            }
        }
    }

    ubCopIndex = 1; // must be one because at zero we would get wait instruction
    SETBARCOLORSBACK;

    ubCopIndex = s_ubBarColorsCopPositionsBorder[0];
    SETBARCOLORSBACK;

    ubCopIndex = s_ubBarColorsCopPositionsPerspective[0];
    SETBARCOLORSBACKPERSPECTIVE;

    ubCopIndex = s_ubBarColorsCopPositionsPerspectiveBack[0];
    SETBARCOLORSBACKPERSPECTIVEBACK;

    copSwapBuffers();
}

UWORD getBarColor(const UBYTE ubColNo)
{
    UBYTE ubColorRealIndex = ubColNo + s_ubColorIndex;
    while (ubColorRealIndex >= MAXCOLORS)
        ubColorRealIndex -= MAXCOLORS;
    return s_pBarColors[ubColorRealIndex];
}

UWORD getBarColorPerspective(const UBYTE ubColNo)
{
    UBYTE ubColorRealIndex = ubColNo + s_ubColorIndex;
    while (ubColorRealIndex >= MAXCOLORS)
        ubColorRealIndex -= MAXCOLORS;
    return s_pBarColorsPerspective[ubColorRealIndex];
}

UWORD getBarColorPerspectiveBack(const UBYTE ubColNo)
{
    UBYTE ubColorRealIndex = ubColNo + s_ubColorIndex;
    while (ubColorRealIndex >= MAXCOLORS)
        ubColorRealIndex -= MAXCOLORS;
    return s_pBarColorsPerspectiveBack[ubColorRealIndex];
}

// Build perspective row function: scheme following
/*
ColUMN            0   1   2   3        4   5   6   7        8   9   10   11

Bitplane 0 -      1   0   1   0        1   0   1   0        1   0    1    0
Bitplane 1 -      0   1   1   0        0   1   1   0        0   1    1    0
Bitplane 2 -      0   0   0   1        1   1   1   0        0   0    0    1
Bitplane 3 -      0   0   0   0        0   0   0   1        1   1    1    1


*/

void printPerspectiveRow2(tSimpleBufferTestManager *s_pMainBuffer, const UWORD uwRowNo, const UWORD uwBytesPerRow, const UWORD uwBarWidth)
{
#ifdef ACE_DEBUG
    UBYTE ubDebug = 0;
#endif
    typedef struct _tBitplanes
    {
        UBYTE *p_ubBitplaneStartPointer;
        UBYTE *p_ubBitplaneEndPointer;
        UBYTE *p_ubBitplanePointer;
    } tBitplanes;

    tBitplanes bitplanes[BITPLANES];

    //ulValue = 0b00000001 11111111 1111111 111111111 00000000;

    UWORD uwSpaceBetweenCols = 8;

    UBYTE *p_ubBitplane0StartPointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
    UBYTE *p_ubBitplane1StartPointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[1]);
    UBYTE *p_ubBitplane2StartPointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[2]);
    UBYTE *p_ubBitplane3StartPointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[3]);

    p_ubBitplane0StartPointer = p_ubBitplane0StartPointer + uwBytesPerRow * uwRowNo; // vertical position
    UBYTE *p_ubBitplane0Pointer = p_ubBitplane0StartPointer + 4 * 4 + 3;             // go to last byte of 5th  bar

    p_ubBitplane1StartPointer = p_ubBitplane1StartPointer + uwBytesPerRow * uwRowNo; // vertical position
    UBYTE *p_ubBitplane1Pointer = p_ubBitplane1StartPointer + 4 * 4 + 3;             // go to 5th  bar

    p_ubBitplane2StartPointer = p_ubBitplane2StartPointer + uwBytesPerRow * uwRowNo; // vertical position
    UBYTE *p_ubBitplane2Pointer = p_ubBitplane2StartPointer + 4 * 4 + 3;             // go to 5th  bar

    p_ubBitplane3StartPointer = p_ubBitplane3StartPointer + uwBytesPerRow * uwRowNo; // vertical position
    UBYTE *p_ubBitplane3Pointer = p_ubBitplane3StartPointer + 4 * 4 + 3;             // go to 5th  bar

    bitplanes[0].p_ubBitplaneStartPointer = p_ubBitplane0StartPointer;
    bitplanes[0].p_ubBitplaneEndPointer = p_ubBitplane0StartPointer + 48;
    bitplanes[0].p_ubBitplanePointer = p_ubBitplane0Pointer;

    bitplanes[1].p_ubBitplaneStartPointer = p_ubBitplane1StartPointer;
    bitplanes[1].p_ubBitplaneEndPointer = p_ubBitplane1StartPointer + 48;
    bitplanes[1].p_ubBitplanePointer = p_ubBitplane1Pointer;

    bitplanes[2].p_ubBitplaneStartPointer = p_ubBitplane2StartPointer;
    bitplanes[2].p_ubBitplaneEndPointer = p_ubBitplane2StartPointer + 48;
    bitplanes[2].p_ubBitplanePointer = p_ubBitplane2Pointer;

    bitplanes[3].p_ubBitplaneStartPointer = p_ubBitplane3StartPointer;
    bitplanes[3].p_ubBitplaneEndPointer = p_ubBitplane3StartPointer + 48;
    bitplanes[3].p_ubBitplanePointer = p_ubBitplane3Pointer;

    for (UBYTE ubBitplaneCounter = 0; ubBitplaneCounter < BITPLANES; ubBitplaneCounter++)
    {
        UWORD uwSpaceBetweenColsCounter = 0;
        UWORD uwBarWidthCounter = 0;
        BYTE bBytePos = 0;
        UBYTE ubBarCounter = 4;

        // start bitplane 0
        while (bitplanes[ubBitplaneCounter].p_ubBitplanePointer >= bitplanes[ubBitplaneCounter].p_ubBitplaneStartPointer)
        {
            if (uwSpaceBetweenColsCounter < uwSpaceBetweenCols)
            {
#ifdef ACE_DEBUG
                if (ubDebug)
                    logWrite("Setting space (%d-%d-bytepos :%d)\n", uwSpaceBetweenColsCounter, uwSpaceBetweenCols, bBytePos);
#endif

                uwSpaceBetweenColsCounter++;
                bBytePos++;
                if (bBytePos >= 8)
                {
                    bBytePos = 0;
                    bitplanes[ubBitplaneCounter].p_ubBitplanePointer--;
#ifdef ACE_DEBUG
                    if (ubDebug)
                        logWrite("Byte ended!!! decrementing p_ubBitplane0Pointer\n");
#endif
                }
            }
            else
            {
                // Actual colum writing
                if (uwBarWidthCounter < uwBarWidth)
                {
#ifdef ACE_DEBUG
                    if (ubDebug)
                        logWrite("Setting bar (%d-%d-bytepos :%d)\n", uwBarWidthCounter, uwBarWidth, bBytePos);
#endif
                    // Column (starting at 4)    0   1   2   3        4
                    // Bitplane 0 -              1   0   1   0        1   0   1   0        1   0    1    0
                    if (ubBitplaneCounter == 0)
                    {
                        if ((ubBarCounter % 2) == 0)
                            *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                    }

                    // Column (starting at 4)    0   1   2   3        4
                    // Bitplane 1 -              0   1   1   0        0   1   1   0        0   1    1    0
                    else if (ubBitplaneCounter == 1)
                    {
                        if ((ubBarCounter % 4) == 1 || (ubBarCounter % 4) == 2)
                            *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                    }

                    // Column (starting at 4)    0   1   2   3        4
                    // Bitplane 2 -              0   0   0   1        1   1   1   0        0   0    0    1
                    else if (ubBitplaneCounter == 2)
                    {
                        if (ubBarCounter >= 3)
                            *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                    }

                    // Column (starting at 4)    0   1   2   3        4
                    // Bitplane 3 -      0   0   0   0        0   0   0   1        1   1    1    1
                    else if (ubBitplaneCounter == 3)
                    {
                        // we never have to paint something here
                    }

                    bBytePos++;
                    if (bBytePos >= 8)
                    {
                        bBytePos = 0;
                        bitplanes[ubBitplaneCounter].p_ubBitplanePointer--;
#ifdef ACE_DEBUG
                        if (ubDebug)
                            logWrite("Byte ended!!! decrementing p_ubBitplane0Pointer\n");
#endif
                    }

                    uwBarWidthCounter++;
                }
                else
                {
#ifdef ACE_DEBUG
                    if (ubDebug)
                        logWrite("Bar cycle ended, resetting counters and incrementing the wait space\n");
#endif
                    uwSpaceBetweenColsCounter = 0;
                    uwBarWidthCounter = 0;
                    uwSpaceBetweenCols = 8;
                    ubBarCounter--;
                }
            }
            // Compose the byte
        }

// start of the right part of the screen
// restore pointers
#ifdef ACE_DEBUG
        if (ubDebug)
            logWrite("Start right side... repositioning\n");
#endif
        bitplanes[ubBitplaneCounter].p_ubBitplanePointer = bitplanes[ubBitplaneCounter].p_ubBitplaneStartPointer + 4 * 5;
        uwSpaceBetweenColsCounter = 0;
        uwBarWidthCounter = 0;
        uwSpaceBetweenCols = 8;
        ubBarCounter = 5;
        bBytePos = 7;

        while (bitplanes[ubBitplaneCounter].p_ubBitplanePointer < bitplanes[ubBitplaneCounter].p_ubBitplaneEndPointer)
        {

            if (uwBarWidthCounter < uwBarWidth)
            {
#ifdef ACE_DEBUG
                if (ubDebug)
                    logWrite("Setting bar (%d-%d-bytepos :%d)\n", uwBarWidthCounter, uwBarWidth, bBytePos);
#endif
                // Column (starting at 5)                             5   6   7        8   9   10   11
                // Bitplane 0 -              1   0   1   0        1   0   1   0        1   0    1    0
                if (ubBitplaneCounter == 0)
                {
                    if ((ubBarCounter % 2) == 0)
                        *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                }

                // Column (starting at 5)                             5   6   7        8   9   10   11
                // Bitplane 1 -              0   1   1   0        0   1   1   0        0   1    1    0
                else if (ubBitplaneCounter == 1)
                {
                    if ((ubBarCounter % 4) == 1 || (ubBarCounter % 4) == 2)
                        *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                }

                // Column (starting at 5)                             5   6   7        8   9   10   11
                // Bitplane 2 -              0   0   0   1        1   1   1   0        0   0    0    1
                else if (ubBitplaneCounter == 2)
                {
                    if (ubBarCounter == 5 || ubBarCounter == 6 || ubBarCounter == 11)
                        *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                }

                // Column (starting at 5)                             5   6   7        8   9   10   11
                // Bitplane 3 -              0   0   0   0        0   0   0   1        1   1    1    1
                else if (ubBitplaneCounter == 3)
                {
                    if (ubBarCounter >= 7)
                        *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                }

                bBytePos--;
                if (bBytePos < 0)
                {
                    bBytePos = 7;
                    bitplanes[ubBitplaneCounter].p_ubBitplanePointer++;
#ifdef ACE_DEBUG
                    if (ubDebug)
                        logWrite("Byte ended!!! incrementing p_ubBitplane0Pointer\n");
#endif
                }

                uwBarWidthCounter++;
            }
            else
            {
                if (uwSpaceBetweenColsCounter < uwSpaceBetweenCols)
                {
#ifdef ACE_DEBUG
                    if (ubDebug)
                        logWrite("Setting space (%d-%d-bytepos :%d)\n", uwSpaceBetweenColsCounter, uwSpaceBetweenCols, bBytePos);
#endif

                    uwSpaceBetweenColsCounter++;
                    bBytePos--;
                    if (bBytePos < 0)
                    {
                        bBytePos = 7;
                        bitplanes[ubBitplaneCounter].p_ubBitplanePointer++;
#ifdef ACE_DEBUG
                        if (ubDebug)
                            logWrite("Byte ended!!! incrementing p_ubBitplane0Pointer\n");
#endif
                    }
                }
                else
                {
#ifdef ACE_DEBUG
                    if (ubDebug)
                        logWrite("Bar cycle ended, resetting counters and incrementing the wait space\n");
#endif
                    uwSpaceBetweenColsCounter = 0;
                    uwBarWidthCounter = 0;
                    uwSpaceBetweenCols = 8;
                    ubBarCounter++;
                }
            }
        }
    }
}

// Build the tPerspectiveBarArray array to manage the copperlist
UBYTE buildPerspectiveCopperlist(UBYTE ubCopIndex)
{
    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
    tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];

    UBYTE ubWaitCount = 0;
    UBYTE ubSpecialWaitSet = 0;

    copSetWaitBackAndFront(0, 209 + 43 + ubWaitCount - 1);

    // Change palette for perspective rows
    SETBARCOLORSFRONTANDBACKPERSPECTIVE

    ubCopIndexFirstLine = ubCopIndex;
    copSetMoveBackAndFront(&g_pCustom->color[15], 0x0000);
    copSetMoveBackAndFront(&g_pCustom->color[15], 0x0000);

    for (UBYTE ubCount = 0; ubCount < PERSPECTIVEBARSNUMBER + PERSPECTIVEBARSNUMBERBACK; ubCount++)
    {
#ifdef ACE_DEBUG
        logWrite("setting wait for row %u\n", 209 + 43 + ubWaitCount);
#endif
        copSetWaitBackAndFront(0, 209 + 43 + ubWaitCount);

        //s_ubPerspectiveBarCopPositions[ubCount] = ubCopIndex;
        tPerspectiveBarArray[ubCount].ubCopIndex = ubCopIndex;
        tPerspectiveBarArray[ubCount].ubScrollCounter = 0;

        copSetMoveBackAndFront(&g_pCustom->bplcon1, 0x0000);
        copSetMoveBackAndFront(&g_pCustom->bpl1mod, 0x0008);
        copSetMoveBackAndFront(&g_pCustom->bpl2mod, 0x0008);

        // test di oggi
        if (ubCount == PERSPECTIVEBARSNUMBER-2)
        { 
            #ifdef ACE_DEBUG
            logWrite("setting palette change for border at %u \n",ubCount);
#endif

            // Change palette for perspective back rows
            SETBARCOLORSFRONTANDBACKBORDER
        }
        // fine test di oggi

        if (ubCount == PERSPECTIVEBARSNUMBER-1)
        { 
            #ifdef ACE_DEBUG
            logWrite("setting palette change for back at %u \n",ubCount);
#endif

            // Change palette for perspective back rows
            SETBARCOLORSFRONTANDBACKPERSPECTIVEBACK
        }


        if (209 + 43 + ubWaitCount + PERSECTIVEBARHEIGHT - 1 > 255 && ubSpecialWaitSet == 0)
        {
#ifdef ACE_DEBUG
            logWrite("setting special wait to go under 255 (1) \n");
#endif
            copSetWaitBackAndFront(0xdf, 0xff);
            ubSpecialWaitSet = 1;
        }

        UWORD uwLastWait = 209 + 43 + ubWaitCount + PERSECTIVEBARHEIGHT - 1;
        copSetWaitBackAndFront(0, uwLastWait);
#ifdef ACE_DEBUG
        logWrite("setting copperlist last row with wait %u (%u) \n", uwLastWait, ubWaitCount);
#endif

        if ((ubCount % 2) == 0)
        {

            tPerspectiveBarArray[ubCount].ubCopIndex2 = ubCopIndex;

            copSetMoveBackAndFront(&g_pCustom->color[0], 0x0888);
            copSetMoveBackAndFront(&g_pCustom->color[0], 0x0888);
        }
        else
        {
            tPerspectiveBarArray[ubCount].ubCopIndex2 = ubCopIndex;

            copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);
            copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);
        }
        if (209 + 43 + ubWaitCount > 255 - PERSECTIVEBARHEIGHT && ubSpecialWaitSet == 0)
        {
#ifdef ACE_DEBUG
            logWrite("setting special wait to go under 255 (2)\n");
#endif
            copSetWaitBackAndFront(0xdf, 0xff);
            ubSpecialWaitSet = 1;
        }

        ubWaitCount += PERSECTIVEBARHEIGHT;
    }

    INITSCROLLFLAG(0,
                   0, 0, 0, 0, 0, 0, 0, 0,
                   0, 0, 0, 0, 0, 0, 0, 0,
                   1, 1, 1, 1, 1, 1, 1, 1,
                   1, 1, 1, 1, 1, 1, 1, 1);

    INITSCROLLFLAG(1,
                   0, 0, 0, 0, 0, 0, 1, 1,
                   1, 1, 1, 1, 1, 1, 1, 2,
                   2, 2, 2, 2, 2, 2, 2, 2,
                   2, 2, 2, 2, 4, 4, 4, 4);

    INITSCROLLFLAG(2,
                   0, 0, 0, 1, 1, 1, 1, 1,
                   1, 2, 2, 2, 2, 2, 3, 3,
                   4, 3, 4, 4, 4, 4, 4, 4,
                   4, 5, 5, 5, 6, 8, 8, 8);

    INITSCROLLFLAG(3,
                   0, 0, 1, 1, 1, 1, 2, 2,
                   2, 2, 3, 3, 3, 4, 4, 4,
                   5, 5, 5, 6, 6, 6, 6, 6,
                   7, 7, 7, 8, 9, 10, 10, 10);

    INITSCROLLFLAG(4,
                   0, 0, 1, 1, 1, 2, 2, 3,
                   3, 3, 4, 4, 4, 5, 5, 6,
                   6, 6, 8, 8, 8, 8, 8, 9,
                   9, 10, 11, 10, 12, 13, 13, 14);

    INITSCROLLFLAG(5,
                   0, 0, 1, 1, 2, 2, 3, 3,
                   4, 4, 5, 5, 5, 6, 6, 7,
                   7, 8, 9, 9, 10, 10, 11, 11,
                   11, 12, 13, 13, 14, 15, 16, 17);

    INITSCROLLFLAG(6,
                   0, 1, 1, 2, 2, 3, 3, 4,
                   4, 5, 6, 6, 7, 7, 8, 8,
                   9, 10, 11, 11, 12, 13, 13, 13,
                   14, 14, 16, 16, 17, 18, 19, 20);

    INITSCROLLFLAG(7,
                   0, 1, 1, 2, 3, 3, 4, 4,
                   5, 6, 6, 7, 8, 8, 9, 10,
                   10, 11, 13, 13, 14, 15, 15, 16,
                   16, 17, 19, 18, 20, 21, 22, 23);

    INITSCROLLFLAG(8,
                   0, 1, 1, 2, 3, 4, 4, 5,
                   6, 7, 7, 8, 9, 10, 10, 11,
                   12, 13, 14, 15, 16, 17, 18, 19,
                   19, 19, 21, 21, 22, 23, 24, 25);

    INITSCROLLFLAG(9,
                   0, 1, 2, 2, 3, 4, 5, 6,
                   7, 7, 8, 9, 10, 11, 12, 12,
                   13, 14, 16, 17, 18, 19, 20, 21,
                   21, 22, 24, 24, 25, 26, 27, 28);

    INITSCROLLFLAG(10,
                   0, 1, 2, 3, 4, 5, 5, 6,
                   7, 8, 9, 10, 11, 12, 13, 15,
                   15, 16, 18, 19, 20, 21, 22, 23,
                   23, 25, 26, 26, 28, 29, 30, 31);

    INITSCROLLFLAG(11,
                   0, 1, 2, 3, 4, 5, 6, 7,
                   8, 9, 10, 11, 12, 13, 14, 16,
                   16, 17, 19, 20, 22, 23, 24, 25,
                   25, 27, 28, 29, 30, 31, 32, 33);

    //Here starts back perspective

    INITSCROLLFLAG(12,
                   0, 1, 2, 3, 4, 5, 5, 6,
                   7, 8, 9, 10, 11, 12, 13, 15,
                   15, 16, 18, 19, 20, 21, 22, 23,
                   23, 25, 26, 26, 28, 29, 30, 31);

    INITSCROLLFLAG(13,
                   0, 1, 2, 2, 3, 4, 5, 6,
                   7, 7, 8, 9, 10, 11, 12, 12,
                   13, 14, 16, 17, 18, 19, 20, 21,
                   21, 22, 24, 24, 25, 26, 27, 28);

    INITSCROLLFLAG(14,
                   0, 1, 1, 2, 3, 4, 4, 5,
                   6, 7, 7, 8, 9, 10, 10, 11,
                   12, 13, 14, 15, 16, 17, 18, 19,
                   19, 19, 21, 21, 22, 23, 24, 25);

    INITSCROLLFLAG(15,
                   0, 1, 1, 2, 3, 3, 4, 4,
                   5, 6, 6, 7, 8, 8, 9, 10,
                   10, 11, 13, 13, 14, 15, 15, 16,
                   16, 17, 19, 18, 20, 21, 22, 23);

    return ubCopIndex;
}

// Mask the 4th bitplane filling with 0xFF
void MaskScreen(UBYTE ubOffset)
{
    UWORD uwMask = 0x3414 - ubOffset;
    blitWait();
    g_pCustom->bltcon0 = 0x01FF;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = 0x0008;
    //g_pCustom->bltapt = (UBYTE*)((ULONG)&pData[40*224*ubBitplaneCounter]);
    g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[3]);
    g_pCustom->bltsize = uwMask;
    return;
}

// Mask the 4th bitplane filling with 0xFF
void unMaskScreen(UBYTE ubMask)
{
    blitWait();
    g_pCustom->bltcon0 = 0x0100;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = 0x002C;
    //g_pCustom->bltapt = (UBYTE*)((ULONG)&pData[40*224*ubBitplaneCounter]);
    g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[3] + ubMask);
    g_pCustom->bltsize = 0x3402;
    return;
}
UBYTE unMaskIntro(UBYTE bXCamera, UBYTE ubCmp)
{
    static UBYTE lastBx = 0;
    static UBYTE ubMask = 38;

    if (lastBx == bXCamera)
        return 0;
    lastBx = bXCamera;

    if (bXCamera == ubCmp)
    {
        unMaskScreen(ubMask);
        if (ubMask == 0)
            return 1;
        ubMask -= 2;
    }
    return 0;
}
