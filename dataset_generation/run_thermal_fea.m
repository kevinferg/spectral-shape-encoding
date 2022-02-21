function [model,results] = run_thermal_fea(p)
hmax = 0.025;

model = createpde('thermal','steadystate');

p = simplify(p,'KeepCollinearPoints',false);
[gd,sf,ns] = convert_poly_2_geodesc(p);

[geometry,borders] = decsg(gd,sf,ns);
geometry = csgdel(geometry,borders);
geometryFromEdges(model,geometry);
generateMesh(model,'HMax',hmax,'GeometricOrder','linear');

model = apply_thermal_BCs(model);
results = solve(model);