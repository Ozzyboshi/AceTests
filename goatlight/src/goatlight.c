#include "goatlight.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include "simplebuffertest.h"

#define AUTOSCROLLING
#define BITPLANES 3

#define copSetWaitBackAndFront(var, var2)                  \
  copSetWait(&pCmdListBack[ubCopIndex].sWait, var, var2);  \
  copSetWait(&pCmdListFront[ubCopIndex].sWait, var, var2); \
  ubCopIndex++;

#define copSetMoveBackAndFront(var, var2)                  \
  copSetMove(&pCmdListBack[ubCopIndex].sMove, var, var2);  \
  copSetMove(&pCmdListFront[ubCopIndex].sMove, var, var2); \
  ubCopIndex++;

#define copSetMoveBack(var, var2)                         \
  copSetMove(&pCmdListBack[ubCopIndex].sMove, var, var2); \
  ubCopIndex++;

static tView *s_pView;    // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferTestManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs = 0;
//static tCameraManager *s_pCamera;

static unsigned char *s_pMusic;

//void updateCamera(UBYTE);
void updateCamera2(BYTE);
UWORD getBarColor(const UBYTE);
void switchCopColors();
void printPerspectiveRow(tSimpleBufferTestManager *s_pMainBuffer, const UWORD, const UWORD, const UWORD, const UWORD);

#define MAXCOLORS 4

static UWORD s_pBarColors[MAXCOLORS] = {
    0x0F00, // color of first col

    0x00F0, // color of the second col
    0x000F, // color of the third col
    0x0000, // color of the fourth col
};

static UBYTE s_ubBarColorsCopPositions[MAXCOLORS];

static UBYTE s_ubColorIndex = 0;

#define SETBARCOLORSFRONTANDBACK                                                      \
  for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)                       \
  {                                                                                   \
    s_ubBarColorsCopPositions[ubCounter] = ubCopIndex;                                \
    copSetMoveBackAndFront(&g_pCustom->color[ubCounter + 1], getBarColor(ubCounter)); \
  }

#define SETBARCOLORSBACK                                                      \
  for (UBYTE ubCounter = 0; ubCounter < MAXCOLORS; ubCounter++)               \
  {                                                                           \
    copSetMoveBack(&g_pCustom->color[ubCounter + 1], getBarColor(ubCounter)); \
  }

static UBYTE s_ubPerspectiveBarCopPositions[2];

//void copyToMainBplFromFast(const unsigned char* pData,const UBYTE ubSlot,const UBYTE ubMaxBitplanes);

void gameGsCreate(void)
{
  ULONG ulRawSize = (SimpleBufferTestGetRawCopperlistInstructionCount(BITPLANES) + 11 + 5 * 3 + 1
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
    while (uwRowCounter < 207)
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
      //sp_ubBitplanePointer += 4;

      uwRowCounter++;
    }
    ubContBitplanes++;
  }

  UWORD uwRowWidth = 25;
  for (UWORD uwCounter = 208; uwCounter<248;uwCounter++)
  {
    
    printPerspectiveRow(s_pMainBuffer, uwCounter, 48, uwRowWidth, 1);
    if ((uwCounter%4)==3) uwRowWidth++;
  }

  /*printPerspectiveRow(s_pMainBuffer, 208, 48, 25, 1);
  printPerspectiveRow(s_pMainBuffer, 209, 48, 25, 1);
  printPerspectiveRow(s_pMainBuffer, 210, 48, 26, 1);
  printPerspectiveRow(s_pMainBuffer, 211, 48, 26, 1);
  printPerspectiveRow(s_pMainBuffer, 212, 48, 26, 1);
  printPerspectiveRow(s_pMainBuffer, 213, 48, 26, 1);

  printPerspectiveRow(s_pMainBuffer, 214, 48, 27, 1);
  printPerspectiveRow(s_pMainBuffer, 215, 48, 27, 1);*/

