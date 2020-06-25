#include "rodonea.h"
#include "../tests/huffman.h"

#include <ace/managers/key.h>                   // Keyboard processing
#include <ace/managers/game.h>                  // For using gameExit
#include <ace/managers/system.h>                // For systemUnuse and systemUse
#include <ace/managers/viewport/simplebuffer.h> // Simple buffer
#include <ace/managers/blit.h>

/*#include "../src/customtrigonometry.h"
#include "../tests/flower.h"*/

#include "../_res/thegrbth.h"
#include "rod3X1.h"
//#include "rodo2X1.h"
#include "../_res/rodstart.h"

long mt_init(const unsigned char *);
//long mt_init();
void mt_music();
void mt_end();

void blitClear(tSimpleBufferManager *, UBYTE);
void init_compression();
void decode_stream3(UWORD uwFrames, HuffNode *tree, unsigned padding);

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

static unsigned int iOutIndex = 0;

static unsigned padding;
static UWORD uwFinalAngle;


// START COMPRESSION VAR
/*FILE* fin ;
   FILE* fout ;*/
     tFile *pFile;



static const unsigned char *ptrCompressedData = &rod3X1_compressed_data[0];

void gameGsCreate(void)
{
  init_compression();
  ubRodonea = (UBYTE *)AllocMem(259200, MEMF_CHIP | MEMF_CLEAR);

// Start compression data
//fin = fopen("out.Z", "rb");
//fout = fopen("out", "wb");
#if 0
  for (int i = 0; i < 256; i++) {
        memcpy(&padding,ptrCompressedData,4);
        ptrCompressedData+=4;
        b0 = (padding & 0x000000ff) << 24u;
         b1 = (padding & 0x0000ff00) << 8u;
         b2 = (padding & 0x00ff0000) >> 8u;
         b3 = (padding & 0xff000000) >> 24u;
         padding = b0 | b1 | b2 | b3;
        freq[i] = padding;
    }

    memcpy(&padding,ptrCompressedData,4);
        ptrCompressedData+=4;
    b0 = (padding & 0x000000ff) << 24u;
   b1 = (padding & 0x0000ff00) << 8u;
   b2 = (padding & 0x00ff0000) >> 8u;
   b3 = (padding & 0xff000000) >> 24u;
   padding = b0 | b1 | b2 | b3;
   construct_huffman(freq);
   decode_stream3(30, tree, padding);
   logWrite("alessio fine chunk\n");
   gameExit();
   //if (ubRodonea[0]!=0x2d) gameExit();
#endif

/*pFile = fileOpen("rodo2X1.bin", "r");
if (!pFile)
{
    gameExit();
    return ;
}*/
  //fileClose(pFile);*/

  // Create a view - first arg is always zero, then it's option-value
  s_pView = viewCreate(0,
                       TAG_VIEW_GLOBAL_CLUT, 1, // Same Color LookUp Table for all viewports
                       TAG_END);                // Must always end with TAG_END or synonym: TAG_DONE

  // Now let's do the same for main playfield
  s_pVpMain = vPortCreate(0,
                          TAG_VPORT_VIEW, s_pView,
                          TAG_VPORT_BPP, 1, // 2 bits per pixel, 4 colors
                          // We won't specify height here - viewport will take remaining space.
                          TAG_END);
  s_pMainBuffer = simpleBufferCreate(0,
                                     TAG_SIMPLEBUFFER_VPORT, s_pVpMain, // Required: parent viewport
                                     TAG_SIMPLEBUFFER_BITMAP_FLAGS, BMF_CLEAR,
                                     TAG_SIMPLEBUFFER_IS_DBLBUF, 1,
                                     TAG_END);

  // Since we've set up global CLUT, palette will be loaded from first viewport
  // Colors are 0x0RGB, each channel accepts values from 0 to 15 (0 to F).
  s_pVpMain->pPalette[0] = 0x0000; // First color is also border color
  s_pVpMain->pPalette[1] = 0x0888; // Gray
  s_pVpMain->pPalette[2] = 0x0800; // Red - not max, a bit dark
  s_pVpMain->pPalette[3] = 0x0008; // Blue - same brightness as red

  /*   systemSetDma(DMAB_SPRITE, 0);
       systemSetDma(DMAB_COPPER, 0);
        systemSetDma(DMAB_BLITHOG, 0);*/

  /*fix16_sinlist_init();
  fix16_coslist_init();
  createFlower(3, 1, 100,150);
  for (int i=0;i<360;i++)
    rotatePoints(i);*/
  // Init music
  mt_init(thegrbth_data);
  //mt_init(mt_greathbath);
  //mt_init();

  // We don't need anything from OS anymore
  systemUnuse();

  uwFinalAngle=180; // first animation is a par rodonea

  // Load the view
  viewLoad(s_pView);

  /*s_ubDiwStrt +=10;
  g_pCustom->diwstrt =(s_ubDiwStrt<<8)|0x0081;*/
}

