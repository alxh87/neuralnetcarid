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

%%%%%%%%%EDIT THIS FOR ACCURACY
%create random weight vectors dimw(36,21) and wb(20,361) using


%set up learning conditions
n=0.2;
cycles=160;
%%%%%%%%%%%%%%%%%%%%%

samples=size(x,2);


%blank error curve, blank counter k


disp('Starting training...');


%nodes=input('How many hidden nodes? min 10 max 30   ')
for nodes=17;
wStr=['InitialW_' num2str(nodes)  'Nodes.csv']
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
       
        

%        wplot(countk,:)=[ w(1,:)];
%        wbplot1(countk,:)=[ wb(1,:)];
%        wbplot2(countk,:)=[ wb(2,:)];
        
        vb= wb*x(:,countj);               %activation vector 
%        savevb(countk,:)=vb;
        y=((1-exp(-vb))./(1+exp(-vb))); %output to hidden layer
        yaug=[y;-1];                    %augment hidden layer
        
        v=w*yaug;                  %activation vector for next pass
        z=((1-exp(-v))./(1+exp(-v)));   %output z layer
%        zplot(countk,:)=z';
        
    

        dzdv=0.5*(1-z.^2);              
        delta=(d(:,countj)-z).*(dzdv);         %find delta
        
        dydvb=0.5*(1-y.^2);
        gh=w;
        
        for u=1:length(y)
            deltab(u,1)=delta(:,1)'*gh(:,u)*0.5*(1-y(u,1)^2);
        end
        
%         for u=1:length(y)
%             deltab(u,1)=delta(:,1)'*gh(:,u)*0.5*(1-yaug(u,1)^2);     %find deltabar
%         end
        
        w=w+n*delta*yaug';        %update w vector
        wb=wb+n*deltab*(x(:,countj))';       %update wbar
        
        err=0.5*(d(:,countj)-z).^2;
        cy_err=cy_err+err;          %find cycle error curve
        cy_err_sum=cy_err_sum+sum(err);
        
    end
    errcur=[errcur cy_err];
    errcur_sum=[errcur_sum cy_err_sum];
    
    if mod(counti,10) == 0
        csvwrite('Matrix_W.csv',w);
        csvwrite('Matrix_WB.csv',wb);
        validation_rate=Validation();
        valx=[valx counti];
        valy=[valy validation_rate];
    end
end

disp('Training completed.');

    
figure(1);
for i=1:36
    subplot(6,6,i);
    plot(errcur(i,:));
    title(sprintf('Letter %c',letters(i)));
    %xlabel('Cycle Count');
    ylabel('Cycle Error');
end

figure(2);
plot(errcur_sum);
xlabel('Cycle Count');
ylabel('Cycle Error');
hold on;
yyaxis right;
plot(valx,valy);
ylabel('Validation Rate(%)');
hold off;
figStr=['Fig ' num2str(nodes)  ' Nodes.jpg']
%saveas(H,figStr)

%figure(3);
%plot(Erms);


outwStr=['FinalMatrix_W_' num2str(nodes)  'Nodes.csv']
csvwrite(outwStr,w);
outwbStr=['FinalMatrix_WB_' num2str(nodes)  'Nodes.csv']
csvwrite(outwbStr,w);

end

%disp('Writing w matrix...');
%csvwrite('Matrix_W.csv',w);
%disp('Writing wb matrix...');
%csvwrite('Matrix_WB.csv',wb);
disp('Done.');


%{
%test A
for countval=1:3;
    A(:,countval)=[rawdata{1}(:,countval) ; -1]
    B(:,countval)=[rawdata{2}(:,countval) ; -1]
    C(:,countval)=[rawdata{3}(:,countval) ; -1]   %augment input
end

for countval=1:3;
    vb = wb*A(:,countval);
    y=(1-exp(-vb))./(1+exp(-vb));   %hidden layer
    yaug=[y;-1];
    v=w*yaug;
    testA(:,countval)=(1-exp(-v))./(1+exp(-v))    %output layer
end

for countval=1:3;
    vb = wb*B(:,countval);
    y=(1-exp(-vb))./(1+exp(-vb));   %hidden layer
    yaug=[y;-1];
    v=w*yaug;
    testB(:,countval)=(1-exp(-v))./(1+exp(-v))    %output layer
end

for countval=1:3;
    vb = wb*C(:,countval);
    y=(1-exp(-vb))./(1+exp(-vb));   %hidden layer
    yaug=[y;-1];
    v=w*yaug;
    testC(:,countval)=(1-exp(-v))./(1+exp(-v))    %output layer
end
%}

% 
% 
% %test x2
% C2=[C2 ; -1]          %augment input
% 
% vb = wb{61}*C2;
% y=(1-exp(-vb))./(1+exp(-vb));   %hidden layer
% yaug=[y;-1];
% v=w{61}*yaug;
% zt2=(1-exp(-v))./(1+exp(-v))    %output layer
% 
% %test x2
% U2=[U2 ; -1]          %augment input
% 
% vb = wb{61}*U2;
% y=(1-exp(-vb))./(1+exp(-vb));   %hidden layer
% yaug=[y;-1];
% v=w{61}*yaug;
% zt3=(1-exp(-v))./(1+exp(-v))    %output layer
% 
%         