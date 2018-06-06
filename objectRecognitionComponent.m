function objectRecognitionComponent(imageNumber)
    %% Reading the image file
    if imageNumber == 1 
        fprintf("\nReading separatedObjs.gif image ...");
        inputImage = double(imread('separatedObjs.gif'));
        fprintf("\nImage loaded successfully ...");
    else
        fprintf("\nReading closeObjs.gif image ...");
        inputImage = double(imread('closeObjs.gif'));
        fprintf("\nImage loaded successfully ...");
    end
    
    %% Plotting the original image after size extraction
    [heightOfInputImage, widthOfInputImage] = size(inputImage);
    figure(1);
    subplot(1,2,1);
    imshow(inputImage, []);
    title("Original Image")
    
    %% Finding the Threshold Value using a Modified Otsu Method Approach
    maximumIntensityValue = max(inputImage(:));    
    desiredThreshold = -1;
    
    % Loop for Performing Gradient Descent by finding Minimum Threshold
    % Value by Recomputing Histogram Intervals and Width
    for intensityValueIterator=1:maximumIntensityValue
        
        % Defining Histogram Intervals and Width
        numberOfIntervals = 40;
        widthOfIntervals = floor((maximumIntensityValue/numberOfIntervals) + 1);
        intervalBoundaries = ones(numberOfIntervals-1, 1);
        for i=1:numberOfIntervals-1
            intervalBoundaries(i) = 1 + i*widthOfIntervals;
        end

        % Creating Histogram based on Computed Histogram Intervals and Width 
        intensityLevelProbabilityDistribution = zeros(numberOfIntervals, 1);
        for row=1:heightOfInputImage
            for column=1:widthOfInputImage
                for interval=1:numberOfIntervals-1
                    if inputImage(row, column) < intervalBoundaries(interval)
                        if interval == 1
                           if inputImage(row, column) >= 1
                               intensityLevelProbabilityDistribution(interval) = intensityLevelProbabilityDistribution(interval) + 1;
                           end
                        elseif inputImage(row, column) >= intervalBoundaries(interval-1)
                            intensityLevelProbabilityDistribution(interval) = intensityLevelProbabilityDistribution(interval) + 1;
                        end
                    end
                end
            end
        end
        intensityLevelProbabilityDistribution = intensityLevelProbabilityDistribution/sum(intensityLevelProbabilityDistribution); %Minimizing histogram space by considering max value = N
        
        % Viewing Histogram of Intensity Level Probability Distribution
        %h = histogram(intensityLevelProbabilityDistribution)
        
        % Application of Traditional Otsu's Method
        thresholdingValue = 0;
        maxBetweenClassVariance = -1.0;
        % Checking for all Possible Threshold Values
        for t=1:numberOfIntervals
            weightClassA = 0.00;
            meanClassA = 0.00;
            meanClassB = 0.00;
            % Calculating the summed entities for ClassA Weight, and ClassA
            % and Class B means
            for pixelValueClassA=1:t-1
                weightClassA = weightClassA + intensityLevelProbabilityDistribution(pixelValueClassA);
                meanClassA = meanClassA + intensityLevelProbabilityDistribution(pixelValueClassA)*(pixelValueClassA);
            end
            for pixelValueClassB=t:numberOfIntervals
                meanClassB = meanClassB + intensityLevelProbabilityDistribution(pixelValueClassB)*(pixelValueClassB);    
            end
            % Checking for Invalid Weights and Computing Final Weights and Means 
            weightClassB = 1 - weightClassA;
            if weightClassA == 0 || weightClassB == 0 %Invalid weight => Divide by Zero Exception for Mean Calculation
                continue;
            end
            meanClassA = meanClassA / weightClassA;
            meanClassB = meanClassB / weightClassB;
            
            % Computing Between Class Variance and Storing its Minimum Value by Comparing its Previous Minimum value 
            betweenClassVariance = weightClassA*weightClassB*((meanClassA - meanClassB)^2);
            if betweenClassVariance > maxBetweenClassVariance
                maxBetweenClassVariance = betweenClassVariance;
                thresholdingValue = t;
            end
        end

        % Readjusting the Thresholding Value to its Actual Value From the
        % Estimated Interval 't' = thresholdingValue
        thresholdingValue = intervalBoundaries(thresholdingValue);
        if desiredThreshold == -1
            desiredThreshold = thresholdingValue;
        end               
        if thresholdingValue < desiredThreshold
            desiredThreshold = thresholdingValue;
        end
    end
    
    % Binarizing the Input Image as per the Threshold Values
    binaryImage = inputImage;
    for row=1:heightOfInputImage
        for column=1:widthOfInputImage        
            if binaryImage(row, column) < desiredThreshold
                binaryImage(row, column) = 255;
            else
                binaryImage(row, column) = 0;
            end
        end
    end
      
    fprintf("\nComputed Threshold Value using Modified Otsu Method: %d", desiredThreshold)

    %% Region Labelling Task using the Flood-Fill Algorithm
    %  Variable Definitions: 
    %  regionMarker = Number of Connected Components
    %  regionMarkerVectorValues = Unique Region Labels
    %  extractedConnectedComponentsMatrix = Labelled Region Matrices
    %  regionMatrix = Region Matrix Subjected to Folld-Filling Before Post-Processing
    
    regionMatrix = zeros(heightOfInputImage, widthOfInputImage);
    regionMarker = 0;
    for row=1:heightOfInputImage
        for column=1:widthOfInputImage        
            if binaryImage(row, column) > 0 && regionMatrix(row, column) == 0
                regionMarker = regionMarker + 1;
                colorRegion(row, column, regionMarker); %See EXTENDED/UTILITY section
            end
        end
    end    

    %% Region Post-Processing Task 
    %  Goal: To Remove Unwanted Regions which Violate Specific Rules 
    %  Rule-1: Each Row and Each Column for a Region cannot have more than 75% of pixels than its Maximum Height/Width respectively
    %  Rule-2: Each Row and Each Column for a Region cannot have less than 2 pixels-count respectively
    
    % Defining Utlility Temporary Values
    regionMatrixTemp = regionMatrix;
    regionMarkerTemp = regionMarker;
    regionMarkerVectorValues = 1:regionMarker; % Stores the unique region labels
    
    % Performing Violation Test for all Regions
    for regionInConsideration=1:regionMarkerTemp
        pixelColumnsViolation = 0;
        pixelRowsViolation = 0;

        % Calculating Row-Pixel Counts and the Number of Row Violations
        % Detected
        for column=1:widthOfInputImage
            pixelRowsLimitCounter = 0;
            if ismember(regionInConsideration, regionMarkerVectorValues) == 0
                continue;
            end
            for row=1:heightOfInputImage           
                if regionMatrixTemp(row, column) == regionInConsideration
                    pixelRowsLimitCounter = pixelRowsLimitCounter + 1; 
                end
            end
            if (pixelRowsLimitCounter < 2 && pixelRowsLimitCounter > 0) || (pixelRowsLimitCounter > (0.75 * heightOfInputImage))
                if pixelRowsViolation > 2
                    break;
                end
                pixelRowsViolation = pixelRowsViolation + 1;
            elseif pixelRowsLimitCounter ~=0
                pixelRowsViolation = pixelRowsViolation - 1;
            end
        end
        % Calculating Column-Pixel Counts and the Number of Column
        % Violations Detected
        for row=1:heightOfInputImage
            pixelColumnsLimitCounter = 0;
            if ismember(regionInConsideration, regionMarkerVectorValues) == 0
                continue;
            end
            for column=1:widthOfInputImage           
                if regionMatrixTemp(row, column) == regionInConsideration
                    pixelColumnsLimitCounter = pixelColumnsLimitCounter + 1; 
                end
            end
            if (pixelColumnsLimitCounter < 2 && pixelColumnsLimitCounter > 0) || (pixelColumnsLimitCounter > (0.75 * heightOfInputImage))
                if pixelRowsViolation > 2
                    break;
                end                
                pixelColumnsViolation = pixelColumnsViolation + 1;
            elseif pixelColumnsLimitCounter ~=0
                pixelColumnsViolation = pixelColumnsViolation - 1;
            end
        end
        
        % If the Number of Violations is a Positive Value, Remove the
        % Region and its Pixels 
        if pixelRowsViolation >= 0 || pixelColumnsViolation >= 0 
            regionMarker = regionMarker-1;
            regionMarkerVectorValues = regionMarkerVectorValues(regionMarkerVectorValues~=regionInConsideration);
            
            % Removal of Unwanted/Violated Region
            for rowRemoval=1:heightOfInputImage
                for colRemoval=1:widthOfInputImage
                    if regionMatrix(row, column) == regionInConsideration
                        regionMatrix(row, column) = 0;
                    end
                end
            end
        end
    end    
    
    fprintf("\nNumber of Regions Detected by Flood-Fill Algorithm After Post-Processing: %d", regionMarker);
    
    % Create 2 Region Matrices for Viewing Purposes and Statistics
    % Computation Respectively
    regionViewerMatrix = zeros(heightOfInputImage, widthOfInputImage);
    extractedConnectedComponentsMatrix = zeros(heightOfInputImage, widthOfInputImage);
    for regions=1:length(regionMarkerVectorValues)
        fillMatrixWithRegionElements(regionMarkerVectorValues(regions), 0); %See EXTENDED/UTILITY section
        fillMatrixWithRegionElements(regionMarkerVectorValues(regions), 1);
    end
    
    % Displaying FInal Region-Image
    figure(1);
    subplot(1,2,2);
    imshow(regionViewerMatrix, []);
    title("Thresholded Image")

    %% Statistics Computation Initiation Segment

    % Computing Statistics for Each Region
    for regions=1:length(regionMarkerVectorValues)
        % Initializing Runlength matrix and Areaofblob, Centroids and
        % Perimeter Statistics Variables
        runLengths = []; % Stores the (rowIndex, startColumnIndex, endCoolumnIndex) for the run
        runLengthStatus = 0; % Status Codes: 0 => Not Found, 1 => Running, 2 => Storing Run
        areaOfBlob = 0;
        xCentroid = 0;
        yCentroid = 0;
        perimeter = 0;
        elongation = 0;
        fractionalFill = 0;
        whitePixelValue = regionMarkerVectorValues(regions);
        % Computing some Statistical Metrics on the fly while Forming 
        % the Running Length Matrix
        for row=1:heightOfInputImage
            for column=1:widthOfInputImage
                if runLengthStatus == 1
                    if extractedConnectedComponentsMatrix(row, column) ~= whitePixelValue || column+1 == widthOfInputImage
                        if column+1 == widthOfInputImage
                            if startIndex(2) ~= column 
                                areaOfBlob = areaOfBlob + 1;
                                xCentroid = xCentroid + column;
                                yCentroid = yCentroid + row;
                            end
                            endIndex = column;
                        else
                            endIndex = column-1;
                        end
                        runLengthStatus = 3;
                    else                    
                        areaOfBlob = areaOfBlob + 1;
                        xCentroid = xCentroid + column;
                        yCentroid = yCentroid + row;
                        continue;
                    end
                end
                if runLengthStatus == 0
                    if extractedConnectedComponentsMatrix(row, column) == whitePixelValue
                        areaOfBlob = areaOfBlob + 1;
                        xCentroid = xCentroid + column;
                        yCentroid = yCentroid + row;
                        startIndex = [row, column];
                        runLengthStatus = 1;                
                        continue;
                    end
                end
                if runLengthStatus == 3
                    if isempty(runLengths)
                        runLengths = [startIndex(1), startIndex(2), endIndex];
                    else
                        runLengths = [runLengths; startIndex(1), startIndex(2), endIndex];
                    end
                    runLengthStatus = 0;
                end
            end
        end
        
        % Output Computed Statistics
        xCentroid = xCentroid/areaOfBlob;
        yCentroid = yCentroid/areaOfBlob;
        fprintf("\n\nComputed Centroid for '%d'-Labelled Region [Format - (x,y)]: (%f, %f)", whitePixelValue, xCentroid, yCentroid);        
        minMBR = [min(runLengths(:,2)), min(runLengths(:,1))];
        maxMBR = [max(runLengths(:,3)), max(runLengths(:,1))];
        fprintf("\nMinimum MBR Coordinate for '%d'-Labelled Region [Format - (x,y)]: (%d, %d)", whitePixelValue, minMBR(1), minMBR(2));
        fprintf("\nMaximum MBR Coordinate for '%d'-Labelled Region [Format - (x,y)]: (%d, %d)", whitePixelValue, maxMBR(1), maxMBR(2));
        fprintf("\nBlob Area for '%d'-Labelled Region: %d", whitePixelValue, areaOfBlob);        
        fractionalFill = areaOfBlob/((maxMBR(1) - minMBR(1))*(maxMBR(2) - minMBR(2)));
        fprintf("\nFractional Fill for '%d'-Labelled Region: %f", whitePixelValue, fractionalFill);        
        
        %% Perimeter Estimation using Implied Erosion-Based Approach
        % Assumption: No holes exist near the borders 
        paddedImage = [extractedConnectedComponentsMatrix(1, :); extractedConnectedComponentsMatrix(:, :); extractedConnectedComponentsMatrix(end, :)];
        paddedImage = [paddedImage(:, 1) , paddedImage(:, :), paddedImage(:, end)];
        [heightOfPaddedImage, widthOfPaddedImage] = size(paddedImage);
        erodedArea = 0;
        for row=2:heightOfPaddedImage-1
            for column=1:widthOfPaddedImage-1
                if paddedImage(row, column) == whitePixelValue
                    if paddedImage(row-1, column-1) == whitePixelValue && paddedImage(row-1, column) == whitePixelValue && paddedImage(row-1, column+1) == whitePixelValue && paddedImage(row, column-1) == whitePixelValue && paddedImage(row, column) == whitePixelValue && paddedImage(row, column+1) == whitePixelValue && paddedImage(row+1, column-1) == whitePixelValue && paddedImage(row+1, column) == whitePixelValue && paddedImage(row+1, column+1) == whitePixelValue 
                        erodedArea = erodedArea + 1;
                    end                    
                end
            end
        end
        perimeter = areaOfBlob - erodedArea;
        fprintf("\nEstimated Perimeter for '%d'-Labelled Region: %d", whitePixelValue, perimeter);
        elongation = perimeter^2/areaOfBlob;
        fprintf("\nCalculated Elongation Parameter for '%d'-Labelled Region: %f", whitePixelValue, elongation);
        
        
        %% Hole Detection Segment using Running-Length Code Strategy
        
        % Initiation of hole-finding variables
        [heightOfRunLength, widthOfRunLength] = size(runLengths);
        numberOfHoles = 0;
        universalHoleIndexManager = [];
        possibleHoleIndices = [];
        holeUpperPart = 0;
        holeLowerPart = 0;
        % Storing All Hole-Indices for Region in Universal-Hole-Index-Manager 
        for row=1:heightOfRunLength
            if ~isempty(possibleHoleIndices) && (holeUpperPart == 1 && holeLowerPart == 1)
                if isempty(universalHoleIndexManager)
                    universalHoleIndexManager = [possibleHoleIndices];
                else
                    universalHoleIndexManager = [universalHoleIndexManager; possibleHoleIndices];
                end
            end
            [heightOfManager, ~] = size(universalHoleIndexManager);
            for managerRow=1:heightOfManager
                if runLengths(row, :) == universalHoleIndexManager(managerRow, :)
                    continue;
                end
            end
            possibleHoleIndices = [];
            holeUpperPart = 0;
            holeLowerPart = 0;
            rowUpIndex = -1;
            rowDownIndex = -1;
            if row+1 ~= heightOfRunLength+1
                if runLengths(row, 1) == runLengths(row+1, 1)
                    possibleHoleIndices = [runLengths(row, 1) ,runLengths(row, 3), runLengths(row+1, 2)];
                    %look up
                    if row-1 > 0
                        for previousRowUpIndex=row:-1:1
                            for rowUpIndex=previousRowUpIndex-1:-1:0
                                if previousRowUpIndex-1 == 0
                                    rowUpIndex = -1;
                                    break;
                                elseif (runLengths(rowUpIndex, 1) == runLengths(previousRowUpIndex, 1)-1)
                                    break;
                                end
                            end
                            if rowUpIndex == -1
                                break;
                            end
                            if (runLengths(rowUpIndex, 2) > runLengths(previousRowUpIndex, 3)) || (runLengths(rowUpIndex, 3) < runLengths(previousRowUpIndex, 2))
                                holeUpperPart  = 1;
                                break; %hole completed found
                            else
                                if ~isempty(possibleHoleIndices)
                                    possibleHoleIndices = [possibleHoleIndices; runLengths(rowUpIndex, 1), runLengths(rowUpIndex, 2), runLengths(rowUpIndex, 3)];
                                else
                                    possibleHoleIndices = [runLengths(rowUpIndex, 1), runLengths(rowUpIndex, 2), runLengths(rowUpIndex, 3)];
                                end
                            end                        
                        end
                        if rowUpIndex == -1 %continue loop since up part not satisfied
                            continue;
                        end
                    else
                        continue;
                    end
                    %look down
                    if row+1 < heightOfRunLength+1
                        for previousRowDownIndex=row:heightOfRunLength+1
                            for rowDownIndex=previousRowDownIndex+1:heightOfRunLength
                                if previousRowDownIndex+1 == heightOfRunLength
                                    rowDownIndex = -1;
                                elseif rowDownIndex(runLengths(rowDownIndex, 1) == runLengths(previousRowDownIndex, 1)+1)
                                    break;
                                end
                            end
                            if rowDownIndex == -1
                                break;
                            end
                            if (runLengths(rowDownIndex, 2) > runLengths(previousRowDownIndex, 3)) || (runLengths(rowDownIndex, 3) < runLengths(previousRowDownIndex, 2))
                                holeLowerPart = 1;
                                break; %hole completed found
                            else
                                if ~isempty(possibleHoleIndices)
                                    possibleHoleIndices = [possibleHoleIndices; runLengths(rowDownIndex, 1), runLengths(rowDownIndex, 2), runLengths(rowDownIndex, 3)];
                                else
                                    possibleHoleIndices = [runLengths(rowDownIndex, 1), runLengths(rowDownIndex, 2), runLengths(rowDownIndex, 3)];
                                end
                            end                        
                        end
                        if rowDownIndex == -1  %continue loop since up part not satisfied
                            continue;
                        end
                    else
                        continue;
                    end
                    if holeUpperPart == 1 && holeLowerPart == 1
                       numberOfHoles = numberOfHoles + 1;
                    end
                end
            end
        end
        
        % Total Hole-Area Estimation
        areaOfHoles = 0;
        if ~isempty(runLengths) && ~isempty(universalHoleIndexManager)
            [heightOfManager, ~] = size(universalHoleIndexManager);
            for row=1:heightOfManager
                for holeIndex=universalHoleIndexManager(row, 2):universalHoleIndexManager(row, 3)
                    areaOfHoles = areaOfHoles + 1;
                end
            end
        end
        
        fprintf("\nNumber Of Holes Detected for '%d'-Labelled Region: %d", whitePixelValue, numberOfHoles);
        fprintf("\nEstimated Total Area of Holes for '%d'-Labelled Region: %d\n\n", whitePixelValue, areaOfHoles);        
        %% Running-Length Algorithm Outcome
        
        % Displaying Region in Consideration
        connectedComponentImage = zeros(heightOfInputImage, widthOfInputImage);
        for row=1:heightOfInputImage
            for column=1:widthOfInputImage
                if extractedConnectedComponentsMatrix(row, column) == whitePixelValue
                    connectedComponentImage(row, column) = 255;
                end
            end
        end
        titleForFigure = sprintf("Region-%d in Consideration", whitePixelValue);
        figure(whitePixelValue+1)
        subplot(1,3,1)
        imshow(connectedComponentImage, [])
        title(titleForFigure)        

        % Displaying Detected Holes by Running-Length Algorithm
        holesImage = zeros(heightOfInputImage, widthOfInputImage);
        if ~isempty(runLengths) && ~isempty(universalHoleIndexManager)
            universalHoleIndexManager = setdiff(universalHoleIndexManager, runLengths, 'rows');    
            [heightOfManager, ~] = size(universalHoleIndexManager);
            for row=1:heightOfManager
                for colorRow=universalHoleIndexManager(row,2):universalHoleIndexManager(row,3)
                    holesImage(universalHoleIndexManager(row, 1), colorRow) = 255; 
                end
            end
        end
        titleForFigure = sprintf("Holes Detected for Region-%d", whitePixelValue);
        figure(whitePixelValue+1)
        subplot(1,3,2)
        imshow(holesImage, [])
        title(titleForFigure);
        
        % Displaying Pixels Captured by Running-Length Algorithm
        runLengthImage = zeros(heightOfInputImage, widthOfInputImage);
        if ~isempty(runLengths) && ~isempty(universalHoleIndexManager)    
            for row=1:heightOfRunLength
                for colorRow=runLengths(row,2):runLengths(row,3)
                    runLengthImage(runLengths(row, 1), colorRow) = 255; 
                end
            end
        end
        titleForFigure = sprintf("Runnning-Length Pixels Detected for Region-%d", whitePixelValue);        
        figure(whitePixelValue+1)
        subplot(1,3,3)
        imshow(runLengthImage, [])
        title(titleForFigure)
    end
    
    %% Spacing Line
    fprintf("\n\n")
    %% EXTENDED/UTILITY FUNCTIONS
    
    % Flood-Fill Algorithm Recursive Code
    function a = colorRegion(pixelRow, pixelColumn, color)
        regionMatrix(pixelRow, pixelColumn) =  color;
        if pixelColumn-1 > 0 && binaryImage(pixelRow, pixelColumn-1) > 0 && regionMatrix(pixelRow, pixelColumn-1) == 0
            colorRegion(pixelRow, pixelColumn-1, color);
        end
        if pixelColumn+1 < widthOfInputImage+1 && binaryImage(pixelRow, pixelColumn+1) > 0 && regionMatrix(pixelRow, pixelColumn+1) == 0
            colorRegion(pixelRow, pixelColumn+1, color);
        end
        if pixelRow-1 > 0 && binaryImage(pixelRow-1, pixelColumn) > 0 && regionMatrix(pixelRow-1, pixelColumn) == 0
            colorRegion(pixelRow-1, pixelColumn, color);
        end
        if pixelRow+1 < heightOfInputImage+1 && binaryImage(pixelRow+1, pixelColumn) > 0 && regionMatrix(pixelRow+1, pixelColumn) == 0
            colorRegion(pixelRow+1, pixelColumn, color);
        end
        if pixelRow+1 < heightOfInputImage+1 && pixelColumn+1 < widthOfInputImage+1 && binaryImage(pixelRow+1, pixelColumn+1) > 0 && regionMatrix(pixelRow+1, pixelColumn+1) == 0
            colorRegion(pixelRow+1, pixelColumn+1, color); 
        end
        if pixelRow-1 > 0 && pixelColumn-1 > 0 && binaryImage(pixelRow-1, pixelColumn-1) > 0 && regionMatrix(pixelRow-1, pixelColumn-1) == 0
            colorRegion(pixelRow-1, pixelColumn-1, color);
        end
        if pixelRow-1 > 0 && pixelColumn+1 < widthOfInputImage+1 && binaryImage(pixelRow-1, pixelColumn+1) > 0 && regionMatrix(pixelRow-1, pixelColumn+1) == 0
            colorRegion(pixelRow-1, pixelColumn+1, color); 
        end
        if pixelRow+1 < heightOfInputImage+1 && pixelColumn-1 > 0 && binaryImage(pixelRow+1, pixelColumn-1) > 0 && regionMatrix(pixelRow+1, pixelColumn-1) == 0
            colorRegion(pixelRow+1, pixelColumn-1, color);                        
        end        
    end

    % Matrix Region Filler For Viewing 
    function fillMatrixWithRegionElements(regionValue, fillingMode)
        for regionRow=1:heightOfInputImage
            for regionColumn=1:widthOfInputImage        
                if regionMatrix(regionRow, regionColumn) == regionValue
                    if fillingMode == 0
                        regionViewerMatrix(regionRow, regionColumn) = 255;
                    else
                        extractedConnectedComponentsMatrix(regionRow, regionColumn) = regionValue;                        
                    end
                end
            end
        end
    end

end
