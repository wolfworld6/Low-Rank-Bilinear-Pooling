function [Gram]=...
    get_score_main020testOnly(dataset, network, endLayer, classificationType, initMethod, use448, net, batchSize)
useFewShot=false; % this is only for few shots learning

% two calling methods:
% 1. get_activations_dataset_network_layer('MIT', 'VGG_M', 13);
% 2. get_activations_dataset_network_layer(dataset, network, 'pcaConv', use448, net, batchSize);

% filling in absent values
if nargin<3,
    error('too few input arguments');
end
if nargin<4, use448=false;
    fprintf('default value use448=false\n');
end
if nargin<5
    net=load(consts(dataset, network));
    % implicitly assume that endLayer is a number
    net.layers=net.layers(1:endLayer);
    fprintf('default net read from (dataset, network, endLayer)\n');
end
if nargin<6,
    batchSize=8;
    fprintf('default batchSize=8\n');
end

% use448 could be an int32, indicates specific resolution
if isa(use448, 'logical'),
    use448=int32(use448*224+224);
end

% from endLayer to deduce confId. Note that endLayer could be 'char'
if isa(endLayer, 'numeric'),
    endLayer=num2str(endLayer);
end
confId=endLayer;

% feature output file name
if strncmpi(confId, 'compact', 7)
    l=net.layers{end-2};
    assert(strncmpi(l.name, 'compact', 7));
    projDim=l.outDim;
elseif strcmp(confId, 'pca_fb')
    l=net.layers{end-3};
    assert(strcmp(l.name, 'pca_reduction'));
    projDim=numel(l.weights{2});
else
    projDim=0;
end

feature_out_file = fullfile('./imdbFolder/CUB/exp/', ['classifierW_' dataset '_' network '_' initMethod '_' classificationType '_' endLayer '_' int2str(use448) '.mat']);

vl_simplenn_display(net);

fprintf('loading from the existing mat file\n');
% load(feature_out_file);

imdb = load('imdbFolder/CUB/cub-seed-01/imdb-seed-1.mat');

train=imdb2set(imdb.images.set, 1);

%%%%%%% comment later
train = [train  ]; % augmentation ---

val=imdb2set(imdb.images.set, 0);
% support for few shot learning
if useFewShot
    train = few_train(imdb, 1);
end

% debug resize the image to be 448*448
net.normalization.imageSize=double([use448 use448 3]);
net.normalization.averageImage = net.meta.normalization.averageImage;
%         net.normalization.rgbVariance = net.meta.normalization.rgbVariance;


bopts = net.normalization ;
bopts.numThreads = 12;
getBatch=getBatchWrapperModeAware(bopts);

% get the features
netGpu=vl_simplenn_move(net, 'gpu');
%         [trainFV, trainY]=getNetLastActivationsMain014(imdb, train, netGpu, getBatch, batchSize);
[Gram]=getScoreMain020TestOnly(imdb, val, netGpu, getBatch, batchSize);


