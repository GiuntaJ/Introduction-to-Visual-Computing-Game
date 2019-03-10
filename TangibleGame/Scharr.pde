PImage scharr(PImage img) {
  
  float[][] hKernel = {{ 3, 10, 3}, 
                       { 0, 0, 0}, 
                       { -3, -10, -3}};

  float[][] vKernel = {{ 3, 0, -3}, 
                       { 10, 0, -10}, 
                       { 3, 0, -3}};

  float[] buffer = new float[img.width*img.height];

  PImage result = createImage(img.width, img.height, ALPHA);

  float max = Float.MIN_VALUE;

  final int N = 3;
  for (int x = N/2; x < img.width - N/2; ++x) {
    for (int y = N/2; y < img.height - N/2; ++y) {

      float sum = 0;
      float sum_h = 0;
      float sum_v = 0;

      for (int i = x - N/2; i <= x + N/2; ++i) {
        for (int j = y - N/2; j <= y + N/2; ++j) {

          sum_h += (brightness(img.pixels[j*img.width + i])) * hKernel[j - y + N/2][i - x + N/2];
          sum_v += (brightness(img.pixels[j*img.width + i])) * vKernel[j - y + N/2][i - x + N/2];
        }
      }

      sum = sqrt(pow(sum_h, 2) + pow(sum_v, 2));
      
      if (max < sum) {
        max = sum;
      }

      buffer[y * img.width + x] = sum;
    }
  }

  for (int y = 2; y < img.height - 2; y++) { // Skip top and bottom edges
    for (int x = 2; x < img.width - 2; x++) { // Skip left and right
      
      int val=(int) ((buffer[y * img.width + x] / max)*255); 
      result.pixels[y * img.width + x]=color(val);
    }
  }
  
  return result;
}
