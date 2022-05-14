function [] = generate_matlab_dataset(geometry, field, oss, filename, res)
% generate_matlab_dataset - creates a dataset of PDE solution fields on 
% varying geometries and stores the results in a .mat file
%
% INPUTS:
% geometry - Type of shape dataset: "voronoi" or "lattice"
% field    - Type of field to generate: "stress" or "temperature"
% oss      - Generate "out of sample set" geometries? 0: No / 1: Yes
% filename - Name of .mat file where the result should be stored
% res      - Target maximum mesh edge length, default 0.025
%
% OUTPUTS:
% Creates .mat file of name ~filename~ with the following:
% 'nodes'  - x-y coordinates of each node
% 'elem'   - node indices of each triangular mesh element
% 'stress' - stress (or temperature) values at each node
% 'dt'     - SDF values at each node
% 'sdf'    - 64x64 matrix of SDF values across unit square
% 
% SIDE EFFECTS AND REQUIREMENTS:
% Communicates with SDF generator program 'calc_sdf' using temporary text
% files "bound.txt", "point.txt", and "out.txt"
% 
% See also run_compression_fea, run_thermal_fea


if ~exist("geometry","var")
    geometry = "voronoi";
end

if ~exist("field","var")
    field = "stress";
end

if ~exist("oss","var")
    oss = 0;
end

if ~exist("filename","var")
    filename = "default_matlab_dataset.mat";
end

if ~exist("res","var")
    res = 0.025;
end


if geometry == "voronoi"
    n_vals = 3:4; % 2 values
    wall_vals = [.10,.12,.14,.16,.18]; % 5 values 
    degree_vals = [1,5,10,15,20]; % 5 values
    repeats = 20;
    if oss
        wall_vals = [0.06,0.08,0.20,0.22];
        repeats = 5;
    end

    [ns,ws,ds] = ndgrid(n_vals,wall_vals,degree_vals);
    combos = [ns(:),ws(:),ds(:)];
    [rows,~] = size(combos);

elseif geometry == "lattice"
    n_vals = 4:8; % 5 values
    degree_vals = [1,5,10,15]; % 4 values
    side_vals = 3:4; % 2 values
    repeats = 25;
    if oss
        n_vals = [2,3,9,10];
        repeats = 5;
    end
    [ns,ds,ss] = ndgrid(n_vals,degree_vals,side_vals);
    combos = [ns(:),ds(:),ss(:)];
    [rows,~] = size(combos);

else
    fprintf("Unrecognized geometry type: Use ""lattice"" or ""voronoi""\n");
    return;
end


s = repeats*rows;
nodes = cell(s,1);
elem = cell(s,1);
stress = cell(s,1);
dt = cell(s,1);
sdf = cell(s,1);

rng(0);

index = 0;
bar = waitbar(0,"Progress:   0.00%");
for j = 1:repeats
    for i = 1:rows
        index = index+1;
        
        % First, do FEA...
        % Sometimes the geometry gets created in such a way that breaks the
        % mesh generator. In these cases, I re-generate geometry until it
        % works, hence the loop below:
        no_geometry = 1; 
        while no_geometry
            try
                if geometry == "voronoi"
                    n = combos(i,1);
                    minwall = combos(i,2);
                    degree = combos(i,3);
                    [p,~,~] = create_porous_geometry(n,minwall,1,degree);
                else
                    degree = combos(i,2);
                    side = combos(i,3);
                    n = combos(i,1)+3*(side==4)-1*(side==3);
                    [p,~] = create_lattice_pores(n,side,degree);
                    
                end
                

                if field == "stress"
                    [~,results] = run_compression_fea(p, res);
                elseif field == "temperature"
                    [~,results] = run_thermal_fea(p, res);
                else
                    fprintf("Unrecognized field name: Use ""stress"" or ""temperature""\n");
                    close(bar);
                    return;
                end

                no_geometry = 0;
            catch
                no_geometry = no_geometry + 1;
                
                if no_geometry > 10
                    fprintf("Geometry creation or FEA failed 10 times consecutively. Something needs to be fixed.\n");
                    close(bar);
                    return;
                end
            end
        end
        
        % Input all data into cells
        % Currently requires temporary text file i/o and system calls to use SDF generation

        nodes{index} = results.Mesh.Nodes;
        elem{index} = int64(results.Mesh.Elements);

        if field == "stress"
            stress{index} = results.VonMisesStress;
        else
            stress{index} = results.Temperature;
        end

        output_polyshape(p,"bound.txt");
        export_nodes(results.Mesh.Nodes,"point.txt");
        system("calc_sdf bound.txt point.txt out.txt");
        B = readmatrix("out.txt");
        system("calc_sdf bound.txt out.txt");
        A = readmatrix("out.txt");
        sdf{index} = A;
        dt{index} = B;
        
        progress = index/(repeats*rows);
        waitbar(progress,bar,sprintf("Progress: %6.2f%%",progress*100));
    end
end

save(filename,'nodes','elem','stress','dt','sdf')
close(bar);

