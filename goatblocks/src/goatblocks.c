#include "goatblocks.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>
#include <ace/utils/palette.h>

#include "goatblock32X32.h"
#include "goatblockplt.h"

#define copSetWaitBackAndFront(var, var2, var3)            \
  copSetWait(&pCmdListBack[ubCopIndex].sWait, var, var2);  \
  copSetWait(&pCmdListFront[ubCopIndex].sWait, var, var2); \
  if (var3)                                                \
    g_sWaitPositions[ubWaitCounter++] = ubCopIndex;        \
  ubCopIndex++;

#define copSetMoveBackAndFront(var, var2)                  \
  copSetMove(&pCmdListBack[ubCopIndex].sMove, var, var2);  \
  copSetMove(&pCmdListFront[ubCopIndex].sMove, var, var2); \
  ubCopIndex++;

#define MAXTIMERS 6
typedef struct tTimersManager
{
  BYTE bCubeIndexArray[5];
  ULONG ulTimeDelta;
}tTimersManager;

static tTimersManager TIMER[MAXTIMERS];


typedef struct tBlock
{
  UWORD uwX;
  UWORD uwY;

  BYTE bDimCounter;

  UBYTE ubStatus; // 0 => shown , 1 => dimming , 2 => dimmed , 3 => showing

  UBYTE ubRow; // Raw number, first raw is 0
} tBlock;

#define BLOCK_NEXT_STAGE(var)       \
  s_pBlocks[var].ubStatus++;        \
  if (s_pBlocks[var].ubStatus >= 4) \
    s_pBlocks[0].ubStatus = 0;

#define CREATEBLOCK(var1, var2, var3, var4) \
  s_pBlocks[var1].uwX = var2;               \
  s_pBlocks[var1].uwY = var3;               \
  s_pBlocks[var1].ubStatus = 0;             \
  s_pBlocks[var1].bDimCounter = 15;         \
  s_pBlocks[var1].ubRow = var4;             \
  drawBlock(s_pBlocks[var1]);

#define NUMBLOCKS 5 + 4 * 2 + 3 * 2

static tBlock s_pBlocks[NUMBLOCKS];

void drawBlock(tBlock);
void drawBlock2(tBlock);
void deleteBlock(tBlock);
void initTimer();

#define BITPLANES 4
#define VSPACE 8
#define VPADDING 25

// All variables outside fns are global - can be accessed in any fn
// Static means here that given var is only for this file, hence 's_' prefix
// You can have many variables with same name in different files and they'll be
// independent as long as they're static
// * means pointer, hence 'p' prefix
static tView *s_pView;    // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs = 0;
static tCopCmd *pCopCmds;
static UWORD g_sWaitPositions[7];
static ULONG ulStart;
static ULONG ulTimerDelta;
static UBYTE ubTimerIndex = 0;
//static BYTE pDisappearArray[] = {0,1,2,3,-1};
//static UBYTE ubDisappearIndex = 0;

