## How to generate datasets
To generate the shape datasets, first a separate executable that computes a signed distance field (SDF) must be compiled. Then, a MATLAB script generates all datasets as .mat files.

### Compiling SDF executable
#### Windows
1. Install MinGW, in particular gcc and mingw32-make
2. Navigate to `dataset_generation/sdf_files/` in a terminal
3. Run `mingw32-make win_makefile`
4. Copy the file `dataset_generation/sdf_files/bin/calc_sdf.exe` to `dataset_generation/`

#### \*nix
1. Ensure gcc and make are installed.
2. Navigate to `dataset_generation/sdf_files/` in a terminal
3. Run `make nix_makefile`
4. Run `cp bin/calc_sdf ../`

### Generating MATLAB datasets
MATLAB with the PDE toolbox must be installed: https://www.mathworks.com/help/pde/  
Navigate to `dataset_generation/` in MATLAB and run `create_all_datasets.m` to create all datasets.
To make a dataset with specific parameters, use `generate_matlab_dataset.m`.



## List of MATLAB dataset generation files


### Files to generate datasets:

| File | Description |
| --- | --- |
| `create_all_datasets.m`     | Generates all datasets |
| `generate_matlab_dataset.m` | Creates a dataset .mat file according to input specifications |

### FEM:

| File | Description |
| --- | --- |
| `run_compression_fea.m` | Runs the compression problem on an input polyshape object |
| `run_thermal_fea.m` | Runs the thermal problem on an input polyshape object |
| `apply_compression_BCs.m` | Applies the compression problem boundary conditions and sets structural properties |
| `apply_thermal_BCs.m` | Applies the heat problem boundary conditions and sets thermal properties |


### Geometry creation:

| File | Description |
| --- | --- |
| `create_porous_geometry.m` | Creates a polyshape in the Voronoi Set |
| `create_lattice_pores.m` | Creates a polyshape in the Lattice Set |
| `create_bounded_voronoi.m` | Places random points in a 1x1 square and performs voronoi tessellation |
| `interpolate_boundary.m` | Separates a boundary into a set number of segments |
| `smooth_boundary.m` | Applies Laplacian smoothing given a boundary curve |
| `smooth_holes.m` | Applies boundary smoothing to every hole region in a given polyshape |

### Other:

| File | Description |
| --- | --- |
| `export_nodes.m` | Prints node info to a text file | 
| `output_polyshape.m` | Prints polyshape object info to a text file |
| `get_edge_id.m` | Gets the id for an edge in a pde model, given coordinates of a point on the edge |
| `convert_poly_2_geodesc.m` | Converts a polyshape object to a geometry description suitable for MATLAB's pde toolbox |
