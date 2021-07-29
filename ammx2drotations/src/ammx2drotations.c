#include "ammx2drotations.h"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameExit
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer

#define BITPLANES 2

// All variables outside fns are global - can be accessed in any fn
// Static means here that given var is only for this file, hence 's_' prefix
// You can have many variables with same name in different files and they'll be
// independent as long as they're static
// * means pointer, hence 'p' prefix
static tView *s_pView; // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs=0;
static tCopCmd *pCopCmds;

void ammxmainloop();

void ammx2drotationsGsCreate(void) {
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

  // Load the view
  viewLoad(s_pView);
  
}

void ammx2drotationsGsLoop(void) {
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  //Forbid();
  //Enable();
  if(keyCheck(KEY_ESCAPE)) {
    gameExit();
    return ;
  }
  //Disable();
/*for (int lol = 0;lol <1000; lol++)*/
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);


  g_pCustom->color[0] = 0x0FFF;
    ammxmainloop((ULONG)s_pMainBuffer->pBack->Planes);
    g_pCustom->color[0] = 0x0000;
  
  vPortWaitForEnd(s_pVpMain);
  /*vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);*/
}

void ammx2drotationsGsDestroy(void) {
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}
