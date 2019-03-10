class Cylinder {
  
  final int CYLINDER_COLOR;
  final int CYLINDER_COLOR_TO_PLACE;
  
  final float CYLINDER_RADIUS;
  final float CYLINDER_HEIGHT;
  final int CYLINDER_RESOLUTION;
  final float ANGLE;
  
  float[] x;
  float[] y;
  
  PShape closedCylinder;
  PShape bottom;
  PShape top;
  PVector location;

  Cylinder(int CYLINDER_COLOR, int CYLINDER_COLOR_TO_PLACE, int CYLINDER_RADIUS,
           float CYLINDER_HEIGHT, int CYLINDER_RESOLUTION, float ANGLE) {
    
    this.CYLINDER_COLOR = CYLINDER_COLOR;
    this.CYLINDER_COLOR_TO_PLACE = CYLINDER_COLOR_TO_PLACE;
    this.CYLINDER_RADIUS = CYLINDER_RADIUS;
    this.CYLINDER_HEIGHT = CYLINDER_HEIGHT;
    this.CYLINDER_RESOLUTION = CYLINDER_RESOLUTION;
    this.ANGLE = ANGLE;
    
    
    x = new float[CYLINDER_RESOLUTION+1];
    y = new float[CYLINDER_RESOLUTION+1];
    
    closedCylinder = new PShape();
    bottom = new PShape();
    top = new PShape();
    location = new PVector(0f, 0f, 0f);
    
    //get the x and y position on a circle for all the sides
    for (int i = 0; i < x.length; i++) {
      x[i] = sin(ANGLE*i) * CYLINDER_RADIUS;
      y[i] = cos(ANGLE*i) * CYLINDER_RADIUS;
    }
    
    bottom = createShape();
    bottom.beginShape(TRIANGLE_FAN);
    bottom.vertex(0, 0, 0);
    
    for (int i = 0; i < x.length; i++) {
      bottom.vertex(x[i], y[i], 0);
    }
    
    bottom.endShape();

    top = createShape();
    top.beginShape(TRIANGLE_FAN);
    top.vertex(0, 0, CYLINDER_HEIGHT);
    
    for (int i = 0; i < x.length; i++) {
      top.vertex(x[i], y[i], CYLINDER_HEIGHT);
    }
    
    top.endShape();

    closedCylinder = createShape();

    closedCylinder.beginShape(QUAD_STRIP);
    
    //draw the border of the cylinder
    for (int i = 0; i < x.length; i++) {
      closedCylinder.vertex(x[i], y[i], 0);
      closedCylinder.vertex(x[i], y[i], CYLINDER_HEIGHT);
    }
    
    closedCylinder.endShape();
  }
  
  void display(float x, float y, float z, boolean toPlace, PGraphics surface) {
    final int COLOR;
    
    surface.pushMatrix();
    
    surface.rotateX(PI/2);
    location = new PVector(x,y,z);
    surface.translate(location.x, location.y, location.z);
    
    if (toPlace) {      
      COLOR = CYLINDER_COLOR_TO_PLACE;
    } else {
      COLOR = CYLINDER_COLOR;
    }
    
    closedCylinder.setFill(COLOR);
    bottom.setFill(COLOR);
    top.setFill(COLOR);
    
    surface.shape(closedCylinder);
    surface.shape(bottom);
    surface.shape(top);
    
    surface.popMatrix();
  }
  
  PVector getPosition2d() {
    return new PVector(location.x, location.y);
  }
}
