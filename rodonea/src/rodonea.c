#include "rodonea.h"

#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>

#include "../tests/huffman.h"

/*#include "../src/customtrigonometry.h"
#include "../tests/flower.h"*/

#include "../_res/thegrbth.h"
// togli per far funzionare #include "rod3X1.h"
//#include "rodo2X1.h"
//#include "../_res/rodstart.h"

#include "../_res/rodo1byte/rodo2X1_180_1byte_compressed.h"
#include "../_res/rodo1byte/rodo2X1_180_1byte_compressed_help.h"

#include "../_res/rodo1byte/rodo2X1_180_1byte_compressed_rot3.h"
#include "../_res/rodo1byte/rodo2X1_180_1byte_compressed_help_rot3.h"

#include "../_res/rodo1byte/rodo3X1_360_1byte_compressed_rot3.h"
#include "../_res/rodo1byte/rodo3X1_360_1byte_compressed_rot3_help.h"

#include "../_res/rodo1byte/rodo4X1_180_1byte_compressed.h"
#include "../_res/rodo1byte/rodo4X1_180_1byte_compressed_help.h"

#include "../_res/rodo1byte/rodo4X1_180_1byte_compressed_rot3.h"
#include "../_res/rodo1byte/rodo4X1_180_1byte_compressed_help_rot3.h"

#include "../_res/rodo1byte/rodo6X1_180_1byte_compressed.h"
#include "../_res/rodo1byte/rodo6X1_180_1byte_compressed_help.h"

#include "../_res/rodo1byte/rodo6X1_180_1byte_compressed_rot3.h"
#include "../_res/rodo1byte/rodo6X1_180_1byte_compressed_help_rot3.h"

#include "fonts.h"

//#include "../_res/rodo1byte/test.h"

#define DECOMPRESSION_CHUNK_SIZE 70

typedef struct _tRodDecompressorManager
{
  const size_t *pSize;
  const BYTE *pCompressedData;
  const BYTE *pCompressedDataHelper;
  BYTE *pDest;
  UWORD uwFinalAngle;
  const ULONG iDecompressedSize;

} tRodDecompressorManager;

// Global rodonea pointers
static BYTE *sg_pCurrRodonea;
static BYTE *sg_pCurrRodoneaHelper;

// RODONEA 64K
static BYTE sg_bRODONEA64K[64800];
static BYTE sg_bRODONEA64K_BACK[64800];
static BYTE sg_bRODONEA128K[129600];
static BYTE *sg_bHELPERPOINTER;
//static CHIP UWORD sg_bHELPERPOINTERINDEX = 0;

#define DECOMPRESSORMANAGERSIZE 7
tRodDecompressorManager tDecompressorManager[DECOMPRESSORMANAGERSIZE] = {
 

    {&rodo3X1_360_1byte_compressed_rot3_size, rodo3X1_360_1byte_compressed_rot3_data, rodo3X1_360_1byte_compressed_help_rot3_data, sg_bRODONEA128K, 360, 129600},
    {&rodo4X1_180_1byte_compressed_size, rodo4X1_180_1byte_compressed_data, rodo4X1_180_1byte_compressed_help_data, sg_bRODONEA64K, 180, 64800},
    {&rodo4X1_180_1byte_compressed_rot3_size, rodo4X1_180_1byte_compressed_rot3_data, rodo4X1_360_1byte_compressed_help_rot3_data, sg_bRODONEA64K_BACK, 180, 64800},
    {&rodo2X1_180_1byte_compressed_size, rodo2X1_180_1byte_compressed_data, rodo2X1_180_1byte_compressed_help_data, sg_bRODONEA64K, 180, 64800},
    {&rodo2X1_180_1byte_compressed_rot3_size, rodo2X1_180_1byte_compressed_rot3_data, rodo2X1_180_1byte_compressed_help_rot3_data, sg_bRODONEA64K_BACK, 180, 64800},
     {&rodo6X1_360_1byte_compressed_size, rodo6X1_360_1byte_compressed_data, rodo6X1_180_1byte_compressed_help_data, sg_bRODONEA64K, 180, 64800},
  {&rodo6X1_360_1byte_compressed_rot3_size, rodo6X1_360_1byte_compressed_rot3_data, rodo6X1_180_1byte_compressed_help_rot3_data, sg_bRODONEA64K_BACK, 180, 64800},

    // {&rodo2X1_180_1byte_compressed_size, rodo2X1_180_1byte_compressed_data, rodo2X1_180_1byte_compressed_help_data, sg_bRODONEA64K_BACK, 180, 64800},
    // {&rodo3X1_360_1byte_compressed_rot3_size,rodo3X1_360_1byte_compressed_rot3_data,rodo3X1_360_1byte_compressed_help_rot3_data,sg_bRODONEA128K,360,129600},
};
static BYTE unDecompressorManagerIndex = 0;

