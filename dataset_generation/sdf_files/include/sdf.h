#pragma once

#include "shape.h"

double get_distance_to_Shape(Point* P, Shape* shape);

int compute_sdf(char* filein, char* fileout, double xymin, double xymax, int res);

int compute_sdf_points(char* bound_file, char* point_file, char* out_file);

