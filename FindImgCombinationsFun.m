function [combinations, combinationsStr] = FindImgCombinationsFun(M,N,numArrayX,numArrayY)
% Define the grid size
grid_size = [M, N]; % [rows, cols]


coordinates = [numArrayX(:), numArrayY(:)];

% Define the coordinates of the images
%coordinates = [0, 0; 1, 0; 2, 0; 0, 1; 1, 1; 2,1; 0,2; 1,2; 2,2];

% Initialize a cell array to store neighbors for each image
neighbors = cell(size(coordinates, 1), 1);

% Loop through each image
for i = 1:size(coordinates, 1)
    % Current image coordinates
    x = coordinates(i, 1);
    y = coordinates(i, 2);
    
    % Generate potential neighbors by adding and subtracting 1
    potential_neighbors = [
        x+1, y;
        x-1, y;
        x, y+1;
        x, y-1
    ];
    
    % Remove neighbors with negative values or values outside the grid
    valid_neighbors = potential_neighbors(...
        potential_neighbors(:, 1) >= 0 & potential_neighbors(:, 1) < grid_size(1) & ...
        potential_neighbors(:, 2) >= 0 & potential_neighbors(:, 2) < grid_size(2), :);
    
    % Store the valid neighbors
    neighbors{i} = valid_neighbors;
end
combinationsStr = {}; % Initialize as an empty cell array

% Display the results
for i = 1:length(neighbors)
    %fprintf('Neighbors for image at (%d, %d):\n', coordinates(i, 1), coordinates(i, 2));
    %disp(neighbors{i});
    for j = 1:size(neighbors{i}, 1) % Loop through each neighbor
        % Generate combination string
        combo = sprintf('%d,%d,%d,%d', coordinates(i, 1), coordinates(i, 2), neighbors{i}(j, 1), neighbors{i}(j, 2));
        combo2 = sprintf('%d,%d,%d,%d', neighbors{i}(j, 1), neighbors{i}(j, 2), coordinates(i, 1), coordinates(i, 2));
        
        % Append the combination to the cell array
        combinationsStr = [combinationsStr; {combo2}]; % Append as a cell (curly braces)
        for k = 1:length(combinationsStr)
          % Use strcmp to compare strings inside the cell
           if strcmp(combinationsStr{k}, combo)
        % Remove the element from the combinations cell array
           combinationsStr(k) = [];  % Remove the k-th element from the cell array
        break;  % Exit the loop once the item is removed
    end
end


    end
end
% Str to numeric
combinations = {};
for i =1:length(combinationsStr)
element = combinationsStr{i}; % For example, '1,1,,0,1'
% Split the string at the ',,' delimiter
splitStrings = strsplit(element, ',');
combinations = [combinations;str2double(splitStrings)];
end

