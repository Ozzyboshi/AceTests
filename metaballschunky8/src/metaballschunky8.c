#include "metaballschunky8.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/copper.h>
#include <ace/managers/blit.h>
#include "../_res/discocrazy.h"

#define BITPLANES 5
#define NUMCHUNKYROWS 31
#define BARHEIGHT 8 * NUMCHUNKYROWS
// #define COLORDEBUG

#include <limits.h>

#define copSetMoveBackAndFront(var, var2)                  \
  copSetMove(&pCmdListBack[ubCopIndex].sMove, var, var2);  \
  copSetMove(&pCmdListFront[ubCopIndex].sMove, var, var2); \
  ubCopIndex++;

#define copSetMoveBackAndFront2(var, var2)                   \
  copSetMove(&pCmdListBack2[ubCopIndex2].sMove, var, var2);  \
  copSetMove(&pCmdListFront2[ubCopIndex2].sMove, var, var2); \
  ubCopIndex2++;

#define copSetMoveBackAndFront3(var, var2)                   \
  copSetMove(&pCmdListBack3[ubCopIndex3].sMove, var, var2);  \
  copSetMove(&pCmdListFront3[ubCopIndex3].sMove, var, var2); \
  ubCopIndex3++;

#define copSetWaitBackAndFront(var, var2)                  \
  copSetWait(&pCmdListBack[ubCopIndex].sWait, var, var2);  \
  copSetWait(&pCmdListFront[ubCopIndex].sWait, var, var2); \
  ubCopIndex++;

#define copSetWaitBackAndFrontStart(var, var2)                       \
  copSetWait(&pCmdListBackStart[ubCopIndexStart].sWait, var, var2);  \
  copSetWait(&pCmdListFrontStart[ubCopIndexStart].sWait, var, var2); \
  ubCopIndexStart++;

#define copSetSkipBackAndFront(var, var2)                  \
  copSetSkip(&pCmdListBack[ubCopIndex].sWait, var, var2);  \
  copSetSkip(&pCmdListFront[ubCopIndex].sWait, var, var2); \
  ubCopIndex++;

#define copSetSkipBackAndFront3(var, var2)                   \
  copSetSkip(&pCmdListBack3[ubCopIndex3].sWait, var, var2);  \
  copSetSkip(&pCmdListFront3[ubCopIndex3].sWait, var, var2); \
  ubCopIndex3++;

#define copSetSkipRawBackAndFront3(var, var2, var3, var4)                   \
  copSetSkipRaw(&pCmdListBack3[ubCopIndex3].sWait, var, var2, var3, var4);  \
  copSetSkipRaw(&pCmdListFront3[ubCopIndex3].sWait, var, var2, var3, var4); \
  ubCopIndex3++;

#define copSetWaitRawBackAndFront2(var, var2, var3, var4)                   \
  copSetWaitRaw(&pCmdListBack2[ubCopIndex2].sWait, var, var2, var3, var4);  \
  copSetWaitRaw(&pCmdListFront2[ubCopIndex2].sWait, var, var2, var3, var4); \
  ubCopIndex2++;

#define copSetWaitRawBackAndFront3(var, var2, var3, var4)                   \
  copSetWaitRaw(&pCmdListBack3[ubCopIndex3].sWait, var, var2, var3, var4);  \
  copSetWaitRaw(&pCmdListFront3[ubCopIndex3].sWait, var, var2, var3, var4); \
  ubCopIndex3++;

#define copSetWaitBackAndFront2(var, var2)                   \
  copSetWait(&pCmdListBack2[ubCopIndex2].sWait, var, var2);  \
  copSetWait(&pCmdListFront2[ubCopIndex2].sWait, var, var2); \
  ubCopIndex2++;

#define copSetWaitBackAndFront3(var, var2)                   \
  copSetWait(&pCmdListBack3[ubCopIndex3].sWait, var, var2);  \
  copSetWait(&pCmdListFront3[ubCopIndex3].sWait, var, var2); \
  ubCopIndex3++;

// All variables outside fns are global - can be accessed in any fn
// Static means here that given var is only for this file, hence 's_' prefix
// You can have many variables with same name in different files and they'll be
// independent as long as they're static
// * means pointer, hence 'p' prefix
static tView *s_pView;    // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static UWORD s_uwCopRawOffs = 0;
static tCopCmd *pCopCmds;

static tCopList *pSecondCopList;
static tCopList *pThirdCopList;

tCopCmd *pCmdListBack3;
tCopCmd *pCmdListFront3;

//tCopCmd *pCopList;

tCopList *mycopListCreate(void *pTagList, ...);
void copSetWaitRaw(tCopWaitCmd *pWaitCmd, UBYTE ubX, UBYTE ubY, UBYTE ubXCompare, UBYTE ubYCompare);
void copSetSkip(tCopWaitCmd *pWaitCmd, UBYTE ubX, UBYTE ubY);
void copSetSkipRaw(tCopWaitCmd *, UBYTE, UBYTE, UBYTE, UBYTE);

UWORD copBuildRaw(UWORD, ULONG, ULONG, UWORD, UWORD, UWORD, UWORD, UWORD, UWORD, UBYTE);
UWORD copBuildRawV2(UWORD, UBYTE, UWORD, UWORD, UWORD, UWORD, UWORD, UWORD, UBYTE, UBYTE);
UWORD copBuildRawV2_255(UWORD, UBYTE, UWORD, UWORD, UWORD, UWORD, UWORD, UWORD, UBYTE);
UWORD copBuildRawV3(UWORD , UBYTE , UWORD , UWORD , UWORD , UWORD , UWORD , UWORD , UBYTE ,UBYTE );


void setChunkyPixelColor(UWORD, UWORD, UWORD);


