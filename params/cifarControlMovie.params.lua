package.path = package.path .. ";" .. "/home/wshainin/workspace/PetaVision/pv-core/parameterWrapper/?.lua";
local pv = require "PVModule";
--local subnets = require "PVSubnets";

local nbatch           = 32;    --Batch size of learning
local nxSize           = 32;    --Cifar is 32 x 32
local nySize           = 32;
local gtScale          = 1/32;
local patchSize        = 9;
local stride           = 1
local displayPeriod    = 1; --200;   --Number of timesteps to find sparse approximation
local numEpochs        = 3;     --Number of times to run through dataset
local numImages        = 50000; --Total number of images in dataset
local numClasses       = 10;
local stopTime         = ((numImages * displayPeriod * numEpochs) / nbatch );
local writeStep        = displayPeriod; 
local initialWriteTime = displayPeriod; 

local runType          = "cifarControlPerceptron";
local runVersion       = 2;
local workspacePath    = "/home/wshainin/workspace/";
local inputPath        = workspacePath .. "cifar-10-batches-mat/mixed_cifar.txt";
local outputPath       = workspacePath .. "sandbox/" .. runType .. "_" .. runVersion;
local groundTruthPath  = "/home/wshainin/workspace/sandbox/cifar_labels.pvp";
local S1MoviePath      = "/home/wshainin/workspace/sandbox/cifarControlMovie_1/S1_Corrected.pvp";
local SLPWeightsPath   = "/home/wshainin/workspace/sandbox/cifarControlPerceptron_1/Checkpoints/batchsweep_00/Checkpoint1500/";