#if 0
  for (int cont = 208 + 2; cont < 218; cont++)
  {
    ULONG ulValue = 0b00000001111111111111111111111111;
    ulValue = 0b00011111111111111111111111110000;

    p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
    p_ubBitplanePointer += 48 * cont; // vertical position
    p_ubBitplanePointer += 4 * 0 - 1; // go byte before to first  bar
    *((ULONG *)p_ubBitplanePointer) = ulValue;

    ulValue = 0b00001111111111111111111111111000;
    p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[1]);
    p_ubBitplanePointer += 48 * cont; // vertical position
    p_ubBitplanePointer += 4 * 1 - 1; // go byte before to 2th  bar
    *((ULONG *)p_ubBitplanePointer) = ulValue;

    ulValue = 0b00000111111111111111111111111100;
    p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
    p_ubBitplanePointer += 48 * cont; // vertical position
    p_ubBitplanePointer += 4 * 2 - 1; // go byte before to 3th  bar
    *((ULONG *)p_ubBitplanePointer) = ulValue;
    p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[1]);
    p_ubBitplanePointer += 48 * cont; // vertical position
    p_ubBitplanePointer += 4 * 2 - 1; // go byte before to 3th  bar
    *((ULONG *)p_ubBitplanePointer) = ulValue;

    ulValue = 0b00000011111111111111111111111110;
    p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[2]);
    p_ubBitplanePointer += 48 * cont; // vertical position
    p_ubBitplanePointer += 4 * 3 - 1; // go byte before to 4th  bar
    *((ULONG *)p_ubBitplanePointer) = ulValue;

    ulValue = 0b00000001111111111111111111111111;
    p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
    p_ubBitplanePointer += 48 * cont; // vertical position
    p_ubBitplanePointer += 4 * 4 - 1; // go byte before to 5th  bar
    *((ULONG *)p_ubBitplanePointer) = ulValue;

    // Right side side start
    ulValue = 0b00000000111111111111111111111111;
    p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[1]);
    p_ubBitplanePointer += 48 * cont; // vertical position
    p_ubBitplanePointer += 4 * 5 - 1; // go byte before to 6th  bar
    *((ULONG *)p_ubBitplanePointer) = ulValue;
    p_ubBitplanePointer += 4;
    *((ULONG *)p_ubBitplanePointer) = 0b10000000011111111111111111111111;
    p_ubBitplanePointer += 4;
    *((ULONG *)p_ubBitplanePointer) = 0b11000000000000000000000000000000;
    p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
    p_ubBitplanePointer += 48 * cont;
    p_ubBitplanePointer += 4 * 5 - 1;
    p_ubBitplanePointer += 4;
    *((ULONG *)p_ubBitplanePointer) = 0b00000000011111111111111111111111;
    p_ubBitplanePointer += 4;
    *((ULONG *)p_ubBitplanePointer) = 0b11000000000000000000000000000000;

    /*p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[1]);
    p_ubBitplanePointer += 48 * cont; // vertical position
    p_ubBitplanePointer += 4 * 1 - 1; // go byte before to 2th  bar
    *((ULONG *)p_ubBitplanePointer) = ulValue;
    p_ubBitplanePointer+=4;
    *((ULONG *)p_ubBitplanePointer) = 0b100000000000000000000000000000 ;*/
  }

  /*p_ubBitplanePointer = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
  p_ubBitplanePointer += 48 * 230;  // vertical position
  p_ubBitplanePointer += 4 * 4 - 1; // go byte before to 4th  bar
  *((ULONG *)p_ubBitplanePointer) = 0b11111111111111111111111111111111;
  p_ubBitplanePointer += 4;
  *((ULONG *)p_ubBitplanePointer) = 0b00000000111111111111111111111111;
  p_ubBitplanePointer += 4;
  *((ULONG *)p_ubBitplanePointer) = 0b10000000000000000000000000000000;*/
