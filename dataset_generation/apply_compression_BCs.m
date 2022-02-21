function model = apply_compression_BCs(model)

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





