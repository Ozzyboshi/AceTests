int xStep = 16;
int yStep = 16;


Blob b;
Blob[] blobs = new Blob[3];
byte[] data = {};
int dataindex = 0;

IntList colors;

int MAXFRAMES = 300;

void setup()
{
    //fullScreen();

  size(320,256);
  //size(640,360);
  for (int i=0;i<blobs.length;i++)
    blobs[i] = new Blob(width/3,height/3);
  colorMode(HSB);
  //noLoop();
  data = new byte[
    20*16*2*MAXFRAMES // x resolution * y resolution * bytes needed for each amiga color (a word) * NUMBER OF FRAMES
    ];
    
    colors = new IntList();

}
int framecounter=0;
void draw()
{
  if (framecounter>=MAXFRAMES)
  {
    saveBytes("colors.bin", data);
    exit();
  }
  framecounter++;
  background(51);
  loadPixels();
  for (int x = 0; x < width; x++)
  {
    if ((x%xStep)!=0)
    {
      int cont=0;
      for (int y = 0; y < height; y++)
      {
        int index = x + y * width;
        pixels[index] = colors.get(cont);
        if ((y%yStep)==0 && y>0) cont++;
      }
      continue;
    }
    color lastColor=color(0,0,0);
    colors.clear();
    
     for (int y = 0; y < height; y++)
     {
       int index = x + y * width;
       //if ((y%yStep)==0 || ((x%xStep)==0))
       if ((y%yStep)==0)
       {  
         float sum=0;
         for (Blob b : blobs)
         {
           float d = dist (x,y,b.pos.x,b.pos.y)*20/20;
           sum+= b.r/d * 100;
         }
         color newColor = color(sum ,255,255);
         pixels[index] = newColor;
         lastColor = newColor;
         
         colors.append(newColor);
         // byte r = unsignedByte((byte)red(newColor));
         int r = (int)red(newColor);
         println("imposto /"+red(newColor)+"/"+green(newColor)+"/"+blue(newColor)+" per x"+x+ "and y "+y);
         println("r vale "+r);
         
         int littleEndianRed = (int)red(newColor);
         int endianMSNibble = (littleEndianRed&0xFF)>>4;
         byte rbyte=(byte)endianMSNibble;
         
         int littleEndianGreen = (int)green(newColor);
         endianMSNibble = (littleEndianGreen&0xFF)>>4;
         byte gbyte=(byte)endianMSNibble;
         
         int littleEndianBlue = (int)blue(newColor);
         endianMSNibble = (littleEndianBlue&0xFF)>>4;
         byte bbyte=(byte)endianMSNibble;
         
         byte firstByte = rbyte;
         int secondByte = gbyte<<4|bbyte;
         
         
        
         
         if (dataindex<20*16*2*MAXFRAMES)
         {
         data[dataindex++]=rbyte; //<>//
         data[dataindex++]=(byte)secondByte;
         //data[dataindex++]=(byte)blue(newColor);
         }
        }
    
        else
        {
          //println("entro"+lastColor);
            pixels[index] = lastColor;
        }
      }
  }
  updatePixels();
  for (int i=0;i<blobs.length;i++)
  {
      blobs[i].update();
     // blobs[i].show();
   }
   
}

byte unsignedByte( int val ) { return (byte)( val > 127 ? val - 256 : val ); }