#if 0
inline void setChunkyPixelColor2(UWORD uwX, UWORD uwY, UWORD uwValue)
{
  if (uwY > 26)
    uwY++;
  UWORD uwIndex = uwX;
  uwIndex += 45 * uwY;
  //pCopList[uwIndex].sMove.bfValue = uwValue;
  return ;

  if (uwY == 26)
  {
    uwY++;
    uwIndex = uwX + 45 * uwY;
    //pCmdListBack[uwIndex].sMove.bfValue = uwValue;
 
  }
}
#endif

//Music
long mt_init(const unsigned char *);
void mt_music();
void mt_end();

static void interruptHandlerMusic(REGARG(volatile tCustom *pCustom, "a0"), REGARG(volatile void *pData, "a1")) 
{
  mt_music();
}

UWORD COLORS[72];

UBYTE *calcpixel(void *);
void drawpixel(void*);

void gameGsCreate(void)
{
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(BITPLANES) + 2 +
  //                   32 * 4 + // 32 bars - each consists of WAIT + 2 MOVE instruction
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

  // Build a second copperlist
  pSecondCopList = mycopListCreate(0,
                                   TAG_COPPER_LIST_MODE, COPPER_MODE_RAW,
                                   TAG_COPPER_RAW_COUNT, ulRawSize,
                                   TAG_DONE);

  // Build a copperlist to use when Y >= 128
  pThirdCopList = mycopListCreate(0,
                                  TAG_COPPER_LIST_MODE, COPPER_MODE_RAW,
                                  TAG_COPPER_RAW_COUNT, 45 * NUMCHUNKYROWS + 90 + 10,
                                  TAG_DONE);

  s_uwCopRawOffs = simpleBufferGetRawCopperlistInstructionCount(BITPLANES);
  tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  pCopCmds = &pCopBfr->pList[s_uwCopRawOffs];

  /*CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			pSecondCopList->pBackBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);*/

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray
  s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red

  // Copperlist 3 start
  pCmdListBack3 = &pThirdCopList->pBackBfr->pList[0];
  pCmdListFront3 = &pThirdCopList->pFrontBfr->pList[0];
  UWORD ubCopIndex3 = 0;

  // Copperlist 2 start
  tCopCmd *pCmdListBack2 = &pSecondCopList->pBackBfr->pList[0];
  tCopCmd *pCmdListFront2 = &pSecondCopList->pFrontBfr->pList[0];
  UWORD ubCopIndex2 = 0;

  tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
  tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
  tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];
  tCopCmd *pCmdListBackStart = &pCopList->pBackBfr->pList[0];
  tCopCmd *pCmdListFrontStart = &pCopList->pFrontBfr->pList[0];

  UWORD ubCopIndex = 0;
  //UBYTE ubWaitCounter = 0;

  // Load second copperlist addr
  UWORD *cop2lc = (UWORD *)&g_pCustom->cop2lc;
  ULONG ulCop2Addr = (ULONG)((void *)pSecondCopList->pBackBfr->pList);
  ULONG ulCop2AddrNoVerticalWait = (ULONG)((void *)pSecondCopList->pBackBfr->pList + 4);

  ULONG ulCop3Addr = (ULONG)((void *)pThirdCopList->pBackBfr->pList);
  ULONG ulCop3Addr1 = ulCop3Addr + (45 * 4);
  ULONG ulCop3Addr2 = ulCop3Addr1 + (45 * 4);
  ULONG ulCop3Addr3 = ulCop3Addr2 + (45 * 4);
  ULONG ulCop3Addr4 = ulCop3Addr3 + (45 * 4);

  logWrite("cop2addr with vertical wait: %u\n", ulCop2Addr);
  logWrite("cop2addr withOUT vertical wait: %u\n", ulCop2AddrNoVerticalWait);
  logWrite("cop3addr: %u\n", ulCop3Addr);

  UWORD ulCop2H = (UWORD)(ulCop2Addr >> 16);
  logWrite("cop2addr H : %u\n", ulCop2H);
  UWORD ulCop2L = (UWORD)(ulCop2Addr & 0x0000FFFF);
  logWrite("cop2addr L : %u\n", ulCop2L);

  UWORD ulCop2HNoVerticalWait = (UWORD)(ulCop2AddrNoVerticalWait >> 16);
  UWORD ulCop2LNoVerticalWait = (UWORD)(ulCop2AddrNoVerticalWait & 0x0000FFFF);
  logWrite("cop2addr H : %u\n", ulCop2HNoVerticalWait);
  logWrite("cop2addr L : %u\n", ulCop2LNoVerticalWait);

  UWORD ulCop3H = (UWORD)(ulCop3Addr >> 16);
  UWORD ulCop3L = (UWORD)(ulCop3Addr & 0x0000FFFF);
  logWrite("cop3addr H : %u\n", ulCop3H);
  logWrite("cop3addr L : %u\n", ulCop3L);

  UWORD ulCop3H1 = (UWORD)(ulCop3Addr1 >> 16);
  UWORD ulCop3L1 = (UWORD)(ulCop3Addr1 & 0x0000FFFF);
  logWrite("cop3addr H : %u\n", ulCop3H1);
  logWrite("cop3addr L : %u\n", ulCop3L1);

  UWORD ulCop3H2 = (UWORD)(ulCop3Addr2 >> 16);
  UWORD ulCop3L2 = (UWORD)(ulCop3Addr2 & 0x0000FFFF);
  logWrite("cop3addr terza riga H : %x\n", ulCop3H2);
  logWrite("cop3addr tarza riga L : %x\n", ulCop3L2);

  UWORD ulCop3H3 = (UWORD)(ulCop3Addr3 >> 16);
  UWORD ulCop3L3 = (UWORD)(ulCop3Addr3 & 0x0000FFFF);
  logWrite("cop3addr terza riga H : %x\n", ulCop3H3);
  logWrite("cop3addr tarza riga L : %x\n", ulCop3L3);

  UWORD ulCop3H4 = (UWORD)(ulCop3Addr4 >> 16);
  UWORD ulCop3L4 = (UWORD)(ulCop3Addr4 & 0x0000FFFF);
  logWrite("cop3addr quinta riga H : %x\n", ulCop3H4);
  logWrite("cop3addr tarza riga L : %x\n", ulCop3L4);

  // First cop instruction is deleted, dont want to wait 44
  UWORD ubCopIndexStart = 0;
  copSetWaitBackAndFrontStart(0, 0);

  //COPPERLIST 1 START

  // Load the copperlist version with the vertical wait
  copSetMoveBackAndFront(cop2lc, ulCop3H);
  copSetMoveBackAndFront(cop2lc + 1, ulCop3L);

  // set red bg and wait
  //copSetMoveBackAndFront(&g_pCustom->color[0], 0x0FF0);
  copSetWaitBackAndFront(0, 43);

  // this instruction jumps to cop2!!!
  copSetMoveBackAndFront(&g_pCustom->copjmp2, 1);

