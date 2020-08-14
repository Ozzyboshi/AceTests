#include "goatlight.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>                  // for blitwait
#include <fixmath/fix16.h>

#include "simplebuffertest.h"

//#define COLORDEBUG
#define AUTOSCROLLING
#define BITPLANES 3 // 3 bitplanes

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

static unsigned char *s_pMusic;

//void updateCamera(UBYTE);
void updateCamera2(BYTE);
UWORD getBarColor(const UBYTE);
void MaskScreen();
void unMaskScreen();
void printPerspectiveRow(tSimpleBufferTestManager *s_pMainBuffer, const UWORD, const UWORD, const UWORD, const UWORD);
UBYTE buildPerspectiveCopperlist(UBYTE);

#define MAXCOLORS 4

static UWORD s_pBarColors[MAXCOLORS] = {
    0x0F00, // color of first col

    0x00F0, // color of the second col
    0x000F, // color of the third col
    0x0000, // color of the fourth col
};

static UBYTE s_ubBarColorsCopPositions[MAXCOLORS];

static UBYTE s_ubColorIndex = 0;

#define SETBARCOLORSFRONTANDBACK                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                         \
    {                                                                                     \
        s_ubBarColorsCopPositions[ubCounter] = ubCopIndex;                                \
        copSetMoveBackAndFront(&g_pCustom->color[ubCounter + 1], getBarColor(ubCounter)); \
    }

#define SETBARCOLORSBACK                                                          \
    for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                 \
    {                                                                             \
        copSetMoveBack(&g_pCustom->color[ubCounter + 1], getBarColor(ubCounter)); \
    }

#define PERSECTIVEBARHEIGHT 3
#define PERSPECTIVEBARSNUMBER 12 // How many perspective bars?
#define PERSPECTIVEBLOCKSIZE 7   // how many copper instruction for each perspective block?
typedef struct _tPerspectiveBar
{
    UBYTE ubCopIndex;
    UBYTE pScrollFlags[32];
    UBYTE ubScrollCounter;
    UBYTE pScrollFlags2[32];
    UBYTE ubCopIndex2;
} tPerspectiveBar;

static tPerspectiveBar tPerspectiveBarArray[PERSPECTIVEBARSNUMBER];

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

static UBYTE s_ubPerspectiveBarCopPositions[PERSPECTIVEBARSNUMBER];

//void copyToMainBplFromFast(const unsigned char* pData,const UBYTE ubSlot,const UBYTE ubMaxBitplanes);

void gameGsCreate(void)
{
    ULONG ulRawSize = (SimpleBufferTestGetRawCopperlistInstructionCount(BITPLANES) + 11 + PERSPECTIVEBLOCKSIZE * PERSPECTIVEBARSNUMBER + 1
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
    s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
    s_pVpMain->pPalette[1] = 0x0888; // Gray
    s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
    s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red

    // palette for 8 to 15 is for masking entrance and exit
    /*s_pVpMain->pPalette[8] = 0x0FF0;
    s_pVpMain->pPalette[9] = 0x0FF0;
    s_pVpMain->pPalette[10] = 0x0FF0;
    s_pVpMain->pPalette[11] = 0x0FF0;
    s_pVpMain->pPalette[12] = 0x0FF0;
    s_pVpMain->pPalette[13] = 0x0FF0;
    s_pVpMain->pPalette[14] = 0x0FF0;
    s_pVpMain->pPalette[15] = 0x0FF0;*/

    // We don't need anything from OS anymore
    systemUnuse();

    //s_pCamera = s_pMainBuffer->pCamera;

    // Draw rectangles

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
                //else if (ubContBitplanes == 1 && ubCounter % 2 == 1)
                if (ubContBitplanes == 1 && (ubCounter % 4 == 0 || ubCounter % 4 == 3))
                    ubCode = 0x00;

                //Bitplane 2
                else if (ubContBitplanes == 2 && ubCounter % 4 != 3)
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
        printPerspectiveRow(s_pMainBuffer, uwCounter, 48, uwRowWidth, 1);
        if ((uwCounter % PERSECTIVEBARHEIGHT) == 0)
            uwRowWidth += 3;
    }

    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
    tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];

    UBYTE ubCopIndex = 0;

    /*copSetWait(&pCmdListBack[0].sWait, 0, 43);
    copSetMove(&pCmdListBack[1].sMove, &g_pCustom->color[1], s_pBarColors[s_ubColorIndex+0]);
    copSetMove(&pCmdListBack[2].sMove, &g_pCustom->color[2], s_pBarColors[s_ubColorIndex+1]);
    copSetMove(&pCmdListBack[3].sMove, &g_pCustom->color[3], s_pBarColors[s_ubColorIndex+2]);*/

    copSetWaitBackAndFront(0, 43);

    SETBARCOLORSFRONTANDBACK;

    copSetWaitBackAndFront(0, 200);
    copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);

    ubCopIndex = buildPerspectiveCopperlist(ubCopIndex);

    copSetWaitBackAndFront(0, 43);
    copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);

    // set default velocity to 1
    sg_tVelocity = fix16_div(fix16_from_int(1), fix16_from_int(10));
    sg_tVelocityIncrementer = fix16_div(fix16_from_int(1), fix16_from_int(10));

    // Load the view
    viewLoad(s_pView);
}

