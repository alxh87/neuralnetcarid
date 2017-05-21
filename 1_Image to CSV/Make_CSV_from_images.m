% Making CSVs from car images
clear all;
close all;

% Browse for the image file. 
[baseFileName, folder] = uigetfile({'*.jpg','JPG Files (*.jpg)'},...
    'Specify an image file (Multiple files allowed)','MultiSelect','on'); 
fullImageFileName = fullfile(folder, baseFileName);

if isnumeric(baseFileName);
    return;
elseif ischar(baseFileName);
    baseFileName=cellstr(baseFileName);
end

for idx=baseFileName;
    
    %imStr=sprintf('%03d.jpg', idx);
    %disp(imStr);
    %continue;
    
    imStr=char(idx);
    
    oldFolder=cd(folder);
    colorImage = imread(imStr);
    cd(oldFolder);
    
    
    
    [imHeight, imWidth, dim]=size(colorImage);
    fprintf('Filename: %s (Height = %d, Width = %d)\n', imStr, imHeight, imWidth);

    I = rgb2gray(colorImage);

    % Detect MSER regions.
    ROIRegion = [int16(imWidth/3), int16(imHeight*3/8), int16(imWidth/3), int16(imHeight/2)];
    [mserRegions, mserConnComp] = detectMSERFeatures(I,...
                                'RegionAreaRange', [2000 11000],...
                                'MaxAreaVariation', 0.25,...
                                'ROI', ROIRegion);
    
    % Use regionprops to measure MSER properties
    mserStats = regionprops(mserConnComp, 'BoundingBox', 'Eccentricity', ...
        'Solidity', 'Extent', 'Euler', 'Image');

    % Compute the aspect ratio using bounding box data.
    bbox = vertcat(mserStats.BoundingBox);
    w = bbox(:,3);
    h = bbox(:,4);
    aspectRatio = w./h;

    % Threshold the data to determine which regions to remove. These thresholds
    % may need to be tuned for other images.
    filterIdx = aspectRatio' > 6.1;
    filterIdx = filterIdx | aspectRatio' < 2.3; 
    %filterIdx = filterIdx | [mserStats.Eccentricity] > .995 ;
    filterIdx = filterIdx | [mserStats.Solidity] < 0.46;
    filterIdx = filterIdx | [mserStats.Extent] < 0.43 | [mserStats.Extent] > 0.9;
    filterIdx = filterIdx | [mserStats.EulerNumber] > -2 | [mserStats.EulerNumber] < -100;
    
    % Remove too big boxes if height more than 50px
    filterIdx = filterIdx | (bbox(:,4) > 90)';
    % Remove too big boxes if width more than 26% of width
    filterIdx = filterIdx | (bbox(:,3) > (imWidth*0.26))';
    % Remove if centre of Y coordinates upper than half
    filterIdx = filterIdx | ((bbox(:,2)+(bbox(:,4)/2)) < (imHeight / 2))';
    % Remove if centre of X coordinates too far from centre (7.5%)
    filterIdx = filterIdx | ((abs((bbox(:,1)+(bbox(:,3)/2))-(imWidth / 2))) > (imWidth*0.075))';
    
    % Remove regions
    mserStats(filterIdx) = [];
    mserRegions(filterIdx) = [];
    %mserStats.Solidity
    
    if size(mserStats, 1) > 0;
        % Pick only One which has maximum extent value.
        max_ext_idx=1;
        max_ext_value=0;
        for z=1:size(mserStats, 1)
            % fprintf('%.1f %.1f %d %d Eu:%d S:%.2f Ex:%.2f\n',mserStats(z).BoundingBox,mserStats(z).EulerNumber,mserStats(z).Solidity,mserStats(z).Extent);
            if mserStats(z).Extent > max_ext_value
                max_ext_idx=z;
                max_ext_value=mserStats(z).Extent;
            end
        end
        selected_box=mserStats(max_ext_idx).BoundingBox;
        fprintf('Selected Box = %d %d %d %d\n',int16(selected_box));
                
        % Get bounding boxes for all the regions
        bboxes = vertcat(mserStats.BoundingBox); 
        
        % Show the expanded bounding boxes
        IExpandedBBoxes = insertShape(colorImage,'Rectangle',bboxes,'LineWidth',3);
        FinalImg = insertShape(IExpandedBBoxes,'Rectangle',selected_box,'LineWidth',3,'Color','red');
        
        % Show remaining regions
        subplot(3,3,1);
        imshow(FinalImg);
        title(sprintf('MSER Region of %s', imStr));
        subplot(3,3,2);
        cropImg=imcrop(I,selected_box);
        imshow(cropImg);
        title('Cropped Greyscale Image');
        xlabel(sprintf('[%d x %d]',size(cropImg,2),size(cropImg,1)));
        subplot(3,3,3);
        imhist(cropImg);
        title('Histogram of cropped image');
        
        % Calculate median value in grey image
        [counts, binLists]=imhist(cropImg);
        max1_bin=0;
        max1_count=0;
        for k=1:256;
            if counts(k) > max1_count;
                max1_count=counts(k);
                max1_bin=k;
            end
        end
        max2_bin=0;
        max2_count=0;
        for k=256:-1:1;
            if (counts(k) > max2_count) &&...
                    (counts(k) < max1_count) &&...
                    (abs(k-max1_bin) > 40);
                max2_count=counts(k);
                max2_bin=k;
            end
        end
        if max1_bin > max2_bin;
            tempswap=max2_bin;
            max2_bin=max1_bin;
            max1_bin=tempswap;
        end
        threshold=((max1_bin+max2_bin)/2);
        %fprintf('Left Max = %d, Right Max = %d, Threshold = %d(%.2f)\n', max1_bin, max2_bin, int16(threshold), threshold/256);
        hold on;
        ylim=get(gca,'ylim');
        line([threshold threshold],ylim,'Color','r');
        hold off;
        xlabel(sprintf('Threshold level=%d',int16(threshold)));
        
        subplot(3,3,4);
        bwCropImg=im2bw(cropImg,threshold/256);
        imshow(bwCropImg);
        title('Binary converted Image');        
        
        % Inverse Image if black is majority
        if (sum(sum(bwCropImg))/prod(size(bwCropImg))) < 0.375;
            bwCropImg=not(bwCropImg);
            %disp('Inverted');
        end
        
        % Strip Image vertically (first and last 3%)
        xmax=size(bwCropImg,2);
        ymax=size(bwCropImg,1);
        limit_strip=int16(xmax*0.03);
        limit_black=int16(ymax*0.25);       % 75% (1-0.75)
        limit_white=int16(ymax*0.90);       % 90%
        %fprintf('VStrip:%d, Limit_Black:%d, Limit_White:%d\n',limit_strip,limit_black,limit_white);
        vertical_sum=sum(bwCropImg,1);
        strip_flag=(vertical_sum < limit_black) | (vertical_sum > limit_white);
        for i=limit_strip:xmax-limit_strip;
            strip_flag(i)=0;
        end
        
        left_strip=0;
        right_strip=0;
        for i=1:limit_strip
            if i > 3 && strip_flag(i) == 1 &&...
                    strip_flag(i-1) == 0 &&...
                    strip_flag(i-2) == 0 &&...
                    strip_flag(i-3) == 0;
                strip_flag(i) = 0;
            end
            if strip_flag(i) == 1;
                left_strip = i;
            end
            if i > 3 && strip_flag(xmax-i+1) == 1 &&...
                    strip_flag(xmax-i+2) == 0 &&...
                    strip_flag(xmax-i+3) == 0 &&...
                    strip_flag(xmax-i+4) == 0;
                strip_flag(xmax-i+1) = 0;
            end                    
            if strip_flag(xmax-i+1) == 1;
                right_strip = i;
            end
        end
        
        for i=1:left_strip
            strip_flag(i) = 1;
        end
        for i=1:right_strip
            strip_flag(xmax-i+1) = 1;
        end
        
        bwCropImg(:,strip_flag) = [];
        
        % Strip Image horizontally
        horizontal_sum=sum(bwCropImg,2);
        centre_y=int16(size(bwCropImg,1)/2);
        %avg_centre_5lines=int16(mean(horizontal_sum(centre_y-2:centre_y+2)));
        %threshold = int16(avg_centre_5lines * 1.4);
        adj = int16(centre_y/4);
        max_CropImg = max(horizontal_sum);
        threshold = max(horizontal_sum(centre_y-adj:centre_y+adj));
        adjust_threshold = int16((max_CropImg-threshold)/3);
        %fprintf('Width = %d, Threshold=%d(+%d), Max=%d\n',size(bwCropImg,2),threshold,adjust_threshold,max_CropImg);
        strip_flag=boolean(zeros(ymax,1));
        upper_threshold=threshold+adjust_threshold;
        lower_threshold=int16(threshold/3);
        for i=centre_y-3:-1:1;
            if or(horizontal_sum(i) > upper_threshold, horizontal_sum(i) < lower_threshold);
                break;
            end
        end
        for j=1:i
            strip_flag(j)=1;
        end
        for i=centre_y+3:ymax;
            if or(horizontal_sum(i) > upper_threshold, horizontal_sum(i) < lower_threshold);
                break;
            end
        end
        for j=i:ymax
            strip_flag(j)=1;
        end
        bwCropImg(strip_flag,:)=[];    
        %{
        subplot(3,3,7);
        bar(horizontal_sum);
        xlim([1 ymax]);
        title('Vertical Histogram of Binary Image');
        hold on;
        plot(xlim,[upper_threshold upper_threshold],'r');
        plot(xlim,[lower_threshold lower_threshold],'g');
        hold off;
        %}
        subplot(3,3,5);
        imshow(bwCropImg);
        title('Stripped Image');
        xlabel(sprintf('[%d x %d]',size(bwCropImg,2),size(bwCropImg,1)));
        
        % Resize Image
        AdjustedWidth=int16(20*size(bwCropImg,2)/size(bwCropImg,1));
        FinalImage=imresize(bwCropImg,[20 AdjustedWidth]);
        
        % Clear useless solid line on both top and bottom 3 lines
        xmax=size(FinalImage,2);
        ymax=size(FinalImage,1);
        for i=[1 2 3 18 19 20];
            FinalImage(i,:)=MyFunc2(FinalImage(i,:));
        end
        
        subplot(3,3,6);
        imshow(FinalImage);
        title('Fixed Height Image');
        xlabel(sprintf('[%d x %d]',AdjustedWidth,20));
        
        
        
        subplot(3,3,9);
        inverted_FinalImage=not(FinalImage);
        horizontal_sum=sum(inverted_FinalImage,1);
        bar(horizontal_sum);
        title('Horizontal Histogram of stripped image');
        xlim([1 xmax]);
        
        % Pre-adjustment
        temp_strip=0;
        original_horizontal_sum=horizontal_sum;
        while MyFunc1(horizontal_sum) > 18;
            %fprintf('%d %d  ',MyFunc1(horizontal_sum),temp_strip);
            temp_strip=temp_strip+1;
            %fprintf('strip:%d ',temp_strip);
            horizontal_sum=horizontal_sum-1;
        end
        
        cropped_letters=[];
        start_part=false;
        extend_right=false;
        hold on;
        plot(xlim,[temp_strip temp_strip]);
        for i=1:xmax;
            if horizontal_sum(i) > 0
                if ~start_part;
                    start_part=true;
                    starting_point=i;
                    plot([i i],[1 20],'r');
                    extend_right=false;
                end
            else
                if start_part;
                    if (original_horizontal_sum(i) > 0) &&...
                            (((i-starting_point) < 6) || extend_right);
                        if (i-starting_point) < 18;
                            extend_right=true;
                            continue;
                        else
                            extend_right=false;
                        end
                    end
                    start_part=false;
                    plot([i-1 i-1],[1 20],'b');

                    letter_img=MyFunc3(FinalImage,starting_point,i-1);

                    if sum(sum(letter_img)) > 0;
                        cropped_letters=[cropped_letters letter_img];
                    end
                end
            end
        end
        if start_part;
            plot([i i],[1 20],'b');
            
            letter_img=MyFunc3(FinalImage,starting_point,i);
                    
            if sum(sum(letter_img)) > 0;
                cropped_letters=[cropped_letters letter_img];
            end
        end
        %fprintf('\n');
        hold off;
        figs=figure(1);
        figs.OuterPosition=[10 50 1000 800];
        
        subplot(3,3,7);
        imshow(cropped_letters);
        sizeofletters=int8(size(cropped_letters,2)/18);
        title(sprintf('Cropped %d letters',sizeofletters));
        cropped_letters=not(cropped_letters);
        
        ButtonFlag=false;
        %answer=inputdlg('Enter characters collected:','Input Answer');
        h_Text=uicontrol('Style','text','String','Enter characters of left:',...
            'Position',[430 210 150 15],'FontSize',10);
        h_Edit=uicontrol('Style','edit','Position',[430 150 150 50],...
            'FontSize',20,'Callback','ButtonFlag=true;');
        h_Button=uicontrol('Style','pushbutton','String','Save to CSV',...
            'Position',[450 100 110 30],'FontSize',10,...
            'Callback','ButtonFlag=true;');
        
        plate_string=get(h_Edit,'String');
        while not(waitforbuttonpress);
            if ButtonFlag;
                plate_string=get(h_Edit,'String');
                if isempty(plate_string);
                    disp('Input letters on left image.');
                    ButtonFlag=false;
                else
                    if sizeofletters == size(plate_string,2);
                        close(1);
                        break;
                    else
                        disp('Wrong letter counts');
                        ButtonFlag=false;
                    end
                end
            end
        end
        
        if not(isempty(plate_string)) && (sizeofletters == size(plate_string,2));
            plate_string=upper(plate_string);
            fprintf('Input: %s\n',plate_string);
            
            for i=1:sizeofletters;
                %fprintf('Saving letter %c...\n',plate_string(i));
                filename=sprintf('Letter_%c.csv',plate_string(i));
                fprintf('Saving file %s...\n',filename);
                fID=fopen(filename,'at+');
                
                for j=1:20;
                    for k=1:18;
                        fprintf(fID,'%d',cropped_letters(j,(k+(i-1)*18)));
                        if (k<18) || (j<20);
                            fprintf(fID,',');
                        end
                    end
                end
                fprintf(fID,'\n');
                fclose(fID);
            end
        end
        
        
        close all;
    end;
    
    %clear bboxes mserStats xmin ymin xmax ymax;
end;

