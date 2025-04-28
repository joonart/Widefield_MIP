function [numberofInlierForEach, translationParameters] = SurfTransformationsRansacFun(outputImage,SurfMThreshold,combinations,combinationsStr,overlapXStart, overlapXEnd,overlapYStart,overlapYEnd,numX,numY)

% Lets do SURF
% Create a copy for visualization
outputWithMatches = outputImage;
numberofInlierForEach = cell(length(combinations), 1);

% Initialize arrays to store matched points and translation parameters for each ROI pair
matchedPointsForEachPair = struct('points1', {}, 'points2', {}, 'ransacInliers1', {}, 'ransacInliers2', {}, 'translation', {});
translationParameters = [];



% Iterate over pairs of regions
for i = 1:2:length(overlapXStart)-1
    % Extract ROIs
    roi1 = outputImage(overlapYStart(i):overlapYEnd(i), overlapXStart(i):overlapXEnd(i), :);
    roi2 = outputImage(overlapYStart(i+1):overlapYEnd(i+1), overlapXStart(i+1):overlapXEnd(i+1), :);
    
    % Convert ROIs to double for accurate calculations.
    roi1rmse = double(roi1);
    roi2rmse = double(roi2);
    
    % Calculate the squared difference between pixel values.
    squaredDiff = (roi1rmse - roi2rmse).^2;
    
    % Calculate the mean of the squared differences.
    meanSquaredDiff = mean(squaredDiff(:));
    
    % Calculate the RMSE.
    rmseValue = sqrt(meanSquaredDiff);
    fprintf('RMSE (Average): %.4f\n', rmseValue);

    % Detect SURF features
    points1 = detectSURFFeatures(roi1, 'MetricThreshold', SurfMThreshold);
    points2 = detectSURFFeatures(roi2, 'MetricThreshold', SurfMThreshold);
    
    % Extract features
    [features1, validPoints1] = extractFeatures(roi1, points1);
    [features2, validPoints2] = extractFeatures(roi2, points2);
    
    % Match features
    indexPairs = matchFeatures(features1, features2, 'MaxRatio', 0.6, 'MatchThreshold', 1.4);
    
    % Retrieve matched points (adjust positions to original image coordinates)
    matchedPoints1 = validPoints1(indexPairs(:, 1));
    matchedPoints2 = validPoints2(indexPairs(:, 2));
    
    % Adjust points to global coordinates
    matchedPoints1.Location(:, 1) = matchedPoints1.Location(:, 1) + overlapXStart(i) - 1;
    matchedPoints1.Location(:, 2) = matchedPoints1.Location(:, 2) + overlapYStart(i) - 1;
    matchedPoints2.Location(:, 1) = matchedPoints2.Location(:, 1) + overlapXStart(i+1) - 1;
    matchedPoints2.Location(:, 2) = matchedPoints2.Location(:, 2) + overlapYStart(i+1) - 1;

    % Calculate distances between matched points
    distancesPoints = sqrt(sum((matchedPoints1.Location - matchedPoints2.Location).^2, 2));
    
    % Compute the median distance
    medianDistance = median(distancesPoints);
    
    % Identify points to keep (distance within medianDistance ± 2)
    toleranceDist = 2; % Define the tolerance range
    keepIdxDistance = (distancesPoints >= (medianDistance - toleranceDist)) & (distancesPoints <= (medianDistance + toleranceDist));
    
    % Filter matched points
    matchedPoints1Filtered = matchedPoints1(keepIdxDistance);
    matchedPoints2Filtered = matchedPoints2(keepIdxDistance);

    matchedPoints1FilteredTwice = matchedPoints1Filtered;
    matchedPoints2FilteredTwice = matchedPoints2Filtered;
    rowsToRemove1 = true(size(matchedPoints1Filtered, 1), 1);
    
    pixelShiftTolerance = 30;
   % Check for overlap in Y direction
    if overlapYStart(i) == overlapYStart(i + 1)
        for j = 1:(size(matchedPoints1Filtered.Location, 1))
            % Compare ransacInliers1 and ransacInliers2 with OR condition
            if abs(matchedPoints1Filtered.Location(j, 2) - matchedPoints2Filtered.Location(j, 2)) < pixelShiftTolerance
               rowsToRemove1(j) = true; % Mark this row for removal
            else
               rowsToRemove1(j) = false;
            end
        end
        matchedPoints1FilteredTwice = matchedPoints1Filtered(rowsToRemove1);
        matchedPoints2FilteredTwice = matchedPoints2Filtered(rowsToRemove1);
    end

    % Check for overlap in X direction
    if overlapXStart(i) == overlapXStart(i + 1)
        for k = 1:(size(matchedPoints2Filtered.Location, 1))
            % Compare ransacInliers1 and ransacInliers2 with OR condition
            if abs(matchedPoints1Filtered.Location(k, 1) - matchedPoints2Filtered.Location(k, 1)) < pixelShiftTolerance
               rowsToRemove1(k) = true; % Mark this row for removal
            else
               rowsToRemove1(k) = false;
            end
        
        end
        matchedPoints1FilteredTwice = matchedPoints1Filtered(rowsToRemove1);
        matchedPoints2FilteredTwice = matchedPoints2Filtered(rowsToRemove1);
    end
    
    % Debugging: Check number of matches
    fprintf('Pair %d: Number of matches = %d\n', i, size(matchedPoints1Filtered.Location, 1));
    
    % Apply RANSAC to filter matches
   

    %[tform, inlierIdx] = estimateGeometricTransform2D( ...
    %matchedPoints1FilteredTwice.Location, matchedPoints2FilteredTwice.Location, ...
    %'affine', 'MaxDistance', 1);
     try
            [tform, inlierIdx] = estimateGeometricTransform2D( ...
                matchedPoints1FilteredTwice, matchedPoints2FilteredTwice, ...
                'rigid', 'MaxDistance', 2, 'Confidence', 99.99, 'MaxNumTrials', 2000);
    
            % Extract inliers
            ransacInliers1 = matchedPoints1FilteredTwice.Location(inlierIdx, :);
            ransacInliers2 = matchedPoints2FilteredTwice.Location(inlierIdx, :);
    
            % Extract translational parameters from the transformation matrix
            translationParams = tform.T(3, 1:2); % Extract [tx, ty]
        
    catch ME
        % Handle RANSAC failure
        disp(['RANSAC failed for pair ', num2str(i)]);
        disp(ME.message);
        ransacInliers1 = [];
        ransacInliers2 = [];
        translationParams = [NaN, NaN];
    end
    
    %%%%%%%%%%%%
    if ~isempty(ransacInliers1) && ~isempty(ransacInliers2)
        % Adjust inlier coordinates relative to the ROIs
        ransacInliers1_ROI = ransacInliers1;
        ransacInliers1_ROI(:, 1) = ransacInliers1_ROI(:, 1) - overlapXStart(i) + 1;
        ransacInliers1_ROI(:, 2) = ransacInliers1_ROI(:, 2) - overlapYStart(i) + 1;
        
        ransacInliers2_ROI = ransacInliers2;
        ransacInliers2_ROI(:, 1) = ransacInliers2_ROI(:, 1) - overlapXStart(i + 1) + 1;
        ransacInliers2_ROI(:, 2) = ransacInliers2_ROI(:, 2) - overlapYStart(i + 1) + 1;
    
        % Visualize RANSAC inliers on ROI 1
        %figure;
        %imshow(roi1);
       % hold on;
        %plot(ransacInliers1_ROI(:, 1), ransacInliers1_ROI(:, 2), 'go', 'MarkerSize', 10, 'LineWidth', 1.5); % Green circles
       % title(['RANSAC Inliers on ROI 1 for Pair ', num2str(i)]);
       % hold off;
    
        % Visualize RANSAC inliers on ROI 2
       % figure;
       % imshow(roi2);
       % hold on;
       % plot(ransacInliers2_ROI(:, 1), ransacInliers2_ROI(:, 2), 'go', 'MarkerSize', 10, 'LineWidth', 1.5); % Green circles
       % title(['RANSAC Inliers on ROI 2 for Pair ', num2str(i)]);
       % hold off;
    
        % Optionally display matched points between ROI1 and ROI2 for reference
        %figure;
        %showMatchedFeatures(roi1, roi2, ransacInliers1_ROI, ransacInliers2_ROI, 'montage');
        %title(['Matched RANSAC Inliers Between ROI 1 and ROI 2 for Pair ', num2str(i)]);
    else
        disp(['No RANSAC inliers for Pair ', num2str(i)]);
    end
    %%%%%%%%%%%%%%
    % Debugging: Check number of inliers
    fprintf('Pair %d: Number of RANSAC inliers = %d\n', i, size(ransacInliers1, 1));

    % Ensure the index is an integer (e.g., using floor to avoid non-integer indices)
    indexfornumber = floor((i+1)/2); 
    
    % Now use the index to store the value in the cell array
    numberofInlierForEach{indexfornumber} = sprintf('%s,%d', combinationsStr{indexfornumber}, size(ransacInliers1, 1));


    % Store matched points, RANSAC inliers, and translation parameters for this pair
    matchedPointsForEachPair(end + 1).points1 = matchedPoints1.Location;
    matchedPointsForEachPair(end).points2 = matchedPoints2.Location;
    matchedPointsForEachPair(end).ransacInliers1 = ransacInliers1;
    matchedPointsForEachPair(end).ransacInliers2 = ransacInliers2;
    matchedPointsForEachPair(end).translation = translationParams;
    
    % Append translation parameters to array
    translationParameters = [translationParameters; translationParams];
