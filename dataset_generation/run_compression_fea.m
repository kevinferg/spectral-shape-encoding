function [model,results] = run_compression_fea(p)
hmax = 0.025;

model = createpde('structural','static-planestrain');

p = simplify(p,'KeepCollinearPoints',false);
[gd,sf,ns] = convert_poly_2_geodesc(p);

[geometry,borders] = decsg2(gd,sf,ns);
geometry = csgdel(geometry,borders);
geometryFromEdges(model,geometry);
generateMesh(model,'HMax',hmax,'GeometricOrder','linear');
%generateMesh(model,'Hmin',hmax,'hgrad',2,'GeometricOrder','linear');
%generateMesh(model,'Hmin',hmax,'hgrad',2,'GeometricOrder','linear');

model = apply_compression_BCs(model);
results = solve(model);

% To plot:

%pdemesh(model);

%pdeplot(model,'XYData',results.VonMisesStress,'mesh','on'); axis equal
%colormap jet




