#include "fiocco.h"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameClose
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
//#include <fixmath/fix16.h>
#include "acedraw.h"
#include "../_res/discocrazy.h"

//#include "customtrigonometry.h"

#define BITPLANES 2

#define RECTMAXHEIGHT 80

long mt_init(const unsigned char *);
void mt_music();
void mt_end();

static UWORD colorHSV(UBYTE , UBYTE , UBYTE );

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
//static fix16_t tAngle;
static UWORD uwHeight =  RECTMAXHEIGHT;
void blitClear(tSimpleBufferManager *, UBYTE);
static  tAceFIgure* pRectangle;
UBYTE ubOffsetList[RECTMAXHEIGHT*2];
static UWORD s_uwBarY = 44;
static UBYTE s_ubBarHue = 0;


/*void DrawlineOr(UBYTE *, int, int, int, int);
void InitLine();*/

/*inline  int map( int x,  int in_min,  int in_max,  int out_min,  int out_max)
{
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}*/



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
   //   tCopCmd *pBarCmds = &pCopBfr->pList[s_uwCopRawOffs];



    UWORD pColors[32];
    UWORD pColorsFlake[32];
    for (UBYTE i = 0; i < 16; ++i)
    {
        pColors[i] = colorHSV(s_ubBarHue, 255, i * 17);
        pColorsFlake[i] = colorHSV(s_ubBarHue+100, 255, i * 17);
    }
    for (UBYTE i = 16; i < 32; ++i)
    {
        pColors[i] = colorHSV(s_ubBarHue, 255, (31 - i) * 17);
        pColorsFlake[i] = colorHSV(s_ubBarHue+100, 255, (31 - i) * 17);
    }

    for(UBYTE i = 0; i < 32; ++i) {
			copSetWait(&pCopCmds[i * 3 + 0].sWait, 0, s_uwBarY + i*8);
			copSetMove(&pCopCmds[i * 3 + 1].sMove, &g_pCustom->color[0], pColors[i]);
      if (s_uwBarY + i*8==252) copSetWait(&pCopCmds[i * 3 + 2].sWait, 0xdf, 0xff);
      else copSetMove(&pCopCmds[i * 3 + 2].sMove, &g_pCustom->color[1], pColorsFlake[i]);
		}
  
  CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			s_pView->pCopList->pFrontBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray
  s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red

  // We don't need anything from OS anymore
  systemUnuse();

  //fix16_sinlist_init();
  for (UBYTE ubCounter = 0; ubCounter < RECTMAXHEIGHT ; ubCounter++)
  {
    ubOffsetList[ubCounter]=ubCounter+1;
    ubOffsetList[RECTMAXHEIGHT*2-1-ubCounter]=ubCounter+1;
  }

  // Init figures
  pRectangle = AceFigureRectangle(16,uwHeight);

  // Init music
  mt_init(discocrazy_data);


  // Load the view
  viewLoad(s_pView);

  viewProcessManagers(s_pView);
    copProcessBlocks();
}

