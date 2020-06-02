
#include <ace/generic/main.h>
#include <ace/managers/key.h>

// Without it compiler will yell about undeclared gameGsCreate etc
#include "points.h"

void genericCreate(void) {
  // Here goes your startup code
    logWrite(Hello, Amiga!n);
      keyCreate(); // We'll use keyboard
        // Initialize gamestate
	  gamePushState(gameGsCreate, gameGsLoop, gameGsDestroy);
  }

  void genericProcess(void) {
    // Here goes code done each game frame
      keyProcess();
        gameProcess(); // Process current gamestate's loop
}

void genericDestroy(void) {
  // Here goes your cleanup code
    keyDestroy(); // We don't need it anymore
      logWrite(Goodbye, Amiga!n);
      }

