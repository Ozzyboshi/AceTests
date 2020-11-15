#include "curtains.h"
#include <ace/managers/key.h>    // Keyboard processing
#include <ace/managers/game.h>   // For using gameExit
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/blit.h>
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer

#define FIX16
#ifdef FIX16
#include <fixmath/fix16.h>
#endif
#include "../_res/valchiria320x256.h"

#define BITPLANES 5

#ifdef FIX16
typedef struct
{
  fix16_t x;
  fix16_t y;
} v2d;
static v2d g_Gravity;

inline void v2d_add(v2d *dest, const v2d *a, const v2d *b)
{
  dest->x = fix16_add(a->x, b->x);
  dest->y = fix16_add(a->y, b->y);
}

inline void v2d_zero(v2d *dest)
{
  dest->x = 0;
  dest->y = 0;
}

#endif

typedef struct TCurtain
{
  UBYTE ubPosition; // Position of the courtain inside the mask list
  UBYTE ubOffset;   // where in the bitplanes print the courtain (in bytes from 0 to 40)
  UBYTE ubIncrementer;
  UBYTE ubSkipFramesCounter;
#ifdef FIX16
  v2d tLocation;
  v2d tVelocity;
  v2d tAccelleration;
  UBYTE ubCountBouncer;
#endif
  UBYTE *s_pSource;
} TCurtain;

#define MAXCOURTAINS 4
static TCurtain s_pCurtains[MAXCOURTAINS];

inline static void courtain_init(UBYTE ubIndex, UBYTE ubAlloc, UBYTE ubOffset, UBYTE ubSkipFramesCounter)
{
  s_pCurtains[ubIndex].ubOffset = ubOffset;
  s_pCurtains[ubIndex].ubPosition = 0;
  s_pCurtains[ubIndex].ubIncrementer = 1;
  s_pCurtains[ubIndex].ubSkipFramesCounter = ubSkipFramesCounter;
  if (ubAlloc)
    s_pCurtains[ubIndex].s_pSource = AllocMem(10, MEMF_CHIP);
#ifdef FIX16
  s_pCurtains[ubIndex].ubCountBouncer = 0;

  v2d_zero(&s_pCurtains[ubIndex].tLocation);
  v2d_zero(&s_pCurtains[ubIndex].tVelocity);
  v2d_zero(&s_pCurtains[ubIndex].tAccelleration);
#endif
}

void copyToMainBpl(const unsigned char *, const UBYTE, const UBYTE);
void blitBlack(UWORD);
static UBYTE reverse(UBYTE);
void createMask();

static tView *s_pView;    // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs = 0;
static tCopCmd *pCopCmds;
static UBYTE *s_pMask = NULL;
static UBYTE *s_pSource;

