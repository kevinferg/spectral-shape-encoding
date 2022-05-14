% create_all_datasets
% Create datasets for all combinations of:
% voronoi           /   lattice
% stress            /   temperature
% within sample set /   out of sample set

clc; clear variables; close all;

%%% Stress datasets %%%

% Voronoi, within sample set
generate_matlab_dataset("voronoi", "stress", 0, "stress_vor_w.mat", 0.025);
% Voronoi, out of sample set
generate_matlab_dataset("voronoi", "stress", 1, "stress_vor_o.mat", 0.025);

% Lattice, within sample set
generate_matlab_dataset("lattice", "stress", 0, "stress_lat_w.mat", 0.025);
% Lattice, out of sample set
generate_matlab_dataset("lattice", "stress", 1, "stress_lat_o.mat", 0.025);


%%% Thermal datasets %%%

% Voronoi, within sample set
generate_matlab_dataset("voronoi", "temperature", 0, "temp_vor_w.mat", 0.025);
% Voronoi, out of sample set
generate_matlab_dataset("voronoi", "temperature", 1, "temp_vor_o.mat", 0.025);

% Lattice, within sample set
generate_matlab_dataset("lattice", "temperature", 0, "temp_lat_w.mat", 0.025);
% Lattice, out of sample set
generate_matlab_dataset("lattice", "temperature", 1, "temp_lat_o.mat", 0.025);

