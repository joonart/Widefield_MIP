% Global Coordinates Fun

% Number of images (or tiles)

% Find reference tile number
RefImgNum = 0;
for i = 1: length(numArrayY)
    if numArrayX(i) == 0 && numArrayY(i) == 0
        RefImgNum = i;
    end
end

globalCoorBool = false(length(imgNodestoConnect),1); % To Check if already called

stitchXStart = zeros(numImages,1);
stitchXEnd = zeros(numImages,1);
stitchYStart = zeros(numImages,1);
stitchYEnd = zeros(numImages,1);
stitchXStart(RefImgNum) = 1;
stitchXEnd(RefImgNum) = imageWidth;
stitchYStart(RefImgNum) = 1;
stitchYEnd(RefImgNum) = imageHeight;

loopBool = false;
nextImgNum = RefImgNum;
orderofgoing = [];
while ~all(globalCoorBool)
    loopBool = false;
    for i = 1:length(imgNodestoConnect)
        XStartPropagate = 1;
        %XEndPropagate = imageWidth;
        YStartPropagate = 1;
        %YEndPropagate = imageHeight;
        if imgNodestoConnect(i, 1) == nextImgNum || imgNodestoConnect(i, 2) == nextImgNum
            if globalCoorBool(i) == false 
                if imgNodestoConnect(i, 1) == nextImgNum
                    XStartPropagate = stitchXStart(nextImgNum);
                    YStartPropagate = stitchYStart(nextImgNum);
                    stitchXStart(imgNodestoConnect(i, 2))= XStartPropagate + (-1*translationParametersMst(i,1));
                    stitchXEnd(imgNodestoConnect(i, 2))= stitchXStart(imgNodestoConnect(i, 2)) + imageWidth - 1;
                    stitchYStart(imgNodestoConnect(i, 2))= YStartPropagate + (-1*translationParametersMst(i,2));
                    stitchYEnd(imgNodestoConnect(i, 2))= stitchYStart(imgNodestoConnect(i, 2)) + imageHeight - 1;

                    nextImgNum = imgNodestoConnect(i, 2);
                    globalCoorBool(i) = true;
                    loopBool = true;
                    orderofgoing = [orderofgoing,imgNodestoConnect(i, 2)];
                else
                    XStartPropagate = stitchXStart(nextImgNum);
                    YStartPropagate = stitchYStart(nextImgNum);
                    stitchXStart(imgNodestoConnect(i, 1))= XStartPropagate + (-1*translationParametersMst(i,1));
                    stitchXEnd(imgNodestoConnect(i, 1))= stitchXStart(imgNodestoConnect(i, 1)) + imageWidth - 1;
                    stitchYStart(imgNodestoConnect(i, 1))= YStartPropagate + (-1*translationParametersMst(i,2));
                    stitchYEnd(imgNodestoConnect(i, 1))= stitchYStart(imgNodestoConnect(i, 1)) + imageHeight - 1;
        
                    nextImgNum = imgNodestoConnect(i, 1);
                    globalCoorBool(i) = true;
                    loopBool = true;
                    orderofgoing = [orderofgoing,imgNodestoConnect(i, 1)];
                end
            end
        end
       
    end
    if loopBool == false
        nextImgNum = RefImgNum;
    end
end
Final = [stitchXStart,stitchYStart, stitchXEnd, stitchYEnd];

lowestXStart = 0;
lowestYStart = 0;
for i = 1:length(stitchXStart)
    if stitchXStart(i) < lowestXStart
        lowestXStart = stitchXStart(i);
    end
end
for i = 1:length(stitchYStart)
    if stitchYStart(i) < lowestYStart
        lowestYStart = stitchYStart(i);
    end
end
if lowestXStart  < 0
    for i = 1:length(stitchXStart)
        stitchXStart(i) = stitchXStart(i) + (-1*(lowestXStart-1));
        stitchXEnd(i) = stitchXEnd(i) + (-1*(lowestXStart-1));
    end
end
if lowestYStart  < 0
    for i = 1:length(stitchYStart)
        stitchYStart(i) = stitchYStart(i) + (-1*(lowestYStart-1));
        stitchYEnd(i) = stitchYEnd(i) + (-1*(lowestYStart-1));
    end
end
Final = [stitchXStart,stitchYStart, stitchXEnd, stitchYEnd];
maxCanvas = [max(stitchXEnd), max(stitchYEnd)];

orderofgoing = [RefImgNum, orderofgoing];
orderofgoing = flip(orderofgoing);
%............................................


% Max canvas size (inferred from the coordinates)
maxCanvasX = ceil(max(stitchXEnd));
maxCanvasY = ceil(max(stitchYEnd));

% Initialize the canvas with enough space for all images
finalStitchImg = uint8(zeros(maxCanvasY, maxCanvasX));

% Place images from H_images at calculated positions
for i = 1:numel(orderofgoing)
    % Read the current image from the folder using the file name
    img2 = imread(fullfile(hImagesFolder, imageFiles(orderofgoing(i)).name));

    % Convert 12-bit image to 8-bit if necessary
    if max(img2(:)) > 255
        img2 = uint8(double(img2) / 4095 * 255);  % Normalize 12-bit to 8-bit
    end

    % Round the start and end coordinates for placing the image on the final canvas
    yStart = round(stitchYStart(orderofgoing(i)));
    yEnd = round(stitchYEnd(orderofgoing(i)));
    xStart = round(stitchXStart(orderofgoing(i)));
    xEnd = round(stitchXEnd(orderofgoing(i)));

    % Ensure the image placement is within the bounds of the canvas
    yStart = max(1, yStart);
    xStart = max(1, xStart);
    yEnd = min(size(finalStitchImg, 1), yEnd);
    xEnd = min(size(finalStitchImg, 2), xEnd);

    % Extract the portion of the current image that fits within the bounds
    img2Sub = img2(1:(yEnd - yStart + 1), 1:(xEnd - xStart + 1));

    % Check if there is overlap with the existing image on the canvas
    canvasPart = finalStitchImg(yStart:yEnd, xStart:xEnd);
    
    % If there is no overlap, place the image directly
    finalStitchImg(yStart:yEnd, xStart:xEnd) = img2Sub;

    % If overlap occurs, only place the non-overlapping portion (if any)
    % Depending on the exact overlap logic, this can get more complicated. A simple method is
    % to leave the existing image if overlap occurs.
end

% Display the final stitched image
figure;
imshow(finalStitchImg);
title('Stitched Image (Cut and Place Images with Intersections)');