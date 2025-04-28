function [overlapXStart, overlapXEnd,overlapYStart,overlapYEnd] = PartsofImgForPairingFun(overlappingRegion,combinations,imageWidth,imageHeight,featureSearchArea,pixelSizeofImg,distanceMoved)
overlappingRegion = overlappingRegion / 100; % Convert percentage to fraction
overlapXStart = [];
overlapXEnd = [];
overlapYStart = [];
overlapYEnd = [];
areaConstantPixels = round((imageWidth - (distanceMoved/pixelSizeofImg))/2); %% (200 - (120))/2 = 40 pixels
disp(areaConstantPixels);
featureSearchAreaVal = round(imageWidth*(featureSearchArea/200)); %% 0.15*200 = 30 pixels
extraSearch = 0;
if featureSearchAreaVal > areaConstantPixels
    extraSearch = featureSearchAreaVal - areaConstantPixels;
    featureSearchAreaVal = areaConstantPixels;
end
disp(featureSearchAreaVal);
for i = 1:length(combinations)
    firstIndex = 0;
    secondIndex = 0;

    if combinations{i}(1) == combinations{i}(3)
        if combinations{i}(2) > combinations{i}(4)
            firstIndex = combinations{i}(1);
            secondIndex = combinations{i}(2);
        else
            firstIndex = combinations{i}(3);
            secondIndex = combinations{i}(4);
        end

        %overlapXStart = [overlapXStart, firstIndex * imageWidth + 1];
        %overlapXEnd = [overlapXEnd, firstIndex * imageWidth + imageWidth];
        %overlapYStart = [overlapYStart, secondIndex * imageHeight + 1];
        %overlapYEnd = [overlapYEnd, secondIndex * imageHeight + round(imageHeight * overlappingRegion)];

        %overlapXStart = [overlapXStart, firstIndex * imageWidth + 1];
        %overlapXEnd = [overlapXEnd, firstIndex * imageWidth + imageWidth];
        %overlapYStart = [overlapYStart, secondIndex * imageHeight - round(imageHeight * overlappingRegion) + 1];
        %overlapYEnd = [overlapYEnd, secondIndex * imageHeight];

        overlapXStart = [overlapXStart, firstIndex * imageWidth + 1];
        overlapXEnd = [overlapXEnd, firstIndex * imageWidth + imageWidth];
        overlapYStart = [overlapYStart, (secondIndex * imageHeight) + areaConstantPixels - featureSearchAreaVal + 1];
        overlapYEnd = [overlapYEnd, secondIndex * imageHeight + areaConstantPixels + featureSearchAreaVal+extraSearch];

        overlapXStart = [overlapXStart, firstIndex * imageWidth + 1];
        overlapXEnd = [overlapXEnd, firstIndex * imageWidth + imageWidth];
        overlapYStart = [overlapYStart, secondIndex * imageHeight - areaConstantPixels - featureSearchAreaVal - extraSearch + 1];
        overlapYEnd = [overlapYEnd, (secondIndex * imageHeight)- areaConstantPixels + featureSearchAreaVal];
    else
        if combinations{i}(1) > combinations{i}(3)
            firstIndex = combinations{i}(1);
            secondIndex = combinations{i}(2);
        else
            firstIndex = combinations{i}(3);
            secondIndex = combinations{i}(4);
        end
        %overlapXStart = [overlapXStart, firstIndex * imageWidth + 1];
        %overlapXEnd = [overlapXEnd, firstIndex * imageWidth + round(imageWidth * overlappingRegion)];
        %overlapYStart = [overlapYStart, secondIndex * imageHeight + 1];
        %overlapYEnd = [overlapYEnd, secondIndex * imageHeight + imageHeight];

        %overlapXStart = [overlapXStart, firstIndex * imageWidth - round(imageWidth * overlappingRegion) + 1];
        %overlapXEnd = [overlapXEnd, firstIndex * imageWidth];
        %overlapYStart = [overlapYStart, secondIndex * imageHeight + 1];
        %overlapYEnd = [overlapYEnd, secondIndex * imageHeight + imageHeight];

        overlapXStart = [overlapXStart, (firstIndex * imageWidth) + areaConstantPixels - featureSearchAreaVal + 1];
        overlapXEnd = [overlapXEnd, (firstIndex * imageWidth) + areaConstantPixels + featureSearchAreaVal+extraSearch];
        overlapYStart = [overlapYStart, secondIndex * imageHeight + 1];
        overlapYEnd = [overlapYEnd, secondIndex * imageHeight + imageHeight];

        overlapXStart = [overlapXStart, (firstIndex * imageWidth) - areaConstantPixels - featureSearchAreaVal - extraSearch + 1];
        overlapXEnd = [overlapXEnd, (firstIndex * imageWidth) - areaConstantPixels + featureSearchAreaVal];
        overlapYStart = [overlapYStart, secondIndex * imageHeight + 1];
        overlapYEnd = [overlapYEnd, secondIndex * imageHeight + imageHeight];
    end
end