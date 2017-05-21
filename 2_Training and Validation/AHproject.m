clear all;
close all;

%set up inputs with augmentation

letters=['A' 'B' 'C' 'D' 'E' 'F' 'G' 'H' 'I' 'J' 'K' 'L' 'M' 'N' 'O' 'P' 'Q' 'R' 'S' 'T' 'U' 'V' 'W' 'X' 'Y' 'Z' '1' '2' '3' '4' '5' '6' '7' '8' '9' '0'];

testchars=36; %the number of characters we will try to identify from A to 0 (can change this in letters)

for countl=1:testchars;
    rawdata{countl}=csvread(['Training_CSV/Letter_' letters(countl) '.csv']);
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
        
fprintf('Total %d training set ready.\n',countp);

%set up learning conditions
n=0.2;
cycles=160;


samples=size(x,2);

disp('Starting training...');


for nodes=17;
wStr=['InitialW_' num2str(nodes)  'Nodes.csv'] %Weights created from 10 to 30
w=csvread(wStr);
wbStr=['InitialWB_' num2str(nodes)  'Nodes.csv']
wb=csvread(wbStr);


errcur=[];
countk=0;
errcur_sum=[];
valx=[];
valy=[];
Erms=[];

for counti=1:cycles;
    fprintf('Training cycle %d\n',counti);
    cy_err=zeros(36,1);
    cy_err_sum=0;
    
    savew(counti,:)= w(1,:);
    savewb(counti,:)= wb(1,:);

    
    for countj=1:samples;
        
        countk=countk+1;

        vb= wb*x(:,countj);               %activation vector 

        y=((1-exp(-vb))./(1+exp(-vb))); %output to hidden layer
        yaug=[y;-1];                    %augment hidden layer
        
        v=w*yaug;                       %activation vector for next pass
        z=((1-exp(-v))./(1+exp(-v)));   %output z layer     
    
        dzdv=0.5*(1-z.^2);              
        delta=(d(:,countj)-z).*(dzdv);         %find delta
        
        dydvb=0.5*(1-y.^2);
        gh=w;
        
        for u=1:length(y)
            deltab(u,1)=delta(:,1)'*gh(:,u)*0.5*(1-y(u,1)^2);
        end
        
        w=w+n*delta*yaug';                  %update w vector
        wb=wb+n*deltab*(x(:,countj))';      %update wbar
        
        err=0.5*(d(:,countj)-z).^2;
        cy_err=cy_err+err;                  %find cycle error curve
        cy_err_sum=cy_err_sum+sum(err);
        
    end
    errcur=[errcur cy_err];
    errcur_sum=[errcur_sum cy_err_sum];
    Erms=[Erms sqrt(2*sum(cy_err_sum))./(899*36)];
    
    if mod(counti,10) == 0
        csvwrite('Matrix_W.csv',w);
        csvwrite('Matrix_WB.csv',wb);
        validation_rate=Validation();       %Perform Validation test
        valx=[valx counti];
        valy=[valy validation_rate];
    end
end

disp('Training completed.');


figure(1);                               %Plot error for each character
for i=1:36
    subplot(6,6,i);
    plot(errcur(i,:));
    title(sprintf('Letter %c',letters(i)));
    xlabel('Cycle Count');
    ylabel('Cycle Error');
end

H=figure(2);
plot(Erms);                              %Plot error for network

titStr=['RMS Error for ' num2str(nodes) ' Nodes']
title(titStr)

xlabel('Cycle Count');
ylabel('Mean-squared Error');
hold on;
plot(valx,valy);
hold off;

figStr=['Fig ' num2str(nodes)  ' Nodes.jpg']    %Save error figures            
saveas(H,figStr)
outwStr=['FinalMatrix_W_' num2str(nodes)  'Nodes.csv']  %Save final weights
csvwrite(outwStr,w);
outwbStr=['FinalMatrix_WB_' num2str(nodes)  'Nodes.csv']
csvwrite(outwbStr,wb);

end

disp('Writing w matrix...');
csvwrite('Matrix_W.csv',w);
disp('Writing wb matrix...');
csvwrite('Matrix_WB.csv',wb);
disp('Done.');

