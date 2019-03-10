import java.util.Collections;

List<PVector> hough(PImage edgeImg, int nLines, PGraphics surface) {
  
  float discretizationStepsPhi = 0.06f;
  float discretizationStepsR = 2.5f;
  int minVotes = 50;

  // dimensions of the accumulator
  int phiDim = (int) (Math.PI / discretizationStepsPhi +1);
  //The max radius is the image diagonal, but it can be also negative
  int rDim = (int) ((sqrt(edgeImg.width*edgeImg.width +
                     edgeImg.height*edgeImg.height) * 2)/discretizationStepsR +1);
                     
  // our accumulator
  int[] accumulator = new int[phiDim * rDim];

  // pre-compute the sin and cos values
  float[] tabSin = new float[phiDim];
  float[] tabCos = new float[phiDim];

  float ang = 0;
  float inverseR = 1.f / discretizationStepsR;

  for (int accPhi = 0; accPhi < phiDim; ang += discretizationStepsPhi, accPhi++) {
    // we can also pre-multiply by (1/discretizationStepsR) since we need it in the Hough loop
    tabSin[accPhi] = (float) (Math.sin(ang) * inverseR);
    tabCos[accPhi] = (float) (Math.cos(ang) * inverseR);
  }

  // Fill the accumulator: on edge points (ie, white pixels of the edge
  // image), store all possible (r, phi) pairs describing lines going
  // through the point.
  for (int y = 0; y < edgeImg.height; y++) {
    for (int x = 0; x < edgeImg.width; x++) {
      // Are we on an edge?
      if (brightness(edgeImg.pixels[y * edgeImg.width + x]) != 0) {
        // ...determine here all the lines (r, phi) passing through
        // pixel (x,y), convert (r,phi) to coordinates in the
        // accumulator, and increment accordingly the accumulator.
        // Be careful: r may be negative, so you may want to center onto
        // the accumulator: r += rDim / 2

        for (int phiAcc = 0; phiAcc < phiDim; ++phiAcc) {
          int rAcc = (int) (x*tabCos[phiAcc] + y*tabSin[phiAcc]);
          rAcc += rDim/2;
          accumulator[phiAcc*rDim+rAcc] += 1;
        }
      }
    }
  }

  //BestCandidates and local maxima
  int neighbours = 10;
  ArrayList<Integer> bestCandidates = new ArrayList<Integer>();

  for (int r = 0; r < rDim; r++) {
    for (int phi = 0; phi < phiDim; phi++) {
      int idx = phi*rDim + r;
      int currVotes = accumulator[idx];

      //Check if enough votes
      if (currVotes > minVotes) {

        //Check local maxima
        boolean flag = true;
        
        int boundLeftR = max(0, r - neighbours/2);
        int boundRightR = min(rDim, r + neighbours/2);
        int boundLeftPhi = max(0, phi - neighbours/2);
        int boundRightPhi = min(phiDim, phi + neighbours/2);
        
        for (int i = boundLeftR; flag && i < boundRightR; ++i) {
          for (int j = boundLeftPhi; flag && j < boundRightPhi; ++j) {
            if (accumulator[j*rDim + i] > currVotes) {
              flag = false;
            }
          }
        }

        if (flag) {
          bestCandidates.add(idx);
        }
      }
    }
  }

  //Sort bestCandidates by most voted lines
  Collections.sort(bestCandidates, new HoughComparator(accumulator));

  //Retrieve the lines
  ArrayList<PVector> lines=new ArrayList<PVector>();

  for (int i = 0; i < nLines && i < bestCandidates.size(); ++i) {
    
    int idx = bestCandidates.get(i);
    
    //first, compute back the (r, phi) polar coordinates:
    int accPhi = (int) (idx / (rDim));
    int accR = idx - (accPhi) * (rDim);
    
    float r = (accR - (rDim) * 0.5f) * discretizationStepsR;
    float phi = accPhi * discretizationStepsPhi;
    lines.add(new PVector(r, phi));
  }

  //CODE POUR AFFICHER LES LIGNES :
  for (int idx = 0; idx < lines.size(); idx++) {
    
    PVector line=lines.get(idx);
    float r = line.x;
    float phi = line.y;
    
    // Cartesian equation of a line: y = ax + b
    // in polar, y = (-cos(phi)/sin(phi))x + (r/sin(phi))
    // => y = 0 : x = r / cos(phi)
    // => x = 0 : y = r / sin(phi)
    // compute the intersection of this line with the 4 borders of
    // the image
    int x0 = 0;
    int y0 = (int) (r / sin(phi));
    int x1 = (int) (r / cos(phi));
    int y1 = 0;
    int x2 = edgeImg.width;
    int y2 = (int) (-cos(phi) / sin(phi) * x2 + r / sin(phi));
    int y3 = edgeImg.width;
    int x3 = (int) (-(y3 - r / sin(phi)) * (sin(phi) / cos(phi)));
    // Finally, plot the lines
    surface.stroke(204, 102, 0);
    if (y0 > 0) {
      if (x1 > 0)
        surface.line(x0, y0, x1, y1);
      else if (y2 > 0)
        surface.line(x0, y0, x2, y2);
      else
        surface.line(x0, y0, x3, y3);
    } else {
      if (x1 > 0) {
        if (y2 > 0)
          surface.line(x1, y1, x2, y2);
        else
          surface.line(x1, y1, x3, y3);
      } else
        surface.line(x2, y2, x3, y3);
    }
  }

  return lines;
}

class HoughComparator implements java.util.Comparator<Integer> {
  int[] accumulator;
  
  public HoughComparator(int[] accumulator) {
    this.accumulator = accumulator;
  }
  
  @Override
  public int compare(Integer l1, Integer l2) {
    if (accumulator[l1] > accumulator[l2]
        || (accumulator[l1] == accumulator[l2] && l1 < l2)) return -1;
    return 1;
  }
}