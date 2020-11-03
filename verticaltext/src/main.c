
#include <ace/generic/main.h>
#include <ace/managers/key.h>
#include <ace/managers/state.h>

#include "main.h"
#include "verticaltext.h"

tStateManager *g_pGameStateManager = 0;
tState *g_pGameStates[GAME_STATE_COUNT] = {0};

void genericCreate(void)
{
  // Here goes your startup code
  logWrite("Hello, Amiga!\n");
  keyCreate(); // We'll use keyboard
  g_pGameStateManager = stateManagerCreate();
  g_pGameStates[0] = stateCreate(verticaltextGsCreate, verticaltextGsLoop, verticaltextGsDestroy, 0, 0, 0);
  statePush(g_pGameStateManager, g_pGameStates[0]);
}

void genericProcess(void)
{
  // Here goes code done each game frame
  keyProcess();
  stateProcess(g_pGameStateManager);
}

void genericDestroy(void)
{
  // Here goes your cleanup code

  stateManagerDestroy(g_pGameStateManager);
  stateDestroy(g_pGameStates[0]);

  keyDestroy(); // We don't need it anymore
  logWrite("Goodbye, Amiga!\n");
}

void copyBpl(const unsigned char *pSrc,const unsigned char* pDst)
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
  g_pCustom->bltapt = (UBYTE *)((ULONG)pSrc+40*16);
  g_pCustom->bltdpt = (UBYTE *)((ULONG)pDst);
  g_pCustom->bltsize = 0x4014;
}
