%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   Creates a pvp file of activities with uniform random distribution
%%      according to input parameters. For noise injection, min and max would
%%      be some fraction of the threshold.
%%
%%    Will Shainin
%%    Feb 10, 2016
%%
%% Inputs:
%%   outputPath - Absolute path to save pvp file
%%   nbands     - Number of frames
%%   ny         - Size of y dimension
%%   nx         - Size of x dimension
%%   nf         - Size of f dimension
%%   rangeMin   - Minimum value for uniform random distribution
%%   rangeMax   - Maximum value for uniform random distribution
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function generateNoisePVP(outputPath, nbands, ny, nx, nf, rangeMin, rangeMax)
   data = cell(nbands, 1);
   for frame = 1:nbands
      noiseMatrix = unifrnd(rangeMin, rangeMax, [ny, nx, nf]);
      data{frame}.time = 0;
      data{frame}.values = noiseMatrix;
   end%for
   writepvpactivityfile(outputPath, data);
end%function
