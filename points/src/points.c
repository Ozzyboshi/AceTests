#include "points.h"
#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameClose
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>
#include <ace/utils/font.h> // needed for tFont and font stuff

#include "paper_cut.h"
#include "outputfile.h"
#include "uni54.h"

long mt_init(const unsigned char *);
void mt_music();

#define BLIT_LINE_OR ((ABC | ABNC | NABC | NANBC) | (SRCA | SRCC | DEST))
#define BLIT_LINE_XOR ((ABNC | NABC | NANBC) | (SRCA | SRCC | DEST))
#define BLIT_LINE_ERASE ((NABC | NANBC | ANBC) | (SRCA | SRCC | DEST))

void blitLine2(
    tBitMap *pDst, WORD x1, WORD y1, WORD x2, WORD y2,
    UBYTE ubColor, UWORD uwPattern);

void blitClear(tSimpleBufferManager *buffer, UBYTE nBitplane);
void printCursorPixel(tSimpleBufferManager *pMainBuffer, UWORD uwXCoordinate, UWORD uwYCoordinate);

static tView *s_pView;    // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
static tFont *s_pFontUI;
static tTextBitMap *s_pGlyph;

void gameGsCreate(void)
{
        // Create a view - first arg is always zero, then it's option-value
        s_pView = viewCreate(0,
                             TAG_VIEW_GLOBAL_CLUT, 1, // Same Color LookUp Table for all viewports
                             TAG_END);                // Must always end with TAG_END or synonym: TAG_DONE

        // Now let's do the same for main playfield
        s_pVpMain = vPortCreate(0,
                                TAG_VPORT_VIEW, s_pView,
                                TAG_VPORT_BPP, 1, // 1 bits per pixel, 2 colors
                                                  // We won't specify height here - viewport will take remaining space.
                                TAG_END);
        s_pMainBuffer = simpleBufferCreate(0,
                                           TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
                                           TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
                                           TAG_SIMPLEBUFFER_IS_DBLBUF, 1,
                                           //TAG_VPORT_HEIGHT, 32, // Optional: let's make it 32px high
                                           TAG_END);

        s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
        s_pVpMain->pPalette[1] = 0x0888; // Gray

        // We don't need anything from OS anymore
        systemUnuse();

        s_pFontUI = fontCreateFromMem((UBYTE *)uni54_data);
        if (s_pFontUI == NULL)
                return;
        s_pGlyph = fontCreateTextBitMap(320, s_pFontUI->uwHeight);
        fontFillTextBitMap(s_pFontUI, s_pGlyph, "THX to Chillobits team for this awesome effect");
        fontDrawTextBitMap(s_pMainBuffer->pFront, s_pGlyph, 150, 230, 1, FONT_CENTER | FONT_LAZY);
        fontDrawTextBitMap(s_pMainBuffer->pBack, s_pGlyph, 150, 230, 1, FONT_CENTER | FONT_LAZY);

        // Load the view
        viewLoad(s_pView);

        mt_init(g_tPapercutMod_data);
        viewProcessManagers(s_pView);
        copProcessBlocks();
}

void gameGsLoop(void)
{
        //wait1();
        mt_music();
        // This will loop forever until you "pop" or change gamestate
        // or close the game
        if (keyCheck(KEY_ESCAPE))
        {
                gameClose();
                return;
        }
        
        static BYTE bCounter = 0;
        static BYTE bIncrementer = 1;
        static UBYTE *ptr = (UBYTE *)pos_data;
        static int frame = 0;
        static UWORD centerOffset = 0;
        static UWORD uwPattern = 0xFFFF;
        /*if (frame++<2) 
  {
          vPortWaitForEnd(s_pVpMain);
          return ;
  }
  frame=0;*/

        UBYTE lineChanged = 0;
        UWORD uwEndPos = s_pVpMain->uwOffsY + s_pVpMain->uwHeight + 0x2C;

        //g_pCustom->color[0] = 0x0FFF;
        blitClear(s_pMainBuffer, 0);
        static UBYTE i;
        for (i = 0; i < 40; i++)
        {

                UWORD uwX1 = (UWORD)(*ptr);
                UWORD uwY1 = (UWORD)(*(ptr + 1));

                /*UBYTE uwX1 = (UBYTE)(*ptr);
    UBYTE uwY1 = (UBYTE)(*(ptr+1));*/
                if (uwX1 > 0 && uwY1 > 0)
                {
                        //blitLine2(s_pMainBuffer->pBack,80+bCounter ,80+bCounter,bCounter+(UWORD)(*ptr),bCounter+(UWORD)*(ptr+1),1, 0xFFFF);
                        //if (uwX1) blitLine2(s_pMainBuffer->pBack,80+bCounter ,80+bCounter,bCounter+uwX1,bCounter+uwY1,1, 0xFFFF);

                        InitLine();
                        g_pCustom->bltbdat = uwPattern;

                        DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]), 80 + bCounter + centerOffset, 80 + bCounter + centerOffset, bCounter + uwX1, bCounter + uwY1);
                }

                ptr = ptr + 2;

                /*if (g_pRayPos->bfPosY>0x2c)
    {
      if (lineChanged==0) mt_music();
      lineChanged=1;
    }*/
        }

        vPortWaitForEnd(s_pVpMain);
        mt_music();

        for (i = 40; i < 80; i++)
        {

                UWORD uwX1 = (UWORD)(*ptr);
                UWORD uwY1 = (UWORD)(*(ptr + 1));
                if (uwX1 > 0 && uwY1 > 0)
                {
                        InitLine();
                        g_pCustom->bltbdat = uwPattern;

                        DrawlineOr((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]), 80 + bCounter + centerOffset, 80 + bCounter + centerOffset, bCounter + uwX1, bCounter + uwY1);
                }
                ptr = ptr + 2;
        }

        //ptr+=20;
        //g_pCustom->color[0] = 0x0000;
        if (ptr > pos_data + pos_size - 2)
        {
                ptr = (UBYTE *)pos_data;
        }

        bCounter += bIncrementer;
        if (bCounter > 70 || bCounter < 1)
                bIncrementer *= -1;
        //wait2();
        vPortWaitForEnd(s_pVpMain);
        viewProcessManagers(s_pView);
        copProcessBlocks();

        //blitClear(s_pMainBuffer,0); // Here we are deleting front because buffers have been swapped by viewProcessManagers
        //copProcessBlocks();

        frame++;

        if (frame == 1)
        {
                g_pCustom->color[0] = 0x000F;
                centerOffset = 30;
                uwPattern = 0x0FFF;
        }
        else if (frame == 100)
        {
                g_pCustom->color[0] = 0x0F00;
                centerOffset = 0;
                uwPattern = 0xFFFF;
        }
        else if (frame == 200)
        {
                g_pCustom->color[0] = 0x00F0;
                centerOffset = 15;
                uwPattern = 0x0F0F;
        }
        else if (frame == 300)
        {
                g_pCustom->color[0] = 0x0FF0;
                centerOffset = 5;
                uwPattern = 0xF0F0;
        }

        if (frame > 400)
        {

                frame = 0;
        }
}