long mt_init(const unsigned char *);
//long mt_init();
void mt_music();
void mt_end();

void blitClear(tSimpleBufferManager *, UBYTE);
//void init_compression();
void init_compression4();
//void decode_stream3(UWORD uwFrames, HuffNode *tree, unsigned padding);
ULONG decode_stream4(WORD, BYTE *);
//long add(register long a __asm("d0"), register long b __asm("d1"));
void printCharToRight(char);
void scorri();

// All variables outside fns are global - can be accessed in any fn
// Static means here that given var is only for this file, hence 's_' prefix
// You can have many variables with same name in different files and they'll be
// independent as long as they're static
// * means pointer, hence 'p' prefix
static tView *s_pView;    // View containing all the viewports
static tVPort *s_pVpMain; // Viewport for playfield
static tSimpleBufferManager *s_pMainBuffer;

//static UBYTE vertexData[360*2*360];

//static __attribute__((chip)) UBYTE ubRodonea[259200];
static UBYTE *ubRodonea;

//static unsigned int iOutIndex = 0;

static unsigned padding;
static UWORD uwFinalAngle;

static char g_cPhrase[] = {"HELLOOO FOLKS, TIME FOR ANOTHER NOSENSE AMIGADEMO FROM OZZYBOSHI, THIS TIME THE SUBJECT IS A RODONEA, \
A CURVE PLOTTED IN POLAR COORDINATED STUDIED BY FRANCESCO LUDOVICO GRANDI, AN ITALIAN MATH GENIUS WHO LIVED NEAR ME SOME CENTURIES AGO. \
BECAUSE OF STOCK AMIGAS LIMITATIONS I CAN ONLY DISPLAY A FEW ROSES BUT MAYBE ONE DAY I WILL COME UP WITH A BETTER SOLUTION TO STORE AND DRAW MORE RODONEA DATA. \
AS ALWAYS HAPPENS IN MY DEMOS I WANT TO GREET SOMEONE, THIS TIME THE FIRST ONE IS Z3K FOR HIS AWESOME ONLINE PRESENTATION ABOUT DEMOSCENE IN ITALY, \
THE OTHER MENTIONS ARE FOR DR PROCTON, KAFFEINE AND FAROX WHO ALSO ATTENDED. \
NEGATIVE MENTIONS FOR SOME FELLOW COUNTRYMAN FROM AMIGAPAGE.IT THAT FLAMED THE MEETING TOPIC, SORRY GUYS I REALLY DONT UNDERSTAND YOUR BEHAVIOUR BUT DONT WORRY I WONT BOTHER YOU AGAIN WITH OUR ONLINE PARTIES. \
NEXT MEETING COULD BE AN INTERVIEW WITH A TRUE APOLLO MEMBER, I REALLY HOPE TO PERSUADE HIM TO GIVE US SOME OF HIS FREE TIME TO TALK ABOUT THE APOLLO TEAM AS SEEN FROM INSIDE. \
WELL... I THINK THAT'S ALL FOR NOW, THIS SCROLL TEXT WILL REPEAT ITSELF ....                                                                                        \n"};

//static UWORD s_uwBarY = 160;

//UBYTE *firstBitplane;

// START COMPRESSION VAR
/*FILE* fin ;
   FILE* fout ;*/
//tFile *pFile;

//static const unsigned char *ptrCompressedData = &rod3X1_compressed_data[0];
static UWORD s_uwCopRawOffs;

