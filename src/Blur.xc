/////////////////////////////////////////////////////////////////////////////////////////
//
// COMS20600 - WEEKS 9 to 12
// ASSIGNMENT 3
// CODE SKELETON
// TITLE: "Concurrent Image Filter"
//
/////////////////////////////////////////////////////////////////////////////////////////

typedef unsigned char uchar;

#include <platform.h>
#include <stdio.h>
#include "pgmIO.h"

#define IMHT 256
#define IMWD 400

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
			c_out <: line[ x ];
			//printf( "-%4.1d ", line[ x ] ); //uncomment to show image values
		}
	 //printf( "\n" ); //uncomment to show image values
	 }

	 _closeinpgm();
	 printf( "DataInStream:Done...\n" );
	 return;
}


/////////////////////////////////////////////////////////////////////////////////////////
//
// Start your implementation by changing this function to farm out parts of the image...
//
/////////////////////////////////////////////////////////////////////////////////////////
void distributor(chanend c_in, chanend c_out)
{
	uchar val;
	uchar average;

	printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );

	//This code is to be replaced – it is a place holder for farming out the work...
	for( int y = 0; y < IMHT; y++ )
	{
		for( int x = 0; x < IMWD; x++ )
		{
			c_in :> val;
			matrix[y][x] = val;
			//c_out <: (uchar)( val ^ 0xFF ); //Need to cast
		 }
	}

	waitMoment(10000);
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
	}

	for(int i=0; i< IMHT; i++)
	{
		for(int j=0; j<IMWD; j++)
		{
			c_out <: (uchar)(blurredMatrix[i][j]);
		}
	}
	printf( "ProcessImage:Done...\n" );
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
 char infname[] = "D:\\BristolCathedral.pgm"; //put your input image path here
 char outfname[] = "D:\\testout.pgm"; //put your output image path here
 chan c_inIO, c_outIO; //extend your channel definitions here

 par //extend/change this par statement to implement your concurrent filter
 {
	 DataInStream( infname, c_inIO );
	 distributor( c_inIO, c_outIO );
	 DataOutStream( outfname, c_outIO );
 }

 printf( "Main:Done...\n" );

 return 0;
}
