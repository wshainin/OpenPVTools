%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   Computes the euclidean error and change in active elements. 
%%
%%    Will Shainin Feb 11, 2016
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [hamming, percentChange, sqrError] = compareActivities(firstVector, secondVector)
hamming       = sum(xor(firstVector, secondVector));
numActive     = sum(or(firstVector, secondVector));
percentChange = hamming/numActive;
%%sqrError      = sqrt(firstVector * secondVector');
sqrError      = norm(firstVector - secondVector);
end%function
