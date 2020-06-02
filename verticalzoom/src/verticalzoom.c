#include "verticalzoom.h"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameClose
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>

// #define  DO_LOG_WRITE

#include "../_res/valchiria320x256.h"

static tView *s_pView; // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs;
static UWORD s_uwYImgRes = 256;
static UWORD s_uwRawToHide[] = {

127, 143,
 111, 159,
  95, 175, 
  79, 191,
  63, 207, 
  47, 223, 
  31, 239, 
 15, 255, 
  
  126, 144, 109, 161, 92, 178, 75, 195, 58, 212, 41, 229, 24, 246, 7, 128, 146, 108, 164, 90, 182, 72, 200, 54, 218, 36, 236, 18, 254, 0, 125, 147, 106, 166, 87, 185, 68, 204, 49, 224, 29, 243, 10, 129, 149, 105, 169, 85, 189, 65, 210, 44, 231, 23, 251, 3, 124, 150, 103, 171, 82, 193, 60, 215, 38, 237, 16, 130, 152, 102, 174, 80, 198, 56, 221, 33, 245, 9, 123, 153, 100, 177, 76, 202, 51, 227, 26, 252, 1, 131, 155, 99, 181, 73, 208, 46, 234, 20, 122, 156, 97, 184, 69, 213, 40, 241, 12, 132, 158, 96, 188, 66, 219, 35, 249, 5, 121, 160, 93, 192, 61, 225, 28, 133, 163, 91, 197, 57, 232, 22, 120, 165, 88, 201, 52, 238, 14, 134, 168, 86, 206, 48, 247, 8, 119, 170, 83, 211, 42, 253, 118, 172, 78, 216, 34, 135, 176, 77, 222, 30, 117, 179, 71, 228, 21, 136, 183, 70, 235, 17, 116, 186, 64, 242, 6, 137, 190, 62, 250, 2, 115, 194, 55, 138, 199, 53, 114, 203, 45, 139, 209, 43, 113, 214, 37, 140, 220, 32, 112, 226, 25, 141, 233, 19, 110, 240, 11, 142, 248, 4, 107, 145, 104, 148, 101, 151, 98, 154, 94, 157, 89, 162, 84, 167, 81,13,244,27,230,39,217,50,205,59,196,67,205,74,217,230
};
// extra 
/*13
27
39
50
59
67
74
173
180
187
196
205
217
230
244*/

static UWORD s_uwRawToHide2[] = {
  1,
  2,
 4, 5,
  6, 7, 
  8, 9, 
  10, 11, 
  13, 12, 
  14, 15, 
  16, 17,3
  };

static tCopBfr *s_pCopBfr;
static tCopCmd *s_pBarCmds;
static int s_iHideCounter = 0;
static UBYTE s_ubDiwStrt = 0x2c;
static UBYTE s_ubDiwStop = 0x2c;
static UBYTE s_ubMoveArray[256];

void copyToMainBpl(const unsigned char*,const UBYTE, const UBYTE);
UWORD getConsecutiveRowsBefore(UWORD uwRowIndex);
UWORD getConsecutiveRowsAfter(UWORD uwRowIndex);
void setBplModuleAt(UWORD uwIndex,UWORD uwModValue,UBYTE ubDoWait)
{
  if (ubDoWait) copSetWait(&s_pBarCmds[uwIndex * 3 + 0].sWait, 0, 44+uwIndex);
  copSetMove(&s_pBarCmds[uwIndex * 3 + 1].sMove, &g_pCustom->bpl1mod, uwModValue);
  copSetMove(&s_pBarCmds[uwIndex * 3 + 2].sMove, &g_pCustom->bpl2mod, uwModValue);
  
}

// Shrink and expand functions
UBYTE shrinkFromBottom();
UBYTE expandFromBottom();
UBYTE shrinkFromTop();
UBYTE expandFromTop();



void setBplModuleAt3(UWORD uwIndex,UWORD uwModValue,UBYTE ubDoWait)
{
  if (ubDoWait)
  {
    if (0 && 43+uwIndex==255) copSetWait(&s_pBarCmds[uwIndex * 4 + 0].sWait, 0xdf, 43+uwIndex);
    else copSetWait(&s_pBarCmds[uwIndex * 4 + 0].sWait, 0x00, 43+uwIndex);
    
  }
  copSetMove(&s_pBarCmds[uwIndex * 4 + 1].sMove, &g_pCustom->bpl1mod, uwModValue);
  copSetMove(&s_pBarCmds[uwIndex * 4 + 2].sMove, &g_pCustom->bpl2mod, uwModValue);
  if (43+uwIndex==255)
  {
    copSetWait(&s_pBarCmds[uwIndex * 4 + 3].sWait, 0xdf,0xff);
    //copSetMove(&s_pBarCmds[uwIndex * 4 + 3].sMove, &g_pCustom->color[0],0x0f00);
  }
  else copSetMove(&s_pBarCmds[uwIndex * 4 + 3].sMove, &g_pCustom->color[0],ubDoWait?0: 0x0f00);

}