void gameGsCreate(void)
{
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(BITPLANES) +
                     70 * 3 + // 32 bars - each consists of WAIT + 2 MOVE instruction
                     1 +      // Final WAIT
                     1        // Just to be sure
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
  s_pMainBuffer = simpleBufferCreate(0,
                                     TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
                                     TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
                                     TAG_SIMPLEBUFFER_COPLIST_OFFSET, 0,
                                     TAG_SIMPLEBUFFER_IS_DBLBUF, 0,
                                     TAG_END);

  s_uwCopRawOffs = simpleBufferGetRawCopperlistInstructionCount(BITPLANES);
  tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  pCopCmds = &pCopBfr->pList[s_uwCopRawOffs];

  tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
  tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
  tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];

  UWORD ubCopIndex = 0;
  UBYTE ubWaitCounter = 0;

  /*Enable this in double blf mode
  CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			s_pView->pCopList->pFrontBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);*/

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  /*s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray
  s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red*/

  UWORD *pPalette = (UWORD *)goatblockplt_data;
  for (UBYTE ubCount = 0; ubCount < 8; ubCount++)
  {
    s_pVpMain->pPalette[ubCount] = *pPalette;
    pPalette++;
  }

  pPalette = (UWORD *)goatblockplt_data;
  for (UBYTE ubCount = 8; ubCount < 16; ubCount++)
  {
    s_pVpMain->pPalette[ubCount] = (*pPalette) + 0;
    pPalette++;
  }

  // We don't need anything from OS anymore
  systemUnuse();

  // 1st row
  CREATEBLOCK(0, 12, VPADDING, 0);
  CREATEBLOCK(1, 18, VPADDING, 0);
  CREATEBLOCK(2, 24, VPADDING, 0);

  // 2nd row
  CREATEBLOCK(3, 8, VPADDING + 32 + VSPACE, 1);
  CREATEBLOCK(4, 14, VPADDING + 32 + VSPACE, 1);
  CREATEBLOCK(5, 20, VPADDING + 32 + VSPACE, 1);
  CREATEBLOCK(6, 26, VPADDING + 32 + VSPACE, 1);

  // 3rd row
  CREATEBLOCK(7, 6, VPADDING + 32 * 2 + VSPACE * 2, 2);
  CREATEBLOCK(8, 12, VPADDING + 32 * 2 + VSPACE * 2, 2);
  CREATEBLOCK(9, 18, VPADDING + 32 * 2 + VSPACE * 2, 2);
  CREATEBLOCK(10, 24, VPADDING + 32 * 2 + VSPACE * 2, 2);
  CREATEBLOCK(11, 30, VPADDING + 32 * 2 + VSPACE * 2, 2);

  // 4th row
  CREATEBLOCK(12, 8, VPADDING + 32 * 3 + VSPACE * 3, 3);
  CREATEBLOCK(13, 14, VPADDING + 32 * 3 + VSPACE * 3, 3);
  CREATEBLOCK(14, 20, VPADDING + 32 * 3 + VSPACE * 3, 3);
  CREATEBLOCK(15, 26, VPADDING + 32 * 3 + VSPACE * 3, 3);

  // 5th row
  CREATEBLOCK(16, 12, VPADDING + 32 * 4 + VSPACE * 4, 4);
  CREATEBLOCK(17, 18, VPADDING + 32 * 4 + VSPACE * 4, 4);
  CREATEBLOCK(18, 24, VPADDING + 32 * 4 + VSPACE * 4, 4);

  copSetWaitBackAndFront(0, 0x0, 1);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);

  pPalette = (UWORD *)goatblockplt_data;
  for (UBYTE ubCount = 8; ubCount < 16; ubCount++)
  {
    copSetMoveBackAndFront(&g_pCustom->color[ubCount], *pPalette);
    pPalette++;
  }

  /*copSetWaitBackAndFront(0, 0x2c+VPADDING, 1);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0F00);*/

  copSetWaitBackAndFront(0, 0x2c + VPADDING + 32, 1);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);
  for (UBYTE ubCount = 8; ubCount < 16; ubCount++)
  {
    copSetMoveBackAndFront(&g_pCustom->color[ubCount], *pPalette);
    pPalette++;
  }

  copSetWaitBackAndFront(0, 0x2c + VPADDING + 32 + VSPACE + 32, 1);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);
  for (UBYTE ubCount = 8; ubCount < 16; ubCount++)
  {
    copSetMoveBackAndFront(&g_pCustom->color[ubCount], *pPalette);
    pPalette++;
  }

  copSetWaitBackAndFront(0, 0x2c + VPADDING + 32 + VSPACE * 2 + 32 * 2, 1);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);
  for (UBYTE ubCount = 8; ubCount < 16; ubCount++)
  {
    copSetMoveBackAndFront(&g_pCustom->color[ubCount], *pPalette);
    pPalette++;
  }

  copSetWaitBackAndFront(0, 0x2c + VPADDING + 32 + VSPACE * 3 + 32 * 3, 1);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0000);
  for (UBYTE ubCount = 8; ubCount < 16; ubCount++)
  {
    copSetMoveBackAndFront(&g_pCustom->color[ubCount], *pPalette);
    pPalette++;
  }

  /*copSetWaitBackAndFront(0xdf, 0xff, 0);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x00F0);*/

  // Load the view
  viewLoad(s_pView);

  initTimer();

  ulStart = timerGet();
  ulTimerDelta = TIMER[0].ulTimeDelta;
}