void gameGsCreate(void)
{

  // decompress first rodonea
  // it's a 64k one + helper

  /* g_HUFFMAN_COMPRESSED_SIZE = rodo2X1_180_1byte_compressed_rot3_size;
  g_HUFFMAN_COMPRESSED_DATA = (BYTE *)&rodo2X1_180_1byte_compressed_rot3_data[0];*/

  unDecompressorManagerIndex = 0;

  g_HUFFMAN_COMPRESSED_SIZE = *tDecompressorManager[unDecompressorManagerIndex].pSize;
  g_HUFFMAN_COMPRESSED_DATA = (BYTE *)tDecompressorManager[unDecompressorManagerIndex].pCompressedData;
  uwFinalAngle = tDecompressorManager[unDecompressorManagerIndex].uwFinalAngle;

  init_compression4();
  construct_huffman(freq);
  decode_stream4(0, tDecompressorManager[unDecompressorManagerIndex].pDest);
  //decode_stream4(32400, tDecompressorManager[unDecompressorManagerIndex].pDest + 32400);
  /*sg_bHELPERPOINTER = (BYTE *)&rodo2X1_180_1byte_compressed_help_rot3_data[0];
  sg_pCurrRodoneaHelper = rodo2X1_180_1byte_compressed_help_rot3_data;*/

  sg_bHELPERPOINTER = (BYTE *)tDecompressorManager[unDecompressorManagerIndex].pCompressedDataHelper;
  sg_pCurrRodoneaHelper = (BYTE *)tDecompressorManager[unDecompressorManagerIndex].pCompressedDataHelper;

  //uwFinalAngle = 180; // first animation is a for rodonea

  // set global rodo pointer
  //sg_pCurrRodonea = sg_bRODONEA64K;
  sg_pCurrRodonea = tDecompressorManager[unDecompressorManagerIndex].pDest;
#define RAWCOP
#ifdef RAWCOP
  ULONG ulRawSize = (simpleBufferGetRawCopperlistInstructionCount(1) +
                     22 * 2 + // 32 bars - each consists of WAIT + MOVE instruction
                     1 +      // Final WAIT
                     1        // Just to be sure
  );
#endif

  // Create a view - first arg is always zero, then it's option-value
  s_pView = viewCreate(0,
                       TAG_VIEW_GLOBAL_CLUT, 2, // Same Color LookUp Table for all viewports
#ifdef RAWCOP
                       TAG_VIEW_COPLIST_MODE, VIEW_COPLIST_MODE_RAW,
                       TAG_VIEW_COPLIST_RAW_COUNT, ulRawSize,
#else
                       TAG_VIEW_COPLIST_MODE, VIEW_COPLIST_MODE_BLOCK,
#endif
                       TAG_DONE); // Must always end with TAG_END or synonym: TAG_DONE

  // Now let's do the same for main playfield
  s_pVpMain = vPortCreate(0,
                          TAG_VPORT_VIEW, s_pView,
                          TAG_VPORT_BPP, 1, // 1 bits per pixel, 2 colors
                          // We won't specify height here - viewport will take remaining space.
                          TAG_END);

#ifdef RAWCOP
  s_uwCopRawOffs = 0;
#endif
  s_pMainBuffer = simpleBufferCreate(0,
                                     TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
                                     TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
                                     TAG_SIMPLEBUFFER_IS_DBLBUF, 1,
#ifdef RAWCOP
                                     TAG_SIMPLEBUFFER_COPLIST_OFFSET, s_uwCopRawOffs, // Important in rawcop mode
#endif
                                     TAG_END);

#ifdef RAWCOP
  s_uwCopRawOffs += simpleBufferGetRawCopperlistInstructionCount(1);
#endif

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray
  s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red

  // Init music
  mt_init(thegrbth_data);

  // We don't need anything from OS anymore
  systemUnuse();

//copProcessBlocks();
#ifdef RAWCOP
  // Copperlist for the gradient

  tCopBfr *pCopBfr = s_pView->pCopList->pBackBfr;
  tCopCmd *pBarCmds = &pCopBfr->pList[s_uwCopRawOffs];

  copSetWait(&pBarCmds[0].sWait, 0, 44);
  copSetMove(&pBarCmds[1].sMove, &g_pCustom->color[1], 0x0FF0);

  copSetWait(&pBarCmds[2].sWait, 0, 64);
  copSetMove(&pBarCmds[3].sMove, &g_pCustom->color[1], 0x0FFF);


  copSetWait(&pBarCmds[4].sWait, 0, 100);
  copSetMove(&pBarCmds[5].sMove, &g_pCustom->color[0], 0x0A47);

  copSetWait(&pBarCmds[6].sWait, 0, 110);
  copSetMove(&pBarCmds[7].sMove, &g_pCustom->color[0], 0x0837);

  copSetWait(&pBarCmds[8].sWait, 0, 120);
  copSetMove(&pBarCmds[9].sMove, &g_pCustom->color[0], 0x0637);

  copSetWait(&pBarCmds[10].sWait, 0, 130);
  copSetMove(&pBarCmds[11].sMove, &g_pCustom->color[0], 0x0536);

  copSetWait(&pBarCmds[12].sWait, 0, 140);
  copSetMove(&pBarCmds[13].sMove, &g_pCustom->color[0], 0x0325);

  copSetWait(&pBarCmds[14].sWait, 0, 150);
  copSetMove(&pBarCmds[15].sMove, &g_pCustom->color[0], 0x0225);

  copSetWait(&pBarCmds[16].sWait, 0, 160);
  copSetMove(&pBarCmds[17].sMove, &g_pCustom->color[0], 0x0024);

  copSetWait(&pBarCmds[18].sWait, 0, 170);
  copSetMove(&pBarCmds[19].sMove, &g_pCustom->color[0], 0x0023);

  copSetWait(&pBarCmds[20].sWait, 0, 180);
  copSetMove(&pBarCmds[21].sMove, &g_pCustom->color[0], 0x0012);

  copSetWait(&pBarCmds[22].sWait, 0, 190);
  copSetMove(&pBarCmds[23].sMove, &g_pCustom->color[0], 0x0111);

  // start inverse gradient

  copSetWait(&pBarCmds[24].sWait, 0, 200);
  copSetMove(&pBarCmds[25].sMove, &g_pCustom->color[0], 0x0111);

  copSetWait(&pBarCmds[26].sWait, 0, 210);
  copSetMove(&pBarCmds[27].sMove, &g_pCustom->color[0], 0x0012);

  copSetWait(&pBarCmds[28].sWait, 0, 220);
  copSetMove(&pBarCmds[29].sMove, &g_pCustom->color[0], 0x0023);

  copSetWait(&pBarCmds[30].sWait, 0, 230);
  copSetMove(&pBarCmds[31].sMove, &g_pCustom->color[0], 0x0024);

  copSetWait(&pBarCmds[32].sWait, 0, 240);
  copSetMove(&pBarCmds[33].sMove, &g_pCustom->color[0], 0x0225);

  copSetWait(&pBarCmds[34].sWait, 0, 250);
  copSetMove(&pBarCmds[35].sMove, &g_pCustom->color[0], 0x0325);

  copSetWait(&pBarCmds[36].sWait, 0xdf, 0xff);

  copSetWait(&pBarCmds[37].sWait, 0, (UBYTE)260);
  copSetMove(&pBarCmds[38].sMove, &g_pCustom->color[0], 0x0536);

  copSetWait(&pBarCmds[39].sWait, 0, (UBYTE)270);
  copSetMove(&pBarCmds[40].sMove, &g_pCustom->color[0], 0x0637);

  copSetWait(&pBarCmds[41].sWait, 0, (UBYTE)280);
  copSetMove(&pBarCmds[42].sMove, &g_pCustom->color[0], 0x0837);

  copSetWait(&pBarCmds[43].sWait, 0, (UBYTE)290);
  copSetMove(&pBarCmds[44].sMove, &g_pCustom->color[0], 0x0A47);

  CopyMemQuick(
      s_pView->pCopList->pBackBfr->pList,
      s_pView->pCopList->pFrontBfr->pList,
      s_pView->pCopList->pBackBfr->uwAllocSize);
#endif

  /*tCopBlock *s_pBlocks;
  s_pBlocks = copBlockCreate(s_pView->pCopList, 2, 0, 100);
  copMove(s_pView->pCopList, s_pBlocks,&g_pCustom->color[0], 0x0A47);
  copMove(s_pView->pCopList, s_pBlocks,&g_pCustom->color[1], 0x0FF0);  */

  copProcessBlocks();

  /*CopyMemQuick(
			s_pView->pCopList->pBackBfr->pList,
			s_pView->pCopList->pFrontBfr->pList,
			s_pView->pCopList->pBackBfr->uwAllocSize
		);*/

  /* logWrite("inizio debugg\n");
  copDumpBfr(s_pView->pCopList->pFrontBfr);
  copDumpBfr(s_pView->pCopList->pBackBfr);
  gameExit();*/

  // Load the view
  viewLoad(s_pView);

  /*UBYTE* firstBitPlane = (UBYTE *)((ULONG)s_pMainBuffer->pFront->Planes[1]);
  *(firstBitPlane++)=0xFF;
  *(firstBitPlane++)=0xFF;
  *(firstBitPlane++)=0xFF;*/

  //firstBitplane = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
}