inline void myCopSetMove(tCopMoveCmd *pMoveCmd, UWORD uwValue) {
	pMoveCmd->bfUnused = 0;
	// pMoveCmd->bfDestAddr = (ULONG)pAddr - (ULONG)((UBYTE *)g_pCustom);
	pMoveCmd->bfValue = uwValue;
}

void gameGsCreate(void) {

       ULONG ulRawSize = (
			simpleBufferGetRawCopperlistInstructionCount(4) +
			s_uwYImgRes * 4 + // s_uwYImgRes modules changes - each consists of WAIT + 2 MOVE instruction
			1 + // Final WAIT
			1 // Just to be sure
		);

  // Create a view - first arg is always zero, then it's option-value
  s_pView = viewCreate(0,
    TAG_VIEW_GLOBAL_CLUT, 1, // Same Color LookUp Table for all viewports
    TAG_VIEW_COPLIST_MODE, VIEW_COPLIST_MODE_RAW,
  //TAG_VIEW_COPLIST_MODE,VIEW_COPLIST_MODE_BLOCK,
		TAG_VIEW_COPLIST_RAW_COUNT, ulRawSize,
  TAG_DONE); // Must always end with TAG_END or synonym: TAG_DONE

  // Now let's do the same for main playfield
  s_pVpMain = vPortCreate(0,
    TAG_VPORT_VIEW, s_pView,
    TAG_VPORT_BPP, 4, // 3 bits per pixel, 8 colors
   // TAG_VPORT_HEIGHT, 224,
    // We won't specify height here - viewport will take remaining space.
  TAG_DONE);
  s_pMainBuffer = simpleBufferCreate(0,
    TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
    TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
   TAG_SIMPLEBUFFER_COPLIST_OFFSET, 0,
  TAG_DONE);

   s_uwCopRawOffs = simpleBufferGetRawCopperlistInstructionCount(4);


  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpMain->pPalette[0] = 0x06f2; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0000; // Gray
  s_pVpMain->pPalette[2] = 0x0000; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0000; // Blue - same brightness as red
  s_pVpMain->pPalette[4] = 0x0019;
  s_pVpMain->pPalette[5] = 0x0b66;
  s_pVpMain->pPalette[6] = 0x0ccc;
  s_pVpMain->pPalette[7] = 0x0620;

  s_pVpMain->pPalette[8] = 0x0955;
  s_pVpMain->pPalette[9] = 0x0069;
  s_pVpMain->pPalette[10] = 0xe0a;
  s_pVpMain->pPalette[11] = 0x0f99;
  s_pVpMain->pPalette[12] = 0x0f88;
  s_pVpMain->pPalette[13] = 0x0eaa;
  s_pVpMain->pPalette[14] = 0x0004;
  s_pVpMain->pPalette[15] = 0x0346;

  copyToMainBpl(valchiria_data,0,4);

  tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  tCopCmd *pBarCmds = &pCopBfr->pList[s_uwCopRawOffs];

  s_pCopBfr = pCopBfr;
  s_pBarCmds = pBarCmds;

  for (UWORD uwCounter = 0 ; uwCounter <= s_uwYImgRes; uwCounter ++)
  {
    setBplModuleAt3(uwCounter,(UWORD) 0x0000,1);
  }
  
  // Copy the same thing to front buffer, so that copperlist has the same
		// structure on both buffers and we can just update parts we need
		CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			s_pView->pCopList->pFrontBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);

  // Load the view
  viewLoad(s_pView);

    // We don't need anything from OS anymore
  systemUnuse();

  /*blitLine(s_pMainBuffer->pBack, 0, 0, 100, 0, 12, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 1, 200, 1, 6, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 2, 100, 2, 10, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 3, 200, 3, 9, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 4, 100, 4, 8, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 5, 200, 5, 7, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 6, 100, 6, 5, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 7, 200, 7, 4, 0xffff,0);*/

  /*blitLine(s_pMainBuffer->pBack, 0, 255-0, 100, 255-0, 12, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 255-1, 100, 255-1, 11, 0xffff,0);
  blitLine(s_pMainBuffer->pBack, 0, 255-2, 100, 255-2, 10, 0xffff,0);*/

  memset(s_ubMoveArray,0,sizeof(s_ubMoveArray));

  //copProcessBlocks();
}