#if 0

  // set green bg and start cop2

  //2n row
  copSetSkipBackAndFront(0x7, 60);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0A00);
  //copSetSkipBackAndFront(0x7, 60);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x0AFF);
  /*copSetSkipBackAndFront(0x7, 60);
  copSetMoveBackAndFront(&g_pCustom->color[2], 0x0AF0);
  copSetSkipBackAndFront(0x7, 60);
  copSetMoveBackAndFront(&g_pCustom->color[3], 0x0A66);*/

  // 1st row
  //copSetSkipBackAndFront(0x7, 52);
  copSetMoveBackAndFront(&g_pCustom->color[0], 0x00F0);
  //copSetSkipBackAndFront(0x7, 52);
  copSetMoveBackAndFront(&g_pCustom->color[1], 0x00FF);
  //copSetSkipBackAndFront(0x7, 52);
  copSetMoveBackAndFront(&g_pCustom->color[2], 0x0FF0);
  //copSetSkipBackAndFront(0x7, 52);
  copSetMoveBackAndFront(&g_pCustom->color[3], 0x0666);

  //CHECK =>128
  // IF YES WAIT 128100
  // Load the copperlist version without the vertical wait
  //SKIP
  copSetSkipBackAndFront(0, 0x80);
  copSetMoveBackAndFront(cop2lc, ulCop2HNoVerticalWait);
  //SKIP
  copSetSkipBackAndFront(0, 0x80);
  copSetMoveBackAndFront(cop2lc + 1, ulCop2LNoVerticalWait);

  // this instruction jumps to cop2!!!
  copSetMoveBackAndFront(&g_pCustom->copjmp2, 1);

  //copSetWaitBackAndFront(0xdf, 0xff);
  //COPPERLIST 1 END

  // COPPERLIST 2 START
  //copSetWaitRawBackAndFront2(113, 0, 0x7F, 0x00);
  // I will wait for the ray to be in the middle of the screen more or less BUT masking vertical position will work only for scanlines <128
  // This is because the copper cant mask the most significant bit of the vertical position, in other words from scanline 128 this wait will be true
  // I could solve this problem by checking vp before waiting, if vp>=128 THEN wait for the start of 128 and only then wait for the x position
  // Copper skip instruction could be handy..... or not? let's see80fe

  copSetWaitBackAndFront2(0x90, 150);
  copSetWaitRawBackAndFront2(0x90, 0, 0x7F, 0x00);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000F);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000A);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000F);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000A);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000F);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000A);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000F);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000A);
  /*copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000F);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000A);*/
  /*copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000F);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x000A);*/
  //copSetWaitRawBackAndFront2(0x9A, 0, 0x7F, 0x00);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x0FFF);
  //copSetWaitRawBackAndFront2(0xE2, 0, 0x7F, 0x00);
  copSetMoveBackAndFront2(&g_pCustom->color[0], 0x0111);
  copSetMoveBackAndFront2(&g_pCustom->copjmp1, 1);
  // COPPERLIST 2 END
