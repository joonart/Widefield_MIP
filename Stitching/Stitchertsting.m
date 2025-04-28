% Step 1: Create a file dialog to select the folder
folderPath = uigetdir('', 'Select Folder with Images');

% Check if the folder was selected
if folderPath == 0
    error('No folder selected.');
end

% Check if 'H_images' subfolder exists
hImagesFolder = fullfile(folderPath, 'H_images4_C_');
ptImagesFolder = fullfile(folderPath, 'PT_images4_C_');

eachPTimgSize = 126;  % size of pt images, Size to cut from photothermal images
%overlappingRegion = 50; % percentage of overlap between images
featureSearchArea = 44; % percentage of overlap between images
pixelSizeofImg = 0.176; % in micrometer
distanceMoved = 21 ; % in micrometer

%%%%%%%%%%%%% 

% Check for 'H_images' folder
if isfolder(hImagesFolder)
    % Get a list of all .tif files in the 'H_images' folder
    imageFiles = dir(fullfile(hImagesFolder, '*.tif'));
    %disp('Found .tif images in H_images folder:');
    for i = 1:length(imageFiles)
        disp(imageFiles(i).name);
    end
else
    error('The folder "H_images" was not found.');
end

%%%%%%%%%%% Sort
% Assume `imageFiles` is already obtained using dir
fileNames = {imageFiles.name}; % Get filenames as a cell array
disp('file Names');
disp(fileNames);
% Step 1: Extract the numeric part before 'h'
numParts = zeros(size(fileNames)); % Preallocate array for numeric values

for i = 1:length(fileNames)
    % Extract numeric part using regexp
    numPart = regexp(fileNames{i}, '^\d+(?=h)', 'match'); % Match digits before 'h'
    if ~isempty(numPart)
        numParts(i) = str2double(numPart{1}); % Convert to numeric
    else
        error('Filename does not contain the expected format: %s', fileNames{i});
    end
end

% Step 2: Sort the numeric parts
[sortedNums, sortedIdx] = sort(numParts);

% Step 3: Convert back to string with 'h.tif' suffix
sortedFileNames = arrayfun(@(x) sprintf('%dh.tif', x), sortedNums, 'UniformOutput', false);


%%%%%%%%%%%%%% sort


% Initialize the image list
imageFilesPT = []; %#ok<*NASGU>

% Check for 'H_images' folder
if isfolder(ptImagesFolder)
    % Get a list of all .tif files in the 'H_images' folder
    imageFilesPT = dir(fullfile(ptImagesFolder, '*.tif'));
    %disp('Found .tif images in H_images folder:');
    %for i = 1:length(imageFilesPT)
        %disp(imageFilesPT(i).name);
    %end
else
    error('The folder "H_images" was not found.');
end


%%%%%%%%%%% Sort
% Assume `imageFiles` is already obtained using dir
fileNamesPT = {imageFilesPT.name}; % Get filenames as a cell array
disp('File names of PT');
disp(fileNamesPT);
% Step 1: Extract the numeric part before 'h'
numPartsPT = zeros(size(fileNamesPT)); % Preallocate array for numeric values

for i = 1:length(fileNamesPT)
    % Extract numeric part using regexp
    numPartPT = regexp(fileNamesPT{i}, '^\d+(?=pt)', 'match'); % Match digits before 'pt'
    if ~isempty(numPartPT)
        numPartsPT(i) = str2double(numPartPT{1}); % Convert to numeric
    else
        error('Filename does not contain the expected format: %s', fileNamesPT{i});
    end
end

% Step 2: Sort the numeric parts
[sortedNumsPT, sortedIdxPT] = sort(numPartsPT);

% Step 3: Convert back to string with 'h.tif' suffix
sortedFileNamesPT = arrayfun(@(x) sprintf('%dpt.tif', x), sortedNumsPT, 'UniformOutput', false);
%%%%%%%%%%%%%% sort


imgnameandNum = {}; % Initialize as a cell array to save image nume and number
for i = 1:length(sortedFileNames)
    imgnameandNum = [imgnameandNum; {sortedFileNames{i}, num2str(i)}];
end


% Load the first image to get its size
firstImage = imread(fullfile(hImagesFolder, sortedFileNames{1}));
[imageHeight, imageWidth] = size(firstImage);  % Only height and width for grayscale images

