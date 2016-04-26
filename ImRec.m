%% Finding local maxima using morphological reconstruction

function [img, rgb, imrec]=ImRec(rgb,BlockSize,pixelsize,SubDiff,Show)

%% Initialize
if size(rgb,3)==3 % Convert rgb image to grayscale
    img = rgb2gray(rgb);
else % If the image does not have three layes it is not an rgb but a grayscale
    img = rgb;
end

if Show==1
    figure('Name','Original image'), imshow(rgb, 'InitialMag', 'fit')
end

%% Remove background noise
fun = @(block_struct) min(block_struct.data); % Create a function that find the minimum value of individual blocks
w = ceil((BlockSize*1000)/pixelsize); % The block size is defined in the value input section
bg = blockproc(img,[w w],fun); % Apply the function to the image approximating the background value of each block
bg = imresize(bg, size(img), 'bilinear'); % Resize the background value image 
img = img-bg; % And subtract background values from the original image

%% Create marker image (slightly darker than input image)
marker = img-SubDiff;
% mask is the input image
mask = img;

%% Reconstruct image
imrec = imreconstruct(marker,mask,4);
% and calculate the difference to get the maxima
imgdif = (img-imrec) > 5;
% ^ The difference has to be more than five in order to be plotted. This
% only influences the plotting, so that the major differences become more
% clear. Changing the value does not alter the results of the reconstruction.

%% Plot everything
if Show==1
    figure('Name','Image reconstruction')
    subplot(2,2,1), imshow(img), title('original')
    subplot(2,2,2), imshow(marker), title('marker')
    subplot(2,2,3), imshow(imrec), title('reconstructed')
    subplot(2,2,4), imshow(imgdif), title('threshold of difference')
    figure('Name','Reconstructed image'), imshow(imrec, 'InitialMag', 'fit')
end
