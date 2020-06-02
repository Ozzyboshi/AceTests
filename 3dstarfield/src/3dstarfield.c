#include "3dstarfield.h"

#include <time.h>
#include <stdlib.h>

#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameClose
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>

#include <fixmath/fix16.h>

#include "../_res/discocrazy.h"



#define BITPLANES 1
#define SPEED 10
#define STARNUM 100


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


void blitClear(tSimpleBufferManager *, UBYTE );
void InitLine();
void DrawlineOr(UBYTE *, int, int, int, int);
UBYTE printCursorPixel(tSimpleBufferManager* ,UWORD ,UWORD );
long mt_init(const unsigned char *);
void mt_music();
void mt_end();

/*inline unsigned int map(unsigned int x, unsigned int in_min, unsigned int in_max, unsigned int out_min, unsigned int out_max)
{
  fix16_t f16X = fix16_from_int(x);

            0.5           320                   1                   0
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}*/


struct tStar
{
  int iX;
  int iY;
  int iZ;
  int iPZ;
  int iPx;
  int iPy;
};

static struct tStar g_tStarVector[STARNUM];

void starsInit()
{
  time_t t;
  srand((unsigned)time(&t));
  for (unsigned int uiI=0;uiI<STARNUM;uiI++)
  {
    
    int negative = ( int)(rand() % 320);
    if (negative%2) negative=1;
    else negative = -1;

    int negative2 = ( int)(rand() % 9);
    if (negative2%2) negative2=1;
    else negative2 = -1;

    negative = uiI%3?1:-1;
    negative2 = uiI%2?1:-1;

    g_tStarVector[uiI].iX = negative * ( int)(rand() % 80);
    g_tStarVector[uiI].iY = negative2 * ( int)(rand() % 64);
    //g_tStarVector[uiI].iZ = (unsigned int)(rand() % 320);
    g_tStarVector[uiI].iZ = ( int)(rand() % 319);
    //g_tStarVector[uiI].iZ = 319;
    //g_tStarVector[uiI].iPZ = g_tStarVector[uiI].iZ;

    g_tStarVector[uiI].iPx = 0;
    g_tStarVector[uiI].iPy = 0;

  }
}

void starsMove()
{
  for (unsigned int uiI=0;uiI<STARNUM;uiI++)
  {
    if (g_tStarVector[uiI].iZ>SPEED)
    {
      g_tStarVector[uiI].iPZ=g_tStarVector[uiI].iZ;
      g_tStarVector[uiI].iZ-=SPEED;
    }
    else g_tStarVector[uiI].iZ = 319;
  }
}

