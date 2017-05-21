
clear all



for nodes=10:30;
    w=2*rand(36,nodes+1)-1;
    wb=2*rand(nodes,361)-1;

    wStr=['InitialW_' num2str(nodes)  'Nodes.csv']
    wbStr=['InitialWB_' num2str(nodes)  'Nodes.csv']

    csvwrite(wStr,w);

    %disp('Writing wb matrix into InitialWB_', nodes , 'Nodes.csv...');
    csvwrite(wbStr,wb);
    
end