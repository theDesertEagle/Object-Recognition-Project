# Region Extraction and Statistics Computation
A fragment of an object-recognition system to perform noise removal, adaptive thresholding, connected component extraction and finally region-statistics computation for a given pair of images. This project component can be integrated with a mechanical robotic-arm system to extract and compute various regions of interest along with its set of region-statistics, based on which machine learning-based object-classifiers can be developed.  

## Instructions
Run the `objectRecognitionComponent.m` script in the MATLAB terminal using the command `objectRecognitionComponent(imageName.gif)` where the `imageName.gif` can be replaced by two sample images:
1. `separatedObjs.gif` : A greyscale image consisting of toys which are considerably at a distance from each other.
   ![Separated Objects GIF](/separatedObjs.gif)
2. `closeObjs.gif` : A greyscale image consisting of toys which are closer to each other.
   ![Close Objects GIF](/closeObjs.gif)

## Algorithms Overview
### 1. Histogram Intensity Thresholding and Smoothing by Bins: </br> 
**Assumption:** The least threshold value will be the best local optimal solution. </br>
**Procedure:**
1. Define a Histogram Intervals, Widths and their corresponding Boundary Elements 
2. Create an Intensity Level Probability Distribution based on the above parameters 
3. Apply Otsu’s Method 
   1. Calculate the means and weights for two estimated Gaussian Distribution Classes for the threshold interval 
   2. Calculate Between-Class Variance using the means and weights 
   3. Store the threshold interval value with Minimum Between-Class Variance -
   4. Repeat from Step-3.1 until all threshold intervals are exhausted 
4. Convert the threshold interval to its corresponding threshold value 
5. Repeat from Step-1 till number of Histogram Intervals is exactly equal to the maximum intensity value 
6. Pick the smallest threshold value from this the computed threshold values in Step-5 
7. Binarize image with respect to threshold

### 2. Region Labelling, Region Post-Processing and Connected Component Extraction: </br> 
**Assumption:** None of the objects of interest are points or cover 3/4th of image space in one specific row/column. None of the objects create occlusions. </br> 
**Procedure:**
1. Find a high-intensity pixel from binary image and assign it a color/label
2. Using 8-connectivity, check for high-intensity pixel in North, North-East, East, South-East, South, South-West, West and North-West Neighbors respectively
3. Color any of the neighboring pixels that are high-intensity pixels 
4. Repeat from Step-2 recursively until all neighbors are exhausted 
5. Repeat from Step-1 for unlabelled/uncolored pixels 
6. Post-process regions to remove unwanted regions estimated to violate two rules:  
   - **Rule 1:** Each Row-Pixels count must be greater than 1 pixel and less than 75% of the  height of the image  
   - **Rule 2:** Each Column-Pixels count must be greater than 1 pixel and less than 75% of  the width of the image  
   1. Estimation is done by counting the number of times Rule-1 and Rule-2 are violated each per column and each row respectively. If they are not violated for a column or row respectively, the corresponding column or row ‘number of violation times’ is reduced by one.  
   2. If number of violations of either row or column is positive, remove the region with its associated pixels
7. Repeat Step-6 violation test for all remaining regions

### 3. Run-Length Compressed Storage of Region: </br>
**Assumption:** Distinct regions are uniquely labelled </br>
1. Set Run-Length Status = Run Not Started 
2. Perform raster scan on image until a region pixel is visited 
3. Store Row Index and Column Start Index 
4. Set Run-Length Status = Run Processing and continue raster scan 
5. If non-region pixel/raster scan row-end has arrived, store Column End Index and set Run-Length Status = Run Completed 
6. Store Row Index, Column Start Index and Column End Index in a matrix 
7. Repeat from Step-1 for all remaining row-elements and rows of image

### 4. Area + Centroid + MBR + Fractional Fill Coordinates Estimation: </br>
**Assumption:** Result precision is the same as given image resolution </br>
**Procedure:** While Run-Length Status = Run Processing, keep incrementing Area by 1 and adding Centroid’s X and Y from this run. After Run-Length Compression Completion, divide Centroid by Calculated Area. During these runs, keep track of maximum and minimum values of X and Y. The minimum (X,Y) and maximum (X,Y) correspond to MBR coordinates. Subtract Area by Area of MBR calculated by MBR coordinate to get Fractional Fill.

### 5. Perimeter and Elongation Estimation using Erosion-based Approach: </br>
**Assumption:** No hole exists close to the boundary of the region </br>
**Procedure:** Apply a 3x3 ones’ matrix erosion kernel to each pixel of region </br>
**Kernel Logic:** If all pixels in 3x3 grid are labelled as the region in consideration, increase the counter. Keep convoluting until all pixels are covered. Finally, subtract Blob Area with This Counter to provide an estimate of the Perimeter. Square the Perimeter and Divide by Blob Area to get Elongation.

### Hole-Extraction using Run-Length Strategy:
Assumption: 4-connectivity implementation 
1. Maintain a Hole-Indices Manager which stores all hole-indices (including row-index)
2. If one entry in Run-Length matrix has same row-index as the next entry, store Run-Length value as possible Hole 
3. Check for gaps for all the Run-Length entries at the top and bottom of reference-Run until a roof/floor entry is reached, ensuring that each entry has row-index one minus/plus the previous respectively row-index. If this constraint is not met, all of the entries will be visited and thus this feature is concavity/convexity extending as background pixel. 
4. If both the top and bottom of the hole are non-background pixels, then add this the set of hole-indices X (start and end indices) and Y (row index) to the Hole-Indices Manager. 
5. Finally, take a set difference between Hole-Indices Manager and Run-Length matrix

## Observations
The threshold value estimated by the adaptive thresholding algorithm was found to be 81 for both of the images.

### Adaptive Thresholding Results for Both Images
![Adaptive Thresholding GIF](/imgDoc/adaptiveThresholding.gif)

### Connected Componenet Extraction Resutls for separatedObjs.gif
![Separated Objs Results-1 Image](/imgDoc/separatedObjsRes1.PNG)
![Separated Objs Results-2 Image](/imgDoc/separatedObjsRes2.PNG)

### Region Statistics for separatedObjs.gif
![Separated Objs Table](/imgDoc/separatedObjsTable.PNG)

### Connected Componenet Extraction Resutls for closeObjs.gif
![Close Objs Results-1 Image](/imgDoc/closeObjsRes1.PNG)
![Close Objs Results-2 Image](/imgDoc/closeObjsRes2.PNG)

### Region Statistics for closeObjs.gif
![Separated Objs Table](/imgDoc/closeObjsTable.PNG)

## Known Bugs
The performance of hole-extraction seems to be good, as it can be visually observed in the resultant images above. However, the number of detected holes may overflow the desired results.

## @ the.desert.eagle
