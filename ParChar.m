%% Inputs
if ~exist('Savepath','var') % Inputs are only used if the script is not run from within the ParChar_run script
    [FileName, Path] = uigetfile({'*.jpg;*.tiff;*.tif;*.bmp'}, 'Select Picture for processing')

    ImHeight=15; % The actual height of an image, in mm
    ImWidth=22.5; % The actual width of an image, in mm
    MeasDepth=2; % The depth of the measuring volume, in mm
    SubDiff=50; % The amount to subtract between marker/mask during image reconstruction, can be skipped by setting to 0
    BlockSize=2; % The width (in mm) of each block to be processed for background removal 
    Lvl=0.1; % The threshold level, standard is 0.1
    MaxInt=0.5; % The fraction of the maximum intensity required for individual particles
    CalcPSD=1; % If 1, particle characteristics will be calculated, if 0 they will not
    PlotResults=1; % If 0 the image and plots are not shown, 1 they are shown, 2 they are shown in subplots
end
%% Check if required toolbox and function exists
% Is the Image Processing Toolbox installed?
if license('checkout','Image_Toolbox')
    try
        J = adapthisteq(rand(8,8));
    catch
        disp('ERROR: Image Processing Toolbox not found!')
        result=0;
    end
else
    disp('ERROR: Image Processing Toolbox not found!')
end

%% Load data 
if exist('stats','var') % Make sure that old stats are cleared before proceeding
    clear('stats')
end

PathFile=[Path FileName];

warning('off','MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero') % Turns off redundant warning message
info=imfinfo(PathFile);
warning('on','MATLAB:imagesci:tifftagsread:badTagValueDivisionByZero') % Turns it on again
if ismember('DateTime',fieldnames(info))
    DateTime=datenum(info.DateTime,'yyyy:mm:dd HH:MM:SS');
else
    DateTime=datenum(info.FileModDate);
end
pixelsize=(ImHeight/info.Height)*1000; % Pixel size (in microns) is sensor size divided by amount of pixels 
rgb = imread(PathFile); % Load the image

%% Remove noise/out-of-focus and correct background
if SubDiff~=0
    [img, rgb, imrec]=ImRec(rgb,BlockSize,pixelsize,SubDiff,PlotResults); % Load the image reconstruction function
else
    if size(rgb,3)==3
        img = rgb2gray(rgb);
    else
        img = rgb;
    end
    imrec = img;
end
%% Extract usable particles
bw_all=im2bw(imrec,double(max(max(imrec))*Lvl)/255); % Convert to black and white image
bw_all=imclearborder(bw_all); % And clear particles that touch the border
CC=bwconncomp(bw_all,4); % Find individual particles

stats_all=regionprops(CC,img,'Area','EquivDiameter','Centroid','MaxIntensity','MinIntensity','MeanIntensity','PixelIdxList','Image','MajorAxisLength','MinorAxisLength','ConvexImage', 'Solidity','Perimeter');

