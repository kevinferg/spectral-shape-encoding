clc; clear variables; close all;
warning('off','all');

% To generate out-of-sample-set, set oss to 1:
oss = 0;


filename = 'temp_big.mat';
n_vals = 3:4; % 2 values
wall_vals = [.10,.12,.14,.16,.18]; % 5 values 
degree_vals = [1,5,10,15,20]; % 5 values
delta = 1;
repeats = 80;


if oss
    n_vals = [0.06,0.08,0.20,0.22];
    repeats = 10;
    filename = 'temp_big_oss.mat'
end



[ns,ws,ds] = ndgrid(n_vals,wall_vals,degree_vals);
combos = [ns(:),ws(:),ds(:)];
[rows,~] = size(combos);

data = cell(rows*repeats,1);
index = 0;

bar = waitbar(0,"Progress:   0.00%");

s = repeats*rows;

nodes = cell(s,1);
elem = cell(s,1);
stress = cell(s,1);
dt = cell(s,1);





for j = 1:repeats
    
    
for i = 1:rows
    
    index = index+1;
    n = combos(i,1);
    minwall = combos(i,2);
    degree = combos(i,3);
    [p,X,seed] = create_porous_geometry(n,minwall,delta,degree);
    [model,results] = run_thermal_fea(p);

    pt = results;
    nodes{index} = pt.Mesh.Nodes;
    elem{index} = int64(pt.Mesh.Elements);
    stress{index} = pt.Temperature;
    dt{index} = distance_transform_euclidean(model);


    progress = index/(repeats*rows);
    waitbar(progress,bar,sprintf("Progress: %6.2f%%",progress*100));
end

end

save(filename,'nodes','elem','stress','dt')
close(bar);

