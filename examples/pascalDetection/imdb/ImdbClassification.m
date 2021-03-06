% Very lazy class to do classification. Validation is not properly done...
% Now validation is set to 10% of the dataset
%
% Jasper: Experimental untested class!
classdef ImdbClassification < ImdbCalvin
    properties(SetAccess = protected, GetAccess = public)       
        imageDir
        imExt
        meanIm
        labs
        
        flipLR = true;  % Flag if data will be flipped or not
    end
    
    methods
        function obj = ImdbClassification(imageDir, imExt, filenames, labels, datasetIdx, meanIm, numClasses)
            % Set fields of the imdb class
            obj.imageDir = imageDir;
            obj.imExt = imExt;
            obj.meanIm = single(meanIm);
            obj.numClasses = numClasses;
            
            % Split into train/val/test
            if ~iscell(datasetIdx)
                % We have three numbers specifying the random split
                if sum(datasetIdx) ~= 1
                    error('Complete dataset should be divided');
                end
                
                % Randomly split the data
                idx = randperm(length(filenames));
                numTrain = length(filenames) * datasetIdx(1);
                numVal = length(filenames) * datasetIds(2);
                
                idxTrain = idx(1:numTrain);
                idxVal = idx(numTrain+1:numTrain+1+numVal);
                idxTest = idx(numTrain+1+numVal+1:end);
                obj.data.train = filenames(idxTrain);
                obj.data.val = filenames(idxVal);
                obj.data.test = filenames(idxTest);
                obj.labs.train = labels(idxTrain,:);
                obj.labs.val = labels(idxVal,:);
                obj.labs.test = labels(idxTest,:);
            else
                % We have cell arrays specifying the predifined split
                % Check if split is correct
                allIdx = cat(1, datasetIdx{:});
                if ~isequal(sort(allIdx), (1:length(filenames))')
                    warning('Dataset not correctly divided');
                end
                
                obj.data.train = filenames(datasetIdx{1});
                obj.data.val = filenames(datasetIdx{2});
                obj.data.test = filenames(datasetIdx{3});
                obj.labs.train = labels(datasetIdx{1},:);
                obj.labs.val = labels(datasetIdx{2},:);
                obj.labs.test = labels(datasetIdx{3},:);
            end
        end
        
        function [batchData, currBatchSize] = getBatch(obj, batchInds, net, ~)
            if nargin == 2
                gpuMode = false;
            else
                gpuMode = strcmp(net.device, 'gpu');
            end
            
            currBatchSize = length(batchInds);
            batchLabs = zeros(1, 1, obj.numClasses, currBatchSize);
            if gpuMode
                batch = zeros(size(obj.meanIm,1), size(obj.meanIm,2), size(obj.meanIm,3), currBatchSize, 'single', 'gpuArray');
            else
                batch = zeros(size(obj.meanIm,1), size(obj.meanIm,2), size(obj.meanIm,3), currBatchSize, 'single');
            end
            
            for idx=1:length(batchInds)
                imI = batchInds(idx);
                theIm = single(imread([obj.imageDir obj.data.(obj.datasetMode){imI} obj.imExt]));
                if size(theIm,3) == 1
                    theIm = repmat(theIm, [1 1 3]);
                end
                batch(:,:,:,idx) = imresize(theIm, [size(obj.meanIm,1) size(obj.meanIm,2)], ...
                                          'bilinear', 'antialiasing', false);
                batchLabs(1,1,:,idx) = obj.labs.(obj.datasetMode)(imI,:);
            end
            
            batch = bsxfun(@minus, batch, obj.meanIm);
            if obj.flipLR
                batch = fliplr(batch);
            end
            
            batchData{1} = 'input';
            batchData{2} = batch;
            
            if ~strcmp(obj.datasetMode, 'test');
                batchData{3} = 'label';
                batchData{4} = batchLabs;
            end
        end
        
        function initEpoch(obj, epoch)
            initEpoch@ImdbCalvin(obj, epoch);
            
            % Flip image vertically at the start of each epoch
            obj.switchFlipLR();
        end

        function switchFlipLR(obj)
            % Switch the flipLR switch
            obj.flipLR = mod(obj.flipLR+1, 2);      
        end
    end
end