// Draw stars in the bitplane
void starsDraw()
{
  //blitWait();
  for (unsigned int uiI=0;uiI<STARNUM;uiI++)
  {
    



    fix16_t x = fix16_div(
      fix16_from_int(g_tStarVector[uiI].iX),
      fix16_from_int(g_tStarVector[uiI].iZ)
    );

    fix16_t y = fix16_div(
      fix16_from_int(g_tStarVector[uiI].iY),
      fix16_from_int(g_tStarVector[uiI].iZ)
    );

    x = fix16_mul(x,fix16_from_int(319));
    y = fix16_mul(y,fix16_from_int(255));

    WORD uwXDraw = (int) fix16_to_int(x);
    if (uwXDraw > 160 || uwXDraw < -160)
    {
      g_tStarVector[uiI].iPZ = -1;
      g_tStarVector[uiI].iZ = 319;
      continue;
    }

    WORD uwYDraw = (UWORD) fix16_to_int(y);
    if (uwYDraw > 128 || uwYDraw < -128 )
    {
      g_tStarVector[uiI].iPZ = -1;
      g_tStarVector[uiI].iZ = 319;
      continue;
    }

    uwXDraw += 160;
    uwYDraw +=128;
    
    //logWrite("preced3 %d = %d \n",(int)g_tStarVector[uiI].iPx,(UWORD)uwXDraw);

    printCursorPixel(s_pMainBuffer,(UWORD)uwXDraw, uwYDraw);

    

    //if (g_tStarVector[uiI].iZ>150) continue;
    if (g_tStarVector[uiI].iZ<200)
    {
      if (uwXDraw<319)
        printCursorPixel(s_pMainBuffer,uwXDraw+1, uwYDraw);

      if (uwXDraw>0)
          printCursorPixel(s_pMainBuffer,uwXDraw-1, uwYDraw);

      if (uwYDraw<254)
          printCursorPixel(s_pMainBuffer,uwXDraw, uwYDraw+1);

      if (uwYDraw>0)
          printCursorPixel(s_pMainBuffer,uwXDraw, uwYDraw-1);
    }
    /*else
    {
      if (uwXDraw<319)
        printCursorPixel(s_pMainBuffer,uwXDraw+1, uwYDraw);

      if (uwXDraw>0)
          printCursorPixel(s_pMainBuffer,uwXDraw-1, uwYDraw);

      if (uwYDraw<254)
          printCursorPixel(s_pMainBuffer,uwXDraw, uwYDraw);

      if (uwYDraw>0)
          printCursorPixel(s_pMainBuffer,uwXDraw, uwYDraw);
    }*/
    

    //logWrite("preced4 %d = %d \n",(int)g_tStarVector[uiI].iPx,(UWORD)uwXDraw);

   /* fix16_t px = fix16_div(
      fix16_from_int(g_tStarVector[uiI].iX),
      fix16_from_int(g_tStarVector[uiI].iPZ)
    );

    fix16_t py = fix16_div(
      fix16_from_int(g_tStarVector[uiI].iY),
      fix16_from_int(g_tStarVector[uiI].iPZ)
    );

    px = fix16_mul(px,fix16_from_int(g_tStarVector[uiI].iPZ));
    py = fix16_mul(py,fix16_from_int(g_tStarVector[uiI].iPZ));

    WORD uwPXDraw = (UWORD) fix16_to_int(px);
    WORD uwPYDraw = (UWORD) fix16_to_int(py);

    uwPXDraw += 160;
    uwPYDraw +=128;*/


    if (g_tStarVector[uiI].iZ<300 )
    {
      InitLine();
      //blitWait();
      g_pCustom->bltbdat = 0xFFFF;
      DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]),(UWORD) uwXDraw,(UWORD)uwYDraw , (int)g_tStarVector[uiI].iPx, (int)g_tStarVector[uiI].iPy);
      //vPortWaitForEnd(s_pVpMain);
     //printCursorPixel(s_pMainBuffer,(UWORD)g_tStarVector[0].iPx, (UWORD)g_tStarVector[uiI].iPy);
     //logWrite("aaaaa %d\n",(int)g_tStarVector[uiI].iPx);
     
     // Drawline((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]), g_tStarVector[uiI].iPx,g_tStarVector[uiI].iPy , (int) uwXDraw, (int)uwYDraw);
      //blitLine(s_pMainBuffer->pBack, g_tStarVector[uiI].iPx,g_tStarVector[uiI].iPy ,  uwXDraw, uwYDraw,1, 0xffff, 0);
    }

  g_tStarVector[uiI].iPx = (int)uwXDraw;
  //logWrite("preced %d = %d \n",(int)g_tStarVector[uiI].iPx,(UWORD)uwXDraw);
  g_tStarVector[uiI].iPy = (int)uwYDraw;


  if (uiI%5==0) 
  {
    
    vPortWaitForEnd(s_pVpMain);
    mt_music();
  }
  //logWrite("preced2 %d = %d \n",(int)g_tStarVector[uiI].iPx,(UWORD)uwXDraw);

  
    /*InitLine();
    g_pCustom->bltbdat = 0xFFFF;
    DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]),uwXDraw+1, uwYDraw+1,uwPXDraw,uwPYDraw);
    continue;*/

    /*if (g_tStarVector[uiI].iZ>250) continue;
    if (uwXDraw<319 && uwYDraw<254) printCursorPixel(s_pMainBuffer,uwXDraw+1, uwYDraw+1);*/

    

    

    //g_tStarVector[uiI].iPZ=g_tStarVector[uiI].iZ;


    /*InitLine();
    g_pCustom->bltbdat = 0xFFFF;
    DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]),(int)uwPXDraw, (int)uwPYDraw,(int)uwXDraw,(int) uwYDraw);*/
    
    //DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]),(int)100, (int)100,(int)uwXDraw,(int) uwYDraw);

  }
}


