function model = apply_thermal_BCs(model)

edges = model.Geometry.NumEdges;


top = get_edge_id(model,0.5,1);
bottom = get_edge_id(model,0.5,0);
left = get_edge_id(model,0,00.5);
right = get_edge_id(model,1,0.5);
sides = [top,bottom,left,right];

holes = setdiff(1:edges,sides);

thermalProperties(model,'ThermalConductivity',239);

top = get_edge_id(model,0.5,1);
bottom = get_edge_id(model,0.5,0);

thermalBC(model,'Edge',sides,'Temperature',0);
thermalBC(model,'Edge',holes,'HeatFlux',100);
%thermalBC(model,'Edge',top,'Temperature',100);
%internalHeatSource(model,20)

%thermalBC(model,'Edge',bottom,'Temperature',0);
%thermalBC(model,'Edge',left,'HeatFlux',1000);
%thermalBC(model,'Edge',top,'Temperature',100);




