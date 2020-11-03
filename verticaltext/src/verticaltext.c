#include "verticaltext.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/utils/font.h>                     // needed for tFont and font stuff
#include "../_res/uni54.h"

#define BITPLANES 1
//#define COLORS_DEBUG

static tView *s_pView;    // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs = 0;
static tCopCmd *pCopCmds;
static tFont *s_pFontUI;
static tTextBitMap *s_pGlyph;
tBitMap *g_pBitmapHelper;
char *g_pTxt[] = {
    "", "", "", "", "", "", "",
    "", "", "", "", "", "", "",
    "", "", "", "", // 18 empty rows
    "Vertical scrooltext example",
    "---",
    "This is a vertical scrolltext example",
    "--",
    "It uses one color,",
    "so only one bitplane is set",
    "--",
    "A double buffered technique is used",
    " in orde to save ram",
    "The data is stored in an array of pointers",
   "each pointers points to a phrase",
    "--",
    "Fonts are courtesy of Kain (the ace creator)",
    "",
    "You can set the speed changing the ",
    "ulframe counter module",
    "This demo should reset",
    "automatically after the last row",
    "",
    "",
    "",
    "",
    "---------------END------------",
    0};

static ULONG g_ulTxtSize = 0;

static tBitMap *g_pPlane1;
static tBitMap *g_pPlane2;

//static tCopList *g_pCopList;
//static tCopCmd *g_pCmdList;

void copyBplShifted(UWORD *, UWORD *);

void verticaltextGsCreate(void)
{
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(BITPLANES) +
                     32 * 3 + // 32 bars - each consists of WAIT + 2 MOVE instruction
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
                                     TAG_SIMPLEBUFFER_BOUND_HEIGHT, 256 + 16,
                                     TAG_END);

  s_uwCopRawOffs = simpleBufferGetRawCopperlistInstructionCount(BITPLANES);
  tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  pCopCmds = &pCopBfr->pList[s_uwCopRawOffs];

  s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray

  // We don't need anything from OS anymore
  systemUnuse();

  s_pFontUI = fontCreateFromMem((UBYTE *)uni54_data_shared_data);
  if (s_pFontUI == NULL)
    return;

  s_pGlyph = fontCreateTextBitMap(250, s_pFontUI->uwHeight);

  g_pBitmapHelper = bitmapCreate(320, 256 + 16, 1, BMF_CLEAR);
#ifdef ACE_DEBUG
  logWrite("Nuova bitmap : %p\n", g_pBitmapHelper);
#endif

  UBYTE ubCount = 0;
  while (g_pTxt[ubCount] && ubCount < 17)
  {

#if 1
    fontFillTextBitMap(s_pFontUI, s_pGlyph, g_pTxt[ubCount]);
    fontDrawTextBitMap(s_pMainBuffer->pBack, s_pGlyph, 10, ubCount * 16, 1, FONT_LEFT | FONT_LAZY);
#endif
   

    ubCount++;
  }

  

  g_pPlane1 = s_pMainBuffer->pFront;
  g_pPlane2 = g_pBitmapHelper;

  g_ulTxtSize = sizeof(g_pTxt);
  g_ulTxtSize = g_ulTxtSize >> 2;

  // Load the view
  viewLoad(s_pView);
}

