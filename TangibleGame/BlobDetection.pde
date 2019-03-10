import java.util.ArrayList;
import java.util.List;
import java.util.TreeSet;

class BlobDetection {

  public PImage findConnectedComponents(PImage input, boolean onlyBiggest) {
    
    int[] labels = new int[input.width*input.height];
    List<TreeSet<Integer>> labelsEquivalences = new ArrayList<TreeSet<Integer>>();
    //first label is 0, finding the corresponding index is easier
    int currentLabel = 0;

    for (int i = 0; i < labels.length; ++i) {
      labels[i] = -1;
    }

    input.loadPixels();

    for (int y = 0; y < input.height; ++y) {
      for (int x = 0; x < input.width; ++x) {
        if (brightness(input.pixels[y*input.width + x]) == 255) {
          TreeSet<Integer> neighboursTemp = new TreeSet();

          if (x > 0) {
            neighboursTemp.add(labels[y*input.width + x - 1]);
          }

          if (y > 0) {
            if (x > 0) {
              neighboursTemp.add(labels[(y-1)*input.width + x - 1]);
            }
            if (x < input.width-1) {
              neighboursTemp.add(labels[(y-1)*input.width + x + 1]);
            }
            neighboursTemp.add(labels[(y-1)*input.width + x]);
          }

          neighboursTemp.remove(-1);

          if (neighboursTemp.isEmpty()) {
            labels[y*input.width + x] = currentLabel;
            labelsEquivalences.add(new TreeSet<Integer>());
            labelsEquivalences.get(currentLabel).add(currentLabel);
            currentLabel += 1;
          } else {
            labels[y*input.width + x] = neighboursTemp.first();

            for (int n : neighboursTemp) {
              labelsEquivalences.get(n).add(neighboursTemp.first());
            }
          }
        }
      }
    }
    
    //go through all labels and make them equivalent to each other if they are
    for (int i = currentLabel-1; i >= 0; --i) {
      TreeSet<Integer> labelsTemp = new TreeSet();
      
      for (int l : labelsEquivalences.get(i)) {
        labelsTemp.addAll(labelsEquivalences.get(l));
        labelsEquivalences.get(l).addAll(labelsEquivalences.get(i));
      }
      
      labelsTemp.addAll(labelsTemp);
    }
    
    PImage result;
    
    if (onlyBiggest) {
      result = createImage(input.width, input.height, ALPHA);
      
      //if there is only black pixels
      if (labelsEquivalences.size() == 0) {
        for (int i = 0; i < input.width*input.height; ++i) {
          result.pixels[i] = color(0);
        }
      } else {

        int[] pixelsNumber = new int[currentLabel];
        
        //find the biggest blob
        for (int i = 0; i < labels.length; ++i) {
          if (labels[i] >= 0) {
            pixelsNumber[labelsEquivalences.get(labels[i]).first()] += 1;
          }
        }

        int labelsMax = 0;

        for (int i = 0; i < currentLabel; ++i) {
          labelsMax = (pixelsNumber[i] > pixelsNumber[labelsMax]) ? i : labelsMax;
        }
        
        for (int i = 0; i < input.width*input.height; ++i) {
          result.pixels[i] = (labelsEquivalences.get(labelsMax).contains(labels[i])) ? color(0, 220, 0) : color(0);
        }
      }
    } else {
      
      result = createImage(input.width, input.height, RGB);
      
      //pick up colors for blobs
      int[] colors = new int[currentLabel];
      int col = 0;

      for (int i = 0; i < colors.length; ++i) {
        int r = round(random(255));
        int g = round(random(255));
        int b = round(random(255));

        colors[i] = color(r, g, b);
      }

      for (int i = 0; i < input.width*input.height; ++i) {
        col = 0;

        if (labels[i] >= 0) {
          col = colors[labelsEquivalences.get(labels[i]).first()];
        } else {
          col = color(255);
        }
        
        result.pixels[i] = col;
      }
    }

    return result;
  }
}