void gameGsCreate(void) {
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
    TAG_SIMPLEBUFFER_IS_DBLBUF, 1,
  TAG_END);
  
  s_uwCopRawOffs = simpleBufferGetRawCopperlistInstructionCount(BITPLANES);
  tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  pCopCmds = &pCopBfr->pList[s_uwCopRawOffs];
  
  CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			s_pView->pCopList->pFrontBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray


  // We don't need anything from OS anymore
  systemUnuse();

  starsInit();

  mt_init(g_tDiscocrazy_data_data_fast);

  // Load the view
  viewLoad(s_pView);
}

void gameGsLoop(void) {

  mt_music();
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if(keyCheck(KEY_ESCAPE)) {
    gameClose();
    return ;
  }
    blitClear(s_pMainBuffer,0);
    starsMove();
     //blitWait();
    starsDraw();
    
    vPortWaitForEnd(s_pVpMain);
    viewProcessManagers(s_pView);
    //copProcessBlocks();
    copSwapBuffers();
}

void gameGsDestroy(void) {
  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}

UBYTE printCursorPixel(tSimpleBufferManager* pMainBuffer,UWORD uwXCoordinate,UWORD uwYCoordinate)
{
  UBYTE ris=0;
  UBYTE* primo = (UBYTE*)((ULONG)pMainBuffer->pBack->Planes[0]);
  /*UBYTE* secondo = (UBYTE*)((ULONG)pMainBuffer->pBack->Planes[1]);
  UBYTE* terzo = (UBYTE*)((ULONG)pMainBuffer->pBack->Planes[2]);
  UBYTE* quarto = (UBYTE*)((ULONG)pMainBuffer->pBack->Planes[3]);*/
  
  primo+=40*uwYCoordinate; // Y Offset
  /*secondo+=uwOffset*uwYCoordinate;
  terzo+=uwOffset*uwYCoordinate; // Y Offset
  quarto+=uwOffset*uwYCoordinate;*/

  UBYTE resto=(UBYTE)uwXCoordinate&7;
  UWORD temp=uwXCoordinate>>3;

  primo+=temp;
  /*secondo+=temp;
  terzo+=temp;
  quarto+=temp;*/

  temp=~resto;
  resto=temp&7;

  // Set bit to 1 only if it is zero
  if (!(((*primo) >> resto) & 1))
  {
    *primo|=1UL<<resto;
    ris|=1;
  }

  /*if (!(((*secondo) >> resto) & 1))
  {
    *secondo|=1UL<<resto;
    ris|=2;
  }

  if (!(((*terzo) >> resto) & 1))
  {
    *terzo|=1UL<<resto;
    ris|=4;
  }

  if (!(((*quarto) >> resto) & 1))
  {
    *quarto|=1UL<<resto;
    ris|=8;
  }*/

  return ris;
}

void blitClear(tSimpleBufferManager *buffer, UBYTE nBitplane)
{
    blitWait();
    g_pCustom->bltcon0 = 0x0100;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = 0x0000;
    g_pCustom->bltdpt = (UBYTE *)((ULONG)buffer->pBack->Planes[nBitplane]);
    g_pCustom->bltsize = 0x4014;

    return;
}