% Determine the number of images
numImages = length(sortedFileNames);  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% User input for mosaic size (number of rows and columns)
prompt = {'Number of tiles in X direction:', 'Number of tiles in Y direction:'};
dlgTitle = 'Mosaic Size';
numLines = 1;
defaultAns = {num2str(ceil(sqrt(numImages))), num2str(ceil(numImages / ceil(sqrt(numImages))))}; % Default values based on image count
answer = inputdlg(prompt, dlgTitle, numLines, defaultAns);

numX = str2double(answer{1});
numY = str2double(answer{2});

% Calculate output image size (a large enough canvas)
outputWidth = numX * imageWidth;
outputHeight = numY * imageHeight;

% Initialize the large image (canvas) to hold the arranged images
outputImage = uint8(zeros(outputHeight, outputWidth));  % Grayscale image (8-bit)

% Generate the X and Y positions in a snake-like pattern
numArrayX = [];
numArrayY = [];

for i = 1:numY
    if mod(i, 2) == 1
        % Odd iteration: reverse order from num-1 to 0
        numArrayX = [numArrayX, (numX-1):-1:0];
    else
        % Even iteration: forward order from 0 to num-1
        numArrayX = [numArrayX, 0:(numX-1)];
    end
end

for i = numY-1:-1:0
    numArrayY = [numArrayY, repmat(i, 1, numX)];
end

XPos = numArrayX * imageWidth;
YPos = numArrayY * imageHeight;

% Place images from H_images at calculated positions
for i = 1:numImages
    % Read the current image
    img = imread(fullfile(hImagesFolder, sortedFileNames{i}));
    
    % Convert 12-bit image to 8-bit if necessary
    if max(img(:)) > 255
        img = uint8(double(img) / 4095 * 255);  % Normalize 12-bit to 8-bit
    end
    
    % Calculate the position in the canvas
    xStart = XPos(i) + 1;
    yStart = YPos(i) + 1;
    xEnd = xStart + imageWidth - 1;
    yEnd = yStart + imageHeight - 1;
    
    % Place the image in the canvas
    outputImage(yStart:yEnd, xStart:xEnd) = img;
end

% Create a cell array to store the coordinate labels
XYtoImgNumber = cell(length(numArrayX), 1);

% Loop through the arrays and assign labels
for i = 1:length(numArrayX)
    XYtoImgNumber{i} = sprintf('%d,%d,%d', i, numArrayX(i), numArrayY(i));
    % In the form -  image number,coordinateXCoordinateY
end

% End of giving number

% Display the final stitched image
%figure;
%imshow(outputImage);
%title('Stitched Image in Snake-like Pattern');

% Find touching images
[combinations,combinationsStr] = FindImgCombinationsFun(numX,numY,numArrayX,numArrayY);

%disp(combinations);


SurfMThreshold = 2;

% Function to find the coordinates for images to search SURF...............
[overlapXStart, overlapXEnd,overlapYStart,overlapYEnd] = PartsofImgForPairingFun(overlappingRegion,combinations,imageWidth,imageHeight,featureSearchArea,pixelSizeofImg,distanceMoved);
pairImgCoordinates = [overlapXStart',overlapYStart', overlapXEnd',overlapYEnd'];
% SURF and Tx Ty .................
[numberofInlierForEach, translationParameters] = SurfTransformationsRansacFun(outputImage,SurfMThreshold,combinations,combinationsStr,overlapXStart, overlapXEnd,overlapYStart,overlapYEnd,numX,numY);



% MST................................

[imgNodestoConnect,nodeWeights,translationParametersMst,pairsMstIndex] = GraphandMstFun(numImages,numberofInlierForEach,combinationsStr,XYtoImgNumber,numArrayX,numArrayY,translationParameters);

%removeCombinationIdX = false(max(pairsMstIndex),1);
%removeCombinationIdX(pairsMstIndex) = true;
combinationsMst = [];
for i =1:length(pairsMstIndex)
    combinationsMst = [combinationsMst; combinations(pairsMstIndex(i))];
end
% Stiching ..........................
disp('Finished MST')

% ............... Editing

XYtoImgNumberDouble = str2double(split(XYtoImgNumber, ','));

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

toleranceForNegative = 0;
stitchXStart = zeros(numImages,1);
stitchXEnd = zeros(numImages,1);
stitchYStart = zeros(numImages,1);
stitchYEnd = zeros(numImages,1);
stitchXStart(RefImgNum) = 1+toleranceForNegative;
stitchXEnd(RefImgNum) = imageWidth+toleranceForNegative;
stitchYStart(RefImgNum) = 1+toleranceForNegative;
stitchYEnd(RefImgNum) = imageHeight+toleranceForNegative;