#endif

  // COPPERLIST 3 START
  //copSetWaitRawBackAndFront3(0x90, 0x80, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[2], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[3], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[4], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[5], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[6], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[7], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[8], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[9], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[10], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[11], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[12], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[13], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[14], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[15], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[16], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[17], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[18], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[19], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[20], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[21], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[22], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[23], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[24], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[25], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[26], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[27], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[28], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[29], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[30], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[31], 0x0F0F);

  // 8 missing colors here
  //copSetWaitRawBackAndFront3(160, 0x00, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], 0x0444);
  copSetMoveBackAndFront3(&g_pCustom->color[2], 0x0555);
  copSetMoveBackAndFront3(&g_pCustom->color[3], 0x0666);
  copSetMoveBackAndFront3(&g_pCustom->color[4], 0x0444);
  copSetMoveBackAndFront3(&g_pCustom->color[5], 0x0555);
  copSetMoveBackAndFront3(&g_pCustom->color[6], 0x0666);
  copSetMoveBackAndFront3(&g_pCustom->color[7], 0x0444);
  copSetMoveBackAndFront3(&g_pCustom->color[8], 0x0555);
  copSetMoveBackAndFront3(&g_pCustom->color[9], 0x0666);

  /*copSetWaitRawBackAndFront3(0x9A, 0, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[0], 0x0FFF);*/
  copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  copSetSkipBackAndFront3(0, 52);
  copSetMoveBackAndFront3(&g_pCustom->copjmp2, 1);

  // Star of 2nd raw
  copSetMoveBackAndFront3(cop2lc, ulCop3H1);
  copSetMoveBackAndFront3(cop2lc + 1, ulCop3L1);

  copSetMoveBackAndFront3(&g_pCustom->color[1], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[2], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[3], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[4], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[5], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[6], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[7], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[8], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[9], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[10], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[11], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[12], 0x0F00);

  copSetMoveBackAndFront3(&g_pCustom->color[13], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[14], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[15], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[16], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[17], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[18], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[19], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[20], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[21], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[22], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[23], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[24], 0x0F00);

  copSetMoveBackAndFront3(&g_pCustom->color[25], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[26], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[27], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[28], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[29], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[30], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[31], 0x00F0);

  // 8 missing colors here
  //copSetWaitRawBackAndFront3(160, 0x00, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], 0x0777);
  copSetMoveBackAndFront3(&g_pCustom->color[2], 0x0888);
  copSetMoveBackAndFront3(&g_pCustom->color[3], 0x0999);
  copSetMoveBackAndFront3(&g_pCustom->color[4], 0x0777);
  copSetMoveBackAndFront3(&g_pCustom->color[5], 0x0888);
  copSetMoveBackAndFront3(&g_pCustom->color[6], 0x0999);
  copSetMoveBackAndFront3(&g_pCustom->color[7], 0x0777);
  copSetMoveBackAndFront3(&g_pCustom->color[8], 0x0888);
  copSetMoveBackAndFront3(&g_pCustom->color[9], 0x0999);

  copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  copSetSkipBackAndFront3(0, 60);
  copSetMoveBackAndFront3(&g_pCustom->copjmp2, 1);

  // Star of 3rd raw
  copSetMoveBackAndFront3(cop2lc, ulCop3H2);
  copSetMoveBackAndFront3(cop2lc + 1, ulCop3L2);

  copSetMoveBackAndFront3(&g_pCustom->color[1], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[2], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[3], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[4], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[5], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[6], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[7], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[8], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[9], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[10], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[11], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[12], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[13], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[14], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[15], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[16], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[17], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[18], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[19], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[20], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[21], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[22], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[23], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[24], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[25], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[26], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[27], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[28], 0x0F00);
  copSetMoveBackAndFront3(&g_pCustom->color[29], 0x00F0);
  copSetMoveBackAndFront3(&g_pCustom->color[30], 0x000F);
  copSetMoveBackAndFront3(&g_pCustom->color[31], 0x0F0F);

  // 8 missing colors here
  //copSetWaitRawBackAndFront3(160, 0x00, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], 0x0444);
  copSetMoveBackAndFront3(&g_pCustom->color[2], 0x0555);
  copSetMoveBackAndFront3(&g_pCustom->color[3], 0x0666);
  copSetMoveBackAndFront3(&g_pCustom->color[4], 0x0444);
  copSetMoveBackAndFront3(&g_pCustom->color[5], 0x0555);
  copSetMoveBackAndFront3(&g_pCustom->color[6], 0x0666);
  copSetMoveBackAndFront3(&g_pCustom->color[7], 0x0444);
  copSetMoveBackAndFront3(&g_pCustom->color[8], 0x0555);
  copSetMoveBackAndFront3(&g_pCustom->color[9], 0x0666);

  copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  copSetSkipBackAndFront3(0, 68);
  copSetMoveBackAndFront3(&g_pCustom->copjmp2, 1);

  //ubCopIndex3 = copBuildRaw(ubCopIndex3,ulCop3H3,ulCop3L3, 0x00F0,0x000F,0x0F00, 0x0777,0x0888,0x0999,76);

  UBYTE ubVerticalSkip = 76;

   //for (UBYTE ubCopCounter = 3; ubCopCounter < 16; ubCopCounter++)
  for (UBYTE ubCopCounter = 3; ubCopCounter <= NUMCHUNKYROWS; ubCopCounter++)
  {
    UWORD uwCol1, uwCol2, uwCol3, uwCol4, uwCol5, uwCol6;
    if ((ubCopCounter % 2) == 0)
    {
      uwCol1 = 0x0F00;
      uwCol2 = 0x00F0;
      uwCol3 = 0x000F;
      uwCol4 = 0x0444;
      uwCol5 = 0x0555;
      uwCol6 = 0x0666;
    }
    else
    {
      uwCol1 = 0x00F0;
      uwCol2 = 0x000F;
      uwCol3 = 0x0F00;
      uwCol4 = 0x0777;
      uwCol5 = 0x0888;
      uwCol6 = 0x0999;
    }
    logWrite("building for vertical skip %u\n", ubVerticalSkip);
    if (ubCopCounter == 26) // 26 is a special row because it crosses 255, so we mush split the row in 2 pieces
    {
      ubCopIndex3 = copBuildRawV2_255(ubCopIndex3, ubCopCounter, 0x0F00, 0x00F0, 0x000F, 0x0444, 0x0555, 0x0000, 254);
      ubCopIndex3 = copBuildRawV2(ubCopIndex3, ubCopCounter + 1, 0x0F00, 0x00F0, 0x000F, 0x0444, 0x0555, 0x0000, ubVerticalSkip,0);
    }
    else if (ubCopCounter > 26)
    {
      // start test optimizing
      /*if (ubCopCounter==NUMCHUNKYROWS) ubCopIndex3 = copBuildRawV3(ubCopIndex3, ubCopCounter + 1, uwCol1, uwCol2, uwCol3, 0xF88, uwCol5, uwCol6, ubVerticalSkip,0);
      // end test optimizing
      else*/ ubCopIndex3 = copBuildRawV2(ubCopIndex3, ubCopCounter + 1, uwCol1, uwCol2, uwCol3, uwCol4, uwCol5, uwCol6, ubVerticalSkip,0);
    }
    else
    {
      if (ubCopCounter >= 12 ) ubCopIndex3 = copBuildRawV2(ubCopIndex3, ubCopCounter, uwCol1, uwCol2, uwCol3, uwCol4, uwCol5, uwCol6, ubVerticalSkip,1);
      else ubCopIndex3 = copBuildRawV2(ubCopIndex3, ubCopCounter, uwCol1, uwCol2, uwCol3, uwCol4, uwCol5, uwCol6, ubVerticalSkip,0);
    }
    ubVerticalSkip += 8;
  }
  /*ubCopIndex3 = copBuildRawV2_255(ubCopIndex3,NUMCHUNKYROWS-1, 0x0F00,0x00F0,0x000F, 0x0444,0x0555,0x0000,254);
  ubCopIndex3 = copBuildRawV2(ubCopIndex3,NUMCHUNKYROWS, 0x0F00,0x00F0,0x000F, 0x0444,0x0555,0x0000,4);*/
  //ubCopIndex3 = copBuildRawV2(ubCopIndex3,NUMCHUNKYROWS+1, 0x00F0,0x000F,0x0F00, 0x0666,0x0777,0x0888,12);

  // COPPERLIST 3 END

  // We don't need anything from OS anymore
  systemUnuse();

  // Draw rectangles
  for (UBYTE ubCount = 0; ubCount < 31; ubCount++)
  {
    blitRect(s_pMainBuffer->pBack, ubCount * 8, 0, 8, BARHEIGHT + 8, ubCount + 1);
  }

  UBYTE ubColIndex = 1;
  for (UBYTE ubCount = 31; ubCount < 40; ubCount++)
  {
    blitRect(s_pMainBuffer->pBack, ubCount * 8, 0, 8, BARHEIGHT + 8, ubColIndex);
    ubColIndex++;
  }
  mt_init(discocrazy_data);
  //blitRect(s_pMainBuffer->pBack, 1 * 8, 0, 8, 256, 0 + 2);
  // blitRect(s_pMainBuffer->pBack, 2 * 8, 0, 8, 256, 0 + 3);

  UWORD uwColIndex=0;
  COLORS[uwColIndex++]=0x100;
  COLORS[uwColIndex++]=0x200;
  COLORS[uwColIndex++]=0x300;
  COLORS[uwColIndex++]=0x400;
  COLORS[uwColIndex++]=0x500;
  COLORS[uwColIndex++]=0x600;
  COLORS[uwColIndex++]=0x700;
  COLORS[uwColIndex++]=0x800;
  COLORS[uwColIndex++]=0x900;
  COLORS[uwColIndex++]=0xA00;
  COLORS[uwColIndex++]=0xB00;
  COLORS[uwColIndex++]=0xC00;
  COLORS[uwColIndex++]=0xD00;
  COLORS[uwColIndex++]=0xE00;
  COLORS[uwColIndex++]=0xF00;

  COLORS[uwColIndex++]=0x010;
  COLORS[uwColIndex++]=0x020;
  COLORS[uwColIndex++]=0x030;
  COLORS[uwColIndex++]=0x040;
  COLORS[uwColIndex++]=0x050;
  COLORS[uwColIndex++]=0x060;
  COLORS[uwColIndex++]=0x070;
  COLORS[uwColIndex++]=0x080;
  COLORS[uwColIndex++]=0x090;
  COLORS[uwColIndex++]=0x0A0;
  COLORS[uwColIndex++]=0x0B0;
  COLORS[uwColIndex++]=0x0C0;
  COLORS[uwColIndex++]=0x0D0;
  COLORS[uwColIndex++]=0x0E0;
  COLORS[uwColIndex++]=0x0F0;

  COLORS[uwColIndex++]=0x001;
  COLORS[uwColIndex++]=0x002;
  COLORS[uwColIndex++]=0x003;
  COLORS[uwColIndex++]=0x004;
  COLORS[uwColIndex++]=0x005;
  COLORS[uwColIndex++]=0x006;
  COLORS[uwColIndex++]=0x007;
  COLORS[uwColIndex++]=0x008;
  COLORS[uwColIndex++]=0x009;
  COLORS[uwColIndex++]=0x00A;
  COLORS[uwColIndex++]=0x00B;
  COLORS[uwColIndex++]=0x00C;
  COLORS[uwColIndex++]=0x00D;
  COLORS[uwColIndex++]=0x00E;
  COLORS[uwColIndex++]=0x00F;

  COLORS[uwColIndex++]=0x100;
  COLORS[uwColIndex++]=0x200;
  COLORS[uwColIndex++]=0x300;
  COLORS[uwColIndex++]=0x400;
  COLORS[uwColIndex++]=0x500;
  COLORS[uwColIndex++]=0x600;
  COLORS[uwColIndex++]=0x700;
  COLORS[uwColIndex++]=0x800;
  COLORS[uwColIndex++]=0x900;
  COLORS[uwColIndex++]=0xA00;
  COLORS[uwColIndex++]=0xB00;
  COLORS[uwColIndex++]=0xC00;
  COLORS[uwColIndex++]=0xD00;
  COLORS[uwColIndex++]=0xE00;
  COLORS[uwColIndex++]=0xF00;

  COLORS[uwColIndex++]=0x010;
  COLORS[uwColIndex++]=0x020;
  COLORS[uwColIndex++]=0x030;
  COLORS[uwColIndex++]=0x040;
  COLORS[uwColIndex++]=0x050;
  COLORS[uwColIndex++]=0x060;
  COLORS[uwColIndex++]=0x070;
  COLORS[uwColIndex++]=0x080;
  COLORS[uwColIndex++]=0x090;
  COLORS[uwColIndex++]=0x0A0;
  COLORS[uwColIndex++]=0x0B0;
  COLORS[uwColIndex++]=0x0C0;

  
  //pCopList = &pThirdCopList->pBackBfr->pList[0];

  // Load the view
  viewLoad(s_pView);

  systemSetInt(INTB_VERTB, interruptHandlerMusic, 0);
}

