% Script for Automatic Analysis of N embryos
% The number of filesets should be entered for each experiment
% Adapted to use Sobel 5x5 to find direction
% Check analysis of Microtubule density

clc
clear variables
close all
%% Determening paths and setting folders
currdir = pwd;
addpath(pwd);
filedir = uigetdir();
cd(filedir);
%Folders with images
ck_dir =[filedir, '/cytoskeleton']; 
b_dir = [filedir, '/borders'];

%Folder to save information about cells
mkdir(filedir,'/distribution');
dist_dir = [filedir, '/distribution'];

mkdir(filedir,'/images_analysed');
im_dir = [filedir, '/images_analysed'];

mkdir(filedir,'/summary');
sum_dir = [filedir, '/summary'];
%% Number of files to analyse
cd(ck_dir);
files = dir('*.tif');
cd(currdir);

%% Parameters
bin_size = 4;
binrange = -90 : bin_size : 90;
bincenter=binrange(1:(end-1)) + bin_size/2;

for loop=1:length(files);
    %% reading files
    cd(ck_dir);
    clear Name Number Actin_file Image_actin Path  Image_borders
    Name = files(loop).name;
    Number = sscanf(Name, '%f');
    Actin_file = [num2str(Number),'.tif'];
    Image_actin = imread(Actin_file);
    cd(b_dir);
    Path = [b_dir, '/', num2str(Number),'/'];
    cd(Path);
    Image_borders = imread('tracked_bd.png');
    
    %% Running analysis script
    actin_analysis_v1;
    
    %% writing down distributions in each image and analysed image
    cd(dist_dir);
    gradient_filename = [num2str(Number),'_distribution.csv'];
    csvwrite(gradient_filename, m_added_norm);
    
    cd(im_dir);
    image_filename = [num2str(Number),'_analysed_image.tif'];
    print(image1, '-dtiff', '-r150', image_filename);
    
    %% Von-Mises fit
    vonmises_fit_dist_sum;
    
    %% Writing down summarised data
    
    summary = zeros(length(SD),8);
    for counter2 = 1:length(SD)
        summary(counter2,1) = counter2;
    end
    summary(:,2) = mts_density';
    summary(:,3) = SD';
    summary(:,4) = mu';
    summary(:,5) = cell_data(:,2);
    summary(:,6) = cell_data(:,3);
    summary(:,7) = cell_data(:,4);
    for counter2 = 1:length(SD)
        if (abs(summary(counter2, 4)-summary(counter2, 7)) >= 90)
            summary(counter2, 8) = 180 - abs(summary(counter2, 4)-summary(counter2, 7));
        else
            summary(counter2, 8) = abs(summary(counter2, 4)-summary(counter2, 7));
        end
    end
    summary(:,9) = mts_area';
    
    summary_filename = [num2str(Number),'_summary.csv'];
    headers = {'Cell', 'Density', 'SD', 'Direction_cytoskeleton','Area', 'Eccentricity', 'Dorection_cell','DEV', 'Signal Area'};
    cd(sum_dir);
    csvwrite_with_headers(summary_filename,summary,headers);
    close all
end

cd(currdir);

clc
clear variables
close all