end

disp('Initial Translation parameters (tx, ty) for each pair:');
disp(translationParameters);
% Visualize all RANSAC-filtered matches on the large image
figure;
imshow(outputWithMatches);
hold on;
%figure('Position', [100, 100, 1200, 600]); % Create a larger figure window


% Draw RANSAC inliers for each pair
for j = 1:length(matchedPointsForEachPair)
    inliers1 = matchedPointsForEachPair(j).ransacInliers1;
    inliers2 = matchedPointsForEachPair(j).ransacInliers2;
    
    % Draw matches for this pair
    for k = 1:size(inliers1, 1)
        pt1 = inliers1(k, :);
        pt2 = inliers2(k, :);
        plot([pt1(1), pt2(1)], [pt1(2), pt2(2)], 'g-', 'LineWidth', 1); % Line connecting inliers
        plot(pt1(1), pt1(2), 'ro', 'MarkerSize', 5, 'LineWidth', 1); % Point in ROI 1
        plot(pt2(1), pt2(2), 'bo', 'MarkerSize', 5, 'LineWidth', 1); % Point in ROI 2
    end
end
saveas(gcf, 'SURFmatchess.png'); % Saves as PNG (preserves quality)
print('SURFmatchess', '-dtiff', '-r600'); % Saves as TIFF with 600 DPI

