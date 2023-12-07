#include "fir.h"

void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial your fir
	for(int i=0; i<N; i=i+1){
		inputbuffer[i] = 0;
		outputsignal[i] = 0;
	}
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
	// initfir();
	//write down your fir
	for(int idx = 0; idx < N ; idx ++){
		for(int i=N-1; i > 0;i--){ // shift the data to be calculate in fir process
			inputbuffer[i] = inputbuffer[i-1];
		}
		inputbuffer[0] = inputsignal[idx];
		for(int cnt = 0; cnt < N; cnt ++){ // fir mult
			outputsignal[idx] += inputbuffer[cnt] * taps[cnt];
		}
	}
	
	return outputsignal;
}
		


// #include "fir.h"

// void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
// 	// initial your fir
// 	for(int i=0; i<N; i=i+1){
// 		inputbuffer[i] = 0;
// 		outputsignal[i] = 0;
// 	}
// }
// int __attribute__ ( ( section ( ".mprjram" ) ) ) output(int input) {
// 	// count fir output
// 	for(int i=(N-1); i>0; i=i-1){
// 		// x[0] => x[1] x[0] => x[2] x[1] x[0] => x[3] x[2] x[1] x[0] ... etc
// 		inputbuffer[i] = inputbuffer[i-1];
// 	}
// 	inputbuffer[0] = input;

// 	int outputdata = 0;
// 	for (int i=0; i<N; i=i+1){
// 		outputdata += taps[i] * inputbuffer[i];
// 	}
// 	return outputdata;
// }
// int* __attribute__ ( ( section ( ".mprjram" ) ) ) fir(){
// 	initfir();
// 	//write down your fir

// 	for(int i=0; i<N; i=i+1){
// 		outputsignal[i] = output(inputsignal[i]);
// 	}
// 	return outputsignal;
// }