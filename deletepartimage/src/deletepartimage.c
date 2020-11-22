#include "deletepartimage.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer

#include <ace/managers/blit.h>
#include "mivampirademocolors.h"

#include <proto/exec.h>
#include <proto/dos.h>

#include "../_res/rotozoom2/mivampira_zoomout.h"
#include "../_res/rotozoom2/mivampira_zoomoutplt.h"

//#define ACELINE
#define ANIMATIONWAIT 100
#define BITPLANES 5

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
UBYTE *g_pBuffer;
ULONG g_ulBufferLength;
UBYTE *LoadRes(ULONG, char *);
void unLoadRes();
static UBYTE *imgPointer;
static UBYTE *imgPointerStart;
static UWORD *pltPointer;
void clearBpl();
void clearHr(UWORD );
void clearVr(UWORD );

void DrawlineOr(UBYTE *, int, int, int, int);
void InitLine();
void copyToMainBpl();

void deletepartimageGsCreate(void)
{
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(BITPLANES) +
                     1);

  // Create a view - first arg is always zero, then it's option-value
  s_pView = viewCreate(0,
                       TAG_VIEW_GLOBAL_CLUT, 1, // Same Color LookUp Table for all viewports
                     //  TAG_VIEW_COPLIST_MODE, VIEW_COPLIST_MODE_RAW,
                     //  TAG_VIEW_COPLIST_RAW_COUNT, ulRawSize,
                       TAG_END); // Must always end with TAG_END or synonym: TAG_DONE

  // Now let's do the same for main playfield
  s_pVpMain = vPortCreate(0,
                          TAG_VPORT_VIEW, s_pView,
                          TAG_VPORT_BPP, BITPLANES,
                          // We won't specify height here - viewport will take remaining space.
                          TAG_END);
  s_pMainBuffer = simpleBufferCreate(0,
                                     TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
                                     TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
                                //     TAG_SIMPLEBUFFER_COPLIST_OFFSET, 0,
                                     TAG_SIMPLEBUFFER_IS_DBLBUF, 0,
                                     TAG_END);

  s_uwCopRawOffs = simpleBufferGetRawCopperlistInstructionCount(BITPLANES);
  tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  pCopCmds = &pCopBfr->pList[s_uwCopRawOffs];

  /*Enable this in double blf mode
  CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			s_pView->pCopList->pFrontBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);*/

  UBYTE ubCount = 0;
  UWORD *p_uwPalette = (UWORD *)mivampirademocolors_data;
  for (ubCount = 0; ubCount < 16; ubCount++)
  {
    UWORD newColor = *p_uwPalette;

    s_pVpMain->pPalette[ubCount] = newColor;
    p_uwPalette++;
  }

  for (UBYTE ubCount = 16; ubCount < 32; ubCount++)
    s_pVpMain->pPalette[ubCount] = 0x0001;

  // We don't need anything from OS anymore
  systemUnuse();

  LoadRes(38400, "mivampirademo.raw");
  if (g_pBuffer == NULL)
    gameExit();

    //copyToMainBpl((unsigned char*)buf, 0, 0);
#if 1
  UBYTE *lol = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
  memcpy(lol, g_pBuffer, 9600);
  lol = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[1]);
  memcpy(lol, g_pBuffer + 9600, 9600);

  lol = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[2]);
  memcpy(lol, g_pBuffer + 9600 * 2, 9600);

  lol = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[3]);
  memcpy(lol, g_pBuffer + 9600 * 3, 9600);
#endif
  unLoadRes();
  LoadRes(51200, "mivampira_zoomout.raw");
  //imgPointer = (UBYTE *)mivampira_zoomout_data;
  imgPointer = (UBYTE *)g_pBuffer;
  pltPointer = (UWORD *)mivampira_zoomoutplt_data;
  imgPointerStart = imgPointer;

  // Load the view
  viewLoad(s_pView);
}

void deletepartimageGsLoop(void)
{
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if (keyCheck(KEY_ESCAPE))
  {
    gameExit();
    return;
  }
  static ULONG x = 0;
  static ULONG y = 0;
  static UBYTE ubFinish = 0;
  static UBYTE ubRotoZoom = 0;
  static UWORD uwAniWait = ANIMATIONWAIT;

  if (keyUse(KEY_5))
    clearBpl();

  //if (keyUse(KEY_4))
  if (ubFinish && uwAniWait)
    uwAniWait--;
  else if (ubFinish)
  {

    if ((ubRotoZoom % 4) == 0)
    {
      if (imgPointer == imgPointerStart)
        clearBpl();
      if (imgPointer - imgPointerStart > 51200 - 2048)
      {
        gameExit();
        return;
      }
      copyToMainBpl(imgPointer);

      for (UBYTE ubCount = 0; ubCount < 16; ubCount++)
      {
        if (ubCount > 0)
        {
          UWORD newColor = *pltPointer;
          if (*pltPointer == 0x0666)
          {
            s_pVpMain->pPalette[ubCount] = 0x0001;
          }
          else
          {
            s_pVpMain->pPalette[ubCount] = newColor;
          }
        }
        pltPointer++;
      }
      viewUpdateCLUT(s_pView);
    }
    ubRotoZoom++;
  }

  //if (keyCheck(KEY_1))
  {
  if (x < 320 / 2 - 32)
  {
    /*clearVr(x);
    clearVr(319-x);*/
#if 0

    blitWait();
    InitLine();

    DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4]),
               x,
               0,
               x,
               255);

    blitWait();
    InitLine();

    DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4]),
               319 - x,
               0,
               319 - x,
               255);
