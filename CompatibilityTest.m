%% Check if required toolbox and function exists
% Is the version of Matlab new enough?
if verLessThan('matlab','8')
    disp('NOTE: The ParChar code has not been tested on this version of Matlab. It has been tested on R2012b (ver. 8.0) and newer. Issues may occur.')
else
    disp('-> The version of Matlab is new enough')
    c=1;
end
% Is the Image Processing Toolbox installed?
if license('checkout','Image_Toolbox')
    disp('-> Image Processing Toolbox found')
    c=c+1;
else
    disp('ERROR: Image Processing Toolbox not found!')
end

% Has the imoverlay function been downloaded and installed?
if ~exist('imoverlay_orig','file')
    disp('ERROR: You have not downloaed the imoverlay_orig file from the archive.')
    disp('This file is necessary to do background correction and noise removal.')
    disp('If you have downloaded it, the file is not placed in path that is searchable by Matlab.')
else
    disp('-> imoverlay_orig function installed')
    c=c+1;
end

% Has the ImRec function been downloaded and put in a searchable location?
if ~exist('ImRec','file')
    disp('ERROR: You have not downloaed the ImRec file from the archive.')
    disp('This file is necessary to do background correction and noise removal.')
    disp('If you have downloaded it, the file is not placed in path that is searchable by Matlab.')
else
    disp('-> ImRec function has been downloaded')
    c=c+1;
end
    
% Has the bins.mat-file been downloaded and placed in the folder of the
% script?
[binsloc,~,~]=fileparts(mfilename('fullpath'));
if ~exist(fullfile(binsloc,'Bins.mat'),'file')
    disp('ERROR: You have not downloaed the Bins.mat file from the archive')
    disp('This file is necessary to do the particle characterizations.')
else
    disp('-> Bins.mat has been downloaded')
    c=c+1;
end
if c==5
    disp('=> Everything seems to be in order, you are good to go!')
end