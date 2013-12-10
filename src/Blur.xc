/////////////////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// CODE SKELETON
// TITLE: "Concurrent Image Filter"
// Team Eric & Catalin
//
/////////////////////////////////////////////////////////////////////////////////////////

typedef unsigned char uchar;

#include <platform.h>
#include <stdio.h>
#include "pgmIO.h"

#define IMHT 16
#define IMWD 16

typedef struct part {
	int x;
	int y;
	int fx; // final x
	int fy; // final y
	uchar mat[IMHT/2+1][IMWD/2+1];
}partToProcess;

typedef struct processed
{
	int x;
	int y;
	uchar blurredPixel;
}processedPixel;

uchar matrix[IMHT][IMWD];
uchar blurredMatrix[IMHT][IMWD];

void waitMoment(uint myTime)
{
     timer tmr;
     unsigned int waitTime;
     tmr :> waitTime;
     waitTime += myTime;
     tmr when timerafter(waitTime) :> void;
}

/////////////////////////////////////////////////////////////////////////////////////////
//
// Read Image from pgm file with path and name infname[] to channel c_out
//
/////////////////////////////////////////////////////////////////////////////////////////
void DataInStream(char infname[], chanend c_out)
{
	int res;
	uchar line[ IMWD ];

	printf( "DataInStream:Start...\n" );

	res = _openinpgm( infname, IMWD, IMHT );
	if( res )
	{
		printf( "DataInStream:Error openening %s\n.", infname );
		return;
	}

	for( int y = 0; y < IMHT; y++ )
	{
		_readinline( line, IMWD );
		for( int x = 0; x < IMWD; x++ )
		{
			c_out <: (uchar)x;
			//printf( "-%4.1d ", line[ x ] ); //uncomment to show image values
		}
	 //printf( "\n" ); //uncomment to show image values
	 }
	c_out <: 1;
	 _closeinpgm();
	 printf( "DataInStream:Done...\n" );
	 return;
}

void collector(chanend c_outIO, streaming chanend w0, streaming chanend w1, streaming chanend w2, streaming chanend w3) 
{

	for(int i=0; i< IMHT; i++)
	{
		for(int j=0; j<IMWD; j++)
		{
			c_outIO <: (uchar)(blurredMatrix[i][j]);
		}
	}
	printf( "Collector:Done...\n" );
}
/////////////////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to farm out parts of the image...
//
/////////////////////////////////////////////////////////////////////////////////////////
void distributor(chanend c_in, streaming chanend w1, streaming chanend w2, streaming chanend w3, streaming chanend w4)
{
	uchar val;
	int x;
	uchar average;
	partToProcess worker1, worker2, worker3, worker4;

	printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );

	
	//This code is to be replaced – it is a place holder for farming out the work...
	for( int y = 0; y < IMHT; y++ )
	{
		for( int x = 0; x < IMWD; x++ )
		{
			c_in :> val;
			matrix[y][x] = (uchar)x;
			//c_out <: (uchar)( val ^ 0xFF ); //Need to cast
		 }
	}
	

	//assignStruct
	worker1.x = 1;
	worker1.y = 1;
	worker1.fx = IMHT/2 - 1;
	worker1.fy = IMWD/2 - 1;

	for( int x = worker1.x - 1; x <  IMHT/2 + 1; x++ )
	{
		for( int y = 0; y < IMWD/2 + 1; y++ )
		{
			worker1.mat[x][y] = matrix[x][y];
			worker2.mat[x][y] = matrix[x][y + IMWD/2 - 1];
			worker3.mat[x][y] = matrix[x + IMHT/2 -1][y];
			worker4.mat[x][y] = matrix[x + IMHT/2 -1][y + IMWD/2 - 1];
		}
	}

	worker2.x = 1;
	worker2.y = IMWD/2;
	worker2.fx = IMHT/2 - 1;
	worker2.fy = IMWD - 2;

	worker3.x = IMHT/2;
	worker3.y = 1;
	worker3.fx = IMHT - 2;
	worker3.fy = IMWD/2 - 1;

	worker4.x = IMHT/2;
	worker4.y = IMWD/2;
	worker4.fx = IMHT - 2;
	worker4.fy = IMWD - 2;

	w1 <: worker1;
	w2 <: worker2;
	w3 <: worker3;
	w4 <: worker4;

	/*waitMoment(10000);
	for(int i=0; i< IMHT; i++)
	{
		for(int j=0; j<IMWD; j++)
		{
			if(i==0 || i == (IMHT-1) || j == 0 || j == (IMWD-1))
			{
				blurredMatrix[i][j] = (uchar)0;
				continue;
			}
			blurredMatrix[i][j] = (uchar)(matrix[i-1][j-1]/8) +
								  (uchar)(matrix[i-1][j]/8) +
								  (uchar)(matrix[i-1][j+1]/8) +
								  (uchar)(matrix[i][j-1]/8) +
								  (uchar)(matrix[i][j+1]/8) +
								  (uchar)(matrix[i+1][j-1]/8) +
								  (uchar)(matrix[i+1][j]/8) +
								  (uchar)(matrix[i+1][j+1]/8);


		}
	}*/
		printf("distributor ended\n");

}

