#include <ace/managers/viewport/simplebuffer.h> 
#include <ace/managers/blit.h>

typedef struct _tAceFIgure
{
    UWORD uwWidth;
    UWORD uwHeight;
    UWORD uwBytes;
    UBYTE* pData;
    UBYTE ubPrimitiveId;
}tAceFIgure;

void DrawlineOr(UBYTE *, int, int, int, int);
void InitLine();

#define ACEDRAW_RECTANGLE  0





UWORD g_uwAceDrawTranslateX = 0;
UWORD g_uwAceDrawTranslateY = 0;

enum ACEDRAW_RECTMODETYPE {
    ACEDRAWLINECENTER = 1
};

enum ACEDRAW_RECTMODETYPE g_ubAceDrawRectModeType;

inline struct _tAceFIgure* AceFigureRectangle(UWORD uwWidth,UWORD uwHeight)
{
    struct _tAceFIgure* pResult = memAllocChip(sizeof(struct _tAceFIgure));
    pResult->uwWidth = uwWidth;
    pResult->uwHeight = uwHeight;
    pResult->uwBytes = uwWidth>>3;

    pResult->pData = memAllocChip(pResult->uwBytes*uwHeight);
    memset(pResult->pData,0xFF,pResult->uwBytes*uwHeight);

    //acedrawPlotPoint(pResult,0,0);
    
    pResult->ubPrimitiveId = ACEDRAW_RECTANGLE;
    return pResult;
}

inline void AceFigureFree(struct _tAceFIgure* pResult)
{
    memFree(pResult->pData,pResult->uwBytes*pResult->uwHeight);
    memFree(pResult,sizeof(struct _tAceFIgure));
}

inline void acedrawRectangle( struct _tAceFIgure* pRectangle,tBitMap* pBitmap,UBYTE ubBitplane, WORD uwXO,WORD uwYO,UWORD uwHeight)
{
    UBYTE* p_Bitplane = pBitmap->Planes[ubBitplane];
    UWORD BytesPerRow = pBitmap->BytesPerRow;
    UWORD uwX=uwXO+g_uwAceDrawTranslateX;
    UWORD uwY=uwYO+g_uwAceDrawTranslateY;

    if (uwHeight==0||uwHeight>pRectangle->uwHeight) return ;

    // If we are requesting a smaller height and we want to draw to the center of the rectangle we add hald of the difference
    if (g_ubAceDrawRectModeType==ACEDRAWLINECENTER)
    {
        WORD wHeightDiff = pRectangle->uwHeight-uwHeight;
        if (wHeightDiff>0) uwY+=(wHeightDiff>>1);
    }


    UWORD bltSize = uwHeight<<6;
    bltSize|=0x00000001;

    blitWait();
    g_pCustom->bltcon0 = 0x09F0;
    g_pCustom->bltcon1 = 0x0000;
    g_pCustom->bltafwm = 0xFFFF;
    g_pCustom->bltalwm = 0xFFFF;
    g_pCustom->bltamod = 0x0000;
    g_pCustom->bltbmod = 0x0000;
    g_pCustom->bltcmod = 0x0000;
    g_pCustom->bltdmod = BytesPerRow-pRectangle->uwBytes;
    g_pCustom->bltapt = pRectangle->pData;
    g_pCustom->bltdpt = p_Bitplane+(BytesPerRow*uwY)+(uwX>>3);
    g_pCustom->bltsize = bltSize;
}

inline void acedrawPlotPoint(struct _tAceFIgure* pShape,UWORD uwX,UWORD uwY)
{
    UWORD uwTmp=uwX>>3;
    UBYTE* pPtr = pShape->pData+uwY*pShape->uwBytes+uwTmp;
    UBYTE ubRemainder=(UBYTE)uwX&7;
    uwTmp=~ubRemainder;
    ubRemainder=uwTmp&7;
    *pPtr|=1UL<<ubRemainder;
}

inline void acedrawTranslate(UWORD uwX,UWORD uwY)
{
    g_uwAceDrawTranslateX = uwX;
    g_uwAceDrawTranslateY = uwY;
}

inline void acedrawRectMode(enum ACEDRAW_RECTMODETYPE ubMode)
{
    g_ubAceDrawRectModeType = ubMode;
}

inline void acedrawRect( tSimpleBufferManager *s_pMainBuffer,WORD uwXO,WORD uwYO,WORD uwWidth,WORD uwHeight)
{


    UWORD uwX=uwXO+g_uwAceDrawTranslateX;
    UWORD uwY=uwYO+g_uwAceDrawTranslateY;

    if (g_ubAceDrawRectModeType==ACEDRAWLINECENTER)
    {
        uwX-= (uwWidth>>1);
        uwY-= (uwHeight>>1);
    }

    

    blitLine(s_pMainBuffer->pBack,uwX,uwY,uwX+uwWidth,uwY,1,0xffff,0);
    blitLine(s_pMainBuffer->pBack,uwX,uwY,uwX,uwY+uwHeight,1,0xffff,0);
    blitLine(s_pMainBuffer->pBack,uwX,uwY+uwHeight,uwX+uwWidth,uwY+uwHeight,1,0xffff,0);

    blitLine(s_pMainBuffer->pBack,uwX+uwWidth,uwY,uwX+uwWidth,uwY+uwHeight,1,0xffff,0);

}