#else
    blitLine(s_pMainBuffer->pBack, x, 0, x, 255, 0, 0xFFFF, 31);
    blitLine(s_pMainBuffer->pBack, 319 - x, 0, 319 - x, 255, 0, 0xFFFF, 31);
#endif
    x++;
  }
  else
    ubFinish = 1;
  }

  //if (keyCheck(KEY_2))
  if (y < 256 / 2 - 16)
  {
#ifndef ACELINE


   /* blitWait();
    InitLine();

    DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4]),
               0,
               255 - y,
               319,
               255 - y);

    blitWait();
    InitLine();

    DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4]),
               0,
               y,
               319,
               y);*/
               clearHr(255-y);
               clearHr(y);
#else
    blitLine(s_pMainBuffer->pBack, 0, 255 - y, 319, 255 - y, 0, 0xFFFF, 0);
    blitLine(s_pMainBuffer->pBack, 0, y, 319, y, 0, 0xFFFF, 0);
#endif
    y++;
  }
  if (keyCheck(KEY_3))
  {
    bitmapSaveBmp(s_pMainBuffer->pBack, s_pVpMain->pPalette, "test.bmp");
    gameExit();
  }
  vPortWaitForEnd(s_pVpMain);
}

void deletepartimageGsDestroy(void)
{

  //FreeMem(g_pBuffer, 38400);
  unLoadRes();

  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}
UBYTE *LoadRes(ULONG ulSize, char *pFile)
{
  BPTR file2;
  g_pBuffer = memAlloc(ulSize, MEMF_CHIP);
  if (g_pBuffer == NULL)
    return NULL;
  systemUse();
  file2 = Open((CONST_STRPTR)pFile, MODE_OLDFILE);
  if (file2 == 0)
  {
    gameExit();
  }
  Read(file2, g_pBuffer, ulSize);
  Close(file2);
  systemUnuse();
  g_ulBufferLength = ulSize;
  return g_pBuffer;
}

void unLoadRes()
{
  //FreeMem(g_pBuffer,g_ulBufferLength);
  memFree(g_pBuffer, g_ulBufferLength);
  g_ulBufferLength = 0;
}

// Function to copy data to a main bitplane
// Pass ubMaxBitplanes = 0 to use all available bitplanes in the bitmap
void copyToMainBpl()
{
  UBYTE ubBitplaneCounter;
  for (ubBitplaneCounter = 0; ubBitplaneCounter < 4; ubBitplaneCounter++)
  {
    blitWait();
    g_pCustom->bltcon0 = 0x09F0;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    //g_pCustom->bltbmod = 0x0000;
    //g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = 32;
    g_pCustom->bltapt = (UBYTE *)((ULONG)imgPointer);
    g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[ubBitplaneCounter] + 16 + 40 * 96);
    g_pCustom->bltsize = 0x1004;
    imgPointer += 512;
  }
  return;
}

// Function to copy data to a main bitplane
// Pass ubMaxBitplanes = 0 to use all available bitplanes in the bitmap
void clearBpl()
{
  UBYTE ubBitplaneCounter;
  for (ubBitplaneCounter = 0; ubBitplaneCounter < 5; ubBitplaneCounter++)
  {
    blitWait();
    g_pCustom->bltcon0 = 0x0100;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    /*g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;*/
    g_pCustom->bltdmod = 32;
    //g_pCustom->bltapt = (UBYTE *)((ULONG)&pData[40 * 256 * ubBitplaneCounter]);
    g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[ubBitplaneCounter] + 16);
    g_pCustom->bltsize = 0x4004;
  }
  return;
}

void clearHr(UWORD uwRow)
{
  ULONG* pRow = (ULONG *)((ULONG)s_pMainBuffer->pBack->Planes[4] + 40 * uwRow);
  for (UBYTE ubCount = 0 ; ubCount < 10 ; ubCount++)
  {
  *pRow=0xFFFFFFFF;
  pRow++;
  }
  //*pRow=0xFFFFFFFF;
  return ;

  blitWait();
  g_pCustom->bltcon0 = 0x09FF;
  g_pCustom->bltcon1 = 0x0000;
  g_pCustom->bltafwm = 0xFFFF;
  g_pCustom->bltalwm = 0xFFFF;
  /*g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;*/
  g_pCustom->bltdmod = 0;
  //g_pCustom->bltapt = (UBYTE *)((ULONG)&pData[40 * 256 * ubBitplaneCounter]);
  g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4] + 40 * uwRow);
  g_pCustom->bltsize = 0x0054;
}

void clearVr(UWORD uwCol)
{
  
  /*uwCol = uwCol>>4;
  UBYTE uwColRem = uwCol % 16;
  uwColRem++;*/
  UBYTE ubValue = 0xFF;

  for (UWORD ubCounter = 0;ubCounter<256;ubCounter++)
  {
    UBYTE* pRow = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4] + ubCounter*40 + (uwCol>>3));
    *pRow=ubValue;
  }
  
  return;
  blitWait();
  g_pCustom->bltcon0 = 0x09FF;
  g_pCustom->bltcon1 = 0x0000;
  /*if (uwColRem==1)
  {*/
  g_pCustom->bltafwm = 0x8000;
  g_pCustom->bltalwm = 0;
  /*}
  else if (uwColRem==2)
  {
g_pCustom->bltafwm = 0x8000;
  g_pCustom->bltalwm = 0;
  }*/
  g_pCustom->bltamod = 0x0000;
  /*  g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;*/
  g_pCustom->bltdmod = 38;
  //g_pCustom->bltapt = (UBYTE *)((ULONG)&pData[40 * 256 * ubBitplaneCounter]);
  g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4] + uwCol);
  g_pCustom->bltsize = 0x4001;
}
