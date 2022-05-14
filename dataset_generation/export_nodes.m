function [] = export_nodes(nodes, filename)
% export_nodes - prints node coordinates to a text file for simple parsing
% with other software
%
% INPUTS:
% nodes    - Node x-y coordinates (each column is [x; y])
% filename - Name of output file
%
% OUTPUTS:
% Creates a text file of node locations with the following format:
%
% --------------------------------
%  [number of nodes]
%    [x1] [y1]
%    [x2] [y2]
%    ...
% --------------------------------

fnum = fopen(filename,"w");

[~,n] = size(nodes);

fprintf(fnum,"%d\n", n);
for i=1:n
    fprintf(fnum,"%f %f\n", nodes(1,i), nodes(2,i));
end

fclose(fnum);