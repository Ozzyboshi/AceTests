
#include <ace/generic/main.h>
#include <ace/managers/key.h>
#include <ace/managers/state.h>

#include "main.h"
#include "flashimage.h"

tStateManager *g_pGameStateManager = 0;
tState *g_pGameStates[GAME_STATE_COUNT] = {0};

void genericCreate(void) 
{
  // Here goes your startup code
    //logWrite("Hello, Amiga!\n");
      keyCreate(); // We'll use keyboard
      g_pGameStateManager = stateManagerCreate();
      g_pGameStates[0] = stateCreate(flashimageGsCreate, flashimageGsLoop, flashimageGsDestroy, 0, 0, 0);
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
  //logWrite("Goodbye, Amiga!\n");
}

