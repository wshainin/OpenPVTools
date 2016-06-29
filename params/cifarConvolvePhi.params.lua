package.path = package.path .. ";" .. "/home/wshainin/workspace/PetaVision/pv-core/parameterWrapper/?.lua";
local pv = require "PVModule";
--local subnets = require "PVSubnets";

local nbatch           = 1;    --Batch size of learning
local nxSize           = 32;    --Cifar is 32 x 32
local nySize           = 32;
local gtScale          = 1/32;
local patchSize        = 8;
local stride           = 4
local displayPeriod    = 1;   --Number of timesteps to find sparse approximation

local numEpochs        = 1;     --Number of times to run through dataset
local numImages        = 10; --Total number of images in dataset
local numClasses       = 10;
local stopTime         = (numImages * displayPeriod * numEpochs) / nbatch;
local writeStep        = 1; --displayPeriod; 
local initialWriteTime = 1; --displayPeriod; 

local runType          = "cifarConvolvePhi";
local runVersion       = "1";
local workspacePath    = "/home/wshainin/workspace/";
--local inputPath        = workspacePath .. "cifar-10-batches-mat/mixed_cifar.txt";
local inputPath        = workspacePath .. "cifar-10-batches-mat/test_batch_randorder.txt";
local outputPath       = workspacePath .. "sandbox/" .. runType .. "_" .. runVersion;

local overcompleteness = 2;
local numBasisVectors  = overcompleteness * (stride^2) * 3 * 2; -- nf = overcompleteness x (stride X) x (Stride Y) * (# color channels) * (2 if rectified) 
local basisVectorFile  = "/home/wshainin/workspace/sandbox/cifarControlStrideFourHardThresh_2/Checkpoints/batchsweep_00/Checkpoint1875000/S1ToImageReconS1Error_W.pvp"; --nil for initial weights, otherwise, specifies the weights file to load for dictionaries
local plasticityFlag   = false;  --Determines if we are learning weights or holding them constant
local momentumTau      = 500;   --The momentum parameter. A single weight update will last for momentumTau timesteps.
local dWMax            = 10;    --The learning rate
local VThresh          = .025;  -- .005; --The threshold, or lambda, of the network
local AMin             = 0;
local AMax             = infinity;
local AShift           = 0;     --This being equal to VThresh is a soft threshold
local VWidth           = 0; -- For firm: 100;
local timeConstantTau  = 100;   --The integration tau for sparse approximation
local weightInit       = math.sqrt((1/patchSize)*(1/patchSize)*(1/3));

-- Base table variable to store
local pvParameters = {

   --Layers------------------------------------------------------------
   --------------------------------------------------------------------   
   column = {
      groupType = "HyPerCol";
      startTime                           = 0;
      dt                                  = 1;
      dtAdaptFlag                         = false;
      stopTime                            = stopTime;
      progressInterval                    = (displayPeriod * 10);
      writeProgressToErr                  = true;
      verifyWrites                        = false;
      outputPath                          = outputPath;
      printParamsFilename                 = runType .. "_" .. runVersion .. ".params";
      randomSeed                          = 1234567890;
      nx                                  = nxSize;
      ny                                  = nySize;
      nbatch                              = nbatch;
      filenamesContainLayerNames          = 2;
      filenamesContainConnectionNames     = 2;
      --initializeFromCheckpointDir         = "Checkpoint38198400";
      initializeFromCheckpointDir         = "";
      defaultInitializeFromCheckpointFlag = false;
      checkpointWrite                     = true;
      checkpointWriteDir                  = outputPath .. "/Checkpoints"; --The checkpoint output directory
      checkpointWriteTriggerMode          = "step";
      checkpointWriteStepInterval         = (displayPeriod * 100); --How often to checkpoint
      deleteOlderCheckpoints              = false;
      suppressNonplasticCheckpoints       = false;
      writeTimescales                     = true;
      errorOnNotANumber                   = false;
   };

   S1 = {
      groupType = "MoviePvp";
      nxScale                             = 1/stride;
      nyScale                             = 1/stride;
      nf                                  = numBasisVectors;
      phase                               = 2;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      inputPath                           = "/home/wshainin/drive/_WORK/Sampling/S1_AVG.pvp";
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = true;
      writeSparseValues                   = true;
      updateGpu                           = false; 
      dataType                            = nil;
   };

   ImageReconS1 = {
      groupType = "ANNLayer";
      nxScale                             = 1;
      nyScale                             = 1;
      nf                                  = 3;
      phase                               = 3;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = NULL;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
      VThresh                             = -infinity;
      AMin                                = -infinity;
      AMax                                =  infinity;
      AShift                              = 0;
      VWidth                              = 0;
      clearGSynInterval                   = 0;
   };

--Connections ------------------------------------------------------
--------------------------------------------------------------------

   S1ToImageReconS1 = {
      groupType = "HyPerConn";
      preLayerName                        = "S1";
      postLayerName                       = "ImageReconS1";
      channelCode                         = 0;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = plasticityFlag;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false; -- non-sparse -> non-sparse
      sharedWeights                       = true;
      weightInitType                      = "FileWeight";
      initWeightsFile                     = basisVectorFile;
      useListOfArborFiles                 = false;
      combineWeightFiles                  = false;
      initializeFromCheckpointFlag        = false;
      updateGSynFromPostPerspective       = false; -- Should be false from S1 (sparse layer) to Error (not sparse). Otherwise every input from pre will be calculated (Instead of only active ones)
      pvpatchAccumulateType               = "convolve";
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      nxp                                 = patchSize;
      nyp                                 = patchSize;
      shrinkPatches                       = false;
      normalizeMethod                     = "normalizeL2";
      strength                            = 1;
      normalizeArborsIndividually         = false;
      normalizeOnInitialize               = true;
      normalizeOnWeightUpdate             = true;
      rMinX                               = 0;
      rMinY                               = 0;
      nonnegativeConstraintFlag           = false;
      normalize_cutoff                    = 0;
      normalizeFromPostPerspective        = false;
      minL2NormTolerated                  = 0;
      dWMax                               = dWMax; 
      keepKernelsSynchronized             = true; -- Possibly irrelevant
      useMask                             = false;
   }; 


} --End of pvParameters

-- Print out PetaVision approved parameter file to the console
pv.printConsole(pvParameters)
