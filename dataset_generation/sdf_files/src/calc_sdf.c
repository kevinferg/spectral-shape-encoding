#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "shape.h"
#include "io.h"
#include "sdf.h"

#define XYMIN 0
#define XYMAX 1
#define XYNUM 64


int main(int argc, char** argv) {
	int status;
	if (argc == 3) { 
		compute_sdf(argv[1], argv[2], XYMIN, XYMAX, XYNUM);
	} else if (argc == 4) {
		//printf("Using point file\n");
		compute_sdf_points(argv[1], argv[2], argv[3]);
	} else  {
		fprintf(stderr, "Enter input and output file names as command line arguments\n");
		return -1;
	}
	
	return 0;
}