void gameGsLoop(void)
{
  UWORD ubXData = 0;
  UBYTE ubYData = 0;
  static UBYTE ubDecompressionInitFlag = 0;

  static UBYTE nextStageReady = 0;
  static UWORD uwAngle = 0;

  /*logWrite("inizio debug\n");
  copDumpBfr(s_pView->pCopList->pFrontBfr);
  copDumpBfr(s_pView->pCopList->pBackBfr);
  gameExit();*/

  if (keyCheck(KEY_ESCAPE))
  {
    gameExit();
    return;
  }

  blitClear(s_pMainBuffer, 0);
  mt_music();

  // START DECOMPRESSION NEXT RODO
  if (nextStageReady == 0)
  {
    static ULONG ulDecompressedDataCounter = 0;
    static UBYTE ubHuffmanConstructed = 0;

    if (ubDecompressionInitFlag == 0)
    {
      /*g_HUFFMAN_COMPRESSED_SIZE = rodo2X1_180_1byte_compressed_size;
      g_HUFFMAN_COMPRESSED_DATA = (BYTE *)&rodo2X1_180_1byte_compressed_data[0];*/

      unDecompressorManagerIndex++;

      g_HUFFMAN_COMPRESSED_SIZE = *tDecompressorManager[unDecompressorManagerIndex].pSize;
      g_HUFFMAN_COMPRESSED_DATA = (BYTE *)tDecompressorManager[unDecompressorManagerIndex].pCompressedData;

      /* static UBYTE ubComp4Inited=0;
      if (ubComp4Inited==0)
      {
        g_pCustom->color[0] = 0x0F0F;
        init_compression4();
        ubComp4Inited=1;
        unDecompressorManagerIndex--;
      }
      else
      {*/
      init_compression4();

      decode_stream4(-1, tDecompressorManager[unDecompressorManagerIndex].pDest);
      //decode_stream4(-1, sg_bRODONEA64K_BACK);
      //ubDecompressionInitCounter = decode_stream4(1, sg_bRODONEA64K_BACK);;
      ubDecompressionInitFlag = 1;
      ulDecompressedDataCounter = 0;
      ubHuffmanConstructed = 0;
      //ubComp4Inited=0;
      //}
    }
    else
    {
      if (ubHuffmanConstructed == 0)
      {
        ubHuffmanConstructed = 1;
        construct_huffman(freq);
      }
      else
      {
        ulDecompressedDataCounter += decode_stream4(DECOMPRESSION_CHUNK_SIZE, tDecompressorManager[unDecompressorManagerIndex].pDest + ulDecompressedDataCounter);
        //logWrite ("decompression : %d/%d\n",ulDecompressedDataCounter,tDecompressorManager[unDecompressorManagerIndex].iDecompressedSize);
        //uwDecompressedDataCounter += decode_stream4(DECOMPRESSION_CHUNK_SIZE, sg_bRODONEA64K_BACK + uwDecompressedDataCounter);
        //uwDecompressedDataCounter += decode_stream4(32400, sg_bRODONEA64K_BACK + uwDecompressedDataCounter);
        // if (uwDecompressedDataCounter >= 64800)
        if (ulDecompressedDataCounter >= tDecompressorManager[unDecompressorManagerIndex].iDecompressedSize)
        {
          /*sg_pCurrRodonea = sg_bRODONEA64K_BACK;
        sg_bHELPERPOINTER = (BYTE *)&rodo2X1_180_1byte_compressed_help_data[0];
        sg_pCurrRodoneaHelper = rodo2X1_180_1byte_compressed_help_data;*/
          nextStageReady = 1;
          /*ubDecompressionInitFlag = 0;
        uwAngle = 0;*/
        }
      }
    }
  }
  else if (uwAngle == 0)
  {
    sg_pCurrRodonea = tDecompressorManager[unDecompressorManagerIndex].pDest;
    //sg_pCurrRodonea = sg_bRODONEA64K_BACK;
    /*sg_bHELPERPOINTER = (BYTE *)&rodo2X1_180_1byte_compressed_help_data[0];
    sg_pCurrRodoneaHelper = rodo2X1_180_1byte_compressed_help_data;*/

    sg_bHELPERPOINTER = (BYTE *)tDecompressorManager[unDecompressorManagerIndex].pCompressedDataHelper;
    sg_pCurrRodoneaHelper = (BYTE *)tDecompressorManager[unDecompressorManagerIndex].pCompressedDataHelper;
    uwFinalAngle = tDecompressorManager[unDecompressorManagerIndex].uwFinalAngle;

    ubDecompressionInitFlag = 0;
    nextStageReady = 0;
    //uwDecompressedDataCounter=0;

    if (unDecompressorManagerIndex + 1 >= DECOMPRESSORMANAGERSIZE)
      unDecompressorManagerIndex = -1;
  }
  //END DECOMPRESSION
  static UBYTE ubTxtCounter = 0;
  if (ubTxtCounter == 0)
  {
    static char *s_pPhrasePointer = &g_cPhrase[0];
    printCharToRight(*s_pPhrasePointer);
    s_pPhrasePointer++;
    if (*s_pPhrasePointer == '\n')
      s_pPhrasePointer = &g_cPhrase[0];
  }
  scorri();
  ubTxtCounter++;
  if (ubTxtCounter > 15)
    ubTxtCounter = 0;

  vPortWaitForEnd(s_pVpMain);
  mt_music();

  static UWORD a;
  //ULONG b = uwAngle * 720;
  //BYTE *pRodPointer = &sg_bRODONEA64K[0 * 360];
  /*uwAngle=0;*/
  BYTE *pRodPointer = sg_pCurrRodonea + uwAngle * 360;
  //logWrite("angolo : %d\n",uwAngle);
  blitWait();

  //g_pCustom->color[0] = 0x0F0F;

  //for (a = 0; a < 360 ; a++)
  a = 0;
  while (a < 360)
  {
    BYTE bCompressedX = (*pRodPointer) >> 4;
    bCompressedX = bCompressedX & 0x0F;
    BYTE bCompressedY = (*pRodPointer) & 0x0F;

    if ((bCompressedX >> 3) == 1)
    {
      if (bCompressedX == 0b00001000)
      {
        bCompressedX = *sg_bHELPERPOINTER;
        sg_bHELPERPOINTER++;
      }
      else
        bCompressedX = 0b11110000 | bCompressedX;
    }

    if ((bCompressedY >> 3) == 1)
    {

      if (bCompressedY == 0b00001000)
      {
        bCompressedY = *sg_bHELPERPOINTER;
        sg_bHELPERPOINTER++;
      }
      else
        bCompressedY = 0b11110000 | bCompressedY;
    }

    ubXData += bCompressedX;
    ubYData += bCompressedY;

    *((UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]) + (40 * (ubYData + 48) + ((ubXData + 60) >> 3))) |= 1UL << ((~((ubXData + 60) & 7)) & 7);

    //*(firstBitplane + (40 * (ubYData) + ((ubXData) >> 3))) |= 1UL << ((~((ubXData) & 7)) & 7);
    /*UBYTE *primo = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]) + (40 * (ubYData + 28) + ((ubXData + 60) >> 3));
      *primo |= 1UL << ((~((ubXData + 60) & 7)) & 7);*/

    /* UBYTE *primo = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]) + (40 * (ubYData ) + ((ubXData ) >> 3));
      *primo |= 1UL << ((~((ubXData ) & 7)) & 7);*/
    pRodPointer++;
    a++;
  }
  // g_pCustom->color[0] = 0x0000;

  uwAngle++;
  if (uwAngle >= uwFinalAngle)
  {
    uwAngle = 0;
    //sg_bHELPERPOINTERINDEX = 0;
    sg_bHELPERPOINTER = sg_pCurrRodoneaHelper;
  }

  vPortWaitForEnd(s_pVpMain);

  // blitClear(s_pMainBuffer, 0);
  //blitClear(s_pMainBuffer, 0);

  /*blitWait();
  g_pCustom->bltcon0 = 0x0100;
  g_pCustom->bltcon1 = 0x0000;
  g_pCustom->bltafwm = 0xFFFF;
  g_pCustom->bltalwm = 0xFFFF;
  g_pCustom->bltamod = 0x0000;
  g_pCustom->bltbmod = 0x0000;
  g_pCustom->bltcmod = 0x0000;
  g_pCustom->bltdmod = 0x0000;
  g_pCustom->bltdpt = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]);
  g_pCustom->bltsize = 0x4014;*/

  viewProcessManagers(s_pView);
  //copProcessBlocks();

  /*blitWait();
    waitblit();*/
  copSwapBuffers();

  //  wait1();
  ///}
}

