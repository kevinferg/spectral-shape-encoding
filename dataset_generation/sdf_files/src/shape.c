#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "shape.h"
#include "io.h"

#define POINTS_BUFFER 100
#define BOUNDS_BUFFER 50
#define COLLINEAR_TOLERANCE 0.00000001

int get_orientation(Point* A, Point* B, Point* C);


/*******************  Boundary functions *******************/
Boundary* new_Boundary(void) {
	Boundary* boundary = malloc(sizeof(Boundary));
	if (boundary == NULL) return NULL;
	
	return init_Boundary(boundary);
}

Boundary* init_Boundary(Boundary* boundary) {
	int i;
	boundary->num_points = 0;
	boundary->is_hole = 0;
	boundary->is_ccw = 0;
	boundary->room_for_points = POINTS_BUFFER;
	
	boundary->points = malloc(sizeof(Point)*(boundary->room_for_points));
	if (boundary->points == NULL) return NULL;
	
	return boundary;
}

int destroy_Boundary(Boundary* boundary) {
	free(boundary->points);
	free(boundary);
	return 0;
}


int add_point_to_Boundary(Boundary* boundary, Point* point) {
	if (boundary->num_points >= boundary->room_for_points) {
		(boundary->room_for_points) *= 2;
		boundary->points = realloc(boundary->points, (boundary->room_for_points)*sizeof(Point));
	}

	(boundary->points[boundary->num_points]).x = point->x;
	(boundary->points[boundary->num_points]).y = point->y;
	
	(boundary->num_points)++;
	
	return 0;
}


int read_Boundary(FILE* f, Boundary* boundary) {
	int i, num_points, status;
	Point point;
	
	Number num1, num2;
	num1 = next_number(f, NUM_INT);
	num2 = next_number(f, NUM_INT);
	
	if (num1.type == NUM_ERROR || num2.type == NUM_ERROR) return -1;
	
	
	num_points = num1.i;
	boundary->num_points = 0;
	boundary->is_hole = num2.i;
	
	//printf("%d points in this boundary, hole? %d\n",num_points, num2.i);
	
	for (i = 0; i < num_points; i++) {
		status = read_Point(f, &point);
		if (status) return status;
		add_point_to_Boundary(boundary, &point);
	}
	
	boundary->is_ccw = get_orientation(&(boundary->points[0]),
	                                   &(boundary->points[num_points * 1/3]),
									   &(boundary->points[num_points * 2/3]));
	
	return 0;
}


/***********************************************************/



/******************** Shape Functions **********************/
Shape* new_Shape(void) {
	Shape* shape = malloc(sizeof(Shape));
	if (shape == NULL) return NULL;
	
	shape->num_bounds = 0;
	shape->room_for_bounds = BOUNDS_BUFFER;
	
	shape->bounds = malloc(sizeof(Boundary)*(shape->room_for_bounds));
	
	return shape;
}

int destroy_Shape(Shape* shape) {
	int i;
	for (i = 0; i < shape->num_bounds; i++) {
		free(shape->bounds[i].points);
	}

	free(shape->bounds);
	free(shape);
	return 0;
}


int add_boundary_to_Shape(Shape* shape, Boundary* boundary) {
	int i;
	if (shape->num_bounds >= shape->room_for_bounds) {
		(shape->room_for_bounds) *= 2;
		shape->bounds = realloc(shape->bounds, (shape->room_for_bounds)*sizeof(Point));
	}
	
	init_Boundary(&(shape->bounds[shape->num_bounds]));
	shape->bounds[shape->num_bounds].is_hole = boundary->is_hole;
	shape->bounds[shape->num_bounds].is_ccw = boundary->is_ccw;
	
	for (i = 0; i < boundary->num_points; i++) {
		add_point_to_Boundary(&(shape->bounds[shape->num_bounds]), &(boundary->points[i]));
		//printf("Added point to boundary with coords: %f  %f\n",boundary->points[i].x,boundary->points[i].y); fflush(stdout);
	}

	(shape->num_bounds)++;
	
	return 0;
}

Shape* read_Shape(char* filename) {
	Number num;
	int status;
	int num_bounds, i;
	Shape* shape = new_Shape();
	FILE* f = fopen(filename, "r");
	if (f == NULL) {
		destroy_Shape(shape);
		return NULL;
	}
	Boundary* boundary = new_Boundary();
	if (boundary == NULL) {
		fclose(f);
		destroy_Shape(shape);
		return NULL;
	}
		
	
	num = next_number(f, NUM_INT);
	if (num.type == NUM_ERROR) {
		fclose(f);
		destroy_Boundary(boundary);
		destroy_Shape(shape);
		return NULL;
	}
	num_bounds = num.i;
	////printf("%d boundaries in the file.\n", num.i);
	
	
	for (i = 0; i < num_bounds; i++) {
		status = read_Boundary(f, boundary);
		if (status) {
			fclose(f);
			destroy_Boundary(boundary);
			destroy_Shape(shape);
			return NULL;
		}
		add_boundary_to_Shape(shape, boundary);
		//printf("**** %f %f, %f, %f\n", shape->bounds[i].points[2].x,shape->bounds[i].points[2].y,shape->bounds[i].points[3].x,shape->bounds[i].points[3].y);
	
	}

	destroy_Boundary(boundary);
	fclose(f);
	return shape;
}





/***********************************************************/

/******************* Point Functions ***********************/

int get_orientation(Point* A, Point* B, Point* C) {
	
	double val = (A->x * B->y  +  A->y * C->x  +  B->x * C->y -
		          A->y * B->x  -  A->x * C->y  -  B->y * C->x);
	
	if (fabs(val) > COLLINEAR_TOLERANCE) return val > 0 ? 1 : -1;
	else return 1;
}

int read_Point(FILE* f, Point* point) {
	Number num1, num2;
	num1 = next_number(f, NUM_DOUBLE);
	num2 = next_number(f, NUM_DOUBLE);
	
	if (num1.type == NUM_ERROR || num2.type == NUM_ERROR) return -1;
	
	point->x = num1.f;
	point->y = num2.f;
	
	//printf("Reading point: %f %f\n", point->x, point->y);
	
	return 0;
}


/***********************************************************/

