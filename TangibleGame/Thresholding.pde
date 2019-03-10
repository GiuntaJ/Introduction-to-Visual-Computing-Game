PImage threshold(PImage img, int threshold) {
  
  // create a new, initially transparent, 'result' image
  PImage result = createImage(img.width, img.height, RGB);

  img.loadPixels();
  for (int i = 0; i < img.width * img.height; i++) {
    result.pixels[i] = (brightness(img.pixels[i]) >= threshold) ? color(255, 255, 255) : color(0, 0, 0);
  }

  return result;
}

PImage brightThreshold(PImage img, int min,  int max) {
  // create a new, initially transparent, 'result' image
  PImage result = createImage(img.width, img.height, RGB);

  img.loadPixels();
  for (int i = 0; i < img.width * img.height; i++) {
    float b = brightness(img.pixels[i]);
    result.pixels[i] = (b >= min && b <= max) ? img.pixels[i] : color(0, 0, 0);
  }

  return result;
}

PImage hueThreshold(PImage img, int min, int max) {
  // create a new, initially transparent, 'result' image
  PImage result = createImage(img.width, img.height, RGB);

  img.loadPixels();
  for (int i = 0; i < img.width * img.height; i++) {
    float h = hue(img.pixels[i]);
    result.pixels[i] = (h >= min && h <= max) ? img.pixels[i] : color(0, 0, 0);
  }

  return result;
}

PImage saturationThreshold(PImage img, int min, int max) {
  // create a new, initially transparent, 'result' image
  PImage result = createImage(img.width, img.height, RGB);

  img.loadPixels();
  for (int i = 0; i < img.width * img.height; i++) {
    float s = saturation(img.pixels[i]);
    result.pixels[i] = (s >= min && s <= max) ? color(255, 255, 255) : color(0, 0, 0);
  }

  return result;
}

PImage thresholdHSB(PImage img, int minH,int maxH,int minS,int maxS,int minB,int maxB){
  PImage brightTh = brightThreshold(img, minB, maxB);
  PImage hueTh = hueThreshold(brightTh, minH, maxH);
  return saturationThreshold(hueTh, minS, maxS);
}
