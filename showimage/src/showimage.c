

#include "showimage.h"
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameClose
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include "../_res/valchiria320x256.h"

// All variables outside fns are global - can be accessed in any fn
// Static means here that given var is only for this file, hence 's_' prefix
// You can have many variables with same name in different files and they'll be
// independent as long as they're static
// * means pointer, hence 'p' prefix
static tView *s_pView; // View containing all the viewports

static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;
void copyToMainBpl(const unsigned char*,const UBYTE, const UBYTE);

void gameGsCreate(void) {
  // Create a view - first arg is always zero, then it's option-value
  s_pView = viewCreate(0,
    TAG_VIEW_GLOBAL_CLUT, 1, // Same Color LookUp Table for all viewports
  TAG_END); // Must always end with TAG_END or synonym: TAG_DONE

  

  // Now let's do the same for main playfield
  s_pVpMain = vPortCreate(0,
    TAG_VPORT_VIEW, s_pView,
    TAG_VPORT_BPP, 4, // 2 bits per pixel, 4 colors
    // We won't specify height here - viewport will take remaining space.
  TAG_END);
  s_pMainBuffer = simpleBufferCreate(0,
    TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
    TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
  TAG_END);

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

  // We don't need anything from OS anymore
  //systemUnuse();
  //Execute("RUN casentino2020");

  // Load the view
  viewLoad(s_pView);
}

void gameGsLoop(void) {
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  //if(keyCheck(KEY_ESCAPE)) {
    static int frameno = 0;
  if (frameno++>1000) {
    gameClose();return ;
    /*systemUse();
    Execute("df0:casentino2020");*/
  }
  else {
    // Process loop normally
    // We'll come back here later
  }
  vPortWaitForEnd(s_pVpMain);
}

void gameGsDestroy(void) {
  // Cleanup when leaving this gamestate
  //systemUse();

  // This will also destroy all associated viewports and viewport managers
  //viewDestroy(s_pView);
  //Execute("casentino2020");
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

void mysystemDestroy(void) {
        // disable all interrupts
        g_pCustom->intena = 0x7FFF;
        g_pCustom->intreq = 0x7FFF;

        // Wait for vbl before disabling sprite DMA
        while (!(g_pCustom->intreqr & INTF_VERTB)) {}
        g_pCustom->dmacon = 0x07FF;
        g_pCustom->intreq = 0x7FFF;

        
        systemUse();

        // Restore all OS DMA
        //g_pCustom->dmacon = DMAF_SETCLR | DMAF_MASTER | s_uwOsInitialDma;

       

        WaitBlit();
        DisownBlitter();

        logWrite("Closing graphics.library...");
        CloseLibrary((struct Library *) GfxBase);
        logWrite("OK\n");

        
}
