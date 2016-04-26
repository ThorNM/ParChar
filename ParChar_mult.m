%% Analyze multiple images
clearvars, clc

[File,Path] = uigetfile({'*.jpg;*.tiff;*.tif;*.bmp'},'Select first file to process'); 
Savepath = uigetdir('','Select save-to directory');

ImHeight=15; % The actual height of an image, in mm
ImWidth=22.5; % The actual width of an image, in mm
MeasDepth=1; % The depth of the measuring volume, in mm
SubDiff=0; % The amount to subtract between marker/mask during image reconstruction
BlockSize=2; % The width (in mm) of each block to be processed for background removal 
Lvl=0.10; % The threshold level, standard is 0.1
MaxInt=0.5; % The fraction of the maximum intensity required for individual particles
CalcPSD=1; % If 1, particle characteristics will be calculated
PlotResults=0; % If 0 the image and plots are not shown, 1 they are shown, 2 they are shown in subplots

[~,~,ext]=fileparts(File); % Find the extension of the selected files
ext=['*',ext]; % Add asterix to be able to select all similar files
files=dir(fullfile(Path,ext)); % Make directory of all similar files in the selected folder

statsDS=table();
psdDS=dataset();
o = waitbar(0,'Processing images... ');
for l=1:size(files,1)
    FileName=files(l,1).name;
    tic,ParChar,toc
    if exist('stats','var') % Only continue if stats exists, otherwise picture is empty
        bins_categories(1:length(midpoints),1)={0};
        bins_vol_categories(1:length(midpoints),1)={0};
        for i=1:length(midpoints) % Create names for each bin to use as a header later
            bins_categories(i,1)={['Freq',num2str(midpoints(i,1))]};
            bins_vol_categories(i,1)={['BinVol',num2str(i)]};
        end
        bins_categories=strrep(bins_categories,'.','_'); % Change dot to underscore
        
        AreaTotal=sum([stats.Area]); % Calculate total area (in pixels) of particles
        NumParticles=size(stats,1); % Count the number of particles in the picture
        Sphericity=mean([stats.Sphericity]);
        psdDS(size(psdDS,1)+1,:)=dataset(DateTime,{Vols',bins_vol_categories{:}},...
            {freq',bins_categories{:}},DiameterMean,DiameterStd,AreaTotal,VC,NumParticles,Sphericity);
        
        if strcmp(psdDS.Properties.VarNames(1),'Var1') % If variable names have not been assigned, they will be here
            header=dataset(DateTime,{Vols',bins_vol_categories{:}},...
            {freq',bins_categories{:}},DiameterMean,DiameterStd,AreaTotal,VC,NumParticles,Sphericity);
            psdDS.Properties.VarNames=header.Properties.VarNames;
        end

        [~,name]=fileparts(FileName);
        nam={};
        for d=1:size(stats,1)
             nam(d)={[name '_' num2str(d)]};
        end
        st=height(statsDS);
        statsDS(st+1:st+size(stats,1),:)=struct2table(stats,'AsArray',true);
        statsDS.Properties.RowNames(st+1:st+size(stats,1))=nam;
    else
        psdDS(size(psdDS,1)+1,1:105)=dataset(NaN);
        psdDS(size(psdDS,1),1)=dataset(DateTime);
    end
    [~,name]=fileparts(FileName);
    psdDS.Properties.ObsNames(size(psdDS,1))=cellstr(name);

    psdDS(sum(double(psdDS),2)==0,:)=dataset(NaN); % If any empty (zero-valued) rows did not get NaN's they will now

    if height(statsDS)>10000 % Save to file whenever there's more than 10000 psds (clear memory afterwards)
        save(fullfile(Savepath,['Partcam_' num2str(l) '.mat']),'statsDS')
        clearvars -except psdDS Path Savepath ImHeight ImWidth MeasDepth SubDiff Lvl MaxInt CalcPSD PlotResults l files o 
        statsDS=table();
    else
        clearvars -except psdDS statsDS Path Savepath ImHeight ImWidth MeasDepth SubDiff Lvl MaxInt CalcPSD PlotResults l files o
    end
    waitbar(l/size(files,1))
end
Partcam=dataset2table(psdDS);
save(fullfile(Savepath,['Partcam_' num2str(l) '.mat']),'statsDS') % Save the last stats-data to file
save(fullfile(Savepath,'Pcam_all.mat'),'Partcam') % Save the PSD-data to file
close(o)