#endif

  tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
  tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
  tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];

  UBYTE ubCopIndex = 0;

  /*copSetWait(&pCmdListBack[0].sWait, 0, 43);
	copSetMove(&pCmdListBack[1].sMove, &g_pCustom->color[1], s_pBarColors[s_ubColorIndex+0]);
  copSetMove(&pCmdListBack[2].sMove, &g_pCustom->color[2], s_pBarColors[s_ubColorIndex+1]);
  copSetMove(&pCmdListBack[3].sMove, &g_pCustom->color[3], s_pBarColors[s_ubColorIndex+2]);*/

  copSetWaitBackAndFront(0, 43);

  SETBARCOLORSFRONTANDBACK

  copSetWaitBackAndFront(0, 200);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);

  // Space for first perspective row

  copSetWaitBackAndFront(0, 208 + 43);
  s_ubPerspectiveBarCopPositions[0] = ubCopIndex;
  copSetMoveBackAndFront(&g_pCustom->bplcon1, 0x0000); // just to get some cop space - this is for coppointer2
  copSetMoveBackAndFront(&g_pCustom->bpl1mod, 0x0008); // just to get some cop space - this is for coppointer2
  copSetMoveBackAndFront(&g_pCustom->bpl2mod, 0x0008); // just to get some cop space - this is for coppointer3
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x00F); // just to get some cop space - this is for coppointer3

  copSetWaitBackAndFront(0, 209 + 43);
  s_ubPerspectiveBarCopPositions[1] = ubCopIndex;
  copSetMoveBackAndFront(&g_pCustom->bplcon1, 0x0000);  // just to get some cop space - this is for coppointer2
  copSetMoveBackAndFront(&g_pCustom->bpl1mod, 0x0008);  // just to get some cop space - this is for coppointer2
  copSetMoveBackAndFront(&g_pCustom->bpl2mod, 0x0008);  // just to get some cop space - this is for coppointer3
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000); // just to get some cop space - this is for coppointer3

  copSetWaitBackAndFront(0, 210 + 43);
  copSetMoveBackAndFront(&g_pCustom->bplcon1, 0x0000);  // just to get some cop space - this is for coppointer2
  copSetMoveBackAndFront(&g_pCustom->bpl1mod, 0x0008);  // just to get some cop space - this is for coppointer2
  copSetMoveBackAndFront(&g_pCustom->bpl2mod, 0x0008);  // just to get some cop space - this is for coppointer3
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000); // just to get some cop space - this is for coppointer3

  copSetWaitBackAndFront(0xdf, 0xff);

  copSetWaitBackAndFront(0, 43);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);

  // Load the view
  viewLoad(s_pView);
}

void gameGsLoop(void)
{
  // This will loop forever until you "pop" or change gamestate
  // or close the game

  static BYTE bXCamera = 0;
#ifdef AUTOSCROLLING

  bXCamera++;
  bXCamera++;
  bXCamera++;
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

  if (keyUse(KEY_N))
  {
    switchCopColors();
  }

  if (keyUse(KEY_C))
  {
    bXCamera--;
    updateCamera2(bXCamera);
  }

  if (keyUse(KEY_A))
  {
    /*if (uwCameraXPos!=0) uwCameraXPos--;
    logWrite("Sub %u\n",uwCameraXPos);*/

    //UBYTE i=0;
    /*ULONG ulPlaneAddr;
    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdList = &pCopList->pBackBfr->pList[s_pMainBuffer->uwCopperOffset];
#ifdef ACE_DEBUG

    logWrite("coplist addr %x\n", pCmdList);
#endif*/
    /*tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  tCopCmd *pCmdList = &pCopBfr->pList[pManager->uwCopperOffset];*/

    //copDumpCmd(pCmdList);

    //	for (i = 0; i < s_pMainBuffer->sCommon.pVPort->ubBPP; ++i) {
    //ulPlaneAddr = 4 + (ULONG)s_pMainBuffer->pFront->Planes[0];
    /*copSetMove(&pCmdList[6].sMove, &g_pBplFetch[i].uwHi, ulPlaneAddr >> 16);
			copSetMove(&pCmdList[7].sMove, &g_pBplFetch[i].uwLo, ulPlaneAddr & 0xFFFF);*/

    /* copSetMove(&pCmdList[6].sMove, &g_pBplFetch[0].uwHi, ulPlaneAddr >> 16);
    copSetMove(&pCmdList[7].sMove, &g_pBplFetch[0].uwLo, ulPlaneAddr & 0xFFFF);*/
    //	}

    //copSwapBuffers();
    //gameExit();
  }

  if (keyUse(KEY_D))
  {
    tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
    copDumpBfr(pCopBfr);

    pCopBfr = s_pView->pCopList->pFrontBfr;
    copDumpBfr(pCopBfr);
  }

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
  ULONG ulPlaneAddr = (ULONG)s_pMusic;

  ulPlaneAddr = (ULONG)((ULONG)s_pMainBuffer->pBack->Planes[0]);
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
  }

  copSetMove(&pCmdList[6].sMove, &g_pBplFetch[0].uwHi, ulPlaneAddr >> 16);
  copSetMove(&pCmdList[7].sMove, &g_pBplFetch[0].uwLo, ulPlaneAddr & 0xFFFF);

  copSetMove(&pCmdList[8].sMove, &g_pBplFetch[1].uwHi, ulPlaneAddr2 >> 16);
  copSetMove(&pCmdList[9].sMove, &g_pBplFetch[1].uwLo, ulPlaneAddr2 & 0xFFFF);

  copSetMove(&pCmdList[10].sMove, &g_pBplFetch[2].uwHi, ulPlaneAddr3 >> 16);
  copSetMove(&pCmdList[11].sMove, &g_pBplFetch[2].uwLo, ulPlaneAddr3 & 0xFFFF);

  static UWORD alessio = 0;

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

