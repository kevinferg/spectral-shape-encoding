#include <stdio.h>
#include <stdlib.h>
#include "io.h"

#define NUM_CHARS_TO_BUFFER 32
#define IS_NUM_CHAR(c) (((c)=='-') || ((c) == '.') || ((c) >='0' && (c) <='9'))



Number next_number(FILE* f, NumberType type){
	char current=0;
	static char buf[NUM_CHARS_TO_BUFFER];
	int index = 0;
	Number num = {.type = NUM_ERROR};
	do{
		current = fgetc(f);
		if (current == EOF){
			num.type = NUM_ERROR;
			return num;
		}
	}while(!IS_NUM_CHAR(current));
	
	
	while(IS_NUM_CHAR(current)){
		buf[index] = current;
		index++;
		current = fgetc(f);
		if (index>=NUM_CHARS_TO_BUFFER)
			break;
		
	}
	buf[index] = '\0';
	
	
	switch (type) {
	case NUM_DOUBLE:
		num.type = sscanf(buf, "%lf", &(num.f)) != 1? NUM_ERROR: NUM_DOUBLE;
		break;
	case NUM_INT:
		num.type = sscanf(buf, "%d", &(num.i)) != 1? NUM_ERROR: NUM_INT;
		break;
	default:
		num.type = NUM_ERROR;
	}

	return num;
}