loopBool = false;
nextImgNum = RefImgNum;
orderofgoing = [];
disp('Global coordinates running...')
while ~all(globalCoorBool)
    loopBool = false;
    for i = 1:length(imgNodestoConnect)
        XStartPropagate = 0;
        %XEndPropagate = imageWidth;
        YStartPropagate = 0;
        %YEndPropagate = imageHeight;
        if imgNodestoConnect(i, 1) == nextImgNum || imgNodestoConnect(i, 2) == nextImgNum

            if globalCoorBool(i) == false 

                if imgNodestoConnect(i, 1) == nextImgNum  %% is nextImgNum larger?

                    if combinationsMst{i}(1) == combinationsMst{i}(3) %% Don't get confused here this code repeats below
                        if XYtoImgNumberDouble(imgNodestoConnect(i, 2),3)>XYtoImgNumberDouble(nextImgNum,3)
                            XStartPropagate = stitchXStart(nextImgNum);
                            YStartPropagate = stitchYEnd(nextImgNum);  %%%%%%%%%%%%%%%%%%%%  Fishy..........
                            %disp('normal A');
                            %disp(nextImgNum);
                        else
                            XStartPropagate = stitchXStart(nextImgNum);
                            YStartPropagate = stitchYStart(nextImgNum);  %%%%%%%%%%%%%%%%%%%%  new
                            %disp('weird A');
                            %disp(nextImgNum);
                        end
                    else
                        if XYtoImgNumberDouble(imgNodestoConnect(i, 2),2)>XYtoImgNumberDouble(nextImgNum,2)
                            XStartPropagate = stitchXEnd(nextImgNum);
                            YStartPropagate = stitchYStart(nextImgNum);
                            %disp('normal B');
                            %disp(nextImgNum);
                        else
                            XStartPropagate = stitchXStart(nextImgNum);
                            YStartPropagate = stitchYStart(nextImgNum);
                            %disp('weird B');
                            %disp(nextImgNum);
                        end
                    end
                    if XYtoImgNumberDouble(imgNodestoConnect(i, 2),3)>XYtoImgNumberDouble(nextImgNum,3) || XYtoImgNumberDouble(imgNodestoConnect(i, 2),2)>XYtoImgNumberDouble(nextImgNum,2)
                        stitchXStart(imgNodestoConnect(i, 2))= XStartPropagate - (-1*translationParametersMst(i,1)) ; % +1 needed?
                        stitchXEnd(imgNodestoConnect(i, 2))= stitchXStart(imgNodestoConnect(i, 2)) + imageWidth - 1;
                        stitchYStart(imgNodestoConnect(i, 2))= YStartPropagate - (-1*translationParametersMst(i,2));
                        stitchYEnd(imgNodestoConnect(i, 2))= stitchYStart(imgNodestoConnect(i, 2)) + imageHeight - 1;
                        %disp('normal 1');
                    else
                        if combinationsMst{i}(1) == combinationsMst{i}(3) %% Y movement
                            stitchXStart(imgNodestoConnect(i, 2))=XStartPropagate+(-1*translationParametersMst(i,1));
                            stitchYEnd(imgNodestoConnect(i, 2))=YStartPropagate+(-1*translationParametersMst(i,2))-1;
                            stitchXEnd(imgNodestoConnect(i, 2)) = stitchXStart(imgNodestoConnect(i, 2))+imageWidth-1;
                            stitchYStart(imgNodestoConnect(i, 2)) = stitchYEnd(imgNodestoConnect(i, 2))-imageHeight+1;
                            %disp('weird 1');
                            %disp([stitchXStart(imgNodestoConnect(i, 2)), stitchYStart(imgNodestoConnect(i, 2)) ,stitchXEnd(imgNodestoConnect(i, 2)), stitchYEnd(imgNodestoConnect(i, 2))]);
                        else  %% X movement
                            stitchXEnd(imgNodestoConnect(i, 2))=XStartPropagate+(-1*translationParametersMst(i,1)) -1;
                            stitchYStart(imgNodestoConnect(i, 2))=YStartPropagate+(-1*translationParametersMst(i,2));
                            stitchXStart(imgNodestoConnect(i, 2)) = stitchXEnd(imgNodestoConnect(i, 2))-imageWidth+1;
                            stitchYEnd(imgNodestoConnect(i, 2)) = stitchYStart(imgNodestoConnect(i, 2))+imageHeight-1;
                            %disp('weird 2');
                        end
                  
                    end
                    nextImgNum = imgNodestoConnect(i, 2);
                    globalCoorBool(i) = true;
                    loopBool = true;
                    orderofgoing = [orderofgoing,imgNodestoConnect(i, 2)];
                else  %% imgNodestoConnect(i, 2) == nextImgNum
                    if combinationsMst{i}(1) == combinationsMst{i}(3) %% Y movement
                        if XYtoImgNumberDouble(imgNodestoConnect(i, 1),3)>XYtoImgNumberDouble(nextImgNum,3)
                            XStartPropagate = stitchXStart(nextImgNum);
                            YStartPropagate = stitchYEnd(nextImgNum);  %%%%%%%%%%%%%%%%%%%%  Fishy..........
                            %disp('normal C');
                            %disp(nextImgNum);
                        else  % Weird way
                            XStartPropagate = stitchXStart(nextImgNum);
                            YStartPropagate = stitchYStart(nextImgNum);  %%%%%%%%%%%%%%%%%%%%  new
                            %disp('weird c');
                            %disp(nextImgNum);
                        end
                    else  % X movement
                        if XYtoImgNumberDouble(imgNodestoConnect(i, 1),2)>XYtoImgNumberDouble(nextImgNum,2)
                            XStartPropagate = stitchXEnd(nextImgNum);
                            YStartPropagate = stitchYStart(nextImgNum);
                            %disp('normal d');
                            %disp(nextImgNum);
                        else
                            XStartPropagate = stitchXStart(nextImgNum);
                            YStartPropagate = stitchYStart(nextImgNum);
                            %disp('weird d');
                            %disp(nextImgNum);
                        end
                    end
                    if XYtoImgNumberDouble(imgNodestoConnect(i, 1),3)>XYtoImgNumberDouble(nextImgNum,3) || XYtoImgNumberDouble(imgNodestoConnect(i, 1),2)>XYtoImgNumberDouble(nextImgNum,2)
                        stitchXStart(imgNodestoConnect(i, 1))= XStartPropagate - (-1*translationParametersMst(i,1));
                        stitchXEnd(imgNodestoConnect(i, 1))= stitchXStart(imgNodestoConnect(i, 1)) + imageWidth - 1;
                        stitchYStart(imgNodestoConnect(i, 1))= YStartPropagate - (-1*translationParametersMst(i,2)) ;
                        stitchYEnd(imgNodestoConnect(i, 1))= stitchYStart(imgNodestoConnect(i, 1)) + imageHeight - 1;
                        %disp('normal 2a');
                    else
                        if combinationsMst{i}(1) == combinationsMst{i}(3) %% Y movement
                            stitchXStart(imgNodestoConnect(i, 1))=XStartPropagate+(-1*translationParametersMst(i,1));
                            stitchYEnd(imgNodestoConnect(i, 1))=YStartPropagate+(-1*translationParametersMst(i,2))-1;
                            stitchXEnd(imgNodestoConnect(i, 1)) = stitchXStart(imgNodestoConnect(i, 1))+imageWidth-1;
                            stitchYStart(imgNodestoConnect(i, 1)) = stitchYEnd(imgNodestoConnect(i, 1))-imageHeight+1;
                            %disp('weird 2a');
                        else  %% X movement
                            stitchXEnd(imgNodestoConnect(i, 1))=XStartPropagate+(-1*translationParametersMst(i,1)) -1;
                            stitchYStart(imgNodestoConnect(i, 1))=YStartPropagate+(-1*translationParametersMst(i,2));
                            stitchXStart(imgNodestoConnect(i, 1)) = stitchXEnd(imgNodestoConnect(i, 1))-imageWidth+1;
                            stitchYEnd(imgNodestoConnect(i, 1)) = stitchYStart(imgNodestoConnect(i, 1))+imageHeight-1;
                            %disp('weird 3a');
                        end
                    end
        
                    nextImgNum = imgNodestoConnect(i, 1);
                    globalCoorBool(i) = true;
                    loopBool = true;
                    orderofgoing = [orderofgoing,imgNodestoConnect(i, 1)];
                end
                %disp(XStartPropagate); 
                %disp(YStartPropagate);
            end
        end
       
    end
    %disp('Order of going..')%%%%%%%%%%%
    %disp(orderofgoing)
    if loopBool == false
       indicesFalse = find(globalCoorBool == 0);
       %disp(indicesFalse);
       for z = 1: length(indicesFalse)
           if stitchXStart(imgNodestoConnect(indicesFalse(z), 1)) ~= 0
                nextImgNum = imgNodestoConnect(indicesFalse(z), 1);
                break;
                
           elseif stitchXStart(imgNodestoConnect(indicesFalse(z), 2)) ~= 0
                nextImgNum = imgNodestoConnect(indicesFalse(z), 2);
               
                break;
           end
       end
    end
