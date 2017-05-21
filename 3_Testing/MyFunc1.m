% Calculation of maximum columns of consecutive non-zero values
%
% Usage : retVal = MyFunc1(1-by-n values)
%
function ret=MyFunc1(arg)
    ret=0;
    count=0;
    for i=1:size(arg,2);
        if arg(i)>0;
            count=count+1;
        else
            if count > ret;
                ret=count;
            end
            count=0;
        end
    end
    if count > ret;
        ret=count;
    end
end