void gameGsDestroy(void)
{

  mt_end();
  // Cleanup when leaving this gamestate
  systemUse();

  FreeMem(ubRodonea, 259200);
  FreeMem(tree, sizeof(HuffNode) * 512);

  //fclose(fout);
  //fclose(fin);

  // This will also destroy all associated viewports and viewport managers
  viewDestroy(s_pView);
}

void blitClear(tSimpleBufferManager *buffer, UBYTE nBitplane)
{
  blitWait();
  //waitblit();
  g_pCustom->bltcon0 = 0x0100;
  g_pCustom->bltcon1 = 0x0000;
  g_pCustom->bltafwm = 0xFFFF;
  g_pCustom->bltalwm = 0xFFFF;
  g_pCustom->bltamod = 0x0000;
  g_pCustom->bltbmod = 0x0000;
  g_pCustom->bltcmod = 0x0000;
  g_pCustom->bltdmod = 0x0000;
  g_pCustom->bltdpt = (UBYTE *)((ULONG)buffer->pBack->Planes[nBitplane] + 16 * 40);
  // g_pCustom->bltsize = 0x4014;
  g_pCustom->bltsize = 0x3C14;

  return;
}

void init_compression4()
{
  static int b0;
  static int b1, b2, b3;
  //static unsigned freq[256];

  if (tree != NULL)
    FreeMem(tree, sizeof(HuffNode) * 512);
  tree = (HuffNode *)AllocMem(sizeof(HuffNode) * 512, MEMF_CHIP | MEMF_CLEAR);

  for (int i = 0; i < 256; i++)
  {
    memcpy(&padding, g_HUFFMAN_COMPRESSED_DATA, 4);
    g_HUFFMAN_COMPRESSED_DATA += 4;
    b0 = (padding & 0x000000ff) << 24u;
    b1 = (padding & 0x0000ff00) << 8u;
    b2 = (padding & 0x00ff0000) >> 8u;
    b3 = (padding & 0xff000000) >> 24u;
    padding = b0 | b1 | b2 | b3;
    freq[i] = padding;
  }

  memcpy(&padding, g_HUFFMAN_COMPRESSED_DATA, 4);
  g_HUFFMAN_COMPRESSED_DATA += 4;
  b0 = (padding & 0x000000ff) << 24u;
  b1 = (padding & 0x0000ff00) << 8u;
  b2 = (padding & 0x00ff0000) >> 8u;
  b3 = (padding & 0xff000000) >> 24u;
  padding = b0 | b1 | b2 | b3;
  //construct_huffman(freq);
}