end
Final = [stitchXStart,stitchYStart, stitchXEnd, stitchYEnd];
disp('Finished Global coordinates');
%disp(Final);%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lowestXStart = 1;
lowestYStart = 1;
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
        stitchXStart(i) = stitchXStart(i) + (-1*(lowestXStart-1))+1;
       
        
        stitchXEnd(i)= stitchXStart(i)+imageWidth-1;
        

    end  
end
if lowestYStart  < 0
    for i = 1:length(stitchYStart)
        stitchYStart(i) = stitchYStart(i) + (-1*(lowestYStart-1))+1;
        stitchYEnd(i)= stitchYStart(i)+imageHeight-1;
    end
end
if lowestXStart > 0 && lowestXStart < 1
    for i = 1:length(stitchXStart)
        stitchXStart(i) = stitchXStart(i) + ((lowestXStart+1))+1;
        stitchXEnd(i) = stitchXEnd(i) + ((lowestXStart+1))+1;
    end  
end
if lowestYStart > 0 && lowestYStart < 1
    for i = 1:length(stitchYStart)
        stitchYStart(i) = stitchYStart(i) + ((lowestYStart+1))+1;
        stitchYEnd(i) = stitchYEnd(i) + ((lowestYStart+1))+1;
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
    img2 = imread(fullfile(hImagesFolder, sortedFileNames{orderofgoing(i)}));

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
%colormap('jet')
%title('Stitched Image (Cut and Place Images with Intersections)');