void gameGsLoop(void) 
{

  static UBYTE ubFrameModule = 0;
  static UBYTE automaticMode = 0;
  UBYTE ubRefresh = 0;

  //g_pCustom->color[0] = 0x0F00;
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if(keyUse(KEY_ESCAPE)) 
  {
    gameClose();
  }

  // Automatic mode On
  if (keyUse(KEY_Q))
  {
    automaticMode=1;
  }

  // Automatic mode Off
  else if (keyUse(KEY_W))
  {
    automaticMode=0;
  }
  else if (keyUse(KEY_D))
  {
    copDumpBfr(s_pCopBfr);
    //gameClose();
    return ;
  }
  
  if (keyCheck(KEY_Z))
  {
    ubRefresh = shrinkFromBottom(); // Shrinks image hiding rows on the bottom and compressing towards upper part of the screen
  }
  else if (keyCheck(KEY_A))
  {
    ubRefresh = expandFromBottom(); // Expange image showing news rows on the bottom of the screen
  }

  else if (keyCheck(KEY_X))
  {
    ubRefresh = shrinkFromTop();
  }

  else if (keyCheck(KEY_S))
  {
    ubRefresh = expandFromTop();
  }

  // Shrink alternatively up-down
  else if (automaticMode == 1 || keyCheck(KEY_C))
  {
    if (ubFrameModule==0)
    {
      ubRefresh = shrinkFromTop();
      ubFrameModule=1;
    }
    else
    {
      ubRefresh = shrinkFromBottom();
      ubFrameModule=0;
    }
    if (automaticMode == 1 && ubRefresh == 0) automaticMode=2;
  }

  // Expand alternatively up-down
  else if (automaticMode == 2 || keyCheck(KEY_D))
  {
    if (ubFrameModule==0)
    {
      ubRefresh = expandFromTop();
      ubFrameModule=1;
    }
    else
    {
      ubRefresh = expandFromBottom();
      ubFrameModule=0;
    }

    if (automaticMode == 2 && ubRefresh == 0) automaticMode=1;
  }

  if (ubRefresh) 
  {
      
    ubRefresh=0;

    UWORD uwNewBplModValue;
    UWORD uwRayCounter = s_ubDiwStrt-0x2c;
    UWORD uWModdedRows = 0;
    for (UWORD uwCounter = 0 ; uwCounter < s_uwYImgRes && uwRayCounter<s_uwYImgRes; uwCounter ++)
    {
      
      UWORD uwNewIndex = uwRayCounter;

      myCopSetMove(&s_pBarCmds[uwNewIndex * 4 + 1].sMove, 0x0000);
      myCopSetMove(&s_pBarCmds[uwNewIndex * 4 + 2].sMove, 0x0000);

      if (s_ubMoveArray[uwCounter]==0)
      {
        /*myCopSetMove(&s_pBarCmds[uwNewIndex * 4 + 1].sMove, 0x0000);
        myCopSetMove(&s_pBarCmds[uwNewIndex * 4 + 2].sMove, 0x0000);*/
        uwRayCounter++;
      }
      else
      {

        /*myCopSetMove(&s_pBarCmds[uwNewIndex * 4 + 1].sMove, 0x0000);
        myCopSetMove(&s_pBarCmds[uwNewIndex * 4 + 2].sMove, 0x0000);*/

        // quante righe consecutive sotto???
        UWORD uwConsecutiveRowsAfter = getConsecutiveRowsAfter(uwCounter);
        uwNewBplModValue = 40 + uwConsecutiveRowsAfter*40;

        uwNewIndex-=uWModdedRows;
  #ifdef DO_LOG_WRITE
        logWrite("Righe sotto consecutive : %u\n",uwConsecutiveRowsAfter);
        logWrite("Imposto singolo mod alla riga : %u\n",uwNewIndex);
#endif

        myCopSetMove(&s_pBarCmds[uwNewIndex * 4 + 1].sMove, uwNewBplModValue);
        myCopSetMove(&s_pBarCmds[uwNewIndex * 4 + 2].sMove, uwNewBplModValue);

        for (UWORD uwNextCounter = 1 ; uwNextCounter <= uwConsecutiveRowsAfter; uwNextCounter++)
        {
          UWORD uwNewIndex2=uwNextCounter+uwNewIndex;
  #ifdef DO_LOG_WRITE
          logWrite("Mod aggiuntivo a zero per indice : %u\n",uwNewIndex2);
  #endif
          if (uwNewIndex2<256)
          {
          myCopSetMove(&s_pBarCmds[uwNewIndex2 * 4 + 1].sMove, 0x0000);
          myCopSetMove(&s_pBarCmds[uwNewIndex2 * 4 + 2].sMove, 0x0000);
          }
        }
        uWModdedRows++;
        uwRayCounter++;
        uwCounter+=uwConsecutiveRowsAfter;
      }
    }

    //copDumpBfr(s_pCopBfr);


    /*CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			s_pView->pCopList->pFrontBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);*/
    //g_pCustom->color[0] = 0x0000;
    // Process loop normally
    // We'll come back here later
  }

	//copProcessBlocks();
	vPortWaitForEnd(s_pVpMain);
}

