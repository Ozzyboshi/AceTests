#include "ammxmatrix.h"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameExit
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer

#define BITPLANES 4

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

void ammxmatrixmul3X3(UBYTE*);
void ammxmatrixmul3X3Trig(UBYTE*);
void ammxmatrixmul1X3(UBYTE*);

void ammxmatrixGsCreate(void) {
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

void ammxmatrixGsLoop(void) {
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if(keyCheck(KEY_ESCAPE)) {
    gameExit();
    return ;
  }

  if (keyCheck(KEY_1)||keyCheck(KEY_2)||keyCheck(KEY_3))
  {
    static UBYTE ubOut[1000];
    memset(&ubOut, 0xaa, 100);
    g_pCustom->color[0] = 0x0F00;
    // ammxmainloop4((ULONG)s_pMainBuffer->pBack->Planes[0]);
    if (keyCheck(KEY_1))
      ammxmatrixmul3X3(ubOut);
    else if (keyCheck(KEY_2))
      ammxmatrixmul3X3Trig(ubOut);
    else if (keyCheck(KEY_3))
      ammxmatrixmul1X3(ubOut);
    g_pCustom->color[0] = 0x0000;
    systemUse();
    int i =0,j=0;
    for (j=0;j<3;j++)
    {
      printf("Row %d %02x%02x %02x%02x %02x%02x %02x%02x \n",j+1, ubOut[i+0], ubOut[i+1], ubOut[i+2], ubOut[i+3],ubOut[i+4], ubOut[i+5], ubOut[i+6], ubOut[i+7]);
      i+=8;
    }
    printf("Separating row  %02x%02x %02x%02x %02x%02x %02x%02x \n", ubOut[i+0], ubOut[i+1], ubOut[i+2], ubOut[i+3],ubOut[i+4], ubOut[i+5], ubOut[i+6], ubOut[i+7]);
    i+=8;

    for (j=0;j<3;j++)
    {
      printf("Row %d %02x%02x %02x%02x %02x%02x %02x%02x \n",j+1, ubOut[i+0], ubOut[i+1], ubOut[i+2], ubOut[i+3],ubOut[i+4], ubOut[i+5], ubOut[i+6], ubOut[i+7]);
      i+=8;
    }

    printf("Separating row  %02x%02x %02x%02x %02x%02x %02x%02x \n", ubOut[i+0], ubOut[i+1], ubOut[i+2], ubOut[i+3],ubOut[i+4], ubOut[i+5], ubOut[i+6], ubOut[i+7]);
    i+=8;

    printf("Second matrix rotated:\n");

    for (j=0;j<3;j++)
    {
      printf("Row %d %02x%02x %02x%02x %02x%02x %02x%02x \n",j+1, ubOut[i+0], ubOut[i+1], ubOut[i+2], ubOut[i+3],ubOut[i+4], ubOut[i+5], ubOut[i+6], ubOut[i+7]);
      i+=8;
    }

    printf("Separating row  %02x%02x %02x%02x %02x%02x %02x%02x \n", ubOut[i+0], ubOut[i+1], ubOut[i+2], ubOut[i+3],ubOut[i+4], ubOut[i+5], ubOut[i+6], ubOut[i+7]);
    i+=8;

    printf("Final results:\n");
    for (j=0;j<3;j++)
    {
      printf("Row %d %02x%02x %02x%02x %02x%02x %02x%02x \n",j+1, ubOut[i+0], ubOut[i+1], ubOut[i+2], ubOut[i+3],ubOut[i+4], ubOut[i+5], ubOut[i+6], ubOut[i+7]);
      i+=8;
    }


    systemUnuse();
    gameExit();
  }

  vPortWaitForEnd(s_pVpMain);
}

void ammxmatrixGsDestroy(void) {
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}