disp(Final)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
finalStitchImgPT = uint16(zeros(maxCanvasY, maxCanvasX));
% Place images from H_images at calculated positions
for i = 1:numel(orderofgoing)
    % Read the current image from the folder using the file name
    img3 = imread(fullfile(ptImagesFolder, sortedFileNamesPT{orderofgoing(i)}));

    % Convert 12-bit image to 8-bit if necessary
    %if max(img2(:)) > 255
    %    img2 = uint8(double(img2) / 4095 * 255);  % Normalize 12-bit to 8-bit
    %end

    % Round the start and end coordinates for placing the image on the final canvas
    yStart = round(stitchYStart(orderofgoing(i)));
    yEnd = round(stitchYEnd(orderofgoing(i)));
    xStart = round(stitchXStart(orderofgoing(i)));
    xEnd = round(stitchXEnd(orderofgoing(i)));

    % Ensure the image placement is within the bounds of the canvas
    yStart = max(1, yStart);
    xStart = max(1, xStart);
    yEnd = min(size(finalStitchImgPT, 1), yEnd);
    xEnd = min(size(finalStitchImgPT, 2), xEnd);

    % Extract the portion of the current image that fits within the bounds
    img3Sub = img3(1:(yEnd - yStart + 1), 1:(xEnd - xStart + 1));

    % Check if there is overlap with the existing image on the canvas
    canvasPart = finalStitchImgPT(yStart:yEnd, xStart:xEnd);
    
    % If there is no overlap, place the image directly
    finalStitchImgPT(yStart:yEnd, xStart:xEnd) = img3Sub;

    % If overlap occurs, only place the non-overlapping portion (if any)
    % Depending on the exact overlap logic, this can get more complicated. A simple method is
    % to leave the existing image if overlap occurs.
end

imwrite(finalStitchImgPT,'StitchedPTImg.tif');
%%%%%%%%%%%%%%%%%%%%%  Small PT  %%%%%%%%%%%%%%%%%%%%%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