void gameGsLoop(void)
{

  UBYTE *addr = calcpixel(&pThirdCopList->pBackBfr->pList[0]);
  //mt_music();
  //vPortWaitForEnd(s_pVpMain);

#ifdef COLORDEBUG
  g_pCustom->color[0] = 0x0F00;
#endif

  //tCopCmd *pCmdListBack = &pThirdCopList->pBackBfr->pList[0];

  // This will loop forever until you "pop" or change gamestate
  // or close the game
  
#if 1

  for (UBYTE ubContX = 0; ubContX < 40; ubContX++)
  {
    for (UBYTE ubContY = 0; ubContY < 32; ubContY++)
    {
      
      setChunkyPixelColor((UWORD)ubContX, ubContY, COLORS[*addr]);
      
      addr++;
    }

   
  }

  /*for (UBYTE ubContX = 0; ubContX < 4; ubContX++)
    for (UBYTE ubContY = 0; ubContY < 32; ubContY++)*/

  //drawpixel( &pThirdCopList->pBackBfr->pList[0]);
      

  //mt_music();
  #ifdef COLORDEBUG
  g_pCustom->color[0] = 0x0000;
#endif

  vPortWaitForEnd(s_pVpMain);
  if (keyCheck(KEY_ESCAPE)) gameExit();

  
  return;

  for (UBYTE ubContX = 4; ubContX < 10; ubContX++)
  {
    for (UBYTE ubContY = 0; ubContY < 32; ubContY++)
    {
      setChunkyPixelColor((UWORD)ubContX, ubContY, COLORS[*addr]);
      
      addr++;
    }

   
  }
  mt_music();

  vPortWaitForEnd(s_pVpMain);

  for (UBYTE ubContX = 10; ubContX < 20; ubContX++)
  {
    for (UBYTE ubContY = 0; ubContY < 32; ubContY++)
    {
      setChunkyPixelColor((UWORD)ubContX, ubContY, COLORS[*addr]);
      
      addr++;
    }

   
  }
  mt_music();

  vPortWaitForEnd(s_pVpMain);

  for (UBYTE ubContX = 20; ubContX < 30; ubContX++)
  {
    for (UBYTE ubContY = 0; ubContY < 32; ubContY++)
    {
      setChunkyPixelColor((UWORD)ubContX, ubContY, COLORS[*addr]);
      
      addr++;
    }

   
  }
  mt_music();

  vPortWaitForEnd(s_pVpMain);

  for (UBYTE ubContX = 30; ubContX < 40; ubContX++)
  {
    for (UBYTE ubContY = 0; ubContY < 32; ubContY++)
    {
      setChunkyPixelColor((UWORD)ubContX, ubContY, COLORS[*addr]);
      
      addr++;
    }

   
  }
  mt_music();
  #endif



#ifdef COLORDEBUG
  g_pCustom->color[0] = 0x0F00;
#endif


  if (keyCheck(KEY_ESCAPE))
  {
    gameExit();
  }
  #if 0

  if (keyUse(KEY_D))
  {
    /*tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
    copDumpBfr(pCopBfr);*/

    tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
    copDumpBfr(pCopBfr);
  }

  if (keyUse(KEY_F))
  {
    /*tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
    copDumpBfr(pCopBfr);*/

    tCopBfr *pCopBfr = pThirdCopList->pBackBfr;
    copDumpBfr(pCopBfr);
  }

  if (keyUse(KEY_SPACE))
  {
    static UWORD y = 0;
    setChunkyPixelColor(39, y, 0x0FFF);
    y++;
  }
  #endif
#ifdef COLORDEBUG
  g_pCustom->color[0] = 0x0000;
#endif
  vPortWaitForEnd(s_pVpMain);
}