void verticaltextGsLoop(void)
{
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if (keyCheck(KEY_ESCAPE))
  {
    gameExit();
    return;
  }

  static ULONG ulFrame = 0;

  //if (keyUse(KEY_SPACE))
  if (ulFrame % 4)
  {
    static UBYTE ubScrollCounter = 0;
    static UWORD ubTxtIndex = 17;

    if (1)
    {

      tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
      tCopCmd *pCmdList = &pCopList->pBackBfr->pList[s_pMainBuffer->uwCopperOffset];
      static ULONG ulPlaneAddr = 0;
      if (ubScrollCounter == 0)
      {
#ifdef COLORS_DEBUG
        g_pCustom->color[0] = 0x0FF0;
#endif
        ulPlaneAddr = (ULONG)(g_pPlane1->Planes[0]);
        copyBplShifted((UWORD *)g_pPlane1->Planes[0], (UWORD *)g_pPlane2->Planes[0]);
      }
      ulPlaneAddr += 40;

      copSetMove(&pCmdList[6 + 0].sMove, &g_pBplFetch[0].uwHi, ulPlaneAddr >> 16);
      copSetMove(&pCmdList[6 + 1].sMove, &g_pBplFetch[0].uwLo, ulPlaneAddr & 0xFFFF);
      copSwapBuffers();
      ubScrollCounter++;
      vPortWaitForEnd(s_pVpMain);
      if (ubScrollCounter == 1)
      {
        char buf[60];
        sprintf(buf,"%*s", -50, g_pTxt[ubTxtIndex++]);
        fontFillTextBitMap(s_pFontUI, s_pGlyph, buf);
        if (ubTxtIndex >= g_ulTxtSize)
          ubTxtIndex = 0;
        fontDrawTextBitMap(g_pPlane2, s_pGlyph, 10, 16 * 16, 1, FONT_LEFT | FONT_LAZY);
      }
    }

    if (ubScrollCounter >= 16)
    {
#ifdef COLORS_DEBUG
      g_pCustom->color[0] = 0x0F00;
#endif
      ubScrollCounter = 0;
      tBitMap *pTmp = g_pPlane1;
      g_pPlane1 = g_pPlane2;
      g_pPlane2 = pTmp;
    }

  }

  
  if (keyUse(KEY_1))
  {
#ifdef COLORS_DEBUG
    g_pCustom->color[0] = 0x0F0F;
#endif
    // Point the first bitplane to next line
    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdList = &pCopList->pBackBfr->pList[s_pMainBuffer->uwCopperOffset];
    static ULONG ulPlaneAddr = 0;
    if (ulPlaneAddr == 0)
      ulPlaneAddr = (ULONG)s_pMainBuffer->pFront->Planes[0];
    //ulPlaneAddr += 40;

    copSetMove(&pCmdList[6 + 0].sMove, &g_pBplFetch[0].uwHi, ulPlaneAddr >> 16);
    copSetMove(&pCmdList[6 + 1].sMove, &g_pBplFetch[0].uwLo, ulPlaneAddr & 0xFFFF);
    copSwapBuffers();
  }

  // Go to helper
  if (keyUse(KEY_2))
  {

    // Point the first bitplane to next line
    tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdList = &pCopList->pBackBfr->pList[s_pMainBuffer->uwCopperOffset];
    static ULONG ulPlaneAddr = 0;
    if (ulPlaneAddr == 0)
      ulPlaneAddr = (ULONG)g_pBitmapHelper->Planes[0];
    //ulPlaneAddr += 40;

    copSetMove(&pCmdList[6 + 0].sMove, &g_pBplFetch[0].uwHi, ulPlaneAddr >> 16);
    copSetMove(&pCmdList[6 + 1].sMove, &g_pBplFetch[0].uwLo, ulPlaneAddr & 0xFFFF);
    copSwapBuffers();
  }
  ulFrame++;
}

void verticaltextGsDestroy(void)
{
  // Cleanup when leaving this gamestate
  systemUse();

  bitmapDestroy(g_pBitmapHelper);

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}

void copyBplShifted(UWORD *pSrc, UWORD *pDst)
{

  blitWait();
  g_pCustom->bltcon0 = 0x09F0;
  g_pCustom->bltcon1 = 0x0000;
  g_pCustom->bltafwm = 0xFFFF;
  g_pCustom->bltalwm = 0xFFFF;
  g_pCustom->bltamod = 0x0000;
  g_pCustom->bltbmod = 0x0000;
  g_pCustom->bltcmod = 0x0000;
  g_pCustom->bltdmod = 0x0000;
  g_pCustom->bltapt = (UBYTE *)((ULONG)pSrc + 40 * 16);
  g_pCustom->bltdpt = (UBYTE *)((ULONG)pDst);
  g_pCustom->bltsize = 0x4014;
}