sumandOrder = [];
sumPixelsmin = 0;
sumPixelsmax = 0;
for i = 1:length(sortedFileNamesPT)
    % Read the current image from the folder using the file name
    img3 = imread(fullfile(ptImagesFolder, sortedFileNamesPT{i}));
    
    % Get the size of the image
    [imgHeight, imgWidth, ~] = size(img3);

    % Compute the center coordinates
    center_x = floor(imgWidth / 2);
    center_y = floor(imgHeight / 2);
    
    % Compute the cropping indices
    half_width = round(eachPTimgSize/2); % Half of 100 (since 100x100 is the desired size)
    x_StartS = max(center_x - half_width, 1); % Ensure within bounds
    y_StartS = max(center_y - half_width, 1);
    x_EndS = min(center_x + half_width, imgWidth);
    y_EndS = min(center_y + half_width, imgHeight);

    img3 = img3(y_StartS:y_EndS, x_StartS:x_EndS, :);
    sumandOrder = [sumandOrder; sum(img3(:)),i];
   
    
end

sumandOrder=sortrows(sumandOrder, 1);
orderofgoings = sumandOrder(:,2);
finalStitchImgPTs = uint16(zeros(maxCanvasY, maxCanvasX));

% Place images from H_images at calculated positions
for i = 1:numel(orderofgoings)
    % Read the current image from the folder using the file name
    img3 = imread(fullfile(ptImagesFolder, sortedFileNamesPT{orderofgoings(i)}));

    % Get the size of the image
    [imgHeight, imgWidth, ~] = size(img3);

    % Compute the center coordinates
    center_x = floor(imgWidth / 2);
    center_y = floor(imgHeight / 2);
    
    % Compute the cropping indices
    half_width = round(eachPTimgSize/2); % Half of 100 (since 100x100 is the desired size)
    x_StartS = max(center_x - half_width, 1); % Ensure within bounds
    y_StartS = max(center_y - half_width, 1);
    x_EndS = min(center_x + half_width, imgWidth);
    y_EndS = min(center_y + half_width, imgHeight);

    img3 = img3(y_StartS:y_EndS, x_StartS:x_EndS, :);

    % Convert 12-bit image to 8-bit if necessary
    %if max(img2(:)) > 255
    %    img2 = uint8(double(img2) / 4095 * 255);  % Normalize 12-bit to 8-bit
    %end

    % Round the start and end coordinates for placing the image on the final canvas
    

    xStart = round((stitchXStart(orderofgoings(i)) + stitchXEnd(orderofgoings(i))) / 2 - (eachPTimgSize / 2));
    yStart = round((stitchYStart(orderofgoings(i)) + stitchYEnd(orderofgoings(i))) / 2 - (eachPTimgSize / 2));
    xEnd = round((stitchXStart(orderofgoings(i)) + stitchXEnd(orderofgoings(i))) / 2 + (eachPTimgSize / 2));
    yEnd = round((stitchYStart(orderofgoings(i)) + stitchYEnd(orderofgoings(i))) / 2 + (eachPTimgSize / 2));

    % Ensure the image placement is within the bounds of the canvas
    yStart = max(1, yStart);
    xStart = max(1, xStart);
    yEnd = min(size(finalStitchImgPTs, 1), yEnd);
    xEnd = min(size(finalStitchImgPTs, 2), xEnd);

    % Extract the portion of the current image that fits within the bounds
    img3Sub = img3(1:(yEnd - yStart + 1), 1:(xEnd - xStart + 1));

    % Check if there is overlap with the existing image on the canvas
    canvasPart = finalStitchImgPTs(yStart:yEnd, xStart:xEnd);

    
    
    
    finalStitchImgPTs(yStart:yEnd, xStart:xEnd) = img3Sub;
    
    % If there is no overlap, place the image directly
    %%%%%%%

    % If overlap occurs, only place the non-overlapping portion (if any)
    % Depending on the exact overlap logic, this can get more complicated. A simple method is
    % to leave the existing image if overlap occurs.
end

imwrite(finalStitchImgPTs,'StitchedPTsImg.tif');
%figure;
%imshow(finalStitchImgPTs, []);
%colormap('hot'); 






finalStitchImgh = uint16(zeros(maxCanvasY, maxCanvasX));

% Place images from H_images at calculated positions
for i = 1:numel(orderofgoings)
    % Read the current image from the folder using the file name
    img4 = imread(fullfile(hImagesFolder, sortedFileNames{orderofgoings(i)}));
