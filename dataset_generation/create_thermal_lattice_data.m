clc; clear variables; close all;
warning('off','all');


% To generate out-of-sample-set, set oss to 1:
oss = 0;


filename = 'lattice_temp.mat';
n_vals = 4:8; % 5 values
degree_vals = [1,5,10,15]; % 4 values
side_vals = 3:4; % 2 values

repeats = 25;


if oss
    n_vals = [2,3,9,10];
    repeats = 5
    filename = 'lattice_temp_oss.mat'
end

[ns,ds,ss] = ndgrid(n_vals,degree_vals,side_vals);
combos = [ns(:),ds(:),ss(:)];
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
    degree = combos(i,2);
    side = combos(i,3);
    n = combos(i,1)+3*(side==4)-1*(side==3);
    [p,seed] = create_lattice_pores(n,side,degree);
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
