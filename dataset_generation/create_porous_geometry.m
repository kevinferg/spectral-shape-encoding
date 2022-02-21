function [p,X,seed] = create_porous_geometry(N,minwall,delta,degree,seed)

if ~exist('seed','var')
    seed = randi(intmax);
end

rng(seed);

[p,X] = create_bounded_voronoi(N,[0,1],[0,1],minwall);
p = smooth_holes(p,delta,degree);

