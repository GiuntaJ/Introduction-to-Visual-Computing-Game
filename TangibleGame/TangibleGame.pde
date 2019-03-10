import processing.video.*;
import gab.opencv.*;

final int SCREEN_WIDTH = 2490;
final int SCREEN_HEIGHT = 900;
final int GAME_WIDTH = 1850;
final int GAME_HEIGHT = 700;
final int SCORE_HEIGHT = 200;

final int SCALE = 10;
final float MAGIC_MOUSE = 1.45;

final int PLATE_SIZE = 1800;
final int PLATE_THICKNESS = 50;

final int PLATE_COLOR = #FFF6A1;
final int BACKGROUND_COLOR = #E7E7FF;
final int SCORE_SURFACE_COLOR = #A1A1B2;
final int SCORE_BOARD_CHART_COLOR = #CFCFE5;

final int CYLINDER_COLOR = #A68CFF;
final int CYLINDER_COLOR_TO_PLACE = #FF3A93;
final int CYLINDER_RADIUS = 125;
final float CYLINDER_HEIGHT = 220;
final int CYLINDER_RESOLUTION = 50;
final float ANGLE = TWO_PI/CYLINDER_RESOLUTION;

final int BALL_COLOR = #887DB0;
final int BALL_RADIUS = 75;
final float ELASTICITY = 0.8;
final float FRICTION = 0.025; 
final float GRAVITY = 1.5;

final int SCROLLBAR_HEIGHT = 20;

final int MIN_BRIGHTNESS = 20;
final int MAX_BRIGHTNESS = 255;
final int MIN_HUE = 70;
final int MAX_HUE = 140;
final int MIN_SATURATION = 65;
final int MAX_SATURATION = 255;
final int FINAL_THRESHOLD = 100;

QuadGraph qg;
BlobDetection blob;
TwoDThreeD tt;
Movie cam;
OpenCV opencv;
PImage img;
  
PVector rotation;

int valueX = SCREEN_WIDTH/2;
int valueY = SCREEN_HEIGHT/2;

float speedMove = 1.0;
float rotateX;
float rotateZ;
float rotateY;

float totalScore;
float lastScore;

PGraphics gameSurface;
PGraphics scoreSurface;
PGraphics topView;
PGraphics scoreBoard;
PGraphics scoreChart;
PGraphics imageProc;

HScrollbar hs;

ArrayList<PVector> cylindersPositions;
ArrayList<Integer> scoreHistory;

Mover mover;
Cylinder cylinder;
Cylinder cylinderToPlace;

enum MODE {
  GameMode, CylindersPlacementMode
}
MODE drawMode;

void settings() {
  size(SCREEN_WIDTH, SCREEN_HEIGHT, P3D);
}

void setup() {
  opencv = new OpenCV(this, 100, 100);
  blob = new BlobDetection();
  qg = new QuadGraph();
  tt = new TwoDThreeD(640, 480, 0);
  rotation = new PVector(0,0,0);

  noStroke();

  mover = new Mover(0, PLATE_THICKNESS, 0, BALL_COLOR, BALL_RADIUS, 
    ELASTICITY, FRICTION, GRAVITY);
  cylindersPositions = new ArrayList();
  cylinder = new Cylinder(CYLINDER_COLOR, CYLINDER_COLOR_TO_PLACE, CYLINDER_RADIUS, 
    CYLINDER_HEIGHT, CYLINDER_RESOLUTION, ANGLE);
  cylinderToPlace = new Cylinder(CYLINDER_COLOR, CYLINDER_COLOR_TO_PLACE, CYLINDER_RADIUS, 
    CYLINDER_HEIGHT, CYLINDER_RESOLUTION, ANGLE);

  scoreHistory = new ArrayList();

  gameSurface = createGraphics(GAME_WIDTH, GAME_HEIGHT, P3D);
  scoreSurface = createGraphics(GAME_WIDTH, SCORE_HEIGHT, P3D);
  topView = createGraphics(PLATE_SIZE/SCALE, PLATE_SIZE/SCALE, P2D);
  scoreBoard = createGraphics(PLATE_SIZE/SCALE, PLATE_SIZE/SCALE, P2D);
  scoreChart = createGraphics(GAME_WIDTH-2*PLATE_SIZE/SCALE-4*(SCORE_HEIGHT-PLATE_SIZE/SCALE)/2, PLATE_SIZE/SCALE, P2D);
  imageProc = createGraphics(640, 480, P3D);

  hs = new HScrollbar(2*PLATE_SIZE/SCALE + 3*(SCORE_HEIGHT-PLATE_SIZE/SCALE)/2, GAME_HEIGHT + SCORE_HEIGHT - (SCORE_HEIGHT-PLATE_SIZE/SCALE)/2 - SCROLLBAR_HEIGHT, scoreChart.width, SCROLLBAR_HEIGHT);

  totalScore = 0;
  lastScore = 0;

  drawMode = MODE.GameMode;
  
  cam = new Movie(this, "testvideo.avi");
  cam.loop();  
}

