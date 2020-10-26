#include "metaballschunky.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>
#include <fixmath/fix16.h>

#include "../_res/colors.h"
#include "../_res/electrobusted.h"

#define XMOVE

#define BITPLANES 5

#define XRES 20
#define YRES 16

#define XRESMIDDLE 10
#define YRESMIDDLE 8

#define MAXBALLS 3

static UWORD XRESMAX = XRES * 16;
static UWORD YRESMAX = YRES * 16;

typedef struct tBall
{
  WORD uwX;
  WORD uwY;

  UWORD uwXincrementer;
  UWORD uwYincrementer;

  UWORD uwXframecounter;
  UWORD uwXframe;

  UWORD uwYframecounter;
  UWORD uwYframe;

  fix16_t tX;
  fix16_t tY;

  fix16_t tXinc;
  fix16_t tYinc;

} tBall;

static tBall BALLS[MAXBALLS];

//#define COLORDEBUG

#define copSetWaitBackAndFront(var, var2, var3)            \
  copSetWait(&pCmdListBack[ubCopIndex].sWait, var, var2);  \
  copSetWait(&pCmdListFront[ubCopIndex].sWait, var, var2); \
  if (var3)                                                \
    g_sWaitPositions[ubWaitCounter++] = ubCopIndex;        \
  ubCopIndex++;

#define copSetMoveBackAndFront(var, var2)                  \
  copSetMove(&pCmdListBack[ubCopIndex].sMove, var, var2);  \
  copSetMove(&pCmdListFront[ubCopIndex].sMove, var, var2); \
  ubCopIndex++;

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
static UWORD g_sWaitPositions[YRES];

void setPxColor(UBYTE ubX, UBYTE ubY, UWORD uwValue);
static UWORD colorHSV(UBYTE ubH, UBYTE ubS, UBYTE ubV);

static UWORD COLORS[202] = {
    0x0000, 0x0000, 0x0000,
    0x0100, 0x0100, 0x0100,
    0x0200, 0x0200, 0x0200,
    0x0300, 0x0300, 0x0300,
    0x0400, 0x0400, 0x0400,
    0x0500, 0x0500, 0x0500,

    0x0600, 0x0600, 0x0600,
    0x0700, 0x0700, 0x0700,
    0x0800, 0x0800, 0x0800,
    0x0900, 0x0900, 0x0900,
    0x0A00, 0x0A00, 0x0A00,
    0x0B00, 0x0B00, 0x0B00,

    0x0C00, 0x0C00, 0x0C00,
    0x0D00, 0x0D00, 0x0D00,
    0x0E00, 0x0E00, 0x0E00,
    0x0F00, 0x0F00, 0x0F00,
    0x0F00, 0x0F00, 0x0F00
    /*,0x0110,
  0x0220,0x0220,0x0220,

  0x0330,0x0330,0x0330,
  0x0440,0x0440,0x0440,*/

};

static UWORD GRADIENT[16] = {
  0x0F00,
  0x0E10,
  0x0D20,
  0x0C30,
  0x0B40,
  0x0A50,
  0x0960,
  0x0870,
  0x0780,
  0x0690,
  0x05A0,
  0x04B0,
  0x03C0,
  0x02D0,
  0x01E0,
  0x00F0

};

//Music
long mt_init(const unsigned char *);
void mt_music();
void mt_end();

