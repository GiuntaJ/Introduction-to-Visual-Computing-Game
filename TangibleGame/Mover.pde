class Mover {
  
  final int BALL_COLOR;
  
  final int BALL_RADIUS;
  final float ELASTICITY;
  final float FRICTION; 
  final float GRAVITY;

  PVector vLocation;
  PVector vVelocity;
  PVector vGravity;
  PVector vMoverVelocity;
  PVector vCollision;

  Mover(float x, float y, float z, int BALL_COLOR, int BALL_RADIUS,
        float ELASTICITY, float FRICTION, float GRAVITY) {
    
    this.BALL_COLOR = BALL_COLOR;
    this.BALL_RADIUS = BALL_RADIUS;
    this.ELASTICITY = ELASTICITY;
    this.FRICTION = FRICTION;
    this.GRAVITY = GRAVITY;
    
    vLocation = new PVector(x, -(BALL_RADIUS+y/2f), z); 
    vVelocity = new PVector(0, 0, 0);
    vGravity = new PVector(0, 0, 0);
  }

  void update(float rotX, float rotZ) { 
    vGravity.x = sin(rotZ) * GRAVITY; 
    vGravity.z = sin(rotX) * GRAVITY;

    vVelocity.add(vGravity).add(vVelocity.copy().mult(-1).mult(FRICTION));
    vLocation.add(vVelocity);
  }

  void display(PGraphics surface) {
    surface.fill(BALL_COLOR);
    surface.translate(vLocation.x, vLocation.y, -vLocation.z);
    surface.sphere(BALL_RADIUS);
  }
  
  PVector getPosition2d() {
    return new PVector(vLocation.x, -vLocation.z);
  }

  float checkEdges(int sizePlate) {
    boolean hit = false;

    float xBound = sizePlate/2;
    float zBound = sizePlate/2;

    if (vLocation.x > xBound-BALL_RADIUS) {
      hit = true;
      vLocation.x = xBound-BALL_RADIUS;
      vVelocity.x *= -1;
    } else if (vLocation.x < -xBound+BALL_RADIUS) {
      hit = true;
      vLocation.x = -xBound+BALL_RADIUS;
      vVelocity.x *= -1;
    }

    if (vLocation.z > zBound-BALL_RADIUS) {
      hit = true;
      vLocation.z = zBound-BALL_RADIUS;
      vVelocity.z *= -1;
    } else if (vLocation.z < -zBound+BALL_RADIUS) {
      hit = true;
      vLocation.z = -zBound+BALL_RADIUS;
      vVelocity.z *= -1;
    }
    
    if(hit){
      return vVelocity.mag();
    }else{
      return 0;
    }
  }

  float checkCollisions(ArrayList<PVector> cylindersPositions) {
    float score = 0;
    
    for (PVector cylinderPosition : cylindersPositions) {
      if (this.getPosition2d().dist(cylinderPosition) < BALL_RADIUS+cylinder.CYLINDER_RADIUS) {
        score += vVelocity.mag();
        
        vLocation = vLocation.sub(vVelocity);
        vMoverVelocity = new PVector(vVelocity.x, -vVelocity.z);
        vCollision = this.getPosition2d().copy().sub(cylinderPosition).normalize();
        vMoverVelocity = vMoverVelocity.sub(vCollision.mult(2*(vMoverVelocity.dot(vCollision))));
        vVelocity.x = vMoverVelocity.x*ELASTICITY;
        vVelocity.z = vMoverVelocity.y*ELASTICITY;
      }
    }
    
    return score;
  }
}