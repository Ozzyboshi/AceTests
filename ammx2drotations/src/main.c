
#include <ace/generic/main.h>
#include <ace/managers/key.h>
#include <ace/managers/state.h>

#include "main.h"
#include "ammx2drotations.h"

//#include "findaway.h"
#include "amazed_by_the_pokey.h"
tStateManager *g_pGameStateManager = 0;
tState *g_pGameStates[GAME_STATE_COUNT] = {0};

int g_iChan1Played;
int g_iChan2Played;
int g_iChan3Played;
int g_iChan4Played;

/*static void INTERRUPT interruptHandlerMusic2()
{
  if ((g_pCustom->intreqr >> 5) & 1U)
  {
    g_pCustom->intreq = (1 << INTB_VERTB);
    g_pCustom->intreq = (1 << INTB_VERTB);
    //p61Music();
    
    g_pCustom->color[0] = 0x0F00;

    mt_music();
    g_pCustom->color[0] = 0x0888;
    g_iChan1Played = chan1played();
    g_iChan2Played = chan2played();
    g_iChan3Played = chan3played();
    g_iChan4Played = chan4played();
    g_pCustom->color[0] = 0x0F0F;
  }
  //chan3played();
}*/

void genericCreate(void) 
{
  // Here goes your startup code
    logWrite("Hello, Amiga!\n");
      keyCreate(); // We'll use keyboard
      g_pGameStateManager = stateManagerCreate();
      g_pGameStates[0] = stateCreate(ammx2drotationsGsCreate, ammx2drotationsGsLoop, ammx2drotationsGsDestroy, 0, 0, 0);
      statePush(g_pGameStateManager, g_pGameStates[0]);
      mt_init(amazed_by_the_pokey_data);
      //systemSetInt(INTB_VERTB, interruptHandlerMusic2, 0);

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

