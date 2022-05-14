function [model,results] = run_thermal_fea(p, hmax)
% run_thermal_fea - Creates and runs a steady-state thermal model using
% MATLAB's PDE toolbox.
% 
% Sets outer boundary to constant temperature
% Sets internal boundaries as heat sources
% Applies aluminum's thermal properties
% 
% INPUTS:
% p    - a polyshape object with an outer boundary on the unit square.
% hmax - target maximum mesh edge length
%
% OUTPUTS:
% model   - PDE model
% results - results of PDE
%
% Visualize steady-state temperature results with the following:
%
%   pdeplot(model,'XYData',results.Temperature,'mesh','on');
%   axis equal;
%   colormap jet;
% 
% View mesh only with:
% 
%   pdemesh(model);
% 
% See also run_compression_fea

model = createpde('thermal','steadystate');

p = simplify(p,'KeepCollinearPoints',false);
[gd,sf,ns] = convert_poly_2_geodesc(p);

[geometry,borders] = decsg(gd,sf,ns);
geometry = csgdel(geometry,borders);
geometryFromEdges(model,geometry);
generateMesh(model,'HMax',hmax,'GeometricOrder','linear');

model = apply_thermal_BCs(model);
results = solve(model);
