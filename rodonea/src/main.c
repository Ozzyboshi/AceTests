
#include <ace/generic/main.h>
#include <ace/managers/key.h>
#include <ace/managers/state.h>


// Without it compiler will yell about undeclared gameGsCreate etc
#include "rodonea.h"

tStateManager *g_pGameStateManager = 0;
tState *g_pGameState = 0;

void genericCreate(void)
{
  // Here goes your startup code
  logWrite("Hello, Amiga!\n");
  keyCreate(); // We'll use keyboard
               // Initialize gamestate
  g_pGameStateManager = stateManagerCreate();
  g_pGameState = stateCreate(gameGsCreate, gameGsLoop, gameGsDestroy, 0, 0, 0);
  statePush(g_pGameStateManager, g_pGameState);
  //gamePushState(gameGsCreate, gameGsLoop, gameGsDestroy);
}

void genericProcess(void)
{
  // Here goes code done each game frame
  keyProcess();
  //gameProcess(); // Process current gamestate's loop
  stateProcess(g_pGameStateManager);
}

void genericDestroy(void)
{
  stateManagerDestroy(g_pGameStateManager);
  stateDestroy(g_pGameState);

  // Here goes your cleanup code
  keyDestroy(); // We don't need it anymore
  logWrite("Goodbye, Amiga!\n");
}
