#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "sdf.h"
#include "shape.h"
#include "io.h"



double get_distance(Point* A, Point* B);
double get_dot(Point* A, Point* B);
double get_distance_to_line(Point* P, Point* L1, Point* L2, int reverse);
double get_distance_to_Boundary(Point* P, Boundary* boundary);

Point* read_point_file(char* filename, int* num_points);


int compute_sdf(char* filein, char* fileout, double xymin, double xymax, int res) {
	Shape*  shape = read_Shape(filein);
	if (shape == NULL) {
		fprintf(stderr, "Could not read shape from file\n");
		return -1;
	}
	
	if (xymin > xymax || res <= 0) {
		fprintf(stderr, "Bad dimensions requested\n");
		return -1;
	}
	
	
	Point p;
	int ix, iy;
	double x, y;
	
	FILE* f = fopen(fileout, "w");
	if (f == NULL) {
		destroy_Shape(shape);
		return -1;
	}
		
	
	for (ix = 0; ix < res; ix++) {
		for (iy = 0; iy < res; iy++) {
			p.x = ((double) ix / (double) res) * (xymax - xymin) + xymin;
			p.y = ((double) iy / (double) res) * (xymax - xymin) + xymin;
			
			fprintf(f, "%f ", get_distance_to_Shape(&p, shape));

		}
		fprintf(f, "\n");
	}
	
	fclose(f);
	destroy_Shape(shape);
	
	//printf("Success\n");
	
	return 0;
}




int compute_sdf_points(char* bound_file, char* point_file, char* out_file) {
	int i, num_points;
	Point* points = read_point_file(point_file, &num_points);
	if (points == NULL) {
		return -1;
	}
	
	Shape*  shape = read_Shape(bound_file);
	if (shape == NULL) {
		fprintf(stderr, "Could not read shape from file\n");
		free(points);
		return -1;
	}

	FILE* f = fopen(out_file, "w");
	if (f == NULL) {
		destroy_Shape(shape);
		free(points);
		return -1;
	}
	
	for (i = 0; i < num_points; i++) { 
		fprintf(f, "%f\n", get_distance_to_Shape(&(points[i]), shape));
	}
	
	fclose(f);
	destroy_Shape(shape);
	free(points);
	
	//printf("Success\n");
	
	return 0;

}

Point* read_point_file(char* filename, int* num_points) {
	Number num;
	int status;
	int i, N;
	FILE* f = fopen(filename, "r");
	if (f == NULL) {
		fprintf(stderr, "Point file not found\n");
		return NULL;
	}
	
	num = next_number(f, NUM_INT);
	N = num.i;
	if (num.type == NUM_ERROR || num.i <= 0) {
		*num_points = 0;
		fclose(f);
		return NULL;
	}
	
	Point* points = malloc(sizeof(Point) * N);
	
	for (i = 0; i < N; i++) {
		status = read_Point(f, &(points[i]));
		if (status) { 
			free(num_points);
			*num_points = 0;
			fclose(f);
			return NULL;
		}
	}
	
	*num_points = N;
	
	fclose(f);
	return points;
	
}



double get_distance(Point* A, Point* B) {
	
	double d1 = (A->x - B->x);
	double d2 = (A->y - B->y);

	return sqrt(d1 * d1 + d2 * d2); 
}

double get_dot(Point* A, Point* B) {
	return A->x * B->x + A->y * B->y; 
}



double get_distance_to_line(Point* P, Point* L1, Point* L2, int reverse) {
	
	int sign = get_orientation(L1, L2, P);
	
	Point v1 = { .x = P->x - L1->x,
				 .y = P->y - L1->y};
				 
	Point v2 = { .x = L2->x - L1->x,
				 .y = L2->y - L1->y};

	double scale = get_dot(&v1, &v2)/get_dot(&v2, &v2);
	
	Point target;
	
	//printf("Getting distance from (%f, %f) to points (%f, %f)->(%f, %f)\n",P->x, P->y, L1->x,L1->y, L2->x, L2->y);
	
	
	
	if (scale < 0.) {
		return get_distance(P, L1) * (reverse? -1: 1);
	} else if (scale > 1.) {
		return get_distance(P, L2) * (reverse? -1: 1);
	}
	
	target.x = L1->x + scale * v2.x;
	target.y = L1->y + scale * v2.y;
	
	return get_distance(P, &target) * (sign);
}

double get_distance_to_Boundary(Point* P, Boundary* boundary) {
	int N = boundary->num_points;
	int i;
	double dist, min_dist;
	
	min_dist = get_distance_to_line(P, &(boundary->points[N - 1]), &(boundary->points[0]), boundary->is_hole);
	//printf("     Calculated: %f\n",min_dist);
	for (i = 0; i < N-1; i++) {
		dist = get_distance_to_line(P, &(boundary->points[i]), &(boundary->points[i + 1]), boundary->is_hole);
		//printf("     Calculated: %f\n",dist);
		if (fabs(dist) < fabs(min_dist)) min_dist = dist;
	}

	//printf("Final distance is: %f\n", min_dist * (boundary->is_ccw? 1: -1));
	
	return min_dist * (boundary->is_ccw? -1: 1);
}


double get_distance_to_Shape(Point* P, Shape* shape) {
	int N = shape->num_bounds;
	int i;
	double dist, min_dist = 1e99;
	
	for (i = 0; i < N; i++) {
		
		//printf("\nFinding SDF to boundary %d...\n",i);
		
		dist = get_distance_to_Boundary(P, &(shape->bounds[i]));
		if (fabs(dist) < fabs(min_dist)) min_dist = dist;
	}

	return min_dist;
}

