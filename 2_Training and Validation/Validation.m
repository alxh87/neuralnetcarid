% Validation
function ret=Validation()
    letters=['A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N' 'O' 'P' 'Q' 'R' 'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z' '1' '2' '3' '4' '5' '6' '7' '8' '9' '0'];
    testchars=36; %the number of characters we will try to identify from A to 0 (can change this in letters)

    for countl=1:testchars;
        rawdata{countl}=csvread(['Validation_CSV/Letter_' letters(countl) '.csv']);
        rawdata{countl}=rawdata{countl}';
        rawdata{countl}=rawdata{countl}.*2;
        rawdata{countl}=rawdata{countl}-1;
    end

    countm=1;    %start of traindata (eg if this is 5, the first 4 of each letter can be validation)
    countp=0;
    while countm <= max(cellfun('size', rawdata, 2))
        for countl=1:testchars;
            if size(rawdata{countl},2)>=countm;
                countp=countp+1;
                traindata = rawdata{countl}(:,countm);
                x(:,countp)=[traindata; -1];
                d(:,countp) = zeros(testchars,1)-1;
                d(countl,countp) = 1;
            end
        end
        countm=countm+1;
    end

    fprintf('Total %d validation set ready.\nStarting validation...',countp);

    Ec=0;
    diff=0;
    
    % Bipolar activation function
    fz=@(v) (1-exp(-v))./(1+exp(-v));
    
    % Read w and wb matrix from csv files
    w=csvread('Matrix_W.csv');
    wb=csvread('Matrix_WB.csv');
    
    for countv=1:countp
        vb=wb*x(:,countv);
        y=fz(vb);   %hidden layer
        yaug=[y;-1];
        v=w*yaug;
        z=fz(v);    %output layer
        E=sum(0.5*(d(:,countv)-z).^2);
        Ec=Ec+E;
    end
    
    Erms=sqrt(2*Ec)./(214*36);
    
    ret = Erms;
    fprintf(' Finished.\n');%Matched set : %d(%.2f%%)\n',match,100*match/countp);
end