void gameGsDestroy(void)
{
  mt_end();

  copListDestroy(pSecondCopList);
  copListDestroy(pThirdCopList);

  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}

void setChunkyPixelColor(UWORD uwX, UWORD uwY, UWORD uwValue)
{
  if (uwY > 26)
    uwY++;
  tCopCmd *pCmdListBack = &pThirdCopList->pBackBfr->pList[0];
  UWORD uwIndex = uwX;
  uwIndex += 45 * uwY;
  pCmdListBack[uwIndex].sMove.bfValue = uwValue;

  if (uwY == 26)
  {
    uwY++;
    uwIndex = uwX + 45 * uwY;
    pCmdListBack[uwIndex].sMove.bfValue = uwValue;

  }
}

tCopList *mycopListCreate(void *pTagList, ...)
{

  va_list vaTags;
  va_start(vaTags, pTagList);
  tCopList *pCopList;

  logBlockBegin("copListCreate()");

  // Create copperlist stub
  pCopList = memAllocFastClear(sizeof(tCopList));
  logWrite("Addr: %p\n", pCopList);
  pCopList->pFrontBfr = memAllocFastClear(sizeof(tCopBfr));
  pCopList->pBackBfr = memAllocFastClear(sizeof(tCopBfr));

  // Handle raw copperlist creation
  pCopList->ubMode = tagGet(pTagList, vaTags, TAG_COPPER_LIST_MODE, COPPER_MODE_BLOCK);
  if (pCopList->ubMode == COPPER_MODE_RAW)
  {
    const ULONG ulInvalidSize = ULONG_MAX;
    ULONG ulListSize = tagGet(
        pTagList, vaTags, TAG_COPPER_RAW_COUNT, ulInvalidSize);
    if (ulListSize == ulInvalidSize)
    {
      logWrite("ERR: no size specified for raw list\n");
      goto fail;
    }
    if (ulListSize > USHRT_MAX)
    {
      logWrite(
          "ERR: raw copperlist size too big: %lu, max is %u\n",
          ulListSize, USHRT_MAX);
      goto fail;
    }
    logWrite("RAW mode, size: %lu + WAIT(0xFFFF)\n", ulListSize);
    // Front bfr
    pCopList->pFrontBfr->uwCmdCount = ulListSize + 1;
    pCopList->pFrontBfr->uwAllocSize = (ulListSize + 1) * sizeof(tCopCmd);
    pCopList->pFrontBfr->pList = memAllocChipClear(pCopList->pFrontBfr->uwAllocSize);
    copSetWait(&pCopList->pFrontBfr->pList[ulListSize].sWait, 0xFF, 0xFF);
    // Back bfr
    pCopList->pBackBfr->uwCmdCount = ulListSize + 1;
    pCopList->pBackBfr->uwAllocSize = (ulListSize + 1) * sizeof(tCopCmd);
    pCopList->pBackBfr->pList = memAllocChipClear(pCopList->pBackBfr->uwAllocSize);
    logWrite("Addr orpBackBfr alessiooooooooooooooooooooooooooooooooooo : %p\n", pCopList->pBackBfr->pList);
    copSetWait(&pCopList->pBackBfr->pList[ulListSize].sWait, 0xFF, 0xFF);
  }
  else
  {
    logWrite("BLOCK mode\n");
  }

  logBlockEnd("copListCreate()");
  va_end(vaTags);
  return pCopList;

fail:
  va_end(vaTags);
  copListDestroy(pCopList);
  logBlockEnd("copListCreate()");
  return 0;
}