%%%%%%%%%%%%  16 to 8 bit
    %if max(img4(:)) > 255
    %    img4 = uint8(double(img4) / 4095 * 255);  % Normalize 12-bit to 8-bit
    %end

    % Get the size of the image
    [imgHeight, imgWidth, ~] = size(img4);

    % Compute the center coordinates
    center_x = floor(imgWidth / 2);
    center_y = floor(imgHeight / 2);
    
    % Compute the cropping indices
    half_width = round(eachPTimgSize/2); % Half of 100 (since 100x100 is the desired size)
    x_StartS = max(center_x - half_width, 1); % Ensure within bounds
    y_StartS = max(center_y - half_width, 1);
    x_EndS = min(center_x + half_width, imgWidth);
    y_EndS = min(center_y + half_width, imgHeight);

    img4 = img4(y_StartS:y_EndS, x_StartS:x_EndS, :);

 
    

    xStart = round((stitchXStart(orderofgoings(i)) + stitchXEnd(orderofgoings(i))) / 2 - (eachPTimgSize / 2));
    yStart = round((stitchYStart(orderofgoings(i)) + stitchYEnd(orderofgoings(i))) / 2 - (eachPTimgSize / 2));
    xEnd = round((stitchXStart(orderofgoings(i)) + stitchXEnd(orderofgoings(i))) / 2 + (eachPTimgSize / 2));
    yEnd = round((stitchYStart(orderofgoings(i)) + stitchYEnd(orderofgoings(i))) / 2 + (eachPTimgSize / 2));

    

    % Ensure the image placement is within the bounds of the canvas
    yStart = max(1, yStart);
    xStart = max(1, xStart);
    yEnd = min(size(finalStitchImgh, 1), yEnd);
    xEnd = min(size(finalStitchImgh, 2), xEnd);

    % Extract the portion of the current image that fits within the bounds
    img4Sub = img4(1:(yEnd - yStart + 1), 1:(xEnd - xStart + 1));

    % Check if there is overlap with the existing image on the canvas
    canvasPart = finalStitchImgh(yStart:yEnd, xStart:xEnd);

    
    
    finalStitchImgh(yStart:yEnd, xStart:xEnd) = img4Sub;
    end


%figure('Position', [100, 100, 1200, 600]); % Create a larger figure window
imwrite(finalStitchImgh,'StitchedsImgh.tif');








%%%%%%%%%%%%%%%% hHHHHooooooTTTTTTTTTTTTTTT



Subpixelstitch_H = uint16(zeros(maxCanvasY, maxCanvasX));
showarray = [];
% TEst for subpixel placementc %%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:numel(orderofgoings)
    % Read the current image from the folder using the file name
    img4 = imread(fullfile(hImagesFolder, sortedFileNames{orderofgoings(i)}));
%%%%%%%%%%%%  16 to 8 bit
    %if max(img4(:)) > 255
    %    img4 = uint8(double(img4) / 4095 * 255);  % Normalize 12-bit to 8-bit
    %end

    % Get the size of the image
    [imgHeight, imgWidth, ~] = size(img4); % 200x200

    % Compute the center coordinates
    center_x = floor(imgWidth / 2); % 200/2 = 100
    center_y = floor(imgHeight / 2); % 200/2 = 100
    
    % Compute the cropping indices
    half_width = round(eachPTimgSize/2); % 124/2 = 62
    x_StartS = max(center_x - half_width, 1); % Ensure within bounds
    y_StartS = max(center_y - half_width, 1);
    x_EndS = min(center_x + half_width, imgWidth);
    y_EndS = min(center_y + half_width, imgHeight);

    img4 = img4(y_StartS:y_EndS-1, x_StartS:x_EndS-1, :);

 
    

    xStart = max(1, (stitchXStart(orderofgoings(i)) + stitchXEnd(orderofgoings(i))) / 2 - (eachPTimgSize / 2));
    yStart = max(1, (stitchYStart(orderofgoings(i)) + stitchYEnd(orderofgoings(i))) / 2 - (eachPTimgSize / 2));
    xEnd = min(maxCanvasX, xStart + eachPTimgSize - 1);
    yEnd = min(maxCanvasY, yStart + eachPTimgSize - 1);

   
    


    % Check if there is overlap with the existing image on the canvas
    %canvasPart = Subpixelstitch_H(yStart:yEnd, xStart:xEnd);

    % Ensure indices are within bounds
    yStartIdx = max(1, floor(yStart));
    yEndIdx = min(maxCanvasY, floor(yEnd));
    xStartIdx = max(1, floor(xStart));
    xEndIdx = min(maxCanvasX, floor(xEnd));

    % Assign to canvas
    Subpixelstitch_H(yStartIdx:yEndIdx, xStartIdx:xEndIdx, :) = img4;

    end
    % If there is no overlap, place the image directly
    %%%%%%%



