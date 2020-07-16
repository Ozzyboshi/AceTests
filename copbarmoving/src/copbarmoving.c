#include "copbarmoving.h"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameExit
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer

#define BITPLANES 0
#define STARTWAIT 0x34

static tView *s_pView; // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs=0;
static tCopCmd *pCopCmds;

static UBYTE ubMasterCopWaitIndex = 0;
static UBYTE ubMasterCopWait = STARTWAIT;

void copSetWaitX(tCopWaitCmd *, UBYTE ) ;

void gameGsCreate(void) {
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(BITPLANES) +
                 48 + // 32 bars - each consists of WAIT + 2 MOVE instruction
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

  // Start with black background
  UBYTE ubCopIndex = 0;
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0000);

  // Fixed green bar
  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x2c);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0010);
  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x2d);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0020);
  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x2e);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0030);
  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x2f);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0040);


  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x30);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0030);
  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x31);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0020);
  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x32);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0010);
  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x33);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0000);

  // Start of the moving bar
  ubMasterCopWaitIndex = ubCopIndex;
  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0x34);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0300);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0300);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0900);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0C00);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0F00);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0C00);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0900);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0600);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0300);

  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0xE1);
  copSetWaitX(&pCopCmds[ubCopIndex++].sWait, 0x07);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x0000);

  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0xFD);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x000A);

  copSetWait(&pCopCmds[ubCopIndex++].sWait, 0x07, 0xFE);
  copSetMove(&pCopCmds[ubCopIndex++].sMove, &g_pCustom->color[0], 0x000F);

  // Load the view
  viewLoad(s_pView);
}

void gameGsLoop(void) {

  static UBYTE ubIncrementer = 1;
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if(keyCheck(KEY_ESCAPE)) {
    gameExit();
  }
  ubMasterCopWait+=ubIncrementer;
  if (ubMasterCopWait>=0x77 || ubMasterCopWait<=STARTWAIT ) ubIncrementer*=-1;
  copSetWait(&pCopCmds[ubMasterCopWaitIndex].sWait, 0x07, ubMasterCopWait);

   vPortWaitForEnd(s_pVpMain);
}

void gameGsDestroy(void) {
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}






void copSetWaitX(tCopWaitCmd *pWaitCmd, UBYTE ubX) {
	//pWaitCmd->bfWaitY         = ubY;
	pWaitCmd->bfWaitX         = ubX >> 1;
	pWaitCmd->bfIsWait        = 1;
	pWaitCmd->bfBlitterIgnore = 1;
	pWaitCmd->bfVE            = 0x00;
	pWaitCmd->bfHE            = 0x7F;
	pWaitCmd->bfIsSkip        = 0;
}