void gameGsDestroy(void) 
{
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}

// Function to copy data to a main bitplane
// Pass ubMaxBitplanes = 0 to use all available bitplanes in the bitmap
void copyToMainBpl(const unsigned char* pData,const UBYTE ubSlot,const UBYTE ubMaxBitplanes)
{
  UBYTE ubBitplaneCounter;
  for (ubBitplaneCounter=0;ubBitplaneCounter<s_pMainBuffer->pBack->Depth;ubBitplaneCounter++)
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
    g_pCustom->bltapt = (UBYTE*)((ULONG)&pData[40*256*ubBitplaneCounter]);
    g_pCustom->bltdpt = (UBYTE*)((ULONG)s_pMainBuffer->pBack->Planes[ubBitplaneCounter]+(40*ubSlot));
    g_pCustom->bltsize = 0x4014;
    if (ubMaxBitplanes>0 && ubBitplaneCounter+1>=ubMaxBitplanes) return ;
  }
  return ;
}

// Occhio che faccio tornare il modulo!!!!!
UWORD getConsecutiveRowsBefore(UWORD uwRowIndex)
{
  WORD wOffsetTmp = uwRowIndex-1;
  UWORD uwConsecutiveRows = 0;
  while (wOffsetTmp>=0 && s_ubMoveArray[wOffsetTmp])
  {
    uwConsecutiveRows++;
    wOffsetTmp--;
  }
  return uwConsecutiveRows;
}

// Occhio che faccio tornare il modulo!!!!!
UWORD getConsecutiveRowsAfter(UWORD uwRowIndex)
{
  WORD wOffsetTmp = uwRowIndex+1;
  UWORD uwConsecutiveRows = 0;
  while (wOffsetTmp<256 && s_ubMoveArray[wOffsetTmp])
  {
    uwConsecutiveRows++;
    wOffsetTmp++;
  }
  return uwConsecutiveRows;
}

UBYTE shrinkFromBottom()
{
  // Check if there is some row to hide
  if ((size_t)s_iHideCounter+1>sizeof(s_uwRawToHide)/sizeof(UWORD)) return 0;
   
  // Move diwstop up of one unit
  s_ubDiwStop --;
  g_pCustom->diwstop =(s_ubDiwStop<<8)|0x00C1;

  // set the row I want to hide uquals to 1
  s_ubMoveArray[s_uwRawToHide[s_iHideCounter]]=1;
  
  // Next time we will get the following row
  s_iHideCounter++;
  return 1;
}

UBYTE expandFromBottom()
{
  // Check if there is some row to hide
  if ((size_t)s_iHideCounter<=0) return 0;
  
  // Move diwstop down one unit
  s_ubDiwStop ++;
  g_pCustom->diwstop =(s_ubDiwStop<<8)|0x00C1;

  // Go to the previous row...
  s_iHideCounter--;

  // and set his value to 0 because we want to show it
  s_ubMoveArray[s_uwRawToHide[s_iHideCounter]]=0;
  return 1;
}

UBYTE shrinkFromTop()
{
  // Check if there is some row to hide
  if ((size_t)s_iHideCounter+1>sizeof(s_uwRawToHide)/sizeof(UWORD)) return 0;
   
  // Move Diwstrt down one pixel
  s_ubDiwStrt ++;
  g_pCustom->diwstrt =(s_ubDiwStrt<<8)|0x0081;

  // set the row I want to hide uquals to 1
  s_ubMoveArray[s_uwRawToHide[s_iHideCounter]]=1;

  // Next time we will get the following row
  s_iHideCounter++;

  return 1;
}

UBYTE expandFromTop()
{
  // Check if there is some row to hide
  if ((size_t)s_iHideCounter<=0) return 0;

  // Move diwstrt up one pixel
  s_ubDiwStrt --;
  g_pCustom->diwstrt =(s_ubDiwStrt<<8)|0x0081;

  // Go to the previous row...
  s_iHideCounter--;

  // Clear the row I want to hide
  s_ubMoveArray[s_uwRawToHide[s_iHideCounter]]=0;

  return 1;
}