%figure('Position', [100, 100, 1200, 600]); % Create a larger figure window
imwrite(Subpixelstitch_H,'improvedStitch_H.tif');


% Display the first image
figure('Name', 'Sub pixel test', 'NumberTitle', 'off'); % Create a new figure window
imagesc(Subpixelstitch_H);
colormap(gca,'gray'); % Apply 'jet' colormap
colorbar;
title('Sub pixels');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%% PTTTTTTTTTTTTTTTTTTTTTT


Subpixelstitch_PT = uint16(zeros(maxCanvasY, maxCanvasX));
showarray = [];
% TEst for subpixel placementc %%%%%%%%%%%%%%%%%%%%%%%%%
for i = 1:numel(orderofgoings)
    % Read the current image from the folder using the file name
    img6 = imread(fullfile(ptImagesFolder, sortedFileNamesPT{orderofgoings(i)}));
%%%%%%%%%%%%  16 to 8 bit
    %if max(img4(:)) > 255
    %    img4 = uint8(double(img4) / 4095 * 255);  % Normalize 12-bit to 8-bit
    %end

    % Get the size of the image
    [imgHeight, imgWidth, ~] = size(img6); % 200x200

    % Compute the center coordinates
    center_x = floor(imgWidth / 2); % 200/2 = 100
    center_y = floor(imgHeight / 2); % 200/2 = 100
    
    % Compute the cropping indices
    half_width = round(eachPTimgSize/2); % 124/2 = 62
    x_StartS = max(center_x - half_width, 1); % Ensure within bounds
    y_StartS = max(center_y - half_width, 1);
    x_EndS = min(center_x + half_width, imgWidth);
    y_EndS = min(center_y + half_width, imgHeight);

    img6 = img6(y_StartS:y_EndS-1, x_StartS:x_EndS-1, :);

 %%%%%
     % Define the border value
    %borderValue = uint16(4095);
    
    % Set the first and last row to 4095
   % img6(1, :) = borderValue;
   % img6(end, :) = borderValue;
    
    % Set the first and last column to 4095
   % img6(:, 1) = borderValue;
   % img6(:, end) = borderValue;
 %%%%%%%%%%%   
    % Blend the original image over the background
    %img6 = uint16(mask .* double(img6) + ~mask .* double(background));

    xStart = max(1, (stitchXStart(orderofgoings(i)) + stitchXEnd(orderofgoings(i))) / 2 - (eachPTimgSize / 2));
    yStart = max(1, (stitchYStart(orderofgoings(i)) + stitchYEnd(orderofgoings(i))) / 2 - (eachPTimgSize / 2));
    xEnd = min(maxCanvasX, xStart + eachPTimgSize - 1);
    yEnd = min(maxCanvasY, yStart + eachPTimgSize - 1);

   
    


    % Check if there is overlap with the existing image on the canvas
    %canvasPart = Subpixelstitch_H(yStart:yEnd, xStart:xEnd);

    % Ensure indices are within bounds
    yStartIdx = max(1, floor(yStart));
    yEndIdx = min(maxCanvasY, floor(yEnd));
    xStartIdx = max(1, floor(xStart));
    xEndIdx = min(maxCanvasX, floor(xEnd));

    % Assign to canvas
    Subpixelstitch_PT(yStartIdx:yEndIdx, xStartIdx:xEndIdx, :) = img6;

    end
    % If there is no overlap, place the image directly
    %%%%%%%



%figure('Position', [100, 100, 1200, 600]); % Create a larger figure window
imwrite(Subpixelstitch_PT,'improvedStitch_PT.tif');

figure('Name', 'improved PT', 'NumberTitle', 'off'); % Create a new figure window
imagesc(Subpixelstitch_PT);
colormap(gca,'gray'); % Apply 'jet' colormap
colorbar;
title('Sub pixels');








% Display the first image
figure('Name', 'Hot frame stitched', 'NumberTitle', 'off'); % Create a new figure window
imagesc(finalStitchImgh);
colormap(gca,'gray'); % Apply 'jet' colormap
colorbar;
title('Hot frame');

% Display the second image
figure('Name', 'Photothermal images', 'NumberTitle', 'off'); % Create another figure window
imagesc(finalStitchImgPTs); % Replace 'anotherImage' with your second image variable
colormap(gca,'jet'); % hotApply 'parula' colormap
colorbar;
title('PT image');