void draw() {
  switch(drawMode) {
    case GameMode :
      drawGame();
      break;
    case CylindersPlacementMode : 
      drawPlacement();
      break;
  }

  drawScoreSurface();
  drawImageProc();

  image(gameSurface, 0, 0);
  image(scoreSurface, 0, GAME_HEIGHT);
  image(topView, (SCORE_HEIGHT-PLATE_SIZE/SCALE)/2, GAME_HEIGHT+(SCORE_HEIGHT-PLATE_SIZE/SCALE)/2);
  image(scoreBoard, PLATE_SIZE/SCALE + 2*(SCORE_HEIGHT-PLATE_SIZE/SCALE)/2, GAME_HEIGHT+(SCORE_HEIGHT-PLATE_SIZE/SCALE)/2);
  image(scoreChart, 2*PLATE_SIZE/SCALE + 3*(SCORE_HEIGHT-PLATE_SIZE/SCALE)/2, GAME_HEIGHT+(SCORE_HEIGHT-PLATE_SIZE/SCALE)/2);
  image(imageProc, GAME_WIDTH, 0);


  hs.update();
  hs.display();
}

void drawImageProc(){
  imageProc.beginDraw();
    //CODE FOR CAMERA :
  if (cam.available() == true) {
    cam.read();
  }
  
  img = cam.get();

  //Hue/Brigthness/Saturation thresholding
  PImage thresholded = thresholdHSB(img, MIN_HUE, MAX_HUE, MIN_SATURATION, MAX_SATURATION, 20, MAX_BRIGHTNESS);
  //Blob detection
  PImage connecComp = blob.findConnectedComponents(thresholded, true);
  //Blurring
  PImage blurred = gaussianBlur(connecComp);
  //Edge Detection
  PImage scharred = scharr(blurred);
  //Suppression of pixels with low brightness
  PImage lowBright = threshold(scharred, FINAL_THRESHOLD);

  //Display the original image
  imageProc.image(img, 0, 0);
  //imageProc.image(scharred, 640, 0);
  //imageProc.image(thresholded, 0, 480);
  //imageProc.image(connecComp, 640, 480);

  //Hough transform (and display the lines)
  List<PVector> lines = hough(lowBright, 4, imageProc);

  //Corners of the board
  List<PVector> corners = qg.findBestQuad(lines, img.width, img.height, 500000, 500, false);  
  for (PVector c : corners) {
    imageProc.stroke(204, 102, 0);
    imageProc.fill(0, 180, 150, 100);
    imageProc.ellipse(c.x, c.y, 30, 30);
    //Make the corner homogeneous
    c.z = 1;
  }

  rotation = tt.get3DRotations(corners);
  imageProc.endDraw();
  
}