local numBasisVectors  = (patchSize/stride) * (patchSize/stride) * 3 * 2;   --Total number of basis vectors being learned (patchSize/stride)^2 Xs overcomplete 
--local basisVectorFile  = "/home/wshainin/workspace/sandbox/cifarControl_2/Checkpoints/batchsweep_00/Checkpoint312500/S1ToImageReconS1Error_W.pvp"; --nil for initial weights, otherwise, specifies the weights file to load for dictionaries
local cPlasticityFlag  = true;  --Determines if we are learning weights or holding them constant

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
      progressInterval                    = (displayPeriod * 1000);
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
      nxScale                             = 1;
      nyScale                             = 1;
      nf                                  = numBasisVectors;
      phase                               = 0;
      mirrorBCflag                        = false;
      initializeFromCheckpointFlag        = false;
      --readPvpFile                         = true;
      writeSparseValues                   = true;
      writeStep                           = -1; --writeStep;
      initialWriteTime                    = nil; --initialWriteTime;
      sparseLayer                         = true;
      updateGpu                           = false;
      dataType                            = nil;
      inputPath                           = S1MoviePath; 
      offsetAnchor                        = "tl";
      offsetX                             = 0;
      offsetY                             = 0;
      writeImages                         = 0;
      inverseFlag                         = false;
      normalizeLuminanceFlag              = false;
      normalizeStdDev                     = false;
      jitterFlag                          = 0;
      useImageBCflag                      = false;
      padValue                            = 0;
      autoResizeFlag                      = false;
      displayPeriod                       = displayPeriod;
      batchMethod                         = "byImage";
      start_frame_index                   = {0.000000};
      --skip_frame_index                    = {0.000000};
      randomMovie                         = 0;
      writeFrameToTimestamp               = true;
      flipOnTimescaleError                = true;
      resetToStartOnLoop                  = false;
   };

   --ImageReconS1 = {
   --   groupType = "ANNLayer";
   --   nxScale                             = 1;
   --   nyScale                             = 1;
   --   nf                                  = 3;
   --   phase                               = 3;
   --   mirrorBCflag                        = false;
   --   valueBC                             = 0;
   --   initializeFromCheckpointFlag        = false;
   --   InitVType                           = "ZeroV";
   --   triggerLayerName                    = NULL;
   --   writeStep                           = writeStep;
   --   initialWriteTime                    = initialWriteTime;
   --   sparseLayer                         = false;
   --   updateGpu                           = false;
   --   dataType                            = nil;
   --   VThresh                             = -infinity;
   --   AMin                                = -infinity;
   --   AMax                                =  infinity;
   --   AShift                              = 0;
   --   VWidth                              = 0;
   --   clearGSynInterval                   = 0;
   --};

   BiasS1 = {
      groupType = "ConstantLayer";
      nxScale                             = 1;
      nyScale                             = 1;
      nf                                  = 1;
      phase                               = 0;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ConstantV";
      valueV                              = 1;
      triggerLayerName                    = NULL;
      writeStep                           = -1;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
      VThresh                             = -infinity;
      AMin                                = -infinity;
      AMax                                = infinity;
      AShift                              = 0;
      VWidth                              = 0;
      clearGSynInterval                   = 0;
   };

   GroundTruthReconS1 = {
      groupType = "ANNLayer";
      nxScale                             = gtScale;
      nyScale                             = gtScale;
      nf                                  = numClasses;
      phase                               = 1;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = "GroundTruth";
      triggerOffset                       = 0;
      triggerBehavior                     = "updateOnlyOnTrigger";
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

   GroundTruth = {
      groupType = "MoviePvp";
      nxScale                             = gtScale; 
      nyScale                             = gtScale;
      nf                                  = numClasses;
      phase                               = 0;
      mirrorBCflag                        = true;
      initializeFromCheckpointFlag        = false;
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = true;
      writeSparseValues                   = false;
      updateGpu                           = false;
      dataType                            = nil;
      offsetAnchor                        = "tl";
      offsetX                             = 0;
      offsetY                             = 0;
      writeImages                         = 0;
      useImageBCflag                      = false;
      autoResizeFlag                      = false;
      inverseFlag                         = false;
      normalizeLuminanceFlag              = false;
      jitterFlag                          = 0;
      padValue                            = 0;
      inputPath                           = groundTruthPath;
      displayPeriod                       = displayPeriod;
      batchMethod                         = "byImage";
      randomMovie                         = 0;
      --readPvpFile                         = true;
      start_frame_index                   = {0.000000};
      --skip_frame_index                    = {0.000000};
      writeFrameToTimestamp               = true;
      flipOnTimescaleError                = true;
      resetToStartOnLoop                  = false;
   };

   GroundTruthReconS1Error = {
      groupType = "ANNErrorLayer";
      nxScale                             = gtScale;
      nyScale                             = gtScale;
      nf                                  = numClasses;
      phase                               = 2;
      mirrorBCflag                        = false;
      valueBC                             = 0;
      initializeFromCheckpointFlag        = false;
      InitVType                           = "ZeroV";
      triggerLayerName                    = "GroundTruth";
      triggerOffset                       = 0;
      triggerBehavior                     = "updateOnlyOnTrigger";
      writeStep                           = writeStep;
      initialWriteTime                    = initialWriteTime;
      sparseLayer                         = false;
      updateGpu                           = false;
      dataType                            = nil;
      VThresh                             = 0;
      clearGSynInterval                   = 0;
      errScale                            = 1;
   };

--Connections ------------------------------------------------------
--------------------------------------------------------------------

   --S1ToImageReconS1 = {
   --   groupType = "HyPerConn";
   --   preLayerName                        = "S1";
   --   postLayerName                       = "ImageReconS1";
   --   channelCode                         = 0;
   --   delay                               = {0.000000};
   --   numAxonalArbors                     = 1;
   --   plasticityFlag                      = false;
   --   convertRateToSpikeCount             = false;
   --   receiveGpu                          = false; -- non-sparse -> non-sparse
   --   sharedWeights                       = true;
   --   weightInitType                      = "FileWeight";
   --   initWeightsFile                     = basisVectorFile;
   --   useListOfArborFiles                 = false;
   --   combineWeightFiles                  = false;
   --   initializeFromCheckpointFlag        = false;
   --   triggerLayerName                    = "GroundTruth";
   --   triggerOffset                       = 0;
   --   updateGSynFromPostPerspective       = false; -- Should be false from S1 (sparse layer) to Error (not sparse). Otherwise every input from pre will be calculated (Instead of only active ones)
   --   pvpatchAccumulateType               = "convolve";
   --   normalizeMethod                     = "none";
   --   writeStep                           = -1; --writeStep; TODO
   --   --initialWriteTime                    = initialWriteTime;
   --   writeCompressedCheckpoints          = false;
   --   selfFlag                            = false;
   --   nxp                                 = patchSize;
   --   nyp                                 = patchSize;
   --   shrinkPatches                       = false;
   --   rMinX                               = 0;
   --   rMinY                               = 0;
   --   nonnegativeConstraintFlag           = false;
   --   minL2NormTolerated                  = 0;
   --   keepKernelsSynchronized             = true; -- Possibly irrelevant
   --   useMask                             = false;
   --}; 

   S1ToGroundTruthReconS1Error = {
      groupType = "HyPerConn";
      preLayerName                        = "S1";
      postLayerName                       = "GroundTruthReconS1Error";
      channelCode                         = -1;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = cPlasticityFlag;
      triggerLayerName                    = "GroundTruth";
      triggerOffset                       = 0;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      sharedWeights                       = true;
      --weightInitType                      = "UniformRandomWeight";
      --wMinInit                            = -1;
      --wMaxInit                            = 1;
      --sparseFraction                      = 0.9;
      weightInitType                      = "FileWeight";
      initWeightsFile                     = SLPWeightsPath .. "S1ToGroundTruthReconS1Error_W.pvp";
      useListOfArborFiles                 = false;
      combineWeightFiles                  = false;
      initializeFromCheckpointFlag        = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeStep                           = -1;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      nxp                                 = 1;
      nyp                                 = 1;
      nfp                                 = numClasses;
      shrinkPatches                       = false;
      normalizeMethod                     = "none";
      dWMax                               = 0.1;
      keepKernelsSynchronized             = true;
      gpuGroupIdx                         = -1;
      useMask                             = false;
   };

   S1ToGroundTruthReconS1 = {
      groupType = "CloneConn";
      preLayerName                        = "S1";
      postLayerName                       = "GroundTruthReconS1";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "S1ToGroundTruthReconS1Error";
   };

   GroundTruthReconS1ToGroundTruthReconS1Error = {
      groupType = "IdentConn";
      preLayerName                        = "GroundTruthReconS1";
      postLayerName                       = "GroundTruthReconS1Error";
      channelCode                         = 1;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
   };

   BiasS1ToGroundTruthReconS1 = {
      groupType = "CloneConn";
      preLayerName                        = "BiasS1";
      postLayerName                       = "GroundTruthReconS1";
      channelCode                         = 0;
      delay                               = {0.000000};
      convertRateToSpikeCount             = false;
      receiveGpu                          = true; -- Why not. non-sparse -> non-sparse
      updateGSynFromPostPerspective       = true;
      pvpatchAccumulateType               = "convolve";
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      originalConnName                    = "BiasS1ToGroundTruthReconS1Error";
   };

   BiasS1ToGroundTruthReconS1Error = {
      groupType = "HyPerConn";
      preLayerName                        = "BiasS1";
      postLayerName                       = "GroundTruthReconS1Error";
      channelCode                         = -1;
      delay                               = {0.000000};
      numAxonalArbors                     = 1;
      plasticityFlag                      = cPlasticityFlag;
      triggerLayerName                    = "GroundTruth";
      triggerOffset                       = 0;
      convertRateToSpikeCount             = false;
      receiveGpu                          = false;
      sharedWeights                       = true;
      --weightInitType                      = "UniformWeight";
      --weightInit                          = 0;
      weightInitType                      = "FileWeight";
      initWeightsFile                     = SLPWeightsPath .. "BiasS1ToGroundTruthReconS1Error_W.pvp";
      useListOfArborFiles                 = false;
      combineWeightFiles                  = false;
      initializeFromCheckpointFlag        = false;
      updateGSynFromPostPerspective       = false;
      pvpatchAccumulateType               = "convolve";
      writeStep                           = -1;
      writeCompressedCheckpoints          = false;
      selfFlag                            = false;
      nxp                                 = 1;
      nyp                                 = 1;
      nfp                                 = numClasses;
      shrinkPatches                       = false;
      normalizeMethod                     = "none";
      dWMax                               = .001;
      keepKernelsSynchronized             = true;
      --connectOnlySameFeatures             = false;
      gpuGroupIdx                         = -1;
      useMask                             = false;
   };

   GroundTruthToGroundTruthReconS1Error = {
      groupType = "IdentConn";
      preLayerName                        = "GroundTruth";
      postLayerName                       = "GroundTruthReconS1Error";
      channelCode                         = 0;
      delay                               = {0.000000};
      initWeightsFile                     = nil;
      writeStep                           = -1;
   };

   --Probes------------------------------------------------------------
   --------------------------------------------------------------------

   --S1EnergyProbe = {
   --   groupType = "ColumnEnergyProbe";
   --   message                             = nil;
   --   textOutputFlag                      = true;
   --   probeOutputFile                     = "S1EnergyProbe.txt";
   --   triggerLayerName                    = nil;
   --   energyProbe                         = nil;
   --};

   --ImageReconS1ErrorL2NormEnergyProbe = {
   --   groupType = "L2NormProbe";
   --   targetLayer                         = "ImageReconS1Error";
   --   message                             = nil;
   --   textOutputFlag                      = true;
   --   probeOutputFile                     = "ImageReconS1ErrorL2NormEnergyProbe.txt";
   --   energyProbe                         = "S1EnergyProbe";
   --   coefficient                         = 0.5;
   --   maskLayerName                       = nil;
   --   exponent                            = 2;
   --};

   --S1L1NormEnergyProbe = {
   --   groupType = "L1NormProbe";
   --   targetLayer                         = "S1";
   --   message                             = nil;
   --   textOutputFlag                      = true;
   --   probeOutputFile                     = "S1L1NormEnergyProbe.txt";
   --   energyProbe                         = "S1EnergyProbe";
   --   coefficient                         = 0.025;
   --   maskLayerName                       = nil;
   --};

} --End of pvParameters

-- Print out PetaVision approved parameter file to the console
pv.printConsole(pvParameters)