void gameGsDestroy(void)
{
        // Cleanup when leaving this gamestate
        systemUse();

        fontDestroyTextBitMap(s_pGlyph);
        fontDestroy(s_pFontUI);

        // This will also destroy all associated viewports and viewport managers
        viewDestroy(s_pView);
}

void blitLine2(
    tBitMap *pDst, WORD x1, WORD y1, WORD x2, WORD y2,
    UBYTE ubColor, UWORD uwPattern)
{
        // Based on Cahir's function from:
        // https://github.com/cahirwpz/demoscene/blob/master/a500/base/libsys/blt-line.c

        UWORD uwBltCon1 = LINEMODE;

        // Always draw the line downwards.
        if (y1 > y2)
        {
                SWAP(x1, x2);
                SWAP(y1, y2);
        }

        // Word containing the first pixel of the line.
        WORD wDx = x2 - x1;
        WORD wDy = y2 - y1;

        // Setup octant bits
        if (wDx < 0)
        {
                wDx = -wDx;
                if (wDx >= wDy)
                {
                        uwBltCon1 |= AUL | SUD;
                }
                else
                {
                        uwBltCon1 |= SUL;
                        SWAP(wDx, wDy);
                }
        }
        else
        {
                if (wDx >= wDy)
                {
                        uwBltCon1 |= SUD;
                }
                else
                {
                        SWAP(wDx, wDy);
                }
        }

        WORD wDerr = wDy + wDy - wDx;
        if (wDerr < 0)
        {
                uwBltCon1 |= SIGNFLAG;
        }

        UWORD uwBltSize = (wDx << 6) + 66;
        UWORD uwBltCon0 = ror16(x1 & 15, 4);
        ULONG ulDataOffs = pDst->BytesPerRow * y1 + ((x1 >> 3) & ~1);
        blitWait();
        g_pCustom->bltafwm = -1;
        g_pCustom->bltalwm = -1;
        g_pCustom->bltadat = 0x8000;
        g_pCustom->bltbdat = uwPattern;
        g_pCustom->bltamod = wDerr - wDx;
        g_pCustom->bltbmod = wDy + wDy;
        g_pCustom->bltcmod = pDst->BytesPerRow;
        g_pCustom->bltdmod = pDst->BytesPerRow;
        g_pCustom->bltcon1 = uwBltCon1;
        g_pCustom->bltapt = (APTR)(LONG)wDerr;
        //for(UBYTE ubPlane = 4; ubPlane != pDst->Depth; ++ubPlane) {
        static UBYTE ubPlane = 0;
        UBYTE *pData = pDst->Planes[ubPlane] + ulDataOffs;
        UWORD uwOp = ((ubColor & BV(ubPlane)) ? BLIT_LINE_OR : BLIT_LINE_ERASE);

        blitWait();
        //waitblit();
        g_pCustom->bltcon0 = uwBltCon0 | uwOp;
        g_pCustom->bltcpt = pData;
        g_pCustom->bltdpt = (APTR)(pData);
        g_pCustom->bltsize = uwBltSize;
        //}
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
        g_pCustom->bltsize = 0x3794;

        return;
}
