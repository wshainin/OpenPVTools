package.path = package.path .. ";" .. "/home/wshainin/workspace/OpenPV/parameterWrapper/?.lua";
local pv = require "PVModule";
--local subnets = require "PVSubnets";

local nbatch           = 32;    --Batch size of learning
local nxSize           = 32;    --Cifar is 32 x 32
local nySize           = 32;
local patchSize        = 12;
local stride           = 2
local displayPeriod    = 400;   --Number of timesteps to find sparse approximation
local numEpochs        = 1;     --Number of times to run through dataset
local numImages        = 10000; --Total number of images in dataset
local stopTime         = math.ceil((numImages  * numEpochs) / nbatch) * displayPeriod;
local writeStep        = -1; --displayPeriod; 
local initialWriteTime = displayPeriod; 

local runType          = "CIFAR_ISTA_COMPARE_ENCODE_TEST_128";
local runVersion       = 1;
local workspacePath    = "/home/wshainin/workspace/";
local compneuroPath    = "/nh/compneuro/scratch/wshainin/";
local inputPath        = compneuroPath .. "cifar-10-batches-mat/test_batch_randorder_compneuro.txt";
local outputPath       = compneuroPath .. "sandbox/" .. runType .. "_" .. runVersion;
local checkpointPeriod = (displayPeriod * 100);

