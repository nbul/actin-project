%% Preallocate memory

to_analyse_o = struct([]);
to_analyse_c = struct([]);
to_analyse_all = struct([]);
to_analyse_back_o = struct([]);

mts_density = zeros(1, numel(b_valid));
mts_area = zeros(1, numel(b_valid));
Uniformity = zeros(1, numel(b_valid));
Spars = zeros(1, numel(b_valid));
mts_bundling = zeros(1, numel(b_valid));
kurt = zeros(1, numel(b_valid));
skew = zeros(1, numel(b_valid));

%% Processed Image for Density Analysis
if method == 1
    image_original_double = double(im2uint16(Image2)); % original into double
else
    image_original_double = im2double(Image2);
end

image_edges = edge(Image2, 'Canny');
signal_edges = image_original_double .* image_edges;

if method == 1
    [A1, A2] = histcounts(signal_edges(signal_edges>0));
    bins = (min(A2)+((A2(2)-A2(1))/2)):((A2(2)-A2(1))):(max(A2)-((A2(2)-A2(1))/2));
    [XOut,YOut] = prepareCurveData(bins,A1);
    fo = fitoptions('gauss1', 'Lower', [0 min(A2) 0], 'Upper', [Inf max(A2) Inf]);
    [threshold1, gof_edges] = fit(XOut, YOut, 'gauss1', fo);
    threshold = threshold1.b1*0.7;
    im_bin_c = imbinarize(image_original_double,threshold);
elseif method == 0
    threshold = graythresh(imadjust(image_original_double))*0.7;
    im_bin_c = imbinarize(imadjust(image_original_double),graythresh(imadjust(image_original_double))*0.7);
elseif method == 2
    Mat = zeros((im_x-2)*(im_y-2),2);
    counter4=0;
    im_adjusted = imadjust(image_original_double);
    for xc=2:(im_x-1)
        for yc=2:(im_y-1)
            counter4=counter4+1;
            Mat(counter4,1) = im_adjusted(yc,xc);
            Mat(counter4,2) = (im_adjusted(yc-1,xc-1) + im_adjusted(yc-1,xc) + im_adjusted(yc-1,xc+1) +...
                im_adjusted(yc+1,xc-1) + im_adjusted(yc+1,xc) + im_adjusted(yc+1,xc+1) +...
                im_adjusted(yc,xc-1) + im_adjusted(yc,xc+1))/8;
        end
    end
    Mat2 = hist3(Mat,'Nbins',[256, 256]);
    threshold = TwoDOtsumine(Mat2, length(Mat))*0.7/255;
    im_bin_c = imbinarize(imadjust(image_original_double));
elseif method == 3
   Mat = zeros((im_x-2)*(im_y-2),3);
    counter4=0;
    for xc=2:(im_x-1)
        for yc=2:(im_y-1)
            counter4=counter4+1;
            Mat(counter4,1) = Image2(yc,xc);
            Mat(counter4,2) = (Image2(yc-1,xc-1) + Image2(yc-1,xc) + Image2(yc-1,xc+1) +...
                Image2(yc+1,xc-1) + Image2(yc+1,xc) + Image2(yc+1,xc+1) +...
                Image2(yc,xc-1) + Image2(yc,xc+1))/8;
            median_mat = Image2(yc-1:yc+1,xc-1:xc+1);
            Mat(counter4,3) = median(median_mat(:));
        end
    end
    
    myfunc = @(X,K)(kmeans(X, K, 'replicate',5));
    eva = evalclusters(Mat,myfunc,'DaviesBouldin',...
        'klist',2:15);
    
    km = kmeans(Mat,eva.OptimalK,'replicate',5);
    km2 = reshape(km, im_y-2,im_x-2);
    Image2_small = Image2(2:end-1,2:end-1);
    thr = zeros(eva.OptimalK,1);
    for clust = 1:eva.OptimalK
        thr(clust) = mean(Image2_small(km2==clust));
    end
    [Num1, Idx1] = min(thr);
    threshold = max(Image2_small(km2==Idx1));
    im_bin_c = imbinarize(im2double(Image2),double(threshold)/255/255);
end


%% Generate Cell Masks.
signal_original = image_original_double .* im_bin_c;
background_original = image_original_double .* (ones(im_x,im_y) - im_bin_c);

for k = 1:numel(b_valid)
    clear selected_signal
    % Density data from signal and background
    selected_signal = poly2mask(b_valid{k}(:,2),b_valid{k}(:,1),im_x,im_y);
    to_analyse_o = regionprops(selected_signal, signal_original,'PixelValues');
    to_analyse_c = regionprops(selected_signal, im_bin_c,'PixelValues');
    to_analyse_back_o = regionprops(selected_signal, background_original,'PixelValues');
    to_analyse_all = regionprops(selected_signal, image_original_double,'PixelValues');
    
    % Relative to background and signal area 
    sum_pixvalues_o = sum(to_analyse_o.PixelValues(:,1));
    sum_pixvalues_back_o = sum(to_analyse_back_o.PixelValues(:,1));
    num_pixvalues_c = length(to_analyse_c.PixelValues(to_analyse_c.PixelValues(:, 1) ~= 0,1));
    num_pixvalues_back_c = length(to_analyse_c.PixelValues(to_analyse_c.PixelValues(:, 1) == 0,1));
    
    mts_density(k) = (((sum_pixvalues_o / num_pixvalues_c) - (sum_pixvalues_back_o / num_pixvalues_back_c)) / ...
        (sum_pixvalues_back_o / num_pixvalues_back_c)) * (num_pixvalues_c / (num_pixvalues_c + num_pixvalues_back_c));
    
    % Signal Area
    mts_area(k) = num_pixvalues_c / (num_pixvalues_c + num_pixvalues_back_c);   
    
    % Relative to edges intensity
    if max(to_analyse_c.PixelValues)~= 0
        mts_bundling(k) = (mean(to_analyse_o.PixelValues(to_analyse_c.PixelValues(:,1)~= 0,1))-...
            min(to_analyse_o.PixelValues(to_analyse_c.PixelValues(:,1)~= 0,1))) / ...
            min(to_analyse_o.PixelValues(to_analyse_c.PixelValues(:,1)~= 0,1));
%         mts_bundling(k) = (((sum_pixvalues_o / num_pixvalues_c) - (sum_pixvalues_back_o / num_pixvalues_back_c)) / ...
%             (sum_pixvalues_back_o / num_pixvalues_back_c));
        %         mts_bundling(k) = mean(to_analyse_o.PixelValues(to_analyse_c.PixelValues(:,1)~= 0,1))...
        %             /min(to_analyse_o.PixelValues(to_analyse_c.PixelValues(:,1)~= 0,1));
    else
        mts_bundling(k) = 0;
    end
    
    % Uniformity
    Uniformity(k) = 100 * (1 - sum(abs(to_analyse_all.PixelValues - mean(to_analyse_all.PixelValues))./...
        (to_analyse_all.PixelValues + mean(to_analyse_all.PixelValues)))/length(to_analyse_all.PixelValues));
    %Sparseness
    Spars(k) = calcSparseness(to_analyse_o.PixelValues/mean(to_analyse_o.PixelValues(to_analyse_o.PixelValues>0)),1);
    
    % Kurtosis and skewness
    if max(to_analyse_c.PixelValues)~= 0
        signal = to_analyse_all.PixelValues - min(to_analyse_o.PixelValues(to_analyse_c.PixelValues(:,1)~= 0,1));
        kurt(k) = kurtosis(signal);
        skew(k) = skewness(signal);
    else
        signal = 0;
        kurt(k) = 0;
        skew(k) = 0;
    end
end