void curtainsGsCreate(void)
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

  for (UBYTE ubCount = 16; ubCount < 32; ubCount++)
    s_pVpMain->pPalette[ubCount] = 0x0000;

  copyToMainBpl(valchiria_data, 0, 4);
  memset((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4]), 0xFF, 40 * 256);

  // We don't need anything from OS anymore
  systemUnuse();

  s_pSource = AllocMem(10, MEMF_CHIP);

  // Create mask list
  createMask();

  // Create courtains
  /*s_pCurtains[0].ubOffset = 0;
  s_pCurtains[0].ubPosition = 0;
  s_pCurtains[0].ubIncrementer = 1;
  s_pCurtains[0].ubSkipFramesCounter = 0;
#ifdef FIX16
  s_pCurtains[0].ubCountBouncer = 0;
  v2d_zero(&s_pCurtains[0].tAccelleration);
  s_pCurtains[0].tVelocity = 0;
  s_pCurtains[0].tLocation = 0;
#endif
  s_pCurtains[0].s_pSource = AllocMem(10, MEMF_CHIP);*/
  //inline static void courtain_init(UBYTE ubIndex,UBYTE ubAlloc,UBYTE ubOffset)

  courtain_init(0, 1, 0, 0);
  courtain_init(1, 1, 10, 10);
  courtain_init(2, 1, 20, 20);
  courtain_init(3, 1, 30, 30);

  /*s_pCurtains[1].ubOffset = 10;
  s_pCurtains[1].ubPosition = 0;
  s_pCurtains[1].ubIncrementer = 1;
  s_pCurtains[1].ubSkipFramesCounter = 10;
#ifdef FIX16
  s_pCurtains[1].ubCountBouncer = 0;
 
#endif
  s_pCurtains[1].s_pSource = AllocMem(10, MEMF_CHIP);*/

  /*s_pCurtains[2].ubOffset = 20;
  s_pCurtains[2].ubPosition = 0;
  s_pCurtains[2].ubIncrementer = 1;
  s_pCurtains[2].ubSkipFramesCounter = 20;
#ifdef FIX16
  s_pCurtains[2].ubCountBouncer = 0;
 
#endif
  s_pCurtains[2].s_pSource = AllocMem(10, MEMF_CHIP);

  s_pCurtains[3].ubOffset = 30;
  s_pCurtains[3].ubPosition = 0;
  s_pCurtains[3].ubIncrementer = 1;
  s_pCurtains[3].ubSkipFramesCounter = 30;
#ifdef FIX16
  s_pCurtains[3].ubCountBouncer = 0;
 
#endif
  s_pCurtains[3].s_pSource = AllocMem(10, MEMF_CHIP);*/

#ifdef FIX16
  g_Gravity.y = 0; //fix16_div(fix16_from_int(1), fix16_from_int(1000));
  g_Gravity.x = fix16_div(fix16_from_int(1), fix16_from_int(30));
#endif

  // Load the view
  viewLoad(s_pView);
}

void curtainsGsLoop(void)
{
  static UBYTE ubFadeIn = 1;
  static UWORD uwFrameCounter = 0;
  uwFrameCounter++;

  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if (keyCheck(KEY_ESCAPE))
  {
    gameExit();
    return;
  }
  //if (keyUse(KEY_Q))
  //ubFadeIn = 1;
  if (ubFadeIn && uwFrameCounter % 8 == 0)
  {
    for (UBYTE ubCourtainCounter = 0; ubCourtainCounter < MAXCOURTAINS; ubCourtainCounter++)
    {
      if (s_pCurtains[ubCourtainCounter].ubSkipFramesCounter > 0)
      {
        s_pCurtains[ubCourtainCounter].ubSkipFramesCounter--;
      }
      else
      {
        blitBlack(ubCourtainCounter);
#ifdef FIX16
        if (s_pCurtains[ubCourtainCounter].ubCountBouncer < 4)
        {
          v2d_add(&s_pCurtains[ubCourtainCounter].tAccelleration, &s_pCurtains[ubCourtainCounter].tAccelleration, &g_Gravity);
          v2d_add(&s_pCurtains[ubCourtainCounter].tVelocity, &s_pCurtains[ubCourtainCounter].tVelocity, &s_pCurtains[ubCourtainCounter].tAccelleration);
          v2d_add(&s_pCurtains[ubCourtainCounter].tLocation, &s_pCurtains[ubCourtainCounter].tLocation, &s_pCurtains[ubCourtainCounter].tVelocity);
          s_pCurtains[ubCourtainCounter].ubPosition = (UBYTE)fix16_to_int(s_pCurtains[ubCourtainCounter].tLocation.x);
          if (s_pCurtains[ubCourtainCounter].ubPosition >= 38)
          {
            s_pCurtains[ubCourtainCounter].tVelocity.x = fix16_mul(s_pCurtains[ubCourtainCounter].tVelocity.x, fix16_from_int(-1));
            v2d_add(&s_pCurtains[ubCourtainCounter].tAccelleration, &s_pCurtains[ubCourtainCounter].tAccelleration, &g_Gravity);
            v2d_add(&s_pCurtains[ubCourtainCounter].tVelocity, &s_pCurtains[ubCourtainCounter].tVelocity, &s_pCurtains[ubCourtainCounter].tAccelleration);
            v2d_add(&s_pCurtains[ubCourtainCounter].tLocation, &s_pCurtains[ubCourtainCounter].tLocation, &s_pCurtains[ubCourtainCounter].tVelocity);
            s_pCurtains[ubCourtainCounter].ubPosition = (UBYTE)fix16_to_int(s_pCurtains[ubCourtainCounter].tLocation.x);
            s_pCurtains[ubCourtainCounter].ubCountBouncer++;
          }
        }

        // End of transition here
        else if (ubCourtainCounter == 3)
        {
          //ubFadeIn = 0;

          courtain_init(0, 0, 0, 0);
          courtain_init(1, 0, 10, 10);
          courtain_init(2, 0, 20, 20);
          courtain_init(3, 0, 30, 30);
          blitWait();
          memset((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4]), 0xFF, 40 * 256);
          blitWait();
        }
      }
#else
        s_pCurtains[ubCourtainCounter].ubPosition += s_pCurtains[ubCourtainCounter].ubIncrementer;
        if (s_pCurtains[ubCourtainCounter].ubPosition >= 38)
          s_pCurtains[ubCourtainCounter].ubIncrementer *= -1;
#endif
    }
  }
  vPortWaitForEnd(s_pVpMain);
}