/*void copSetWait(tCopWaitCmd *pWaitCmd, UBYTE ubX, UBYTE ubY) {
	pWaitCmd->bfWaitY         = ubY;
	pWaitCmd->bfWaitX         = ubX >> 1;
	pWaitCmd->bfIsWait        = 1;
	pWaitCmd->bfBlitterIgnore = 1;
	pWaitCmd->bfVE            = 0x7F;
	pWaitCmd->bfHE            = 0x7F;
	pWaitCmd->bfIsSkip        = 0;
}*/

void copSetWaitRaw(tCopWaitCmd *pWaitCmd, UBYTE ubX, UBYTE ubY, UBYTE ubXCompare, UBYTE ubYCompare)
{
  pWaitCmd->bfWaitY = ubY;
  pWaitCmd->bfWaitX = ubX >> 1;
  pWaitCmd->bfIsWait = 1;
  pWaitCmd->bfBlitterIgnore = 1;
  pWaitCmd->bfVE = ubYCompare;
  pWaitCmd->bfHE = ubXCompare;
  pWaitCmd->bfIsSkip = 0;
}

void copSetSkip(tCopWaitCmd *pWaitCmd, UBYTE ubX, UBYTE ubY)
{
  pWaitCmd->bfWaitY = ubY;
  pWaitCmd->bfWaitX = ubX >> 1;
  pWaitCmd->bfIsWait = 1;
  pWaitCmd->bfBlitterIgnore = 1;
  pWaitCmd->bfVE = 0x7F;
  pWaitCmd->bfHE = 0x7F;
  pWaitCmd->bfIsSkip = 1;
}

void copSetSkipRaw(tCopWaitCmd *pWaitCmd, UBYTE ubX, UBYTE ubY, UBYTE ubXCompare, UBYTE ubYCompare)
{
  pWaitCmd->bfWaitY = ubY;
  pWaitCmd->bfWaitX = ubX >> 1;
  pWaitCmd->bfIsWait = 1;
  pWaitCmd->bfBlitterIgnore = 1;
  pWaitCmd->bfVE = ubYCompare;
  pWaitCmd->bfHE = ubXCompare;
  pWaitCmd->bfIsSkip = 1;
}

UWORD copBuildRaw(UWORD ubCopIndex3, ULONG ulCop3H, ULONG ulCop3L, UWORD uwCol1, UWORD uwCol2, UWORD uwCol3, UWORD uwCol4, UWORD uwCol5, UWORD uwCol6, UBYTE ubSkipPos)
{
  UWORD *cop2lc = (UWORD *)&g_pCustom->cop2lc;

  copSetMoveBackAndFront3(cop2lc, ulCop3H);
  copSetMoveBackAndFront3(cop2lc + 1, ulCop3L);

  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[10], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[11], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[12], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[13], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[14], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[15], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[16], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[17], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[18], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[19], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[20], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[21], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[22], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[23], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[24], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[25], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[26], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[27], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[28], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[29], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[30], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[31], 0x0F0F);

  // 8 missing colors here
  //copSetWaitRawBackAndFront3(160, 0x00, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol6);

  copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  copSetSkipBackAndFront3(0, ubSkipPos);
  copSetMoveBackAndFront3(&g_pCustom->copjmp2, 1);

  return ubCopIndex3;
}

UWORD copBuildRawV2(UWORD ubCopIndex3, UBYTE ubChunkyRawNo, UWORD uwCol1, UWORD uwCol2, UWORD uwCol3, UWORD uwCol4, UWORD uwCol5, UWORD uwCol6, UBYTE ubSkipPos,UBYTE ubFlag)
{
  ULONG ulCop3Addr = (ULONG)((void *)pThirdCopList->pBackBfr->pList);
  ulCop3Addr += (45 * 4 * ubChunkyRawNo);
  UWORD *cop2lc = (UWORD *)&g_pCustom->cop2lc;

  UWORD ulCop3H = (UWORD)(ulCop3Addr >> 16);
  UWORD ulCop3L = (UWORD)(ulCop3Addr & 0x0000FFFF);

  /*logWrite("cop3addr ultima riga H : %x\n", ulCop3H4);
  logWrite("cop3addr ultima riga L : %x\n", ulCop3L4);*/

  copSetMoveBackAndFront3(cop2lc, ulCop3H);
  copSetMoveBackAndFront3(cop2lc + 1, ulCop3L);

  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[10], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[11], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[12], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[13], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[14], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[15], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[16], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[17], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[18], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[19], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[20], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[21], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[22], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[23], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[24], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[25], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[26], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[27], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[28], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[29], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[30], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[31], 0x0F0F);

  // 8 missing colors here
  //copSetWaitRawBackAndFront3(160, 0x00, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol6);

  //ubFlag == 0 , we are < 128
  // ubFlag == 1 , we are >= 128
  UBYTE ubVerticalWait = 0;
  if (ubFlag == 1 ) ubVerticalWait = 0x80;

  //copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  copSetWaitRawBackAndFront3(0xdf, ubVerticalWait, 0x7F, 0x00);
  copSetSkipBackAndFront3(0, ubSkipPos);
  copSetMoveBackAndFront3(&g_pCustom->copjmp2, 1);

  return ubCopIndex3;
}


