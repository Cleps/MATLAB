clear all, close all


doTraining = true;

if ~doTraining
    preTrainedDetector = downloadPretrainedYOLOv3Detector();    
end


%data = load('vehicleDatasetGroundTruth.mat');
%cocoDataset = data.vehicleDataset;


data = load('./cocoApi/cocoDatasetGroundTruth.mat');
cocoDataset = data.data;
%cocoDataset = cocoDataset(1:10,:);

%cocoDataset = cocoDataset(1:100,1:2);
%teste = cocoDataset(5,1:2)
% Add the full path to the local vehicle data folder.
%data.imageFilename = fullfile(pwd, data.imageFilename);

rng(0);
shuffledIndices = randperm(height(cocoDataset));
idx = floor(0.8 * length(shuffledIndices));
trainingDataTbl = cocoDataset(shuffledIndices(1:idx), :);
testDataTbl = cocoDataset(shuffledIndices(idx+1:end), :);

%Create an image datastore for loading the images.

train_labels = trainingDataTbl(:, 2:end);
test_labels = testDataTbl(:, 2:end);

train_blds = boxLabelDatastore(train_labels);
test_blds = boxLabelDatastore(test_labels);

train_imds = imageDatastore(trainingDataTbl.imageFilename(:));
test_imds = imageDatastore(testDataTbl.imageFilename(:));

trainingData = combine(train_imds, train_blds);
testData = combine(test_imds, test_blds);

%====================================
%validateInputData(trainingData)
%validateInputData(testData)
%====================================

%imdsTrain = imageDatastore(trainingDataTbl.imageFilename);
%imdsTest = imageDatastore(testDataTbl.imageFilename);
%Create a datastore for the ground truth bounding boxes.
%bldsTrain = boxLabelDatastore(trainingDataTbl(:, 2:end));
%bldsTest = boxLabelDatastore(testDataTbl(:, 2:end));
%Combine the image and box label datastores.
%trainingData = combine(imdsTrain, bldsTrain);
%testData = combine(imdsTest, bldsTest);
%save testData testData
%validate
%validateInputData(trainingDataTbl);
%validateInputData(testData);

%% Data Aug
augmentedTrainingData = transform(trainingData, @augmentData);
% Visualize the augmented images.
augmentedData = cell(4,1);
for k = 1:4
    data = read(augmentedTrainingData);
    augmentedData{k} = insertShape(data{1,1}, 'Rectangle', data{1,2});
    reset(augmentedTrainingData);
end
figure
montage(augmentedData, 'BorderSize', 10)
%% create net

networkInputSize = [227 227 3];
rng(0)
trainingDataForEstimation = transform(trainingData, @(data)preprocessData(data, networkInputSize));
numAnchors = 6;
[anchors, meanIoU] = estimateAnchorBoxes(trainingDataForEstimation, numAnchors)

area = anchors(:, 1).*anchors(:, 2);
[~, idx] = sort(area, 'descend');
anchors = anchors(idx, :);
anchorBoxes = {anchors(1:3,:)
    anchors(4:6,:)
    };

baseNetwork = squeezenet;
classNames = trainingDataTbl.Properties.VariableNames(2:end);

%%

yolov3Detector = yolov3ObjectDetector(baseNetwork, classNames, anchorBoxes, 'DetectionNetworkSource', {'fire9-concat', 'fire5-concat'});


%%Preprocess Training Data
preprocessedTrainingData = transform(augmentedTrainingData, @(data)preprocess(yolov3Detector, data));
%Read the preprocessed training data.
data = read(preprocessedTrainingData);
%Display the image with the bounding boxes.
I = data{1,1};
bbox = data{1,2};
annotatedImage = insertShape(I, 'Rectangle', bbox);
annotatedImage = imresize(annotatedImage,2);
figure
imshow(annotatedImage)
%Reset the datastore.
reset(preprocessedTrainingData);


%%Specify Training Options

numEpochs = 80;
miniBatchSize = 8;
learningRate = 0.001;
warmupPeriod = 1000;
l2Regularization = 0.0005;
penaltyThreshold = 0.5;
velocity = [];

%%Train Model

%minibatchqueue automatically detects the availability of a GPU.
% If you do not have a GPU, or do not want to use one for training,
% set the OutputEnvironment parameter to "cpu". 
if canUseParallelPool
   dispatchInBackground = true;
else
   dispatchInBackground = false;
end

mbqTrain = minibatchqueue(preprocessedTrainingData, 2,...
        "MiniBatchSize", miniBatchSize,...
        "MiniBatchFcn", @(images, boxes, labels) createBatchData(images, boxes, labels, classNames), ...
        "MiniBatchFormat", ["SSCB", ""],...
        "DispatchInBackground", dispatchInBackground,...
        "OutputCast", ["", "double"]);



%%
if doTraining
    
    % Create subplots for the learning rate and mini-batch loss.
    fig = figure;
    [lossPlotter, learningRatePlotter] = configureTrainingProgressPlotter(fig);

    iteration = 0;
    % Custom training loop.
    for epoch = 1:numEpochs
          
        reset(mbqTrain);
        shuffle(mbqTrain);
        
        while(hasdata(mbqTrain))
            iteration = iteration + 1;
           
            [XTrain, YTrain] = next(mbqTrain);
            
            % Evaluate the model gradients and loss using dlfeval and the
            % modelGradients function.
            [gradients, state, lossInfo] = dlfeval(@modelGradients, yolov3Detector, XTrain, YTrain, penaltyThreshold);
    
            % Apply L2 regularization.
            gradients = dlupdate(@(g,w) g + l2Regularization*w, gradients, yolov3Detector.Learnables);
    
            % Determine the current learning rate value.
            currentLR = piecewiseLearningRateWithWarmup(iteration, epoch, learningRate, warmupPeriod, numEpochs);
    
            % Update the detector learnable parameters using the SGDM optimizer.
            [yolov3Detector.Learnables, velocity] = sgdmupdate(yolov3Detector.Learnables, gradients, velocity, currentLR);
    
            % Update the state parameters of dlnetwork.
            yolov3Detector.State = state;
              
            % Display progress.
            displayLossInfo(epoch, iteration, currentLR, lossInfo);  
                
            % Update training plot with new points.
            updatePlots(lossPlotter, learningRatePlotter, iteration, currentLR, lossInfo.totalLoss);
        end        
    end
    save yolov3Detector yolov3Detector
else
    yolov3Detector = preTrainedDetector;
end

%%



