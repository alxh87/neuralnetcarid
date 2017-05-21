% Erase more than 21px of consecutive black line
%
% Usage : retVal(1-by-n values) = MyFunc2(1-by-n values)
%
function ret=MyFunc2(arg)
    limit=21;
    xmax=size(arg,2);
    ret=arg;
    count=0;
    start=false;
    pos=0;
    for i=1:xmax;
        if arg(i) == 0;
            if ~start;
                start=true;
                pos=i;
            end
            count=count+1;
        else
            if start;
                start=false;
                if count >= limit;
                    ret(pos:(i-1))=1;
                end
            end
            count=0;
        end
    end
    if start;
        if count >= limit;
            ret(pos:i)=1;
        end
    end
end
