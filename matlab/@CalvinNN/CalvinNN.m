classdef CalvinNN < handle
    % CalvinNN
    %
    % Default network training script in Matconvnet-Calvin.
    % This uses Matconvnet's Directed Acyclic Graph structure and is
    % heavily inspired by the cnn_train_dag example.
    %
    % Copyright by Holger Caesar, 2015
    
    properties
        net
        imdb
        nnOpts
        stats
    end
    
    methods
        function obj = CalvinNN(net, imdb, nnOpts)
            % obj = CalvinNN(net, imdb, [nnOpts])
            
            % Default arguments
            if ~exist('nnOpts', 'var') || isempty(nnOpts)
                nnOpts = struct();
            end
            
            % Set fields
            obj.imdb = imdb;
            
            % Init options and GPUs
            obj.init(nnOpts);
            
            % Load network and convert to DAG format
            obj.loadNetwork(net);
            
            if obj.nnOpts.convertToTrain
                % Convert network from test to train (add loss layer,
                % dropout etc.)
                obj.convertNetwork();
            end
        end 
        
        % Declarations for methods that are in separate files
        convertNetwork(obj, net);
        convertNetworkToFastRcnn(obj, varargin);
        init(obj, varargin);
        saveState(obj, fileName);
        train(obj);
        results = test(obj);
    end
    
    methods (Access = protected)
        % Declarations for methods that are in separate files
        stats = accumulateStats(obj, stats_);
        state = accumulate_gradients(obj, state, net, batchSize);
        stats = process_epoch(obj, net, state);
    end
    
    methods (Static)
        stats = extractStats(net, inputs);
        stats = testDetection(imdb, nnOpts, net, inputs, batchInds);
        stats = testClassification(imdb, nnOpts, net, inputs, batchInds);
        epoch = findLastCheckpoint(modelDir);
        [net, stats] = loadState(obj, fileName);
    end
end