/* DECODE STREAM FUNCTION : Decodes a Huffman encoded data
** IMPORTANT!!! BEFORE CALLING THIS FUNCTION SET THE SOURCE ENCODED DATA SETTING GLOBAL VAR g_HUFFMAN_COMPRESSED_SIZE and g_HUFFMAN_COMPRESSED_DATA and CALL_INITCOMPRESSION4()
WORD Frames:
  if uwFrames < 0 - reset decompression static counters for a new decompression and exit
  if uwFrames == 0 - decode the whole input data
  dest = where to write
  returns 0 if no writes written
*/
ULONG decode_stream4(WORD uwFrames, BYTE *dest)
{
  static char buf = 0;
  static BYTE nbuf = 0;
  static BYTE bit = 0;
  static HuffNode *p;
  static int count = 0;
  ULONG uwCurFrames = 0;

  // Reset for a new compression
  if (uwFrames < 0)
  {
    count = 0;
    buf = 0;
    nbuf = 0;
    bit = 0;
    return 0;
  }

  if (count == 0)
  {
    count = g_HUFFMAN_COMPRESSED_SIZE - 1028;
  }

  while (count > 0 || nbuf > 0)
  {
    // Start from tree top
    p = tree + 510;
    while (p->left || p->right)
    {
      // Prepare next bit if needed
      if (nbuf == 0)
      {
        if (count <= 0)
          return 0;

        //buf = fgetc(fin);
        buf = (BYTE)*g_HUFFMAN_COMPRESSED_DATA;
        // logWrite("decode stream 4 reading %x\n",(BYTE)*g_HUFFMAN_COMPRESSED_DATA);
        g_HUFFMAN_COMPRESSED_DATA++;

        if (count == 1)
        {
          // Last bit
          nbuf = 8 - padding;
          if (nbuf == 0)
          {
            return 0;
          }
        }
        else
        {
          nbuf = 8;
        }
        count--;
      }
      // p has child
      bit = buf & 1;
      buf >>= 1;
      nbuf--;
      if (bit == 0)
        p = p->left;
      else
        p = p->right;
    }
    *dest = (UBYTE)p->data;
    dest++;

    if (uwFrames)
    {
      uwCurFrames++;
      if (uwCurFrames >= (ULONG)uwFrames)
        return uwCurFrames;
    }
  }
  return uwCurFrames;
}
#if 0
void decode_stream3(UWORD uwFrames, HuffNode *tree, unsigned padding)
{
  static int count = 0;
  UWORD uwCurFrames = 0;

  if (count == 0)
  {
    /*size_t startpos = ftell(fin); // should be 1028
      fseek(fin, 0L, SEEK_END);
      size_t endpos = ftell(fin); // last byte handling
      fseek(fin, startpos, SEEK_SET);
       count = endpos - startpos;*/
    count = rod3X1_compressed_size - 1028;
  }

  static char buf = 0;
  static BYTE nbuf = 0;
  static BYTE bit = 0;
  static HuffNode *p;
  while (count > 0 || nbuf > 0)
  {
    // Start from tree top
    p = tree + 510;
    while (p->left || p->right)
    {
      // Prepare next bit if needed
      if (nbuf == 0)
      {
        if (count <= 0)
          return;

        //buf = fgetc(fin);
        buf = (BYTE)*ptrCompressedData;
        /* logWrite("alessioo %hhx (%hhx) %hhx\n",buf,*ptrCompressedData,ptrCompressedData[1028]);
                if (buf!=(BYTE)*ptrCompressedData) logWrite("diverso incredibile");
                else logWrite("uguale");*/
        ptrCompressedData++;

        if (count == 1)
        {
          // Last bit
          nbuf = 8 - padding;
          if (nbuf == 0)
          {
            return;
          }
        }
        else
        {
          nbuf = 8;
        }
        count--;
      }
      // p has child
      bit = buf & 1;
      buf >>= 1;
      nbuf--;
      if (bit == 0)
        p = p->left;
      else
        p = p->right;
    }
    ubRodonea[iOutIndex] = (UBYTE)p->data;
    //logWrite("alessio2 iterazione %d - %x\n",iOutIndex,ubRodonea[iOutIndex]);

    iOutIndex++;
    if (uwCurFrames > uwFrames)
      return;
    uwCurFrames++;
    //fputc(p->data, fout);
    //printf("####%x#####\n",p->data);
  }
}
#endif