void drawGame() {
  //setup
  gameSurface.beginDraw();
  gameSurface.noStroke();
  gameSurface.background(BACKGROUND_COLOR);
  gameSurface.camera(0, 0, 0, 0, 0, 2000, 0, 1, 0);
  gameSurface.ambientLight(100, 100, 100);
  gameSurface.directionalLight(120, 150, 150, 0, 750, 750);

  //draw game elements
  gameSurface.pushMatrix();
  //display the plate
  gameSurface.translate(0, 0, 2000);
  
  PVector rot = rotation;

  rotateX = abs(rot.x) == 0 ? rotateX : rot.x+PI;
  rotateZ = abs(rot.y) == 0 ? rotateZ : rot.y ;
  rotateY = rotateX != 0.0 || rotateZ != 0.0 ? PI : 0;
 
  
  gameSurface.rotateX(rotateX);
  gameSurface.rotateZ(rotateZ);
  //gameSurface.rotateY(rotateY);
  
  
  //display the plate
  gameSurface.fill(PLATE_COLOR);
  gameSurface.box(PLATE_SIZE, PLATE_THICKNESS, PLATE_SIZE);

  //display the cylinders
  for (PVector cylinderPosition : cylindersPositions) {
    cylinder.display(cylinderPosition.x, cylinderPosition.y, cylinderPosition.z, false, gameSurface);
  }

  //move the ball and check collisions
  mover.update(rotateX, rotateZ);
  float hitEdge = - mover.checkEdges(PLATE_SIZE);
  float hitCyl = mover.checkCollisions(cylindersPositions);
  mover.display(gameSurface);

  gameSurface.popMatrix();
  gameSurface.endDraw();

  scoreSurface.beginDraw();
  scoreSurface.background(123);
  scoreSurface.endDraw();

  if (hitEdge == 0) {
    if (hitCyl != 0) {
      lastScore = hitCyl;
    }
  } else {
    lastScore = hitEdge;
  }

  if (abs(lastScore) > 4) {
    totalScore += hitCyl;
    totalScore += hitEdge;
    totalScore = max(0, totalScore);

    if (scoreHistory.size() <= 0 || abs(scoreHistory.get(scoreHistory.size()-1) - totalScore) > 30) {
      scoreHistory.add((int)totalScore);

      drawNewScore();
    }
  }
}

void drawPlacement() {
  //setup
  gameSurface.beginDraw();
  gameSurface.noStroke();
  gameSurface.background(BACKGROUND_COLOR);
  gameSurface.camera(0, 0, 0, 0, 0, 2000, 0, 1, 0);
  gameSurface.ambientLight(100, 100, 100);
  gameSurface.directionalLight(120, 150, 150, 0, 750, 750);

  //draw the cylinders placement elements
  gameSurface.pushMatrix();

  //draw the rotated plate
  gameSurface.translate(0, 0, 2000);
  gameSurface.rotateX(PI/2);
  gameSurface.rotateZ(0);
  gameSurface.fill(PLATE_COLOR);
  gameSurface.box(PLATE_SIZE, PLATE_THICKNESS, PLATE_SIZE);

  //cylinders
  for (PVector cylinderPosition : cylindersPositions) {
    cylinder.display(cylinderPosition.x, cylinderPosition.y, cylinderPosition.z, false, gameSurface);
  }

  //create cylinder
  float x = map(mouseX-GAME_WIDTH/2, -GAME_WIDTH/2, GAME_WIDTH/2, MAGIC_MOUSE*GAME_WIDTH, -MAGIC_MOUSE*GAME_WIDTH);
  float y = map(mouseY-GAME_HEIGHT/2, -GAME_HEIGHT/2, GAME_HEIGHT/2, MAGIC_MOUSE*GAME_HEIGHT, -MAGIC_MOUSE*GAME_HEIGHT);

  if (mouseY < GAME_HEIGHT) {
    cylinderToPlace.display(bound(x, -PLATE_SIZE/2 + cylinderToPlace.CYLINDER_RADIUS, PLATE_SIZE/2 - cylinderToPlace.CYLINDER_RADIUS), 
      bound(y, -PLATE_SIZE/2 + cylinderToPlace.CYLINDER_RADIUS, PLATE_SIZE/2 - cylinderToPlace.CYLINDER_RADIUS), cylinderToPlace.location.z, !possibleToPlaceCylinder(), 
      gameSurface);
  }

  //draw the ball
  mover.display(gameSurface);

  gameSurface.popMatrix();
  gameSurface.endDraw();
}

void drawScoreSurface() {
  scoreSurface.beginDraw();
  scoreSurface.noStroke();
  scoreSurface.background(SCORE_SURFACE_COLOR);
  scoreSurface.endDraw();

  drawTopView();
  drawScoreBoard();
  drawNewScore();
}

void drawTopView() {
  topView.beginDraw();
  topView.noStroke();
  topView.fill(PLATE_COLOR, 15);
  topView.rect(0, 0, PLATE_SIZE/SCALE, PLATE_SIZE/SCALE);

  topView.fill(CYLINDER_COLOR);
  for (PVector cylinder : cylindersPositions) {
    topView.ellipse((-cylinder.x+PLATE_SIZE/2)/SCALE, (-cylinder.y+PLATE_SIZE/2)/SCALE, 2*CYLINDER_RADIUS/SCALE, 2*CYLINDER_RADIUS/SCALE);
  }

  PVector mPosition = mover.getPosition2d();
  topView.fill(BALL_COLOR);
  topView.ellipse((-mPosition.x+PLATE_SIZE/2)/SCALE, (-mPosition.y+PLATE_SIZE/2)/SCALE, 2*BALL_RADIUS/SCALE, 2*BALL_RADIUS/SCALE);

  topView.endDraw();
}