void gameGsLoop(void)
{
  if(timerGetDelta(ulStart, timerGet()) > ulTimerDelta)
  {
    UBYTE ubCount = 0;
    while (TIMER[ubTimerIndex].bCubeIndexArray[ubCount]>=0)
    {
      BLOCK_NEXT_STAGE(TIMER[ubTimerIndex].bCubeIndexArray[ubCount]);
      ubCount++;
    }
    ulStart = timerGet();
    ubTimerIndex++;
    if (ubTimerIndex>= MAXTIMERS) ubTimerIndex=0;
  }
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if (keyCheck(KEY_ESCAPE))
  {
    gameExit();
  }
  if (keyUse(KEY_Q))
  {
    //drawBlock2(s_pBlocks[0]);
    BLOCK_NEXT_STAGE(0);
  }
  if (keyUse(KEY_W))
  {
    //drawBlock2(s_pBlocks[1]);
    BLOCK_NEXT_STAGE(1);
  }
  if (keyUse(KEY_E))
  {
    //drawBlock2(s_pBlocks[2]);
    BLOCK_NEXT_STAGE(2);
  }
  if (keyUse(KEY_A))
  {
    BLOCK_NEXT_STAGE(3);
  }
  if (keyUse(KEY_S))
  {
    BLOCK_NEXT_STAGE(4);
  }
  if (keyUse(KEY_D))
  {
    BLOCK_NEXT_STAGE(5);
  }
  if (keyUse(KEY_F))
  {
    BLOCK_NEXT_STAGE(6);
  }

 // if (keyUse(KEY_SPACE))
  if (1)
  {

    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
    tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];

    UBYTE ubBlockCounter;
    for (ubBlockCounter = 0; ubBlockCounter < NUMBLOCKS; ubBlockCounter++)
    {
      UWORD *pPalette = (UWORD *)goatblockplt_data;
      tBlock *pBlock = &s_pBlocks[ubBlockCounter];

      // Dimming procedure
      if (pBlock->ubStatus == 1)
      {
        if (pBlock->bDimCounter == 15)
          drawBlock2(*pBlock);
        pBlock->bDimCounter--;
        if (pBlock->bDimCounter < 0)
        {
          deleteBlock(*pBlock);
          pBlock->bDimCounter = -1;
          pBlock->ubStatus = 2;
        }
        else
        {

          UBYTE ubCopIndex = g_sWaitPositions[pBlock->ubRow] + 2;
          UBYTE ubColCounter;
          for (ubColCounter = 8; ubColCounter < 16; ubColCounter++)
          {
            copSetMoveBackAndFront(&g_pCustom->color[ubColCounter], paletteColorDim(*pPalette, pBlock->bDimCounter));
            pPalette++;
          }
        }
      } // end of dimming

      // start of showing
      else if (pBlock->ubStatus == 3)
      {
        pBlock->bDimCounter++;
        if (pBlock->bDimCounter == 0)
        {
          drawBlock(*pBlock);
          drawBlock2(*pBlock);
        }
        if (pBlock->bDimCounter > 15)
        {
          deleteBlock(*pBlock);
          drawBlock(*pBlock);
          pBlock->ubStatus=0;
        }
        else
        {
          UBYTE ubCopIndex = g_sWaitPositions[pBlock->ubRow] + 2;
          UBYTE ubColCounter;

          for (ubColCounter = 8; ubColCounter < 16; ubColCounter++)
          {
            copSetMoveBackAndFront(&g_pCustom->color[ubColCounter], paletteColorDim(*pPalette, pBlock->bDimCounter));
            pPalette++;
          }
        }
      }
    }
  }

  vPortWaitForEnd(s_pVpMain);
}

void gameGsDestroy(void)
{
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}

void drawBlock(tBlock p_Block)
{
  UBYTE ubBitplaneCounter;
  for (ubBitplaneCounter = 0; ubBitplaneCounter < 3; ubBitplaneCounter++)
  {
    blitWait();
    g_pCustom->bltcon0 = 0x09F0;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = 0x0024;
    g_pCustom->bltapt = (UBYTE *)((ULONG)&goatblock32X32_data[4 * 32 * ubBitplaneCounter]);
    g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[ubBitplaneCounter] + p_Block.uwY * 40 + p_Block.uwX);
    g_pCustom->bltsize = 0x0802;
  }
  return;
}

void deleteBlock(tBlock p_Block)
{
  UBYTE ubBitplaneCounter;
  for (ubBitplaneCounter = 0; ubBitplaneCounter < 4; ubBitplaneCounter++)
  {
    blitWait();
    g_pCustom->bltcon0 = 0x0100;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = 0x0024;
    g_pCustom->bltapt = (UBYTE *)((ULONG)&goatblock32X32_data[4 * 32 * ubBitplaneCounter]);
    g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[ubBitplaneCounter] + p_Block.uwY * 40 + p_Block.uwX);
    g_pCustom->bltsize = 0x0802;
  }
  return;
}

void drawBlock2(tBlock p_Block)
{
  blitWait();
  g_pCustom->bltcon0 = 0x01FF;
  g_pCustom->bltcon1 = 0x0000;
  g_pCustom->bltafwm = 0xFFFF;
  g_pCustom->bltalwm = 0xFFFF;
  g_pCustom->bltamod = 0x0000;
  g_pCustom->bltbmod = 0x0000;
  g_pCustom->bltcmod = 0x0000;
  g_pCustom->bltdmod = 0x0024;
  //g_pCustom->bltapt = (UBYTE *)((ULONG)&goatblock32X32_data[0]);
  g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[3] + p_Block.uwY * 40 + p_Block.uwX);
  g_pCustom->bltsize = 0x0802;
}

void initTimer()
{
  TIMER[0].bCubeIndexArray[0] = 0;
  TIMER[0].bCubeIndexArray[1] = -1;
  TIMER[0].ulTimeDelta = 60;

  TIMER[1].bCubeIndexArray[0] = 4;
  TIMER[1].bCubeIndexArray[1] = -1;
  TIMER[1].ulTimeDelta = 60;

  TIMER[2].bCubeIndexArray[0] = 0;
  TIMER[2].bCubeIndexArray[1] = -1;
  TIMER[2].ulTimeDelta = 60;

  TIMER[3].bCubeIndexArray[0] = 4;
  TIMER[3].bCubeIndexArray[1] = -1;
  TIMER[3].ulTimeDelta = 60;

  TIMER[4].bCubeIndexArray[0] = 7;
  TIMER[4].bCubeIndexArray[1] = 5;
  TIMER[4].bCubeIndexArray[2] = -1;
  TIMER[4].ulTimeDelta = 60;

  TIMER[5].bCubeIndexArray[0] = 7;
  TIMER[5].bCubeIndexArray[1] = 5;
  TIMER[5].bCubeIndexArray[2] = -1;
  TIMER[5].ulTimeDelta = 60;
}