void gameGsLoop(void)
{
  UBYTE ubXData = 0;
  UBYTE ubYData = 0;

  static UBYTE nextStageReady = 0;
  static UWORD uwAngle = 0;
  g_pCustom->color[0] = 0x0FF0;
  //fileRead(pFile,ubRodonea, 1);
  // This will loop forever until you "pop" or change gamestate
  // or close the game
  if (keyCheck(KEY_ESCAPE))
  {
    //gameClose();
    gameExit();
  }
  else
  {
    /*static int* ptr = FLOWERS[0].vertexData;
    static int* ptr2 = FLOWERS[0].vertexData+1;*/
    // g_pCustom->color[0] = 0x0F00;
    // g_pCustom->color[1] = 0x00FF;
    blitClear(s_pMainBuffer, 0);
    mt_music();

    g_pCustom->color[0] = 0x000F;
    if (nextStageReady == 0 && iOutIndex < 259200)
    {
      decode_stream3(60, tree, padding);
      g_pCustom->color[0] = 0x0FF0;
      //gameExit();
      /*static int lol = 0;
         if (!lol && ubRodonea[0]!=0x2d) gameExit();
         lol++;*/
    }
    else
    {
      nextStageReady = 1;
      //uwAngle = 0;
      g_pCustom->color[0] = 0x00FF;
      uwFinalAngle=360;
    }

    UWORD a;
    ULONG b = uwAngle * 720;
    blitWait();
    for (a = 0; a < 360; a++, b += 2)
    {
      /*UBYTE* primo = (UBYTE*)((ULONG)s_pMainBuffer->pBack->Planes[0])+(40*FLOWERS[0].vertexData[b + 1]+(FLOWERS[0].vertexData[b]>>3));
       *primo|=1UL<<((~(FLOWERS[0].vertexData[b]&7))&7);*/
      /* UBYTE* primo = (UBYTE*)((ULONG)s_pMainBuffer->pBack->Planes[0])+(40*vertexDataRotated[uwAngle].y[a]+(vertexDataRotated[uwAngle].x[a]>>3));
       *primo|=1UL<<((~(vertexDataRotated[uwAngle].x[a]&7))&7);*/

      if (!nextStageReady)
      {
        /*UBYTE* primo = (UBYTE*)((ULONG)s_pMainBuffer->pBack->Planes[0])+(40*(vertexData[b+1]+28)+((vertexData[b]+60)>>3));
        *primo|=1UL<<((~((vertexData[b]+60)&7))&7);*/

        /*UBYTE *primo = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]) + (40 * (rodo2X1_data[b + 1] + 28) + ((rodo2X1_data[b] + 60) >> 3));
        *primo |= 1UL << ((~((rodo2X1_data[b] + 60) & 7)) & 7);*/
        ubXData += rodstart_data[b];
        ubYData += rodstart_data[b + 1];


        UBYTE *primo = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]) + (40 * (ubYData + 28) + ((ubXData + 60) >> 3));
        *primo |= 1UL << ((~((ubXData + 60) & 7)) & 7);
      }
      else
      {
        ubXData += ubRodonea[b];
        ubYData += ubRodonea[b + 1];
        UBYTE *primo = (UBYTE *)((ULONG)s_pMainBuffer->pBack->Planes[0]) + (40 * (ubYData + 28) + ((ubXData + 60) >> 3));
        *primo |= 1UL << ((~((ubXData + 60) & 7)) & 7);
      }
    }
    uwAngle++;
    if (uwAngle >= uwFinalAngle)
      uwAngle = 0;
    g_pCustom->color[0] = 0x0000;
    vPortWaitForEnd(s_pVpMain);

    viewProcessManagers(s_pView);

    copSwapBuffers();
    //  wait1();
  }
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
  g_pCustom->bltdpt = (UBYTE *)((ULONG)buffer->pBack->Planes[nBitplane]);
  g_pCustom->bltsize = 0x4014;

  return;
}

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

void init_compression()
{
  static int b0;
  static int b1, b2, b3;
  static unsigned freq[256];


  tree = (HuffNode *)AllocMem(sizeof(HuffNode) * 512, MEMF_CHIP | MEMF_CLEAR);

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