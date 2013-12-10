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
#include <math.h>

#define IMHT 16
#define IMWD 16

out port cled[4] = {PORT_CLOCKLED_0,PORT_CLOCKLED_1,PORT_CLOCKLED_2,PORT_CLOCKLED_3};
out port cledG = PORT_CLOCKLED_SELG;
out port cledR = PORT_CLOCKLED_SELR;
in port buttons = PORT_BUTTON;
out port speaker = PORT_SPEAKER;

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

void showLED(out port p, chanend fromCollector)
{
     unsigned int lightUpPattern;
     unsigned int running = 1;
     while (running == 1)
     {
         select
         {
             case fromCollector :> lightUpPattern: //read LED pattern from visualiser process
                 if (lightUpPattern == 100) //Signal to terminate
                 {
                     /* PUT HERE ANY LED FLASHES FOR AN END SEQUENCE*/
                     p <: 0;
                     running = 0;
                 }
                 else
                     p <: lightUpPattern; //send pattern to LEDs
                 break;
             default:
                 break;
         }
     }
     printf("showled stops\n");
}

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
			c_out <: (uchar)line[x]; //line[x]
			// printf( "-%4.1d ", line[ x ] ); //uncomment to show image values
		}
	 // printf( "\n" ); //uncomment to show image values
	 }
	 _closeinpgm();
	 printf( "DataInStream:Done...\n" );
	 return;
}

void visualiser(chanend visualiser, chanend q0, chanend q1, chanend q2, chanend q3)
{
	int no, j, running = 1;
	int led1[13] = {0, 16, 48, 112,112,112,112,112,112,112,112,112,112};
	int led2[13] = {0,  0,  0,   0, 16, 48,112,112,112,112,112,112,112};
	int led3[13] = {0,  0,  0,   0,  0,  0,  0, 16, 48,112,112,112,112};
	int led4[13] = {0,  0,  0,   0,  0,  0,  0,  0,  0, 0, 16, 48, 112};
	int timeToWait = 1000000;
	while(running == 1)
	{
		visualiser :> no;
		q0 <: led1[no];
		q1 <: led2[no];
		q2 <: led3[no];
		q3 <: led4[no];
		waitMoment(timeToWait);
	}
}

