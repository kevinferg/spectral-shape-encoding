function [model,results] = run_compression_fea(p, hmax)
% run_thermal_fea - Creates and runs a plane-strain  model using
% MATLAB's PDE toolbox.
% 
% > Fixes displacement of bottom boundary 
% > Applies vertical compressive load to top boundary
% > Applies aluminum's elastic properties
% 
% INPUTS:
% p    - a polyshape object with an outer boundary on the unit square.
% hmax - target maximum mesh edge length
%
% OUTPUTS:
% model   - PDE model
% results - results of PDE
%
% Visualize von Mises stress results with the following:
%
%   pdeplot(model,'XYData',results.VonMisesStress,'mesh','on');
%   axis equal;
%   colormap jet;
% 
% View mesh only with:
% 
%   pdemesh(model);
% 
% See also run_thermal_fea

model = createpde('structural','static-planestrain');

p = simplify(p,'KeepCollinearPoints',false);
[gd,sf,ns] = convert_poly_2_geodesc(p);

[geometry,borders] = decsg(gd,sf,ns);
geometry = csgdel(geometry,borders);
geometryFromEdges(model,geometry);
generateMesh(model,'HMax',hmax,'GeometricOrder','linear');

model = apply_compression_BCs(model);
results = solve(model);