UWORD copBuildRawV3(UWORD ubCopIndex3, UBYTE ubChunkyRawNo, UWORD uwCol1, UWORD uwCol2, UWORD uwCol3, UWORD uwCol4, UWORD uwCol5, UWORD uwCol6, UBYTE ubSkipPos,UBYTE ubFlag)
{
  ULONG ulCop3Addr = (ULONG)((void *)pThirdCopList->pBackBfr->pList);
  ulCop3Addr += (45 * 4 * ubChunkyRawNo);
  UWORD *cop2lc = (UWORD *)&g_pCustom->cop2lc;

  UWORD ulCop3H = (UWORD)(ulCop3Addr >> 16);
  UWORD ulCop3L = (UWORD)(ulCop3Addr & 0x0000FFFF);

  /*logWrite("cop3addr ultima riga H : %x\n", ulCop3H4);
  logWrite("cop3addr ultima riga L : %x\n", ulCop3L4);*/

  copSetMoveBackAndFront3(cop2lc, ulCop3H);
  copSetMoveBackAndFront3(cop2lc + 1, ulCop3L);

  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol2);

  copSetSkipBackAndFront3(0x7, 0x2a);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol3);
  
  copSetMoveBackAndFront3(&g_pCustom->color[10], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[11], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[12], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[13], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[14], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[15], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[16], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[17], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[18], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[19], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[20], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[21], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[22], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[23], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[24], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[25], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[26], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[27], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[28], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[29], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[30], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[31], 0x0FAF);

  // 8 missing colors here
  //copSetWaitRawBackAndFront3(0x00, 0x00, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol6);

  //ubFlag == 0 , we are < 128
  // ubFlag == 1 , we are >= 128
  UBYTE ubVerticalWait = 0;
  if (ubFlag == 1 ) ubVerticalWait = 0x80;

  //copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  copSetWaitRawBackAndFront3(0xdf, ubVerticalWait, 0x7F, 0x00);
  copSetSkipBackAndFront3(0, ubSkipPos);
  copSetMoveBackAndFront3(&g_pCustom->copjmp2, 1);

  return ubCopIndex3;
}



UWORD copBuildRawV2_255(UWORD ubCopIndex3, UBYTE ubChunkyRawNo, UWORD uwCol1, UWORD uwCol2, UWORD uwCol3, UWORD uwCol4, UWORD uwCol5, UWORD uwCol6, UBYTE ubSkipPos)
{
  ULONG ulCop3Addr = (ULONG)((void *)pThirdCopList->pBackBfr->pList);
  ulCop3Addr += (45 * 4 * ubChunkyRawNo);
  UWORD *cop2lc = (UWORD *)&g_pCustom->cop2lc;

  UWORD ulCop3H = (UWORD)(ulCop3Addr >> 16);
  UWORD ulCop3L = (UWORD)(ulCop3Addr & 0x0000FFFF);

  /*logWrite("cop3addr ultima riga H : %x\n", ulCop3H4);
  logWrite("cop3addr ultima riga L : %x\n", ulCop3L4);*/

  copSetMoveBackAndFront3(cop2lc, ulCop3H);
  copSetMoveBackAndFront3(cop2lc + 1, ulCop3L);

  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[10], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[11], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[12], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[13], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[14], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[15], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[16], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[17], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[18], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[19], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[20], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[21], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[22], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[23], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[24], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[25], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[26], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[27], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[28], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[29], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[30], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[31], 0x0F0F);

  // 8 missing colors here
  //copSetWaitRawBackAndFront3(160, 0x00, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol6);

  copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  copSetSkipBackAndFront3(0, 255);
  //copSetSkipRawBackAndFront3(100,0xFF,0x7F,0x7F);
  copSetMoveBackAndFront3(&g_pCustom->copjmp2, 1);
  return ubCopIndex3;

  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[10], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[11], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[12], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[13], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[14], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[15], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[16], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[17], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[18], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[19], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[20], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[21], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[22], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[23], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[24], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[25], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[26], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[27], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[28], uwCol1);
  copSetMoveBackAndFront3(&g_pCustom->color[29], uwCol2);
  copSetMoveBackAndFront3(&g_pCustom->color[30], uwCol3);
  copSetMoveBackAndFront3(&g_pCustom->color[31], 0x0F0F);

  // 8 missing colors here
  //copSetWaitRawBackAndFront3(160, 0x00, 0x7F, 0x00);
  copSetMoveBackAndFront3(&g_pCustom->color[1], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[2], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[3], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[4], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[5], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[6], uwCol6);
  copSetMoveBackAndFront3(&g_pCustom->color[7], uwCol4);
  copSetMoveBackAndFront3(&g_pCustom->color[8], uwCol5);
  copSetMoveBackAndFront3(&g_pCustom->color[9], uwCol6);

  copSetWaitBackAndFront3(0xdf, 0xff);
  return ubCopIndex3;

  copSetWaitBackAndFront3(0, 0);
  copSetMoveBackAndFront3(&g_pCustom->color[0], 0x0FFF);

  //copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  //copSetSkipBackAndFront3(0,0x00);
  //copSetMoveBackAndFront3(&g_pCustom->copjmp2, 1);

  return ubCopIndex3;

  copSetWaitRawBackAndFront3(0xdf, 0x00, 0x7F, 0x00);
  //copSetWaitBackAndFront3(0xdf, 0xff);

  return ubCopIndex3;
}