void gameGsCreate(void)
{
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(BITPLANES) +
                     YRES + 1 +    // yres is 16 so we need 16 waits + 1 for checking the 255th line
                     XRES * YRES + //reserve space for 20 colors for each YRES
                     1 +           // Final WAIT
                     1             // Just to be sure
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

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray
  s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red
  s_pVpMain->pPalette[4] = 0x00FF;
  s_pVpMain->pPalette[5] = 0x00FA;
  s_pVpMain->pPalette[6] = 0x00F1;

  s_pVpMain->pPalette[7] = 0x00F2;

  s_pVpMain->pPalette[8] = 0x00F3;

  s_pVpMain->pPalette[9] = 0x00F4;

  s_pVpMain->pPalette[10] = 0x00F5;

  s_pVpMain->pPalette[11] = 0x00F6;

  s_pVpMain->pPalette[12] = 0x00F7;

  s_pVpMain->pPalette[13] = 0x00F8;

  s_pVpMain->pPalette[14] = 0x00F9;

  s_pVpMain->pPalette[15] = 0x00AA;

  s_pVpMain->pPalette[16] = 0x0011;
  s_pVpMain->pPalette[17] = 0x0022;
  s_pVpMain->pPalette[18] = 0x0033;
  s_pVpMain->pPalette[19] = 0x0044;
  s_pVpMain->pPalette[20] = 0x0055;
  s_pVpMain->pPalette[21] = 0x0066;

  mt_init(electrobusted_data);

  // We don't need anything from OS anymore
  systemUnuse();

  /*
ColUMN            0   1   2   3        4   5   6   7        8   9   10   11   12   13

Bitplane 0 -      1   0   1   0        1   0   1   0        1   0    1    0    1    0
Bitplane 1 -      0   1   1   0        0   1   1   0        0   1    1    0    0    1
Bitplane 2 -      0   0   0   1        1   1   1   0        0   0    0    1    1    1
Bitplane 3 -      0   0   0   0        0   0   0   1        1   1    1    1    1    1
Bitplane 4 -      0   0   0   0        0   0   0   0        0   0    0    0    0    0

*/

  for (UBYTE ubCont = 0; ubCont < 20; ubCont++)
  {
    blitRect(s_pMainBuffer->pBack, ubCont * 16, 0, 16, 256, ubCont + 1);
  }

  tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
  tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
  tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];

  UWORD ubCopIndex = 0;
  UBYTE ubWaitCounter = 0;

  // Start of opperlist - wait + setting colors
  UBYTE ubSpecialWait = 0;
  for (UBYTE ubCount = 0; ubCount < YRES; ubCount++)
  {
    UBYTE ubXWait = 44 + ubCount * YRES;
    copSetWaitBackAndFront(0, ubXWait, 1);
    copSetMoveBackAndFront(&g_pCustom->color[1], 0x0888);
    copSetMoveBackAndFront(&g_pCustom->color[2], 0x0AAA);
    copSetMoveBackAndFront(&g_pCustom->color[3], 0x0BBB);

    copSetMoveBackAndFront(&g_pCustom->color[4], 0x0111);
    copSetMoveBackAndFront(&g_pCustom->color[5], 0x0222);
    copSetMoveBackAndFront(&g_pCustom->color[6], 0x0333);

    copSetMoveBackAndFront(&g_pCustom->color[7], 0x0444);
    copSetMoveBackAndFront(&g_pCustom->color[8], 0x0555);
    copSetMoveBackAndFront(&g_pCustom->color[9], 0x0666);

    copSetMoveBackAndFront(&g_pCustom->color[10], 0x0444);
    copSetMoveBackAndFront(&g_pCustom->color[11], 0x0555);
    copSetMoveBackAndFront(&g_pCustom->color[12], 0x0666);

    copSetMoveBackAndFront(&g_pCustom->color[13], 0x0777);
    copSetMoveBackAndFront(&g_pCustom->color[14], 0x0888);
    copSetMoveBackAndFront(&g_pCustom->color[15], 0x0999);

    copSetMoveBackAndFront(&g_pCustom->color[16], 0x0AAA);
    copSetMoveBackAndFront(&g_pCustom->color[17], 0x0BBB);
    copSetMoveBackAndFront(&g_pCustom->color[18], 0x0CCC);

    copSetMoveBackAndFront(&g_pCustom->color[19], 0x0444);
    copSetMoveBackAndFront(&g_pCustom->color[20], 0x0555);
    //copSetMoveBackAndFront(&g_pCustom->color[21], 0x0666)   ;

    if ((UWORD)ubXWait + YRES > 255 && ubSpecialWait == 0)
    {
      copSetWaitBackAndFront(0xdf, 0xff, 0);
      ubSpecialWait = 1;
    }
  }

  // Ball init
  BALLS[0].uwX = XRESMIDDLE * 16;
  BALLS[0].uwY = YRESMIDDLE * 16;
  BALLS[0].uwXincrementer = 1;
  BALLS[0].uwYincrementer = 1;
  BALLS[0].uwXframecounter = 0; // X moves each 5 frames
  BALLS[0].uwXframe = 0;

  BALLS[0].uwYframecounter = 1; // Y moves each 5 frames
  BALLS[0].uwYframe = 1;

  BALLS[0].tX = fix16_from_int(XRESMIDDLE);
  BALLS[0].tY = fix16_from_int(YRESMIDDLE);
  BALLS[0].tXinc = fix16_div(fix16_from_int(1), fix16_from_int(10));
  BALLS[0].tYinc = fix16_div(fix16_from_int(1), fix16_from_int(10));

  BALLS[1].uwX = XRESMIDDLE * 16;
  BALLS[1].uwY = YRESMIDDLE * 16;
  BALLS[1].uwXincrementer = -1;
  BALLS[1].uwYincrementer = -1;
  BALLS[1].uwXframecounter = 0; // X moves each 5 frames
  BALLS[1].uwXframe = 0;

  BALLS[1].uwYframecounter = 1; // Y moves each 5 frames
  BALLS[1].uwYframe = 1;

  BALLS[1].tX = fix16_from_int(XRESMIDDLE);
  BALLS[1].tY = fix16_from_int(YRESMIDDLE);
  BALLS[1].tXinc = fix16_div(fix16_from_int(1), fix16_from_int(11));
  BALLS[1].tYinc = fix16_div(fix16_from_int(1), fix16_from_int(10));

  for (int i = 0; i < 202; i++)
    COLORS[i] = colorHSV((UBYTE)i * 4, 255, 255);

  // Load the view
  viewLoad(s_pView);

}

