function [imgNodestoConnect,nodeWeights,translationParametersMst,pairsMstIndex] = GraphandMstFun(numImages,numberofInlierForEach,combinationsStr,XYtoImgNumber,numArrayX,numArrayY,translationParameters)

% Number of images (or tiles)
n_tiles = numImages;

inlier_counts = [];
indexandNumMatch = cellfun(@(x) str2double(strsplit(x, ',')), numberofInlierForEach, 'UniformOutput', false);

for i = 1:length(numberofInlierForEach)
    inlier_counts = [inlier_counts;indexandNumMatch{i}(5)];

end
%disp('Inlier counts')
%disp(inlier_counts)

weights = 1 ./ inlier_counts;

% Define the normalization range
minNorm = 0.01; % Minimum normalized value
maxNorm = 1;    % Maximum normalized value

% Normalize weights to the range [minNorm, maxNorm]
max_weight = max(weights);
min_weight = min(weights);

% Apply the normalization formula
normalized_weights = minNorm + ((weights - min_weight) / (max_weight - min_weight)) * (maxNorm - minNorm);
disp(normalized_weights);
% Initialize the adjacency matrix for the graph
W = zeros(n_tiles);

pairs = [];
for i = 1: length(combinationsStr)
    firstImgNum = 0;
    secondImgNum = 0;
    strIndex1 = strfind(combinationsStr{i}, ',');
    firstImageIndex = combinationsStr{i}(1:strIndex1(2)-1);
    secondImageIndex = combinationsStr{i}(strIndex1(2)+1:end);
    for j = 1 : length(XYtoImgNumber)
        strIndex2 = strfind(XYtoImgNumber{j}, ',');
        imageIndexRef = XYtoImgNumber{j}(strIndex2(1)+1:end);
        imagenumberStr = XYtoImgNumber{j}(1:strIndex2(1)-1);
        if imageIndexRef == firstImageIndex
            firstImgNum = str2double(imagenumberStr);
        end
        if imageIndexRef == secondImageIndex
            secondImgNum = str2double(imagenumberStr);
        end
    end
    pairs = [pairs; firstImgNum,secondImgNum];
end
%disp('pairs')
%disp(pairs) %%%%%%%%%%%%%%%%
% Pair indices for the inlier counts (1st pair, 2nd pair, etc.)
pair_idx = 1;


% Fill the adjacency matrix with the normalized weights
for i = 1:size(pairs, 1)
    % Get the pair of images (i, j)
    i_idx = pairs(i, 1);
    j_idx = pairs(i, 2);
    
    % Assign the normalized weight to the matrix
    W(i_idx, j_idx) = normalized_weights(pair_idx);
    W(j_idx, i_idx) = normalized_weights(pair_idx);  % Since it's undirected
    
    pair_idx = pair_idx + 1;  % Move to the next inlier pair
end

% Display the normalized weighted adjacency matrix
%disp('Normalized weighted adjacency matrix:');
%disp(W);

positions = [];
for i = 1:length(numArrayX)
    positions = [positions; numArrayX(i),-1*numArrayY(i)];
end

% Coordinates of images (tiles) in the 2D plane Y coordinate has to
% negative y coordinates
%positions = [
  %  1, -1;  % Image 1 at (1, 1)
   % 0, -1;  % Image 2 at (0, 1)
   % 0, 0;  % Image 3 at (0, 0)
   % 1, 0;  % Image 4 at (1, 0)
%];

% Plot the weighted graph with custom positions
G = graph(W);  % Create graph from adjacency matrix
%figure;
%h = plot(G, 'EdgeLabel', G.Edges.Weight, 'NodeLabel', {});  % Create plot without node labels

% Set the node positions explicitly based on the coordinates
%h.XData = positions(:, 1);  % X-coordinates
%h.YData = positions(:, 2);  % Y-coordinates

% Optionally, add labels for nodes (e.g., Image 1, Image 2, etc.)
%text(positions(:, 1), positions(:, 2), {'1', '2', '3', '4'}, 'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle');

T = minspantree(G);

% Visualize the MST
figure('Position', [100, 100, 1000, 800]); % Large figure window
h_mst = plot(T, 'EdgeLabel', T.Edges.Weight, 'NodeLabel', {}); % No node labels
%h_mst = plot(T, 'NodeLabel', {});
h_mst.LineWidth = 2.5;
% Use the same node positions as the original graph
h_mst.XData = positions(:, 1);
h_mst.YData = positions(:, 2);

% Label the nodes slightly above their position to avoid overlap
labelOffsetY = 0.02; % Adjust this depending on your coordinate scale
labelPositions = positions + [0, labelOffsetY];

% Generate node number labels
numPositions = size(positions, 1);
labelsofImg = arrayfun(@num2str, 1:numPositions, 'UniformOutput', false);

% Add node labels above each node
text(labelPositions(:, 1), labelPositions(:, 2), labelsofImg, ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', ...
    'FontName', 'Times New Roman', ...
    'FontSize', 14, ...
    'FontWeight', 'bold');

% Try accessing the EdgeLabel text objects differently
edgeLabels = findobj(h_mst, 'Type', 'text', 'Tag', 'EdgeLabel');

if ~isempty(edgeLabels)
    for i = 1:length(edgeLabels)
        set(edgeLabels(i), 'FontName', 'Times New Roman', 'FontSize', 16, 'FontWeight', 'bold');
    end
end


% Optional: Set figure font globally for axes
set(gca, 'FontName', 'Times New Roman', 'FontSize', 14, 'FontWeight', 'bold');

% Display the edges and weights of the MST
disp('Edges in the MST and their weights:');
disp(T.Edges);
%exportgraphics(gcf, 'MST_plot_2.png', 'Resolution', 600);

num_edges = numedges(G);
num_nodes = numnodes(G);
density = num_edges / (num_nodes * (num_nodes - 1) / 2); % Density formula
if density > 0.5
    disp('Likely used Prim''s algorithm (Dense graph).');
else
    disp('Likely used Kruskal''s algorithm (Sparse graph).');
end

imgNodestoConnect = T.Edges.EndNodes;
nodeWeights = T.Edges.Weight;
pairsMstIndex = [];

for i =1:length(imgNodestoConnect)
    for j = 1:length(pairs)
      if imgNodestoConnect(i,:) == pairs(j, :)
          pairsMstIndex = [pairsMstIndex;j];
      end
    end
end
translationParametersMst = [];
for i= 1: length(pairsMstIndex)
    translationParametersMst = [translationParametersMst; translationParameters(pairsMstIndex(i),:)];
end