void curtainsGsDestroy(void)
{

  FreeMem(s_pMask, 5 * 40);
  FreeMem(s_pSource, 10);

  FreeMem(s_pCurtains[0].s_pSource, 10);
  FreeMem(s_pCurtains[1].s_pSource, 10);
  FreeMem(s_pCurtains[2].s_pSource, 10);
  FreeMem(s_pCurtains[3].s_pSource, 10);

  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}
// Function to copy data to a main bitplane
// Pass ubMaxBitplanes = 0 to use all available bitplanes in the bitmap
void copyToMainBpl(const unsigned char *pData, const UBYTE ubSlot, const UBYTE ubMaxBitplanes)
{
  UBYTE ubBitplaneCounter;
  for (ubBitplaneCounter = 0; ubBitplaneCounter < s_pMainBuffer->pBack->Depth; ubBitplaneCounter++)
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
    g_pCustom->bltapt = (UBYTE *)((ULONG)&pData[40 * 256 * ubBitplaneCounter]);
    g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[ubBitplaneCounter] + (40 * ubSlot));
    g_pCustom->bltsize = 0x4014;
    if (ubMaxBitplanes > 0 && ubBitplaneCounter + 1 >= ubMaxBitplanes)
      return;
  }
  return;
}
void blitBlack(UWORD uwCourtainIndex)
{
  UBYTE *pTmp = s_pMask + 5 * s_pCurtains[uwCourtainIndex].ubPosition;
#ifdef SHAREDPSOURCE
  *(s_pSource + 0) = *pTmp;
  *(s_pSource + 9) = reverse(*pTmp);
  pTmp++;

  *(s_pSource + 1) = *pTmp;
  *(s_pSource + 8) = reverse(*pTmp);
  pTmp++;

  *(s_pSource + 2) = *pTmp;
  *(s_pSource + 7) = reverse(*pTmp);
  pTmp++;

  *(s_pSource + 3) = *pTmp;
  *(s_pSource + 6) = reverse(*pTmp);
  pTmp++;

  *(s_pSource + 4) = *pTmp;
  *(s_pSource + 5) = reverse(*pTmp);
  pTmp++;
#else
    *(s_pCurtains[uwCourtainIndex].s_pSource + 0) = *pTmp;
    *(s_pCurtains[uwCourtainIndex].s_pSource + 9) = reverse(*pTmp);
    pTmp++;

    *(s_pCurtains[uwCourtainIndex].s_pSource + 1) = *pTmp;
    *(s_pCurtains[uwCourtainIndex].s_pSource + 8) = reverse(*pTmp);
    pTmp++;

    *(s_pCurtains[uwCourtainIndex].s_pSource + 2) = *pTmp;
    *(s_pCurtains[uwCourtainIndex].s_pSource + 7) = reverse(*pTmp);
    pTmp++;

    *(s_pCurtains[uwCourtainIndex].s_pSource + 3) = *pTmp;
    *(s_pCurtains[uwCourtainIndex].s_pSource + 6) = reverse(*pTmp);
    pTmp++;

    *(s_pCurtains[uwCourtainIndex].s_pSource + 4) = *pTmp;
    *(s_pCurtains[uwCourtainIndex].s_pSource + 5) = reverse(*pTmp);
#endif

  blitWait();
  g_pCustom->bltcon0 = 0x090F;
  g_pCustom->bltcon1 = 0x0000;
  g_pCustom->bltafwm = 0xffff;
  g_pCustom->bltalwm = 0xffff;
  g_pCustom->bltamod = -10;
  g_pCustom->bltdmod = 30;
#ifdef SHAREDPSOURCE
  g_pCustom->bltapt = (UBYTE *)((ULONG)s_pSource);
#else
    g_pCustom->bltapt = (UBYTE *)((ULONG)s_pCurtains[uwCourtainIndex].s_pSource);
#endif
  g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[4] + s_pCurtains[uwCourtainIndex].ubOffset);
  g_pCustom->bltsize = 0x4005;
}

