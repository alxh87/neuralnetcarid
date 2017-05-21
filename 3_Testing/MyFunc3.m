% Strip images by specified columns
%
% Usage : retImg = MyFunc3(FinalImage,StartCol,EndCol)
%
%   retImg : Returned Image Matrix (20-by-18)
%   FinalImage : Original Binary Image
%   StartCol : Starting column number of stripping
%   EndCol : Ending column number of stripping
%
function retImg=MyFunc3(FinalImage,StartCol,EndCol)
    xmax=size(FinalImage,2);
    ymax=size(FinalImage,1);
    horizontal_sum=sum(not(FinalImage),1);
    part_weight=sum(horizontal_sum(StartCol:EndCol));
    partsum=EndCol-StartCol+1;
    width_portion=partsum/xmax*100;
    weight_portion=part_weight*100/(xmax*ymax);
    %{
    fprintf('[%d:%d](Width:%d-%.1f%%), (Weight:%d-%.2f%%)\n',StartCol,...
        EndCol,partsum,width_portion,part_weight,weight_portion);
    %}
    % If weight portion > 1.7%
    if (weight_portion > 1.7); %(width_portion > 8)
        if (weight_portion < 2.3) && ((part_weight/partsum) < 8);
            retImg=zeros(20,18);
            return;
        end
            
        % Cut it!!
        %fprintf('Cut this letter\n');
        % Adjust width left column
        if (StartCol > 1) && (horizontal_sum(StartCol-1) > 0);
            if (StartCol-1) == 1;
                StartCol = 1;
            elseif horizontal_sum(StartCol-2) == 0;
                StartCol = StartCol-1;
            end                
        end
        % Adjust width right column
        if (EndCol < xmax) && (horizontal_sum(EndCol+1) > 0);
            if (EndCol+1) == xmax;
                EndCol = xmax;
            elseif horizontal_sum(EndCol+2) == 0;
                EndCol = EndCol+1;
            end
        end
        
        retImg=FinalImage(:,StartCol:EndCol);
        
        % Make width as 18
        width = size(retImg,2);
        if width < 18;
            expansion = 18-width;
            if mod(expansion,2) > 0
                exp_left = int8(expansion/2);
                exp_right = exp_left-1;
            else
                exp_left = expansion/2;
                exp_right = exp_left;
            end
            for i=1:exp_left;
                retImg=[ones(20,1) retImg];
            end
            for i=1:exp_right;
                retImg=[retImg ones(20,1)];
            end
        elseif width > 18;
            %fprintf('Oops, too wide\n');
            retImg=zeros(20,18);
        end
        
        % Check horizontal blank line between character
        vertical_sum=sum(not(retImg),2);
        sum_blank=0;
        mid_blank=0;
        isZero=false;
        toggle_count=0;
        for i=1:20;
            if vertical_sum(i) == 0;
                % up to 3rd line - erase noise
                if i < 4;
                    retImg(1:i,:)=1;
                % after 18th line - erase noise
                elseif i > 17;
                    retImg(i:20,:)=1;
                else
                    isZero = true;
                    if (i >= 5) && (i <= 16);
                        mid_blank=mid_blank+1;
                    end
                end
                
                % add blank lines
                sum_blank=sum_blank+1;
            else
                if isZero;
                    isZero = false;
                    toggle_count=toggle_count+1;
                end
            end
        end
        % If there are more than 6 consecutive blank lines, it's not letter
        if (sum_blank > 6) || (toggle_count > 1) || (mid_blank > 0);
            retImg = zeros(20,18);
            %fprintf('Cancelled - toggle:%d, blank:%d\n',toggle_count,sum_blank);
        end
        %fprintf('Blank:%d\n',sum_blank);
    else
        retImg=zeros(20,18);
    end
end