void gameGsLoop(void) 
{
  
  /*static UWORD tmpHeight = 8;
  static UWORD tmpHeightIncrementer = -1;*/
  static UWORD uwOffsetIncrementer = 7;

  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if(keyCheck(KEY_ESCAPE)) {
    gameClose();
  }
  if(keyUse(KEY_C)) {
    //tmpHeight--;
    //gameClose();
    uwOffsetIncrementer++;
  }
  if(keyUse(KEY_V)) {
    //tmpHeight--;
    //gameClose();
    uwOffsetIncrementer--;
  }

  else {

    

    //static UWORD uwIncrementer = 1;
    blitClear(s_pMainBuffer, 0);
    mt_music();
    blitClear(s_pMainBuffer, 1);

    // Increment tAngle each frame by 0.1


    // translate to the center of the screen
    acedrawTranslate(0,128);

    acedrawRectMode(ACEDRAWLINECENTER);
    //acedrawFill(255);

    tBitMap* pBitmap = (tBitMap*)((ULONG)s_pMainBuffer->pBack);
    static UWORD  uwAngle = 0;
    UWORD  uwOffset = 0;

    for (UWORD ubCounter = 0; ubCounter<320 ; ubCounter +=16 )
    {

      UWORD uwAngleIndex = uwAngle+uwOffset;
      while (uwAngleIndex>=RECTMAXHEIGHT*2) uwAngleIndex-=RECTMAXHEIGHT*2;
      
      acedrawRectangle(pRectangle,pBitmap,0,ubCounter,0,ubOffsetList[uwAngleIndex]);
      uwOffset+=uwOffsetIncrementer;
    }
    uwAngle+=2;
    if (uwAngle>=RECTMAXHEIGHT*2) uwAngle=0;

    static UWORD  uwAngle2 = RECTMAXHEIGHT;
    uwOffset=0;
    //acedrawTranslate(0,34);
    for (UWORD ubCounter = 0; ubCounter<320 ; ubCounter +=16 )
    {

      UWORD uwAngleIndex = uwAngle2+uwOffset;
      while (uwAngleIndex>=RECTMAXHEIGHT*2) uwAngleIndex-=RECTMAXHEIGHT*2;
      
      acedrawRectangle(pRectangle,pBitmap,1,ubCounter,0,ubOffsetList[uwAngleIndex]);
      uwOffset+=uwOffsetIncrementer;
    }

    uwAngle2+=2;
    if (uwAngle2>=RECTMAXHEIGHT*2) uwAngle2=0;
    
    /*tmpHeight+=tmpHeightIncrementer;
    if (tmpHeight<2 || tmpHeight>31) tmpHeightIncrementer*=-1;*/


    //s_pMainBuffer->pBack->BytesPerRow = 0;

  #if 0

    uwHeight+=uwIncrementer;
    blitClear(s_pMainBuffer, 0);

    fix16_t offset = 0;
    for (UWORD uwLoop = 0;uwLoop<300;uwLoop+=10)
    {
      fix16_t a  = fix16_add(tAngle,offset);
      uwHeight = (UWORD)map( fix16_to_int(fix16_sinlist[tAngle]),-1,1,0,100 );
      acedrawRect(s_pMainBuffer,uwLoop-150,0,9,uwHeight);
      offset = fix16_add(offset,fix16_div (fix16_from_int(1),fix16_from_int(10)));
    }
    // if (uwHeight>=100 || uwHeight<=1) uwIncrementer*=-1;

    tAngle = fix16_add(tAngle,fix16_div (fix16_from_int(1),fix16_from_int(10)));
    if (fix16_to_int(tAngle)>360)  tAngle=0;

    // Process loop normally
    // We'll come back here later

    /*InitLine();
    g_pCustom->bltbdat = 0xffff;

    DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]), 
                80 , 
                80 , 
                100, 
                100
    );*/
#endif
    vPortWaitForEnd(s_pVpMain);
    viewProcessManagers(s_pView);
    
    copSwapBuffers();
  }
}

void gameGsDestroy(void) {

  mt_end();

  // Cleanup when leaving this gamestate
  systemUse();

  AceFigureFree(pRectangle);

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}

void blitClear(tSimpleBufferManager *buffer, UBYTE nBitplane)
{
    blitWait();
    //waitblit();
    g_pCustom->bltcon0 = 0x0100;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = 0x0000;
    g_pCustom->bltdpt = (UBYTE *)((ULONG)buffer->pBack->Planes[nBitplane]);
    g_pCustom->bltsize = 0x3794;

    return;
}


/**
 * Converts 24-bit HSV to 12-bit RGB
 * This fn is messy copypasta from stackoverflow to make it run on 12-bit.
 */
static UWORD colorHSV(UBYTE ubH, UBYTE ubS, UBYTE ubV)
{
    UBYTE ubRegion, ubRem, p, q, t;

    if (ubS == 0)
    {
        ubV >>= 4; // 12-bit fit
        return (ubV << 8) | (ubV << 4) | ubV;
    }

    ubRegion = ubH / 43;
    ubRem = (ubH - (ubRegion * 43)) * 6;

    p = (ubV * (255 - ubS)) >> 8;
    q = (ubV * (255 - ((ubS * ubRem) >> 8))) >> 8;
    t = (ubV * (255 - ((ubS * (255 - ubRem)) >> 8))) >> 8;

    ubV >>= 4;
    p >>= 4;
    q >>= 4;
    t >>= 4; // 12-bit fit
    switch (ubRegion)
    {
    case 0:
        return (ubV << 8) | (t << 4) | p;
    case 1:
        return (q << 8) | (ubV << 4) | p;
    case 2:
        return (p << 8) | (ubV << 4) | t;
    case 3:
        return (p << 8) | (q << 4) | ubV;
    case 4:
        return (t << 8) | (p << 4) | ubV;
    default:
        return (ubV << 8) | (p << 4) | q;
    }
}

