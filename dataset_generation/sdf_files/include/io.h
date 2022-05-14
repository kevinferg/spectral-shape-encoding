#pragma once

#include <stdio.h>

typedef enum NumberType {
	NUM_ERROR = -1,
	NUM_DOUBLE,
	NUM_INT
} NumberType;

typedef struct Number {
	NumberType type;
	union {
		double f;
		int i;
	};
} Number;

Number next_number(FILE* f, NumberType type);

