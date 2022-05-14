#pragma once

#include <stdio.h>
#include "io.h"

#define COLLINEAR_TOLERANCE 0.00000001

typedef struct Point {
	double x;
	double y;
} Point;

typedef struct Boundary {
	Point* points;
	int is_hole;
	int is_ccw;
	int num_points;
	int room_for_points;
} Boundary;

typedef struct Shape {
	Boundary* bounds;
	int num_bounds;
	int room_for_bounds;
} Shape;


Boundary* new_Boundary(void);
Boundary* init_Boundary(Boundary* boundary);
int destroy_Boundary(Boundary* boundary);
int add_point_to_Boundary(Boundary* boundary, Point* point);

Shape* new_Shape(void);
int add_boundary_to_Shape(Shape* shape, Boundary* boundary);
int destroy_Shape(Shape* shape);

int get_orientation(Point* A, Point* B, Point* C);
int read_Point(FILE* f, Point* point);
int read_Boundary(FILE* f, Boundary* boundary);
Shape* read_Shape(char* filename);