void gameGsLoop(void)
{
#ifdef COLORDEBUG
  g_pCustom->color[0] = 0x0FF0;
#endif

  static UWORD uwFrameNo = 0;
  static UBYTE *pColorPtr = &colors_data[0];

  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if (keyCheck(KEY_ESCAPE))
  {
    gameExit();
  }

  if (keyUse(KEY_D))
  {
    tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
    copDumpBfr(pCopBfr);

    pCopBfr = s_pView->pCopList->pFrontBfr;
    copDumpBfr(pCopBfr);
  }

  if (keyUse(KEY_Z))
  {
    setPxColor(0, 0, 0x0F00);
  }

  static UBYTE xZoom = 0;
  if (keyUse(KEY_Q))
    xZoom++;
  if (keyUse(KEY_W))
    xZoom--;

  //if (keyUse(KEY_X))
  if (1)
  {
#ifdef XMOVE

    // Move the balls
    for (UBYTE ubBallCounter = 0; ubBallCounter < 2; ++ubBallCounter)
    {
#ifdef FIX16
      BALLS[ubBallCounter].tX = fix16_add(BALLS[ubBallCounter].tX, BALLS[ubBallCounter].tXinc);
      if (BALLS[ubBallCounter].tX < 0 || BALLS[ubBallCounter].tX > fix16_from_int(XRES))
        BALLS[ubBallCounter].tXinc = fix16_mul(BALLS[ubBallCounter].tXinc, fix16_from_int(-1));

      BALLS[ubBallCounter].tY = fix16_add(BALLS[ubBallCounter].tY, BALLS[ubBallCounter].tYinc);
      if (BALLS[ubBallCounter].tY < 0 || BALLS[ubBallCounter].tY > fix16_from_int(YRES))
        BALLS[ubBallCounter].tYinc = fix16_mul(BALLS[ubBallCounter].tYinc, fix16_from_int(-1));
#else
      if (BALLS[ubBallCounter].uwXframecounter == 0)
      {
        BALLS[ubBallCounter].uwXframecounter = BALLS[ubBallCounter].uwXframe;
        BALLS[ubBallCounter].uwX += BALLS[ubBallCounter].uwXincrementer;
        if (BALLS[ubBallCounter].uwX <= 0 || BALLS[ubBallCounter].uwX >= XRESMAX)
          BALLS[ubBallCounter].uwXincrementer *= -1;
      }
      else
        BALLS[ubBallCounter].uwXframecounter--;

      if (BALLS[ubBallCounter].uwYframecounter == 0)
      {
        BALLS[ubBallCounter].uwYframecounter = BALLS[ubBallCounter].uwYframe;
        BALLS[ubBallCounter].uwY += BALLS[ubBallCounter].uwYincrementer;
        if (BALLS[ubBallCounter].uwY <= 0 || BALLS[ubBallCounter].uwY >= YRESMAX)
          BALLS[ubBallCounter].uwYincrementer *= -1;
      }
      else
        BALLS[ubBallCounter].uwYframecounter--;
#endif
    }
#endif

    //Horizontal

    for (UBYTE ubHorizontalCounter = 0; ubHorizontalCounter < XRES; ubHorizontalCounter++)
    {
#ifdef FIX16
      fix16_t distX = fix16_sub(fix16_from_int(ubHorizontalCounter), BALLS[0].tX);
      fix16_t distXSquare = fix16_mul(distX, distX);
#else
      LONG wXdist = ubHorizontalCounter * 16 - BALLS[0].uwX;
      LONG wXdist_2 = ubHorizontalCounter * 16 - BALLS[1].uwX;
      if (wXdist < 0)
        wXdist = wXdist * -1;
      if (wXdist_2 < 0)
        wXdist_2 = wXdist_2 * -1;
#ifdef ACE_DEBUG
      logWrite("X Distance for horizontal counter %u is %d\n", ubHorizontalCounter, wXdist);
      logWrite("X Distance 2 for horizontal counter %u is %d\n", ubHorizontalCounter, wXdist_2);
#endif

      /*LONG wXdistElevatedTo2=wXdist;
      if (wXdistElevatedTo2<0) wXdistElevatedTo2*=-1;*/

      /* LONG wXdist_2 = ubHorizontalCounter * 16 - BALLS[1].uwX;
      LONG wXdistElevatedTo2_2 = wXdist_2;
      if (wXdistElevatedTo2_2 < 0)
        wXdistElevatedTo2_2 *= -1;*/
#endif

      // vertical
      for (UBYTE ubVerticalCounter = 0; ubVerticalCounter < YRES; ubVerticalCounter++)
      {

#ifdef FIX16
        fix16_t distY = fix16_sub(fix16_from_int(ubVerticalCounter), BALLS[0].tY);
        fix16_t distYSquare = fix16_mul(distY, distY);
        fix16_t dist = fix16_add(distXSquare, distYSquare);
        UWORD wDist = (UWORD)fix16_to_int(dist);
        wDist = wDist << 2;
#else
        LONG wYdist = ubVerticalCounter * 16 - BALLS[0].uwY;
        LONG wYdist_2 = ubVerticalCounter * 16 - BALLS[1].uwY;
        if (wYdist < 0)
          wYdist = wYdist * -1;
        if (wYdist_2 < 0)
          wYdist_2 = wYdist_2 * -1;
#ifdef ACE_DEBUG
        logWrite("Y Distance for horizontal counter %u is %d\n", ubVerticalCounter, wYdist);
        logWrite("Y Distance 2 for horizontal counter %u is %d\n", ubVerticalCounter, wYdist_2);
#endif

        /*LONG wYdist_2 = ubVerticalCounter*16 - BALLS[1].uwY;
        LONG wYdistElevatedTo2=wYdist;
        if (wYdistElevatedTo2<0) wYdistElevatedTo2*=-1;
        LONG wYdistElevatedTo2_2=wYdist_2;
        if (wYdistElevatedTo2_2<0) wYdistElevatedTo2_2*=-1;
        LONG wDist = wXdistElevatedTo2 + wYdistElevatedTo2;
        LONG wDist_2 = wXdistElevatedTo2_2 + wYdistElevatedTo2_2;
        if (wDist>1600) wDist=1600;
        if (wDist_2>1600) wDist_2=1600;*/
        //LONG wDistTot = 0;

        LONG wDist = wXdist + wYdist;
        //wDistTot+=(wDist>>2);

        LONG wDist_2 = wXdist_2 + wYdist_2;

        //if (wDist==0 && wDist_2==0) wDist++;
        LONG wDistTot = wDist + wDist_2;
        //wDistTot+=(wDist_2>>2);

        wDistTot = wDistTot >> xZoom;
#endif

        /*UWORD uwColor = (*pColorPtr << 8) | (*(pColorPtr + 1));
        pColorPtr += 2;
        WORD wXdist = ubHorizontalCounter - BALLS[0].uwX;
        WORD wYdist = ubVerticalCounter - BALLS[0].uwY;
        WORD wDist = wXdist * wXdist + wYdist * wYdist;*/

        //UBYTE ubColIndex = wDist >> 5;

        UWORD uwColor;
        //if (wDistTot>3200) wDist=3200;
        UBYTE ubColorIndex = wDistTot >> 0;
        /*if (ubColorIndex > 144 * 2)
          gameExit();*/
        uwColor = COLORS[ubColorIndex];

       ubColorIndex = wDistTot>>4;
       
       if (ubColorIndex<64) uwColor = COLORS[ubColorIndex];
       else uwColor=0;

       // uwColor = GRADIENT[7];

        /*if (wDist < 20)
          uwColor = 0x0FFF;
        else if (wDist < 50)
          uwColor = 0x0EEE;*/
#if 0
        if (wDistTot < 50)
          uwColor = 0x0E10;
        else if (wDistTot < 100)
          uwColor = 0x0D20;
        else if (wDistTot < 150)
          uwColor = 0x0C30;
        else if (wDistTot < 200)
          uwColor = 0x0B40;
        else if (wDistTot < 250)
          uwColor = 0x0A50;
        else if (wDistTot < 300)
          uwColor = 0x0960;
        else if (wDistTot < 350)
          uwColor = 0x0870;
        else if (wDistTot < 400)
          uwColor = 0x0780;
        else if (wDistTot < 450)
          uwColor = 0x0690;
        else if (wDistTot < 500)
          uwColor = 0x05A0;
        else if (wDistTot < 550)
          uwColor = 0x04B0;
        else if (wDistTot < 600)
          uwColor = 0x03C0;
        else if (wDistTot < 650)
          uwColor = 0x02D0;
        else if (wDistTot < 700)
          uwColor = 0x01E0;
        else if (wDistTot < 750)
          uwColor = 0x00F0;
        else // (wDistTot < 900)
          uwColor = 0;
        if (wDistTot < 10)
          uwColor = 0x0FFF;
#endif

        /*else if (wDist < 300)
          uwColor = 0x0222;
        else if (wDist < 400)
          uwColor = 0x0333;
        else if (wDist < 500)
          uwColor = 0x0444;
        else if (wDist < 600)
          uwColor = 0x0555;
        else if (wDist < 700)
          uwColor = 0x0666;
          else if (wDist < 800)
          uwColor = 0x0777;
          else if (wDist < 900)
          uwColor = 0x0888;
          else if (wDist < 1000)
          uwColor = 0x0999;
          else if (wDist < 1100)
          uwColor = 0x0AAA;
          else if (wDist < 1200)
          uwColor = 0x0BBB;
          else if (wDist < 1300)
          uwColor = 0x0CCC;
          else if (wDist < 1400)
          uwColor = 0x0DDD;
          else if (wDist < 1500)
          uwColor = 0x0EEE;
        else*/
        //uwColor = 0x0FFF;

        //wDist=wDist<<xZoom;
        //uwColor = colorHSV((UBYTE)wDist, 255, (UBYTE)170);
        if (wDist < 20 || wDist_2 < 20)
          uwColor = COLORS[0];

        setPxColor((UBYTE)ubHorizontalCounter, ubVerticalCounter, uwColor);
      }
    }
    uwFrameNo++;
  }
  /*if (uwFrameNo >= 300)
  {
    uwFrameNo = 0;
    pColorPtr = &colors_data[0];
  }*/

#ifdef COLORDEBUG
  g_pCustom->color[0] = 0x0000;
#endif

  vPortWaitForEnd(s_pVpMain);
  copSwapBuffers();
  mt_music();
  //copSwapBuffers();
}