local overcompleteness = 2;
local numBasisVectors  = 128; --overcompleteness * (stride^2) * 3 * 2; -- nf = overcompleteness x (stride X) x (Stride Y) * (# color channels) * (2 if rectified) 
local basisVectorFile  = compneuroPath..'128_S1ToImageReconS1Error_W.pvp'; --nil for initial weights, otherwise, specifies the weights file to load for dictionaries
local plasticityFlag   = false;  --Determines if we are learning weights or holding them constant
local momentumTau      = 200;   --The momentum parameter. A single weight update will last for momentumTau timesteps.
local dWMax            = 10;    --The learning rate
local VThresh          = .015;  -- .005; --The threshold, or lambda, of the network
local AMin             = 0;
local AMax             = infinity;
local AShift           = .015;     --This being equal to VThresh is a soft threshold
local VWidth           = 0; 
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
      dtAdaptFlag                         = true;
      useAdaptMethodExp1stOrder           = true;
      dtAdaptController                   = "S1EnergyProbe";
      dtAdaptTriggerLayerName             = "Image";
      dtAdaptTriggerOffset                = 0;
      dtScaleMax                          = .1; --1.0; -- minimum value for the maximum time scale, regardless of tau_eff
      dtScaleMin                          = 0.01; -- default time scale to use after image flips or when something is wacky
      dtChangeMax                         = 0.1; -- determines fraction of tau_effective to which to set the time step, can be a small percentage as tau_eff can be huge
      dtChangeMin                         = 0.01; -- percentage increase in the maximum allowed time scale whenever the time scale equals the current maximum
      dtMinToleratedTimeScale             = 0.0001;
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
      checkpointWriteStepInterval         = checkpointPeriod; --How often to checkpoint
      deleteOlderCheckpoints              = false;
      suppressNonplasticCheckpoints       = false;
      writeTimescales                     = true;
      errorOnNotANumber                   = false;
   };

   Image = {
      groupType = "Movie";
      nxScale                             = 1;
      nyScale                             = 1;
      nf                                  = 3;
      phase                               = 0;
      mirrorBCflag                        = true;
      initializeFromCheckpointFlag        = false;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
      inputPath                           = inputPath;
      offsetAnchor                        = "tl";
      offsetX                             = 0;
      offsetY                             = 0;
      writeImages                         = 0;
      inverseFlag                         = false;
      normalizeLuminanceFlag              = true;
      normalizeStdDev                     = true;
      jitterFlag                          = 0;
      useImageBCflag                      = false;
      padValue                            = 0;
      autoResizeFlag                      = false;
      displayPeriod                       = displayPeriod;
      echoFramePathnameFlag               = true;
      batchMethod                         = "byImage";
      start_frame_index                   = {0.000000};
      --skip_frame_index                    = {0.000000};
      writeFrameToTimestamp               = true;
      flipOnTimescaleError                = true;
      resetToStartOnLoop                  = false;
   };

   ImageReconS1Error = {
      groupType = "ANNLayer";
      nxScale                             = 1;
      nyScale                             = 1;
      nf                                  = 3;
      phase                               = 1;
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
      AMax                                = infinity;
      AShift                              = 0;
      clearGSynInterval                   = 0;
      useMask                             = false;
   };

   S1 = {
      groupType = "HyPerLCALayer";
      nxScale                             = 1/stride;
      nyScale                             = 1/stride;
      nf                                  = numBasisVectors;
      phase                               = 2;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ConstantV";
      valueV                              = VThresh;
      --InitVType                           = "InitVFromFile";
      --Vfilename                           = "S1_V.pvp";
      triggerLayerName                    = NULL;
      writeStep                           = displayPeriod;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = true;
      writeSparseValues                   = true;
      updateGpu                           = true;
      dataType                            = nil;
      VThresh                             = VThresh;
      AMin                                = AMin;
      AMax                                = AMax;
      AShift                              = AShift;
      VWidth                              = VWidth;
      clearGSynInterval                   = 0;
      timeConstantTau                     = timeConstantTau;
      selfInteract                        = true;
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

   ImageToImageReconS1Error = {
      groupType = "HyPerConn";
      preLayerName                        = "Image";
      postLayerName                       = "ImageReconS1Error";
      channelCode                         = 0;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = false;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      sharedWeights                       = true;
      weightInitType                      = "OneToOneWeights";
      initWeightsFile                     = nil;
      weightInit                          = weightInit;
      initializeFromCheckpointFlag        = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeStep                           = -1;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      nxp                                 = 1;
      nyp                                 = 1;
      nfp                                 = 3;
      shrinkPatches                       = false;
      normalizeMethod                     = "none";
   };

   ImageReconS1ErrorToS1 = {
      groupType = "TransposeConn";
      preLayerName                        = "ImageReconS1Error";
      postLayerName                       = "S1";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = true;
      updateGSynFromPostPerspective       = true;
      pvpatchAccumulateType               = "convolve";
      writeStep                           = -1;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      gpuGroupIdx                         = -1;
      originalConnName                    = "S1ToImageReconS1Error";
   };

   S1ToImageReconS1Error = {
      groupType = "MomentumConn";
      preLayerName                        = "S1";
      postLayerName                       = "ImageReconS1Error";
      channelCode                         = -1;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = plasticityFlag;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false; -- non-sparse -> non-sparse
      sharedWeights                       = true;
      --weightInitType                      = "UniformRandomWeight";
      --wMinInit                            = -1;
      --wMaxInit                            = 1;
      --sparseFraction                      = 0.9;
      weightInitType                      = "FileWeight";
      initWeightsFile                     = basisVectorFile;
      useListOfArborFiles                 = false;
      combineWeightFiles                  = false;
      initializeFromCheckpointFlag        = false;
      triggerLayerName                    = "Image";
      triggerOffset                       = 0;
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
      momentumTau                         = momentumTau;   --The momentum parameter. A single weight update will last for momentumTau timesteps.
      momentumMethod                      = "viscosity";
      momentumDecay                       = 0;
   }; 

   S1ToImageReconS1 = {
      groupType = "CloneConn";
      preLayerName                        = "S1";
      postLayerName                       = "ImageReconS1";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "S1ToImageReconS1Error";
   };

   ImageReconS1ToImageReconS1Error = {
      groupType = "IdentConn";
      preLayerName                        = "ImageReconS1";
      postLayerName                       = "ImageReconS1Error";
      channelCode                         = 1;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };

   --Probes------------------------------------------------------------
   --------------------------------------------------------------------

   S1EnergyProbe = {
      groupType = "ColumnEnergyProbe";
      message                             = nil;
      textOutputFlag                      = false;
      probeOutputFile                     = "S1EnergyProbe.txt";
      triggerLayerName                    = nil;
      energyProbe                         = nil;
   };

   ImageReconS1ErrorL2NormEnergyProbe = {
      groupType = "L2NormProbe";
      targetLayer                         = "ImageReconS1Error";
      message                             = nil;
      textOutputFlag                      = false;
      probeOutputFile                     = "ImageReconS1ErrorL2NormEnergyProbe.txt";
      energyProbe                         = "S1EnergyProbe";
      coefficient                         = 0.5;
      maskLayerName                       = nil;
      exponent                            = 2;
   };

   S1L1NormEnergyProbe = {
      groupType = "L1NormProbe";
      targetLayer                         = "S1";
      message                             = nil;
      textOutputFlag                      = false;
      probeOutputFile                     = "S1L1NormEnergyProbe.txt";
      energyProbe                         = "S1EnergyProbe";
      coefficient                         = 0.025;
      maskLayerName                       = nil;
   };

} --End of pvParameters

-- Print out PetaVision approved parameter file to the console
pv.printConsole(pvParameters)