if size(stats_all,1)>=1 % Only continue if there's at least one particle, otherwise unusable picture
    if MaxInt~=0
        MI=double([stats_all.MaxIntensity]);
        ind=MI>(max(MI)*MaxInt); % Only select particles that has at least one pixel with an intensity over MaxInt * the overall maximum intensity.
        stats=stats_all(ind',:);
        
        bw = false(size(bw_all));
        for g=1:size(stats,1)
            bw(stats(g).PixelIdxList)=1;
        end
        % ^ The bw-picture is corrected according to the MaxIntensity-rule
    else
        stats=stats_all;
        bw=bw_all;
    end
end
%% Calculate particle characteristics
if exist('stats','var') % Only continue if stats exists, otherwise the picture is black (empty)
if CalcPSD==1
    
% Calculate size parameters and size distribution
[binsloc,~,~]=fileparts(mfilename('fullpath')); % Locate the folder where the script is running from
load(fullfile(binsloc,'Bins.mat')); % Load the size bins that will be used for statistics

EqDiameter=([stats.EquivDiameter].*pixelsize)'; % This is equivalent spherical diameter in microns
Volume=((4/3)*pi()*([stats.EquivDiameter]/2).^3); % Calculate equivalent spherical volume
Volume=Volume*10^-9; % Convert to microliter (or millimeter cubed)

[freq_n(1:size(bins,1),1),BinInd]=histc(EqDiameter,bins); % Sort spherical diameter in bins
freq=freq_n/sum(freq_n); % And calculate frequency in each bin
freq=freq(1:end-1,:);

% Calculate volume distribution
Vols(1:length(midpoints),1)=zeros;
Vols(1:max(BinInd),1)=accumarray(BinInd,Volume'); % Sum volumes according to bins
Vols=Vols/((ImHeight*ImWidth*MeasDepth)*10^-6); % Change volumes to volume concentration, in microliters (particles) pr. liter (water), same as ppm
VC=sum(Vols); % Total volume concentration

% Calculate mean diameter and standard deviation
if size(freq,1)>0;
    midpoints_phi(:,1)=-log(midpoints(:,1)/1000)/log(2); % The particle diameter represented by each bin is recalculated to phi-units
    freq_phi=freq.*midpoints_phi;
    DiameterMean_phi=sum(freq_phi);
    DiameterMean=(10^(-1*DiameterMean_phi*log10(2)))*1000; % The mean diameter is calculated and converted back to microns
    DiameterStd=sqrt((sum(freq.*((midpoints-DiameterMean)).^2)/100)); % According to method of moments (almost like "normal" stddev-calc)
end

% Calculate shape parameters
ConvexPerimeter=NaN(size(stats,1),1);
for i=1:size(stats,1)
    tmp=regionprops(stats(i).ConvexImage,'Perimeter'); % Get perimeter of convex image
    ConvexPerimeter(i,1)=tmp.Perimeter; % ... This is the convex perimeter
end
Convexity=ConvexPerimeter./[stats.Perimeter]'; % And this is most correct way to calcualte convexity
Sphericity=abs([stats.MinorAxisLength]./[stats.MajorAxisLength]);
for i=1:size(stats,1)
    stats(i).ConvexPerimeter=ConvexPerimeter(i);
    stats(i).Convexity=Convexity(i);
    stats(i).Sphericity=Sphericity(i);
end

end
%% Plot results
try
overlay=imoverlay_orig(rgb,bw,[1 1 1]);
% ^ This script, originally from the Matlab File Exchange, puts the in-focus 
% particles/selected pixels on top of the original rgb-image
catch err
    disp('ERROR: You have not downloaed the imoverlay_orig file from the archive.')
    disp('This file is necessary to do background correction and noise removal.')
    disp('If you have downloaded it, the file is not placed in path that is searchable by Matlab.')
end

if PlotResults==1;
    figure('Name','RGB image with particle numbers'); imshow(rgb, 'InitialMag', 'fit')
    hold on
    for i=1:size(stats,1)
        text(stats(i).Centroid(1),stats(i).Centroid(2),num2str(i),'Color','w')
    end
    hold off
    
    figure('Name','Selected particles (white) on top of unedited image (green)');
    imshow(overlay, 'InitialMag', 'fit')
        
    figure('Name',['Histogram, Matlab, ' 'Threshold level=' num2str(Lvl) ', Subdiff=' num2str(SubDiff)]) 
    hist(EqDiameter,bins) % Plot as histogram
    xlabel('Particle ESD, \mum'), ylabel('Count')
    set(gca,'XScale','log')
    xlim([1 10000])
    
    figure('Name', ['PSD, Matlab, ' 'Threshold level=' num2str(Lvl) ', Subdiff=' num2str(SubDiff)]) 
    semilogx(midpoints,freq) % Plot as PSD
    xlabel('Particle ESD, \mum'),ylabel('Frequency')
    legend(['Mean D= ',num2str(round(DiameterMean)),' \mum'])

elseif PlotResults==2;
    figure('Name', [FileName,', Threshold level=' num2str(Lvl) ', Subdiff=' num2str(SubDiff), ', MaxInt=' num2str(MaxInt)]) 
    subplot(2,2,1); 
    imagesc(0:(size(rgb,2)*(pixelsize/1000)),0:(size(rgb,1)*(pixelsize/1000)),rgb) % Show with mm as scale
    axis('image'), xlabel('10^3 \mum')

    subplot(2,2,2);
    hist(EqDiameter,bins) % Plot as histogram
    xlabel('Particle ESD, \mum'), ylabel('Count')
    set(gca,'XScale','log'), xlim([1 10000])
    
    subplot(2,2,3);
    imagesc(0:(size(rgb,2)*(pixelsize/1000)),0:(size(rgb,1)*(pixelsize/1000)),overlay) % Show with mm as scale
    axis('image'), xlabel('10^3 \mum')
    
    subplot(2,2,4);
    semilogx(midpoints,freq) % Plot as PSD
    xlabel('Particle ESD, \mum'),ylabel('Frequency'), xlim([1 10000])
    legend(['Mean ESD = ',num2str(round(DiameterMean)),' \mum'])
end
end