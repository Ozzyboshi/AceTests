
#include <ace/managers/key.h> // Keyboard processing
#include <ace/managers/game.h> // For using gameClose
#include <ace/managers/system.h> // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>

#include "pos0.01.h"

main()
{

    UWORD* ptr = (UWORD*)pos0_01_data;
    for (UWORD i = 0;i<40;i++)
    {

    //  blitLine(s_pMainBuffer->pBack,100+i+j ,100,200+i+j,200,1, 0xFFFF,0);
    printf("%04x %04x \n",*ptr,*(ptr+1));
           ptr=ptr+2;
           getchar();
           // blitLine2(s_pMainBuffer->pBack,100 ,100,200,200,1, 0xFFFF);
    }
}