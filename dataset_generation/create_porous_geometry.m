function [p, X, seed] = create_porous_geometry(N, minwall, delta, degree, seed)
% create_porous_geometry - create geometry for Voronoi set: rounded pores
% at Voronoi cells on unit square
%
% INPUTS:
% N       - number of points/holes
% minwall - minimum wall thickness
% delta   - strength of Laplacian smoothing of each hole
% degree  - degree of Laplacian smoothing of each hole
% seed    - optional seed for Voronoi pore generation
%
% OUTPUTS: 
% p    - MATLAB polyshape of generated structure
% X    - Voronoi point locations
% seed - Seed used to generate Voronoi point locations
%
% See also create_bounded_voronoi, create_lattice_pores


if ~exist('seed','var')
    seed = randi(intmax);
end

rng(seed);

[p,X] = create_bounded_voronoi(N, [0,1], [0,1], minwall);
p = smooth_holes(p, delta, degree);