void construct_huffman(unsigned *freq_in)
{
  int count = 256;
  unsigned freq[256];

  // Initialize data
  for (int i = 0; i < 256; i++)
  {
    freq[i] = freq_in[i];
    tree[i].data = i;
    tree[i].left = NULL;
    tree[i].right = NULL;
    node[i] = &tree[i];
  }

  // Sort by frequency, decreasing order
  /* WARNING: Although this Quick Sort is an unstable sort,
     * it should at least give the same result for the same input frequency table,
     * therefore I'm leaving this code here
     */
  {
    unsigned top = 1;
    lower[0] = 0, upper[0] = 256;
    while (top > 0)
    {
      top--;
      int left = lower[top], right = upper[top];
      int i = left, j = right - 1, flag = 0;
      if (i >= j) // Nothing to sort
        continue;
      while (i < j)
      {
        if (freq[i] < freq[j])
        {
          unsigned t = freq[i];
          freq[i] = freq[j];
          freq[j] = t;
          HuffNode *p = node[i];
          node[i] = node[j];
          node[j] = p;
          flag = !flag;
        }
        flag ? i++ : j--;
      }
      lower[top] = left, upper[top] = i;
      lower[top + 1] = i + 1, upper[top + 1] = right;
      top += 2;
    }
  }

  // Construct tree
  while (count > 1)
  {
    int pos = 512 - count;
    HuffNode *parent = &tree[pos];
    // Select lowest 2 by freq
    int i = count - 2, j = count - 1;
    // Create tree, lower freq left
    parent->left = node[j];
    parent->right = node[i];
    node[j]->parent = node[i]->parent = parent;
    node[i] = parent;
    freq[i] += freq[j];
    // Insert
    for (; i > 0 && freq[i] > freq[i - 1]; i--)
    {
      unsigned t = freq[i];
      freq[i] = freq[i - 1];
      freq[i - 1] = t;
      HuffNode *p = node[i];
      node[i] = node[i - 1];
      node[i - 1] = p;
    }
    count--;
  }
  // Now HEAD = node[0] = tree[511]
  node[0]->parent = NULL;
}
#if 0 
void init_compression()
{
  static int b0;
  static int b1, b2, b3;
  static unsigned freq[256];

  if (tree != NULL)
    FreeMem(ubRodonea, sizeof(HuffNode) * 512);
  tree = (HuffNode *)AllocMem(sizeof(HuffNode) * 512, MEMF_CHIP | MEMF_CLEAR);
  //tree = (HuffNode *)AllocMem(sizeof(HuffNode) * 512, MEMF_CHIP | MEMF_CLEAR);

  for (int i = 0; i < 256; i++)
  {
    memcpy(&padding, ptrCompressedData, 4);
    ptrCompressedData += 4;
    b0 = (padding & 0x000000ff) << 24u;
    b1 = (padding & 0x0000ff00) << 8u;
    b2 = (padding & 0x00ff0000) >> 8u;
    b3 = (padding & 0xff000000) >> 24u;
    padding = b0 | b1 | b2 | b3;
    freq[i] = padding;
  }

  memcpy(&padding, ptrCompressedData, 4);
  ptrCompressedData += 4;
  b0 = (padding & 0x000000ff) << 24u;
  b1 = (padding & 0x0000ff00) << 8u;
  b2 = (padding & 0x00ff0000) >> 8u;
  b3 = (padding & 0xff000000) >> 24u;
  padding = b0 | b1 | b2 | b3;
  construct_huffman(freq);
}
#endif

