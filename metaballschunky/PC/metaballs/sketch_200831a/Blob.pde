class Blob {
PVector pos;
float r;
PVector vel;
  Blob (float x,float y)
  {
    this.pos = new PVector (x,y);
    r = 40;
    this.vel = PVector.random2D();
    this.vel.mult(random(1,2));
  }
  
  void show()
  {
    noFill();
    stroke(111);
    ellipse(pos.x,pos.y,r*2,r*2);
  }
  
  void update()
  {
    pos.add(vel);
    if (pos.x > width || pos.x<0) this.vel.x*=-1; 
    if (pos.y > height || pos.y<0) this.vel.y*=-1; 
  }
}