void gameGsDestroy(void)
{
  mt_end();

  // Cleanup when leaving this gamestate
  systemUse();

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}
void setPxColor(UBYTE ubX, UBYTE ubY, UWORD uwValue)
{
  tCopList *pCopList = s_pMainBuffer->sCommon.pVPort->pView->pCopList;
  tCopCmd *pCmdListBack = &pCopList->pBackBfr->pList[s_uwCopRawOffs];
  //tCopCmd *pCmdListFront = &pCopList->pFrontBfr->pList[s_uwCopRawOffs];
  ubX++;

#ifdef ACE_DEBUG
  logWrite("Setting value %x for pixel vertical %u\n", uwValue, ubY);
#endif
  /*copSetMove(&pCmdListBack[g_sWaitPositions[ubY] + ubX].sMove, &g_pCustom->color[ubX], uwValue);
  copSetMove(&pCmdListFront[g_sWaitPositions[ubY] + ubX].sMove, &g_pCustom->color[ubX], uwValue);*/

  pCmdListBack[g_sWaitPositions[ubY] + ubX].sMove.bfValue = uwValue;
}
/*
void copSetMove(tCopMoveCmd *pMoveCmd, volatile void *pAddr, UWORD uwValue) {
	pMoveCmd->bfUnused = 0;
	pMoveCmd->bfDestAddr = (ULONG)pAddr - (ULONG)((UBYTE *)g_pCustom);
	pMoveCmd->bfValue = uwValue;
}*/

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