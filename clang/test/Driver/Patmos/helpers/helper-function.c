///////////////////////////////////////////////////////////////////////////////////////////////////
//
// This is a helper .c file that isn't itself a test.
//
///////////////////////////////////////////////////////////////////////////////////////////////////
volatile int HELPER_SOURCE_INT = 4;

int helper_source_function(int x) { 
	return x + HELPER_SOURCE_INT;
}