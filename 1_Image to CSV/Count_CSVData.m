% Count Data CSV
clear all;

oldFolder=cd('..\Training_CSV');
%oldFolder=cd('..\Validation_CSV');
result=dir('Letter_*.CSV');
count=size(result,1);

totalline=0;
for i=1:count
    fprintf('%s : ',result(i).name);
    
    countline=0;
    fID=fopen(result(i).name,'rt');
    tline = fgetl(fID);
    while ischar(tline)
       countline=countline+1;
       tline = fgetl(fID);
    end
    fclose(fID);
    
    fprintf('%d lines\n',countline);
    totalline=totalline+countline;
end
fprintf('Total lines : %d\n',totalline);
cd(oldFolder);