void collector(chanend c_outIO, chanend w0, chanend w1, chanend w2, chanend w3, chanend visualiser)//
{
	int totalNo = (IMHT-2)*(IMWD-2);
	int total = totalNo;
	processedPixel pixel;

	while(totalNo > 0) 
	{
		select {
			case w0 :> pixel: {
				blurredMatrix[pixel.x][pixel.y] = pixel.blurredPixel;
				// printf("Rec from 0 %d %d %d\n",pixel.x, pixel.y,pixel.blurredPixel);
				totalNo --;
				break;
			}
			case w1 :> pixel: {
				blurredMatrix[pixel.x][pixel.y] = pixel.blurredPixel;
				// printf("Rec from 1 %d %d %d\n",pixel.x, pixel.y,pixel.blurredPixel);
				totalNo --;
				break;
			}
			case w2 :> pixel: {
				blurredMatrix[pixel.x][pixel.y] = pixel.blurredPixel;
				// printf("Rec from 2 %d %d %d\n",pixel.x, pixel.y,pixel.blurredPixel);
				totalNo --;
				break;
			}
			case w3 :> pixel: {
				blurredMatrix[pixel.x][pixel.y] = pixel.blurredPixel;
				// printf("Rec from 3 %d %d %d\n",pixel.x, pixel.y,pixel.blurredPixel);
				totalNo --;
				break;
			}

			default: break;
		}
		visualiser <: 12*(total-totalNo) / total;
	}
		

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
void distributor(chanend c_in, chanend w1, chanend w2, chanend w3, chanend w4)
{
	uchar val;
	int x;
	uchar average;
	partToProcess worker1, worker2, worker3, worker4;

	//printf( "ProcessImage:Start, size = %dx%d\n", IMHT, IMWD );
		cledR <: 1;
	
	//This code is to be replaced – it is a place holder for farming out the work...
	for( int y = 0; y < IMHT; y++ )
	{
		for( int x = 0; x < IMWD; x++ )
		{
			c_in :> val;
			matrix[y][x] = (uchar)val;
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
		printf("Distributor:Done...\n");

}
//!! We used floating points to keep precision (for errors with +- 8)
void worker1(chanend cin, chanend cout)
{
	partToProcess w1;
	processedPixel pixel;
	double temp;
	cin :> w1;
	for(int i=1; i < IMHT/2; ++i )
		for(int j=1; j < IMWD/2; ++j)
		{
			pixel.x = w1.x + i - 1;
			pixel.y = w1.y + j - 1;
			temp = (w1.mat[i-1][j-1]) +
				   (w1.mat[i-1][  j]) +
				   (w1.mat[i-1][j+1]) +
				   (w1.mat[  i][j-1]) +
				   (w1.mat[  i][j+1]) +
				   (w1.mat[i+1][j-1]) +
				   (w1.mat[i+1][  j]) +
				   (w1.mat[i+1][j+1]);
			temp /= 8;
			pixel.blurredPixel = (uchar)round(temp);
			cout <: pixel;
		}
		printf("Worker1:Done...\n");
}

void worker2(chanend cin, chanend cout) 
{
	partToProcess w2;
	processedPixel pixel;
	double temp;
	cin :> w2;
	for(int i=1; i < IMHT/2; ++i )
		for(int j=1; j < IMWD/2; ++j)
		{
			pixel.x = w2.x + i - 1;
			pixel.y = w2.y + j - 1;
			temp = (w2.mat[i-1][j-1]) +
				   (w2.mat[i-1][  j]) +
				   (w2.mat[i-1][j+1]) +
				   (w2.mat[  i][j-1]) +
				   (w2.mat[  i][j+1]) +
				   (w2.mat[i+1][j-1]) +
				   (w2.mat[i+1][  j]) +
				   (w2.mat[i+1][j+1]);
			temp /= 8;
			pixel.blurredPixel = (uchar)round(temp);
			cout <: pixel;
		}
	printf("Worker2:Done...\n");
}

void worker3(chanend cin, chanend cout) 
{
	partToProcess w3;
	processedPixel pixel;
	double temp;
	cin :> w3;
	for(int i=1; i < IMHT/2; ++i )
		for(int j=1; j < IMWD/2; ++j)
		{
			pixel.x = w3.x + i - 1;
			pixel.y = w3.y + j - 1;
			temp = (w3.mat[i-1][j-1]) +
				   (w3.mat[i-1][  j]) +
				   (w3.mat[i-1][j+1]) +
				   (w3.mat[  i][j-1]) +
				   (w3.mat[  i][j+1]) +
				   (w3.mat[i+1][j-1]) +
				   (w3.mat[i+1][  j]) +
				   (w3.mat[i+1][j+1]);
			temp /= 8;
			pixel.blurredPixel = (uchar)round(temp);
			cout <: pixel;
		}
	printf("Worker3:Done...\n");
}	

void worker4(chanend cin, chanend cout) 
{
	partToProcess w4;
	processedPixel pixel;
	double temp;
	cin :> w4;
	for(int i=1; i < IMHT/2; ++i )
		for(int j=1; j < IMWD/2; ++j)
		{
			pixel.x = w4.x + i - 1;
			pixel.y = w4.y + j - 1;
			temp = (w4.mat[i-1][j-1]) +
				   (w4.mat[i-1][  j]) +
				   (w4.mat[i-1][j+1]) +
				   (w4.mat[  i][j-1]) +
				   (w4.mat[  i][j+1]) +
				   (w4.mat[i+1][j-1]) +
				   (w4.mat[i+1][  j]) +
				   (w4.mat[i+1][j+1]);
			temp /= 8;
			pixel.blurredPixel = (uchar)round(temp);
			cout <: pixel;
		}
	printf("Worker4:Done...\n");		
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
		 // printf( "+%4.1d ", line[ x ] );
		 }
	 // printf( "\n" );
	 _writeoutline( line, IMWD );
	 }

	 _closeoutpgm();
	 tmr :> time2;
	 printf( "DataOutStream:Done in %.3f \n", (time2-time1)/100000000 );
	 return;
}


//MAIN PROCESS defining channels, orchestrating and starting the threads
int main()
{
 chan c_inIO, c_outIO; //extend your channel definitions here
 chan wIN[4];
 chan wOUT[4];
 chan quadrant[4]; //helper channels for LED visualisation
 chan toVisualiser;

 par //extend/change this par statement to implement your concurrent filter
 {
	 on stdcore[0]: DataInStream( "D:\\test0.pgm", c_inIO );
	 on stdcore[0]: distributor( c_inIO, wIN[0], wIN[1], wIN[2], wIN[3]);
	 on stdcore[2]:  worker1(wIN[0], wOUT[0]);
	 on stdcore[2]:  worker2(wIN[1], wOUT[1]);
	 on stdcore[3]:  worker3(wIN[2], wOUT[2]);
	 on stdcore[3]:  worker4(wIN[3], wOUT[3]);
	 on stdcore[1]:  collector(c_outIO, wOUT[0], wOUT[1], wOUT[2], wOUT[3], toVisualiser);//
	 on stdcore[2]: DataOutStream( "D:\\testout.pgm", c_outIO );
	 on stdcore[3]: visualiser(toVisualiser, quadrant[0], quadrant[1], quadrant[2], quadrant[3]);

	 on stdcore[0]: showLED(cled[0],quadrant[0]);
	 on stdcore[1]: showLED(cled[1],quadrant[1]);
	 on stdcore[2]: showLED(cled[2],quadrant[2]);
	 on stdcore[3]: showLED(cled[3],quadrant[3]);
 }

 return 0;
}
