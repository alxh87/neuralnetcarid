% Checkletter
%

function ret=CheckLetter2(input_matrix)
    letters=['A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N' 'O' 'P' 'Q' 'R' 'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z' '1' '2' '3' '4' '5' '6' '7' '8' '9' '0'];
    
    % Bipolar activation function
    fz=@(v) (1-exp(-v))./(1+exp(-v));
    
    % Read w and wb matrix from csv files
    w=csvread('Matrix_W.csv');
    wb=csvread('Matrix_WB.csv');
    
    % Make it bipolar
    input_matrix=input_matrix.*2;
    input_matrix=input_matrix-1;
    
    % Make inputed matrix as 1 column
    for i=1:20
        for j=1:18
            input((i-1)*18+j,1)=input_matrix(i,j);
        end
    end
    
    AugmentedInput=[input ; -1];
    vb=wb*AugmentedInput;
    y=fz(vb);   %hidden layer
    yaug=[y;-1];
    v=w*yaug;
    z=fz(v);    %output layer
    
    positive_count=0;
    for i=1:36
        if z(i) > 0
            positive_count=positive_count+1;
            %fprintf('Positive value : %.4f on %c\n',z(i),letters(i));
            candidates(positive_count)=i;
        end
    end
    
    if positive_count == 0
        ret=0;
    elseif positive_count < 2
        ret=letters(candidates(1));
    else
        max_value=0;
        candidate_number=1;
        for i=1:positive_count
            if z(candidates(i)) > max_value
                max_value=z(candidates(i));
                candidate_number=candidates(i);
            end
        end
        ret=letters(candidate_number);
    end
end
