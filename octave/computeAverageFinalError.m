%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%   Computes a numerical approximation of the average first and second 
%%      derivatives of the error at a specified point and set of frames from
%%      the text file written by an energy probe.
%%
%%    Will Shainin
%%    Feb 11, 2016
%%
%% Inputs:
%%   errorProbeTextFile - Absolute path to energy probe txt file
%%   startFrame         - First frame to calculate. 1 frame has 
%%                           (displayPeriod) timesteps
%%   endFrame           - Last frame to calculate
%%   displayPeriod      - Display Period of run being analyzed
%%   sampleTimestep     - Timestep to calculate derivatives. Estimation
%%                           is calculated using the previous two values
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [acceleration, velocity, position, errorData] = computeAverageFinalError(errorProbeTextFile, startFrame, endFrame, displayPeriod, sampleTimestep)
   numFrames = endFrame - startFrame + 1;
   errorData = dlmread(errorProbeTextFile, ",", (displayPeriod * (startFrame - 1)), 3);
   errorData = errorData(1 : numFrames * displayPeriod, 1);
   i = 1;
   for frame = 1:displayPeriod:numel(errorData)
      t = frame + sampleTimestep - 1;
      pos(i)   = errorData(t);
      vel(i)   = diff(errorData(t-1 : t));
      acc(i++) = diff(diff(errorData(t-2 : t)));
   end%for
   acceleration = sum(acc(:)) / numel(acc);
   velocity     = sum(vel(:)) / numel(vel);
   position     = sum(pos(:)) / numel(pos);
end%function