#ifdef ACE_DEBUG
    logWrite("uwShiftPerspective: %u\n", uwShiftPerspective);
    logWrite("uwModPerspective: %u\n", uwBplMods);
    logWrite("alessio: %u\n", alessio);
#endif

    copSetMove(&pCmdListBack[0 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, uwShiftPerspective);
    copSetMove(&pCmdListBack[1 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, uwBplMods);
    copSetMove(&pCmdListBack[2 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, uwBplMods);

    //uwShiftPerspective=0x00FF;

    copSetMove(&pCmdListBack[5 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, uwShiftPerspective);
    copSetMove(&pCmdListBack[6 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, 0x0006);
    copSetMove(&pCmdListBack[7 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, 0x0006);

    copSetMove(&pCmdListBack[10 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, uwShiftPerspective);
    copSetMove(&pCmdListBack[11 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, 0x0006);
    copSetMove(&pCmdListBack[12 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, 0x0006);

    //alessio++;
  }
  else
  {
    copSetMove(&pCmdList[2].sMove, &g_pCustom->ddfstrt, 0x0038);
    copSetMove(&pCmdList[3].sMove, &g_pCustom->bpl1mod, 0x0008);
    copSetMove(&pCmdList[4].sMove, &g_pCustom->bpl2mod, 0x0008);
    copSetMove(&pCmdList[5].sMove, &g_pCustom->bplcon1, uwShift);

    // start of perspective
    copSetMove(&pCmdListBack[0 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, 0x0000);
    copSetMove(&pCmdListBack[1 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, 0x0008);
    copSetMove(&pCmdListBack[2 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, 0x0008);

    copSetMove(&pCmdListBack[5 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, 0x0000);
    copSetMove(&pCmdListBack[6 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, 0x0008);
    copSetMove(&pCmdListBack[7 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, 0x0008);

    copSetMove(&pCmdListBack[10 + s_ubPerspectiveBarCopPositions[1]].sMove, &g_pCustom->bplcon1, 0x0000);
    copSetMove(&pCmdListBack[11 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl1mod, 0x0008);
    copSetMove(&pCmdListBack[12 + s_ubPerspectiveBarCopPositions[0]].sMove, &g_pCustom->bpl2mod, 0x0008);

    alessio = 0;
  }

  ubCopIndex = 1; // must be one because at zero we would get wait instruction
  SETBARCOLORSBACK

  copSwapBuffers();
}

UWORD getBarColor(const UBYTE ubColNo)
{
  UBYTE ubColorRealIndex = ubColNo + s_ubColorIndex;
  while (ubColorRealIndex >= MAXCOLORS)
    ubColorRealIndex -= MAXCOLORS;
  return s_pBarColors[ubColorRealIndex];
}

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

void printPerspectiveRow(tSimpleBufferTestManager *s_pMainBuffer, const UWORD uwRowNo, const UWORD uwBytesPerRow, const UWORD uwBarWidth, const UWORD uwSpeed)
{
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
        logWrite("Setting space (%d-%d-bytepos :%d)\n", uwSpaceBetweenColsCounter, uwSpaceBetweenCols, bBytePos);
#endif

        uwSpaceBetweenColsCounter++;
        bBytePos++;
        if (bBytePos >= 8)
        {
          bBytePos = 0;
          bitplanes[ubBitplaneCounter].p_ubBitplanePointer--;
#ifdef ACE_DEBUG
          logWrite("Byte ended!!! decrementing p_ubBitplane0Pointer\n");
#endif
        }
      }
      else
      {
        if (uwBarWidthCounter < uwBarWidth)
        {
#ifdef ACE_DEBUG
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
            logWrite("Byte ended!!! decrementing p_ubBitplane0Pointer\n");
#endif
          }

          uwBarWidthCounter++;
        }
        else
        {
#ifdef ACE_DEBUG
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
          logWrite("Setting space (%d-%d-bytepos :%d)\n", uwSpaceBetweenColsCounter, uwSpaceBetweenCols, bBytePos);
#endif

          uwSpaceBetweenColsCounter++;
          bBytePos--;
          if (bBytePos < 0)
          {
            bBytePos = 7;
            bitplanes[ubBitplaneCounter].p_ubBitplanePointer++;
#ifdef ACE_DEBUG
            logWrite("Byte ended!!! incrementing p_ubBitplane0Pointer\n");
#endif
          }
        }
        else
        {
#ifdef ACE_DEBUG
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