static UBYTE reverse(UBYTE b)
{
  b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
  b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
  b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
  return b;
}

void createMask()
{
  s_pMask = AllocMem(5 * 40, MEMF_CHIP | MEMF_CLEAR);
  *s_pMask = 0x80;
  *(s_pMask + 5) = 0xC0;
  *(s_pMask + 10) = 0xE0;
  *(s_pMask + 15) = 0xF0;
  *(s_pMask + 20) = 0xF8;
  *(s_pMask + 25) = 0xFC;
  *(s_pMask + 30) = 0xFE;
  *(s_pMask + 35) = 0xFF;

  *(s_pMask + 40) = 0xFF;
  *(s_pMask + 41) = 0x80;
  *(s_pMask + 45) = 0xFF;
  *(s_pMask + 46) = 0xC0;
  *(s_pMask + 50) = 0xFF;
  *(s_pMask + 51) = 0xE0;
  *(s_pMask + 55) = 0xFF;
  *(s_pMask + 56) = 0xF0;
  *(s_pMask + 60) = 0xFF;
  *(s_pMask + 61) = 0xF8;
  *(s_pMask + 65) = 0xFF;
  *(s_pMask + 66) = 0xFC;
  *(s_pMask + 70) = 0xFF;
  *(s_pMask + 71) = 0xFE;
  *(s_pMask + 75) = 0xFF;
  *(s_pMask + 76) = 0xFF;

  *(s_pMask + 80) = 0xFF;
  *(s_pMask + 81) = 0xFF;
  *(s_pMask + 82) = 0x80;
  *(s_pMask + 85) = 0xFF;
  *(s_pMask + 86) = 0xFF;
  *(s_pMask + 87) = 0xC0;
  *(s_pMask + 90) = 0xFF;
  *(s_pMask + 91) = 0xFF;
  *(s_pMask + 92) = 0xE0;
  *(s_pMask + 95) = 0xFF;
  *(s_pMask + 96) = 0xFF;
  *(s_pMask + 97) = 0xF0;
  *(s_pMask + 100) = 0xFF;
  *(s_pMask + 101) = 0xFF;
  *(s_pMask + 102) = 0xF8;
  *(s_pMask + 105) = 0xFF;
  *(s_pMask + 106) = 0xFF;
  *(s_pMask + 107) = 0xFC;
  *(s_pMask + 110) = 0xFF;
  *(s_pMask + 111) = 0xFF;
  *(s_pMask + 112) = 0xFE;
  *(s_pMask + 115) = 0xFF;
  *(s_pMask + 116) = 0xFF;
  *(s_pMask + 117) = 0xFF;

  *(s_pMask + 115) = 0xFF;
  *(s_pMask + 116) = 0xFF;
  *(s_pMask + 117) = 0xFF;
  *(s_pMask + 118) = 0x80;

  *(s_pMask + 120) = 0xFF;
  *(s_pMask + 121) = 0xFF;
  *(s_pMask + 122) = 0xFF;
  *(s_pMask + 123) = 0xC0;

  *(s_pMask + 125) = 0xFF;
  *(s_pMask + 126) = 0xFF;
  *(s_pMask + 127) = 0xFF;
  *(s_pMask + 128) = 0xE0;

  *(s_pMask + 130) = 0xFF;
  *(s_pMask + 131) = 0xFF;
  *(s_pMask + 132) = 0xFF;
  *(s_pMask + 133) = 0xF0;

  *(s_pMask + 135) = 0xFF;
  *(s_pMask + 136) = 0xFF;
  *(s_pMask + 137) = 0xFF;
  *(s_pMask + 138) = 0xF8;

  *(s_pMask + 140) = 0xFF;
  *(s_pMask + 141) = 0xFF;
  *(s_pMask + 142) = 0xFF;
  *(s_pMask + 143) = 0xFC;

  *(s_pMask + 145) = 0xFF;
  *(s_pMask + 146) = 0xFF;
  *(s_pMask + 147) = 0xFF;
  *(s_pMask + 148) = 0xFE;

  *(s_pMask + 150) = 0xFF;
  *(s_pMask + 151) = 0xFF;
  *(s_pMask + 152) = 0xFF;
  *(s_pMask + 153) = 0xFF;

  *(s_pMask + 155) = 0xFF;
  *(s_pMask + 156) = 0xFF;
  *(s_pMask + 157) = 0xFF;
  *(s_pMask + 158) = 0xFF;
  *(s_pMask + 159) = 0x80;

  *(s_pMask + 160) = 0xFF;
  *(s_pMask + 161) = 0xFF;
  *(s_pMask + 162) = 0xFF;
  *(s_pMask + 163) = 0xFF;
  *(s_pMask + 164) = 0xC0;

  *(s_pMask + 165) = 0xFF;
  *(s_pMask + 166) = 0xFF;
  *(s_pMask + 167) = 0xFF;
  *(s_pMask + 168) = 0xFF;
  *(s_pMask + 169) = 0xE0;

  *(s_pMask + 170) = 0xFF;
  *(s_pMask + 171) = 0xFF;
  *(s_pMask + 172) = 0xFF;
  *(s_pMask + 173) = 0xFF;
  *(s_pMask + 174) = 0xF0;

  *(s_pMask + 175) = 0xFF;
  *(s_pMask + 176) = 0xFF;
  *(s_pMask + 177) = 0xFF;
  *(s_pMask + 178) = 0xFF;
  *(s_pMask + 179) = 0xF8;

  *(s_pMask + 180) = 0xFF;
  *(s_pMask + 181) = 0xFF;
  *(s_pMask + 182) = 0xFF;
  *(s_pMask + 183) = 0xFF;
  *(s_pMask + 184) = 0xFC;

  *(s_pMask + 185) = 0xFF;
  *(s_pMask + 186) = 0xFF;
  *(s_pMask + 187) = 0xFF;
  *(s_pMask + 188) = 0xFF;
  *(s_pMask + 189) = 0xFE;

  *(s_pMask + 190) = 0xFF;
  *(s_pMask + 191) = 0xFF;
  *(s_pMask + 192) = 0xFF;
  *(s_pMask + 193) = 0xFF;
  *(s_pMask + 194) = 0xFF;
}