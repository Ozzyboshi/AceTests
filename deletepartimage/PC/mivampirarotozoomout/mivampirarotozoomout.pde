
float a = 1.0;
float s = 0.0;
  PImage img;
  float c = 0;

void setup() {
  size(64, 64);
  noStroke();
  rectMode(CENTER);
  frameRate(1);
  
  img = loadImage("closeup.bmp");
  
}
int frameno=0;
void draw() {
  
  background(102);
  
    imageMode(CENTER);

  //a = a + 0.04;
  //a+=0.1;
  s = cos(a)*2;
  //pushMatrix();

  translate(32, height/2);

  scale(a); 
  rotate(c);
      image(img, 0, 0);

///popMatrix();  
  //rotate(c);
    a=a-0.04;
    c+=0.25;
    
    if (a<=0) exit();
        frameno++;

    save("lol"+frameno+".bmp");

  /*fill(51);
  rect(0, 0, 50, 50); 
  
  translate(75, 0);
  fill(255);
  scale(s);
  rect(0, 0, 50, 50);   */    
}