void gameGsLoop(void)
{
#ifdef COLORDEBUG
    g_pCustom->color[0] = 0x00FF0;
#endif

    static BYTE bXCamera = 0;
    //static fix16_t bXCamera = 0;
#ifdef AUTOSCROLLING
    static fix16_t tCameraFrame = 0;

    /*bXCamera++;
    bXCamera++;
    bXCamera++;*/

    tCameraFrame = fix16_add(tCameraFrame, sg_tVelocity);

    bXCamera = (BYTE)fix16_to_int(tCameraFrame);

    if (bXCamera >= 32)
    {
        /*tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
      tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
      tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];
        s_ubColorIndex++;
        if (s_ubColorIndex>=MAXCOLORS) s_ubColorIndex=0;
          UBYTE ubCopIndex = s_ubBarColorsCopPositions[0];
          copSetMoveBackAndFront(&g_pCustom->color[1], getBarColor(0));
          ubCopIndex = s_ubBarColorsCopPositions[1];
          copSetMoveBackAndFront(&g_pCustom->color[3], getBarColor(1));*/
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
            //switchCopColors();
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
        if (bXCamera<0) bXCamera = 31;
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

    /*if (keyUse(KEY_M)) 
    {
        static UBYTE ubMasked = 0;
        if (ubMasked==0)
        {
            MaskScreen();
            ubMasked = 1;
        }
        else
        {
            unMaskScreen();
            ubMasked = 0;
        }
    }*/

#ifdef COLORDEBUG
    g_pCustom->color[0] = 0x0000;
#endif

    vPortWaitForEnd(s_pVpMain);

    //if (!bXCamera) switchCopColors();
}

void gameGsDestroy(void)
{

    FreeMem(s_pMusic, 48 * 256);

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
    //ULONG ulPlaneAddr = (ULONG)s_pMusic;

    UBYTE isBitplanesShifted = 0;

    ULONG ulPlaneAddr = (ULONG)((ULONG)s_pMainBuffer->pBack->Planes[0]);
    ULONG ulPlaneAddr2 = (ULONG)((ULONG)s_pMainBuffer->pBack->Planes[1]);
    ULONG ulPlaneAddr3 = (ULONG)((ULONG)s_pMainBuffer->pBack->Planes[2]);

    if (bX > 16)
    {
#ifdef ACE_DEBUG
        logWrite("Aggiungo 2\n");
#endif
        ulPlaneAddr += 2;
        ulPlaneAddr2 += 2;
        ulPlaneAddr3 += 2;
        isBitplanesShifted = 1;
    }

    // Move the upper vertical bars
    copSetMove(&pCmdList[6].sMove, &g_pBplFetch[0].uwHi, ulPlaneAddr >> 16);
    copSetMove(&pCmdList[7].sMove, &g_pBplFetch[0].uwLo, ulPlaneAddr & 0xFFFF);

    copSetMove(&pCmdList[8].sMove, &g_pBplFetch[1].uwHi, ulPlaneAddr2 >> 16);
    copSetMove(&pCmdList[9].sMove, &g_pBplFetch[1].uwLo, ulPlaneAddr2 & 0xFFFF);

    copSetMove(&pCmdList[10].sMove, &g_pBplFetch[2].uwHi, ulPlaneAddr3 >> 16);
    copSetMove(&pCmdList[11].sMove, &g_pBplFetch[2].uwLo, ulPlaneAddr3 & 0xFFFF);

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

        //alessio = bX;
        if (bX == 16)
            alessio++;

        if (alessio >= 25)
        {
            static UWORD uwShiftPerspectiveTmp;
            if (alessio == 25)
                uwShiftPerspectiveTmp = 0x00EE;
            else
                uwShiftPerspectiveTmp -= 34;
            uwBplMods += 4;
            uwShiftPerspective = uwShiftPerspectiveTmp;
        }

        else if (alessio >= 17)
        {
            static UWORD uwShiftPerspectiveTmp;
            if (alessio == 17)
                uwShiftPerspectiveTmp = 0x00EE;
            else
                uwShiftPerspectiveTmp -= 34;
            uwBplMods += 3;
            uwShiftPerspective = uwShiftPerspectiveTmp;
        }

        else if (alessio >= 9)
        {
            static UWORD uwShiftPerspectiveTmp;
            if (alessio == 9)
                uwShiftPerspectiveTmp = 0x00EE;
            else
                uwShiftPerspectiveTmp -= 34;

            uwBplMods += 2;

            uwShiftPerspective = uwShiftPerspectiveTmp;
        }

        else
        {
            if (uwShift > 0)
                uwShiftPerspective = uwShift - alessio * 17;
            else
                uwShiftPerspective = uwShift;
        }
#else

        UBYTE ubLastBplMods = 0;

        // Each perspective row must be modifield in its copperlist block - cycle each of them
        for (UBYTE ubPerspectiveRowCounter = 0; ubPerspectiveRowCounter < PERSPECTIVEBARSNUMBER; ubPerspectiveRowCounter++)
        {
            struct _tPerspectiveBar *tBar = &tPerspectiveBarArray[ubPerspectiveRowCounter];
            struct _tPerspectiveBar *tBarPrev = &tPerspectiveBarArray[ubPerspectiveRowCounter - 1];

            // Check if the row has to be updated
            if (tBar->pScrollFlags[bX])
            {
                tBar->ubScrollCounter++;
#ifdef ACE_DEBUG
                logWrite("Row %u has to be updated for bX %d - incrementing its counter to %u\n", ubPerspectiveRowCounter, bX, tBar->ubScrollCounter);
#endif
            }
            else
            {
#ifdef ACE_DEBUG
                logWrite("Row %u has NOT to be updated for bX %d - counter still at %u\n", ubPerspectiveRowCounter, bX, tBar->ubScrollCounter);
#endif
            }
            //if (ubPerspectiveRowCounter == 0) {
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
                logWrite("alessio: %u\n", alessio);
#endif

                // Update copperlist
                //if (s_ubPerspectiveBarCopPositions[1]!=tBarNext->ubCopIndex) gameExit();
                copSetMove(&pCmdListBack[0 + tBar->ubCopIndex].sMove, &g_pCustom->bplcon1, uwShiftPerspective);
                copSetMove(&pCmdListBack[1 + tBar->ubCopIndex].sMove, &g_pCustom->bpl1mod, uwBplMods);
                copSetMove(&pCmdListBack[2 + tBar->ubCopIndex].sMove, &g_pCustom->bpl2mod, uwBplMods);

                /*if (speciale)
                {
                    uwIndexModReset = 4 + tBarPrev->ubCopIndex;
                    #ifdef ACE_DEBUG
                    logWrite("Special mode activated saving %u\n", uwIndexModReset);
                    #endif

                    copSetMove(&pCmdListBack[5 + tBarPrev->ubCopIndex].sMove, &g_pCustom->bpl1mod, uwBplMods+2);
                    copSetMove(&pCmdListBack[4 + tBarPrev->ubCopIndex].sMove, &g_pCustom->bpl2mod, uwBplMods+2);
                }
                /*else if (ubPerspectiveRowCounter>0)
                {
                    copSetMove(&pCmdListBack[5 + tBarPrev->ubCopIndex].sMove, &g_pCustom->bpl1mod, uwBplMods);
                    copSetMove(&pCmdListBack[4 + tBarPrev->ubCopIndex].sMove, &g_pCustom->bpl2mod, uwBplMods);
                }*/
            }
        }
#endif

        /*copSetMove(&pCmdListBack[0 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, uwShiftPerspective);
        copSetMove(&pCmdListBack[1 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, uwBplMods);
        copSetMove(&pCmdListBack[2 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, uwBplMods);*/

        //uwShiftPerspective=0x00FF;

        /*copSetMove(&pCmdListBack[5 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, uwShiftPerspective);
        copSetMove(&pCmdListBack[6 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, 0x0006);
        copSetMove(&pCmdListBack[7 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, 0x0006);

        copSetMove(&pCmdListBack[10 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, uwShiftPerspective);
        copSetMove(&pCmdListBack[11 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, 0x0006);
        copSetMove(&pCmdListBack[12 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, 0x0006);*/

        //alessio++;
    }
    else
    {
        copSetMove(&pCmdList[2].sMove, &g_pCustom->ddfstrt, 0x0038);
        copSetMove(&pCmdList[3].sMove, &g_pCustom->bpl1mod, 0x0008);
        copSetMove(&pCmdList[4].sMove, &g_pCustom->bpl2mod, 0x0008);
        copSetMove(&pCmdList[5].sMove, &g_pCustom->bplcon1, uwShift);

        for (UBYTE ubPerspectiveRowCounter = 0; ubPerspectiveRowCounter < PERSPECTIVEBARSNUMBER; ubPerspectiveRowCounter++)
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

    copSwapBuffers();
}