void printCharToRight(char carToPrint)
{
  int carToPrintOffset = ((int)carToPrint - 0x20) * 40;
  UBYTE *firstBitPlane = (UBYTE *)((ULONG)s_pMainBuffer->pFront->Planes[0]);

  // vogliamo stampare all'estrema destra quindi aggiungiamo 38
  firstBitPlane += 38;

  for (int i = 0; i < 20; i++)
  {
    *firstBitPlane = (UBYTE)fonts_data[carToPrintOffset];
    firstBitPlane++;
    *firstBitPlane = (UBYTE)fonts_data[carToPrintOffset + 1];
    firstBitPlane++;
    carToPrintOffset += 2;
    firstBitPlane += 38;
  }
}

void scorri()
{

  blitWait();
  //waitblit();
  g_pCustom->bltcon0 = 0x19f0;
  g_pCustom->bltcon1 = 0x0002;

  g_pCustom->bltafwm = 0xffff;
  g_pCustom->bltalwm = 0x7fff;

  g_pCustom->bltamod = 0x0000;
  g_pCustom->bltbmod = 0x0000;
  g_pCustom->bltcmod = 0x0000;
  g_pCustom->bltdmod = 0x0000;

  UBYTE *firstBitPlane = (UBYTE *)((ULONG)s_pMainBuffer->pFront->Planes[0]) + ((20 * 20 - 1) * 2);
  UBYTE *firstBitPlane2 = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]) + ((20 * 20 - 1) * 2);

  g_pCustom->bltdpt = firstBitPlane2;
  g_pCustom->bltapt = firstBitPlane;

  g_pCustom->bltsize = 0x0514;
}
