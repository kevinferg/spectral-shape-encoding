function model = apply_thermal_BCs(model)
% apply_thermal_BCs - apply boundary conditions, heat sources, and material
% properties to a PDE model for the thermal problem
%
% > Sets outer boundary to constant temperature
% > Sets internal boundaries as heat sources
% > Applies aluminum's thermal properties
%
% INPUTS:
% model - PDE model with outer boundary on unit square
%
% OUTPUTS:
% model - PDE model, now with thermal problem applied
%
% See also run_thermal_fea, apply_compression_BCs

edges = model.Geometry.NumEdges;

top = get_edge_id(model,0.5,1);
bottom = get_edge_id(model,0.5,0);
left = get_edge_id(model,0,00.5);
right = get_edge_id(model,1,0.5);
sides = [top,bottom,left,right];

holes = setdiff(1:edges,sides);

thermalProperties(model,'ThermalConductivity',239);

thermalBC(model,'Edge',sides,'Temperature',0);
thermalBC(model,'Edge',holes,'HeatFlux',100);
