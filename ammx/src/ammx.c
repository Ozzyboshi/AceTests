#include "ammx.h"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameExit
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <stdio.h>

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

void ammxmainloop();
void ammxmainloop2();

void ammxGsCreate(void) {
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

void ammxGsLoop(void) {
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  static UBYTE ubDraw=0;

  if(keyCheck(KEY_ESCAPE)) {
    gameExit();
    return ;
  }
  g_pCustom->color[0]=0x0000;

  if (keyCheck(KEY_1))
  {
    static UBYTE ubOut[8];
    memset(&ubOut,0,8);
    ammxmainloop(&ubOut);
    if (ubOut[0]==0xAA && ubOut[1]==0xAA && ubOut[2]==0xAA && ubOut[3]==0xAA && ubOut[4]==0xBB && ubOut[5]==0xBB && ubOut[6]==0xBB && ubOut[7]==0xBB ) 
      g_pCustom->color[0]=0x000F;
    else  g_pCustom->color[0]=0x0F00;
  }

  if (ubDraw || keyCheck(KEY_2))
  {
    static UBYTE ubOut[8];
    memset(&ubOut,0xFF,8);
    g_pCustom->color[0] = 0x0FF0;
    ammxmainloop2((ULONG)s_pMainBuffer->pBack->Planes[0]);
    g_pCustom->color[0] = 0x0000;
    ubDraw=1;
    //if (ubOut[0]==0xFF && ubOut[1]==0xFF && ubOut[2]==0xFF && ubOut[3]==0xFF) 
    //if (ubOut[0]==0x00 && ubOut[1]==0x0b) 
    //if (ubOut[0]==0x01 && ubOut[1]==0x00 && ubOut[2]==0x00 && ubOut[3]==0x00 && ubOut[4]==0x00 && ubOut[5]==0x00 && ubOut[6]==0x00 && ubOut[7]==0x00 ) 
    //  g_pCustom->color[0]=0x00F0;
    //else  g_pCustom->color[0]=0x0F00;
    //systemUse();
    /*FILE* fd = fopen("lol.bin","w+");
    if (fd)
    {
      fwrite(ubOut,8,1,fd);
      fclose(fd);
    }*/
    //printf("D0 %x %x %x %x %x %x %x %x\n",ubOut[0],ubOut[1],ubOut[2],ubOut[3],ubOut[4],ubOut[5],ubOut[6],ubOut[7]);
    //systemUnuse();
    //gameExit();
  }

  vPortWaitForEnd(s_pVpMain);
}

void ammxGsDestroy(void) {
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}
