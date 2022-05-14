function [] = output_polyshape(p, filename)
% output_polyshape - prints information defining a MATLAB polyshape to 
% a text file, for simple parsing with other software
%
% INPUTS:
% p        - MATLAB polyshape
% filename - Name of output file
%
% OUTPUTS:
% Creates a textfile with name ~filename~ containing the polyshape region
% information in the following format:
%
% -------------------------------------
%  [number of boundaries]
%    [first boundary id]
%      [number of points] [hole? 0/1]
%      [x1] [y1]
%      [x2] [y2]
%      ...
%    [second boundary id]
%      [number of points] [hole? 0/1]
%      [x1] [y1]
%      [x2] [y2]
%      ...
%    ...
% -------------------------------------
%
% See also polyshape


fnum = fopen(filename,"w");

nb = p.numboundaries;

fprintf(fnum,"%d\n", nb);

for i = 1:nb
    [x, y] = boundary(p, i);
    nv = length(x) - 1;
    fprintf(fnum,"%d %d\n",nv,ishole(p,i));
    for j = 1:nv
        fprintf(fnum,"%f %f\n",x(j),y(j));
    end
end

fclose(fnum);