hold off;
title('All RANSAC-Filtered Latest');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% save
imwrite(outputWithMatches,'SURFmatches.tif');
% Display translation parameters

avgTxandTy = zeros(length(translationParameters), 2);
count = zeros(length(translationParameters), 1);

for i = 1:length(translationParameters)
    if isnan(translationParameters(i))
        
        if combinations{i}(2)==combinations{i}(4) % x movement
            
            for j = 1:length(combinations) 
                if combinations{j}(2)==combinations{j}(4) && combinations{j}(2) == combinations{i}(2) % Checking in the x direction
                    if ~any(isnan(translationParameters(j,:)))
                        avgTxandTy(i,:) = avgTxandTy(i,:)+translationParameters(j,:);
                        count(i) = count(i)+1;
                    end
                end
            end
            if all(avgTxandTy(i,:) == 0)
                for j = 1:length(combinations)
                    if combinations{j}(2)==combinations{j}(4) X % direction in all row 
                        if ~any(isnan(translationParameters(j,:)))
                            avgTxandTy(i,:) = avgTxandTy(i,:)+translationParameters(j,:);
                            count(i) = count(i)+1;
                        end
                    end
                end
            end
            if avgTxandTy(i,:)==0
                avgTxandTy(i,:) = [NaN,NaN];
            end

        end
        if combinations{i}(1)==combinations{i}(3) % y move

            for j = 1:length(combinations)
                if combinations{j}(1)==combinations{j}(3) && combinations{j}(1) == combinations{i}(1)
                    if ~any(isnan(translationParameters(j,:)))
                        avgTxandTy(i,:) = avgTxandTy(i,:)+translationParameters(j,:);
                        count(i) = count(i)+1;
                    end
                end
            end
            if all(avgTxandTy(i,:) == 0)
                for j = 1:length(combinations)
                    if combinations{j}(1)==combinations{j}(3)
                        if ~any(isnan(translationParameters(j,:)))
                            avgTxandTy(i,:) = avgTxandTy(i,:)+translationParameters(j,:);
                            count(i) = count(i)+1;
                        end
                    end
                end
            end
           

        end
    else
        avgTxandTy(i,:)=[0,0];
        
    end
    if count(i) > 0
        avgTxandTy(i,:) = avgTxandTy(i,:) / count(i);
    else
        avgTxandTy(i,:) = [0, 0];
    end
end
for i = 1:length(translationParameters)
    if isnan(translationParameters(i))
        translationParameters(i,:)=avgTxandTy(i,:);
    end
end
%disp('each num')
%disp(numberofInlierForEach)
splitDataInlierForEach = arrayfun(@(x) split(x, ','), numberofInlierForEach, 'UniformOutput', false);

% Convert the result to a numeric matrix if needed
numericDatasplitDataInlierForEach = cellfun(@str2double, splitDataInlierForEach, 'UniformOutput', false);
% What if there are no features
% Background tiles

fifthElements = cellfun(@(x) x(5), numericDatasplitDataInlierForEach);
minInliercount = min(fifthElements(fifthElements > 0));
AddInliertoempty = 2;
if minInliercount<2
    AddInliertoempty = 2;
else
    AddInliertoempty = round(minInliercount/2);
end
fifthElements(fifthElements == 0) = AddInliertoempty;

for i= 1:length(numericDatasplitDataInlierForEach)
    if numericDatasplitDataInlierForEach{i}(5)==0
        numericDatasplitDataInlierForEach{i}(5)=fifthElements(i);
    end
end
numberofInlierForEach = cellfun(@(x) strjoin(string(x), ','), numericDatasplitDataInlierForEach, 'UniformOutput', false);

disp('Translation parameters (tx, ty) for each pair:');
disp(translationParameters);


