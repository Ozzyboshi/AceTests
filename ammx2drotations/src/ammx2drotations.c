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
void ammxmainloop2();
ULONG ammxmainloop3();
void ammxmainloop3_init();

void ammx2drotationsGsCreate(void) {
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(BITPLANES) +
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
    //TAG_VPORT_HEIGHT,128,
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
  s_pVpMain->pPalette[1] = 0x0F00; // Gray
  s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red

  // We don't need anything from OS anymore
  systemUnuse();
  //Disable();

  // Load the view
  viewLoad(s_pView);

  //ammxmainloop3_init();

   //g_pCustom->diwstrt = 0x2c81;
   //g_pCustom->diwstop = 0x00c1;

   //g_pCustom->dmacon = DMAF_RASTER;
  
}

void ammx2drotationsGsLoop(void) {
  static UBYTE stage = 2;
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  //Forbid();
  //Enable();
  if(keyCheck(KEY_ESCAPE)) {
    gameExit();
    return ;
  }
  if(keyCheck(KEY_0)) stage=0;
  if(keyCheck(KEY_1)) stage=1;
  if(keyCheck(KEY_2)) stage=2;
  //Disable();
/*for (int lol = 0;lol <1000; lol++)*/
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
  vPortWaitForEnd(s_pVpMain);
  vPortWaitForEnd(s_pVpMain);*/


  //g_pCustom->color[0] = 0x00F0;
    if (stage==0) ammxmainloop((ULONG)s_pMainBuffer->pBack->Planes);
    else if (stage==1) ammxmainloop2((ULONG)s_pMainBuffer->pBack->Planes);
    else if (0 && stage==2) 
    {

      ULONG screen0;
      screen0 = ammxmainloop3((ULONG)s_pMainBuffer->pBack->Planes);
        //vPortWaitForEnd(s_pVpMain);

    //  g_pCustom->color[0] = 0x0000;
      tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
    tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[0];
    tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[0];
/*copSetMove(&pCmdListBack[6].sMove, &g_pBplFetch[0].uwHi, screen0 >> 16);
			copSetMove(&pCmdListBack[7].sMove, &g_pBplFetch[0].uwLo, screen0 & 0xFFFF);*/
      copSetMove(&pCmdListFront[6].sMove, &g_pBplFetch[0].uwHi, screen0 >> 16);
			copSetMove(&pCmdListFront[7].sMove, &g_pBplFetch[0].uwLo, screen0 & 0xFFFF);
      
screen0+=40*256;
      /*copSetMove(&pCmdListBack[8].sMove, &g_pBplFetch[1].uwHi, screen0 >> 16);
			copSetMove(&pCmdListBack[9].sMove, &g_pBplFetch[1].uwLo, screen0 & 0xFFFF);*/
      copSetMove(&pCmdListFront[8].sMove, &g_pBplFetch[1].uwHi, screen0 >> 16);
			copSetMove(&pCmdListFront[9].sMove, &g_pBplFetch[1].uwLo, screen0 & 0xFFFF);


      //tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
      //tCopCmd *pCmdList = &pCopList->pBackBfr->pList[s_pMainBuffer->uwCopperOffset];
      //tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
      //pCopCmds = &pCopBfr->pList[0];

     /* tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  pCopCmds = &pCopBfr->pList[0];*/
      /*copSetMove(&pCopCmds[0].sMove, &g_pBplFetch[0].uwHi, screen0 >> 16);
			copSetMove(&pCopCmds[1].sMove, &g_pBplFetch[0].uwLo, screen0 & 0xFFFF);
      copSetMove(&pCopCmds[2].sMove, &g_pBplFetch[0].uwHi, screen0 >> 16);
			copSetMove(&pCopCmds[3].sMove, &g_pBplFetch[0].uwLo, screen0 & 0xFFFF);
      copSetMove(&pCopCmds[4].sMove, &g_pBplFetch[0].uwHi, screen0 >> 16);*/
			//copSetMove(&pCopCmds[5].sMove, &g_pBplFetch[0].uwLo, screen0 & 0xFFFF);
      

     // copSwapBuffers();
  	//copProcessBlocks();

      //copSetMove(&pCopCmds[8 + 0 + 0].sMove, &g_pBplFetch[0].uwHi, screen0 >> 16);
			//copSetMove(&pCopCmds[8 + 0 + 1].sMove, &g_pBplFetch[0].uwLo, screen0 & 0xFFFF);

     //*(s_pMainBuffer->pBack->Planes[0]) = screen0;
     //*(s_pMainBuffer->pFront->Planes[0]) = screen0;

    }
    //g_pCustom->color[0] = 0x0000;
  mt_music();
  vPortWaitForEnd(s_pVpMain);
  copSwapBuffers();
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
