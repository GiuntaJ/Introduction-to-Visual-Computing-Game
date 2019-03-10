PImage gaussianBlur(PImage img) {
  
  float[][] kernel = { { 9, 12, 9 },
    { 12, 15, 12 },
    { 9, 12, 9 }};

  float normFactor = 99.f;
  // create a greyscale image (type: ALPHA) for output
  PImage result = createImage(img.width, img.height, ALPHA);
  // kernel size N = 3
  //
  // for each (x,y) pixel in the image:
  // - multiply intensities for pixels in the range
  // (x - N/2, y - N/2) to (x + N/2, y + N/2) by the
  // corresponding weights in the kernel matrix
  // - sum all these intensities and divide it by normFactor
  // - set result.pixels[y * img.width + x] to this value

  int N = 3;
  for (int x = N/2; x < img.width - N/2; ++x) {
    for (int y = N/2; y < img.height - N/2; ++y) {

      int sum = 0;

      for (int i = x - N/2; i <= x + N/2; ++i) {
        for (int j = y - N/2; j <= y + N/2; ++j) {
          //println("(" + (i - x + N/2) + "," + (j - y + N/2) + ") = " + kernel[j - y + N/2][i - x + N/2]);
          if (y*img.width + x == 167)
            println(sum);
          //println("(" + x + "," + y + ") = ( " + bound(i, 0, img.width-1) + "," + bound(j, 0, img.height-1) +")");
          sum += (brightness(img.pixels[bound(j, 0, img.height-1)*img.width + bound(i, 0, img.width-1)])) * kernel[j - y + N/2][i - x + N/2];
        }
      }

      result.pixels[y * img.width + x] = color((int)(sum/normFactor));
    }
  }
  
  return result;
}