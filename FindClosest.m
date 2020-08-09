function [ closestValue, closestIndex ] = FindClosest( arrayValue, inputArray )
%FindClosest find the value and index of the closest element found for
%input
%   FindClosest (arrayValue, inputArray) returns the Value and Index of the closestValue for the
%   inputArray found in arrayValue.
%   It uses the minimum of absolute difference of single inputArray with
%   arrayValue to return the index. [M, id] = min(X) is used for finding
%   the minimum and the index.

if nargin < 2
    closestValue = [];
    closestIndex = [];
    error('The number of argument is always 2. Check input arguments.');
    
elseif nargin > 2
    closestValue = [];
    closestIndex = [];
    error('The number of argument is always 2. Check input arguments.');
    
else
    closestValue = zeros(1, length(inputArray));
    closestIndex = zeros(1, length(inputArray));
    for i = 1 : length(inputArray)
        value = inputArray(i);
        tmp = abs(arrayValue - value);
        [~, I] = min(tmp);
        closestIndex(i) = I;
        closestValue(i) = arrayValue(I);
    end
end

