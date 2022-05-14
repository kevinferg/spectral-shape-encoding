function [gd,sf,ns] = convert_poly_2_geodesc(poly)
% convert_poly_2_geodesc - Converts a MATLAB polyshape into a MATLAB CSG 
% geometry description.
% 
% The output format is described here:
% https://www.mathworks.com/help/pde/ug/create-geometry-at-the-command-line.html
% 
% INPUTS:
% poly - A MATLAB polyshape
%
% OUTPUTS:
% gd - 
% sf - 
% ns - 
%
% See also polyshape, decsg

N = numboundaries(poly);
ns = repmat("str",1,N);
gd = zeros(max(numsides(poly,1:N)),N);
sf = [];

for i = 1:N
    sides = numsides(poly,i);
    [x,y] = boundary(poly,i);
    gd(1:2*sides+2,i) = [2;sides;x(1:end-1);y(1:end-1)];
    ns(i) = strcat('p',num2str(i));
    
    if i>1 && ishole(poly,i)
        sf = strcat(sf,'-');
    elseif i>1
        sf = strcat(sf,'+');
    end
    sf = strcat(sf,ns(i));
end
