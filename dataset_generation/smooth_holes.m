function p = smooth_holes(p, delta, degree)
% smooth_holes - Smooth every hole in a polyshape
%
% A hole is automatically removed (filled?) if its area ends up < 0.000625
%
% INPUTS:
% p      - MATLAB polyshape whose holes should be smoothed
% delta  - Strength of Laplacian smoothing
% degree - Degree of Laplacian smoothing
%
% OUTPUTS:
% p - polyshape with smoothed holes
%
% See also smooth_boundary, interpolate_boundary, polyshape

if delta == 0 || degree == 0
    return
end

% hidden parameters
pt_density = .025;
min_pts_per_hole = 20;
pph_for_smoothing = 100;
min_area = 0.025*0.025*1;

z = rmholes(p);
boundaries = p.NumRegions+p.NumHoles;
for i = 1:boundaries
    if ishole(p,i)==1
        [x,y] = boundary(p,i);
        X = [x,y];
        X = smooth_boundary(X,pph_for_smoothing,delta,degree);
        X = interpolate_boundary(X,max([min_pts_per_hole,floor(perimeter(p,i))/pt_density]));
        q = polyshape(X);
        if area(q)>min_area
            z = subtract(z,q);
        end
    end
end
p = simplify(z);