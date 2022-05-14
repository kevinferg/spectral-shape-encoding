function model = apply_compression_BCs(model)
% apply_compression_BCs - apply boundary conditions, loads, and material
% properties to a PDE model for the compression problem
%
% > Fixes displacement of bottom boundary 
% > Applies vertical compressive load to top boundary
% > Applies aluminum's elastic properties
%
% INPUTS:
% model - PDE model with outer boundary on unit square
%
% OUTPUTS:
% model - PDE model, now with compression problem applied
%
% See also run_compression_fea, apply_thermal_BCs


% Properties of aluminum: https://www.azom.com/properties.aspx?ArticleID=1446
YMval = 68e9;
PRval = 0.32;
rho = 2570;
structuralProperties(model,'YoungsModulus',YMval,'PoissonsRatio',PRval,'MassDensity',rho);

top = get_edge_id(model,0.5,1);
bottom = get_edge_id(model,0.5,0);
T = 1000;

structuralBC(model,'Edge',bottom,'Constraint','fixed');

structuralBoundaryLoad(model,'Edge',top,'SurfaceTraction',[0;-T]);