void worker1(streaming chanend cin, streaming chanend cout)
{
	partToProcess w1;
	cin :> w1;
	printf ("W1 %d %d\n", w1.mat[w1.x][w1.y], w1.mat[w1.fx][w1.fy]);
}

void worker2(streaming chanend cin, streaming chanend cout) 
{
	partToProcess w2; 
	cin :> w2;
	printf ("W2 %d %d\n", w2.fx, w2.fy);
}	

void worker3(streaming chanend cin, streaming chanend cout) 
{
	partToProcess w3; 
	cin :> w3;
}	

void worker4(streaming chanend cin, streaming chanend cout) 
{
	partToProcess w4; 
	cin :> w4;
	printf ("W4 1 %d %d\n", w4.x, w4.y);
	printf ("W4 2 %d %d\n", w4.fx, w4.fy);
}	


/////////////////////////////////////////////////////////////////////////////////////////
//
// Write pixel stream from channel c_in to pgm image file
//
/////////////////////////////////////////////////////////////////////////////////////////

void DataOutStream(char outfname[], chanend c_in)
{
	timer tmr;
	float time1, time2;
	int res;
	uchar line[ IMWD ];
	tmr :> time1; 
	printf( "DataOutStream:Start...\n" );

	 res = _openoutpgm( outfname, IMWD, IMHT );
	 if( res )
	 {
		 printf( "DataOutStream:Error opening %s\n.", outfname );
		 return;
	 }
	 for( int y = 0; y < IMHT; y++ )
	 {
		 for( int x = 0; x < IMWD; x++ )
		 {
			 c_in :> line[ x ];
		 //printf( "+%4.1d ", line[ x ] );
		 }
	 //printf( "\n" );
	 _writeoutline( line, IMWD );
	 }

	 _closeoutpgm();
	 tmr :> time2;
	 printf( "DataOutStream:Done in %.3f \n", (time2-time1)/1000000 );
	 return;
}


//MAIN PROCESS defining channels, orchestrating and starting the threads
int main()
{
 char infname[] = "D:\\test0.pgm"; //put your input image path here
 char outfname[] = "D:\\testout.pgm"; //put your output image path here
 chan c_inIO, c_outIO; //extend your channel definitions here
 streaming chan wIN[4];
 streaming chan wOUT[4];

 par //extend/change this par statement to implement your concurrent filter
 {
	 DataInStream( infname, c_inIO );
	 distributor( c_inIO, wIN[0], wIN[1], wIN[2], wIN[3]);
	 worker1(wIN[0], wOUT[0]);
	 worker2(wIN[1], wOUT[1]);
	 worker3(wIN[2], wOUT[2]);
	 worker4(wIN[3], wOUT[3]);
	 collector(c_outIO, wOUT[0], wOUT[1], wOUT[2], wOUT[3]);
	 DataOutStream( outfname, c_outIO );
 }

 printf( "Main:Done...\n" );

 return 0;
}
