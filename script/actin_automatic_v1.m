% Script for Automatic Analysis of N embryos
% The number of filesets should be entered for each experiment
% Adapted to use Sobel 5x5 to find direction
% Check analysis of Microtubule density

clear all
close all

cd('../../');
cd('actin/');
files = dir('*.tif');
cd('../');
mkdir('distribution');
mkdir('summary');
mkdir('images_analysed');
for loop=1:length(files);
    cd('actin/');
    clear Name Number Actin_file Image_actin Path  Image_borders
    Name = files(loop).name;
    Number = sscanf(Name, '%f');
    Actin_file = [num2str(Number),'.tif'];
    Image_actin = imread(Actin_file);
    cd('../');
    Path = ['borders/', num2str(Number),'/'];
    cd(Path);
    Image_borders = imread('tracked_bd.png');
    cd('../../');
    
    cd('actin-project/script/');
    actin_analysis_v1;
    cd('../../');
 
    cd('distribution/');
    gradient_filename = [num2str(Number),'_distribution.csv'];
    csvwrite(gradient_filename, m_added_norm);
    cd('../');
    
    cd('images_analysed/');
    image_filename = [num2str(Number),'_analysed_image.tif'];
    print(image1, '-dtiff', '-r150', image_filename);
    cd('../');
    
    cd('actin-project/script/');
    vonmises_fit_dist_sum;
    cd('../../');
    
    cd('summary/');
    summary = zeros(length(SD),8);
    for counter2 = 1:length(SD)
        summary(counter2,1) = counter2;
    end
    summary(:,2) = mts_density';
    summary(:,3) = SD';
    summary(:,4) = mu_degrees';
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
    headers = {'Cell', 'Density', 'SD', 'Direction_actin','Area', 'Eccentricity', 'Dorection_cell','DEV', 'Signal Area'};
    csvwrite_with_headers(summary_filename,summary,headers);
    cd('../');
    close all
end

cd('actin-project/script/');