void drawScoreBoard() {
  scoreBoard.beginDraw();
  scoreBoard.noStroke();
  scoreBoard.background(SCORE_BOARD_CHART_COLOR);

  scoreBoard.textSize(15);
  scoreBoard.fill(0);

  String sVelocity = Float.valueOf(mover.vVelocity.mag()).toString();
  scoreBoard.text("Velocity ", 10, 30);
  scoreBoard.text(sVelocity.substring(0, sVelocity.indexOf(".")+2), 20, 50);
  scoreBoard.text("Total Score ", 10, 80);
  scoreBoard.text(totalScore, 20, 100);
  scoreBoard.text("Last Score ", 10, 130);
  scoreBoard.text(lastScore, 20, 150);


  scoreBoard.endDraw();
}

void drawNewScore() {
  scoreChart.beginDraw();
  scoreChart.noStroke();
  scoreChart.background(SCORE_BOARD_CHART_COLOR);

  int wScore = (int)(30*max(0.1, hs.getPos()));
  int scoreToDraw = 0;

  for (int i = 0; i < scoreHistory.size(); ++i) {
    scoreToDraw = 1+scoreHistory.get(i)/30;

    for (int j = 15; j > 15-scoreToDraw; --j) {
      scoreChart.rect(i*wScore, j*10, wScore-1, 9);
    }
  }

  scoreChart.endDraw();
}

void createCylinder() {
  if (possibleToPlaceCylinder()) {
    cylindersPositions.add(cylinderToPlace.getPosition2d());
  }
}

boolean possibleToPlaceCylinder() {
  PVector otherCylinderPosition;
  Boolean notOnCylinders = true;
  Boolean notOnBall = true;
  int i = 0;

  while (notOnCylinders && i < cylindersPositions.size()) {
    otherCylinderPosition = cylindersPositions.get(i);

    if (cylinderToPlace.getPosition2d().dist(otherCylinderPosition) < 2*cylinderToPlace.CYLINDER_RADIUS) {
      notOnCylinders = false;
    }

    ++i;
  }

  notOnBall = (cylinderToPlace.getPosition2d().dist(mover.getPosition2d()) >= cylinderToPlace.CYLINDER_RADIUS + mover.BALL_RADIUS);

  return (notOnCylinders &&
    notOnBall &&
    cylinderToPlace.location.x == bound(cylinderToPlace.location.x, -PLATE_SIZE/2 + cylinderToPlace.CYLINDER_RADIUS, PLATE_SIZE/2 - cylinderToPlace.CYLINDER_RADIUS) &&
    cylinderToPlace.location.y == bound(cylinderToPlace.location.y, -PLATE_SIZE/2 + cylinderToPlace.CYLINDER_RADIUS, PLATE_SIZE/2 - cylinderToPlace.CYLINDER_RADIUS));
}

void mouseDragged() {
  if (drawMode == MODE.GameMode && mouseY < GAME_HEIGHT) {
    valueX = bound((int)(valueX+(mouseX-pmouseX)*speedMove), 0, SCREEN_WIDTH);
    valueY = bound((int)(valueY+(mouseY-pmouseY)*speedMove), 0, SCREEN_HEIGHT);
  }
}

void mouseClicked() {
  if (mouseButton == LEFT &&
    drawMode == MODE.CylindersPlacementMode &&
    mouseY < GAME_HEIGHT) {

    createCylinder();
  }
}

void mouseWheel(MouseEvent event) {
  if (drawMode == MODE.GameMode) {
    speedMove = bound(speedMove+event.getCount(), 1.0, 5.0);
  }
}

void keyPressed() {
  if (keyCode == SHIFT) {
    drawMode = MODE.CylindersPlacementMode;
  }
}
void keyReleased() {
  if (keyCode == SHIFT) {
    drawMode = MODE.GameMode;
  }
}

int bound(int toBeBounded, int min, int max) {
  if (toBeBounded > max) {
    return max;
  } else if (toBeBounded < min) {
    return min;
  } else {
    return toBeBounded;
  }
}

float bound(float toBeBounded, float min, float max) {
  if (toBeBounded > max) {
    return max;
  } else if (toBeBounded < min) {
    return min;
  } else {
    return toBeBounded;
  }
}