UWORD getBarColor(const UBYTE ubColNo)
{
    UBYTE ubColorRealIndex = ubColNo + s_ubColorIndex;
    while (ubColorRealIndex >= MAXCOLORS)
        ubColorRealIndex -= MAXCOLORS;
    return s_pBarColors[ubColorRealIndex];
}
#if 0
void switchCopColors()
{
    return;
#ifdef ACE_DEBUG

    logWrite("switching colors..\n");
#endif
    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
    tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];
    s_ubColorIndex++;
    if (s_ubColorIndex >= MAXCOLORS)
        s_ubColorIndex = 0;
    UBYTE ubCopIndex = s_ubBarColorsCopPositions[0];
    copSetMoveBackAndFront(&g_pCustom->color[1], getBarColor(0));
    ubCopIndex = s_ubBarColorsCopPositions[1];
    copSetMoveBackAndFront(&g_pCustom->color[3], getBarColor(1));
    //copSwapBuffers();
}
#endif

void printPerspectiveRow(tSimpleBufferTestManager *s_pMainBuffer, const UWORD uwRowNo, const UWORD uwBytesPerRow, const UWORD uwBarWidth, const UWORD uwSpeed)
{
    const UBYTE ubDebug = 0;
    typedef struct _tBitplanes
    {
        UBYTE *p_ubBitplaneStartPointer;
        UBYTE *p_ubBitplaneEndPointer;
        UBYTE *p_ubBitplanePointer;
    } tBitplanes;

    tBitplanes bitplanes[3];

    //ulValue = 0b00000001 11111111 1111111 111111111 00000000;

    UWORD uwSpaceBetweenCols = 8;

    UBYTE *p_ubBitplane0StartPointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
    UBYTE *p_ubBitplane1StartPointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[1]);
    UBYTE *p_ubBitplane2StartPointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[2]);

    p_ubBitplane0StartPointer = p_ubBitplane0StartPointer + uwBytesPerRow * uwRowNo; // vertical position
    UBYTE *p_ubBitplane0Pointer = p_ubBitplane0StartPointer + 4 * 4 + 3;             // go to last byte of 5th  bar

    p_ubBitplane1StartPointer = p_ubBitplane1StartPointer + uwBytesPerRow * uwRowNo; // vertical position
    UBYTE *p_ubBitplane1Pointer = p_ubBitplane1StartPointer + 4 * 4 + 3;             // go to 5th  bar

    p_ubBitplane2StartPointer = p_ubBitplane2StartPointer + uwBytesPerRow * uwRowNo; // vertical position
    UBYTE *p_ubBitplane2Pointer = p_ubBitplane2StartPointer + 4 * 4 + 3;             // go to 5th  bar

    bitplanes[0].p_ubBitplaneStartPointer = p_ubBitplane0StartPointer;
    bitplanes[0].p_ubBitplaneEndPointer = p_ubBitplane0StartPointer + 48;
    bitplanes[0].p_ubBitplanePointer = p_ubBitplane0Pointer;

    bitplanes[1].p_ubBitplaneStartPointer = p_ubBitplane1StartPointer;
    bitplanes[1].p_ubBitplaneEndPointer = p_ubBitplane1StartPointer + 48;
    bitplanes[1].p_ubBitplanePointer = p_ubBitplane1Pointer;

    bitplanes[2].p_ubBitplaneStartPointer = p_ubBitplane2StartPointer;
    bitplanes[2].p_ubBitplaneEndPointer = p_ubBitplane2StartPointer + 48;
    bitplanes[2].p_ubBitplanePointer = p_ubBitplane2Pointer;

    for (UBYTE ubBitplaneCounter = 0; ubBitplaneCounter < 3; ubBitplaneCounter++)
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
                if (uwBarWidthCounter < uwBarWidth)
                {
#ifdef ACE_DEBUG
                    if (ubDebug)
                        logWrite("Setting bar (%d-%d-bytepos :%d)\n", uwBarWidthCounter, uwBarWidth, bBytePos);
#endif
                    if (ubBitplaneCounter == 0)
                    {
                        if ((ubBarCounter % 2) == 0)
                            *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                    }
                    else if (ubBitplaneCounter == 1)
                    {
                        if ((ubBarCounter % 4) == 1 || (ubBarCounter % 4) == 2)
                            *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                    }

                    else if (ubBitplaneCounter == 2)
                    {
                        if ((ubBarCounter % 4) == 3)
                            *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
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
                if (ubBitplaneCounter == 0)
                {
                    if ((ubBarCounter % 2) == 0)
                        *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                }
                else if (ubBitplaneCounter == 1)
                {
                    if ((ubBarCounter % 4) == 1 || (ubBarCounter % 4) == 2)
                        *bitplanes[ubBitplaneCounter].p_ubBitplanePointer |= BV(bBytePos);
                }

                else if (ubBitplaneCounter == 2)
                {
                    if ((ubBarCounter % 4) == 3)
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
    ubCopIndexFirstLine = ubCopIndex;
    copSetMoveBackAndFront(&g_pCustom->color[8], 0x0AAA);
    copSetMoveBackAndFront(&g_pCustom->color[8], 0x0AAA);

    for (UBYTE ubCount = 0; ubCount < PERSPECTIVEBARSNUMBER; ubCount++)
    {
#ifdef ACE_DEBUG
        logWrite("setting wait for row %u\n", 209 + 43 + ubWaitCount);
#endif
        copSetWaitBackAndFront(0, 209 + 43 + ubWaitCount);
        s_ubPerspectiveBarCopPositions[ubCount] = ubCopIndex;
        tPerspectiveBarArray[ubCount].ubCopIndex = ubCopIndex;
        tPerspectiveBarArray[ubCount].ubScrollCounter = 0;

        for (UBYTE ubCount2 = 0; ubCount2 < 32; ubCount2++)
        {
            UBYTE ubValue = 0;
            if (ubCount2 <= ubCount + 1)
                ubValue = 1;
            else
                ubValue = 0;

            tPerspectiveBarArray[ubCount].pScrollFlags[ubCount2] = ubValue;
#ifdef ACE_DEBUG
//logWrite("setting value %u for bar %u at position %u\n", ubValue, ubCount, ubCount2);
#endif
        }

        // 32th (linea inclinata di 33)

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

        copSetMoveBackAndFront(&g_pCustom->bplcon1, 0x0000);
        copSetMoveBackAndFront(&g_pCustom->bpl1mod, 0x0008);
        copSetMoveBackAndFront(&g_pCustom->bpl2mod, 0x0008);

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
    return ubCopIndex;
}

// Mask the 4th bitplane filling with 0xFF
void MaskScreen()
{
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
    g_pCustom->bltsize = 0x4014;
    return;
}

// Mask the 4th bitplane filling with 0xFF
void unMaskScreen()
{
    blitWait();
    g_pCustom->bltcon0 = 0x0100;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = 0x0000;
    //g_pCustom->bltapt = (UBYTE*)((ULONG)&pData[40*224*ubBitplaneCounter]);
    g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[3]);
    g_pCustom->bltsize = 0x4018;
    return;
}
