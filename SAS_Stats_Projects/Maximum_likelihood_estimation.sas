
/*I'm using code directly from here as a starting point: 
https://blogs.sas.com/content/iml/2017/06/14/maximum-likelihood-estimates-in-sas.html*/

/* Create example Binomial(p, 10) data for unknown p */
data Binomial;  
input x @@;
datalines;
6 2 6 4 5 7 5 7 6 4 6 4 7 4 7 7 8 5 8 4 
;

ods select ParameterEstimates; 
proc nlmixed data=Binomial;
   parms p = 0.5;           
   bounds 0 < p < 1;
   NTrials = 10;
   model x ~ binomial(NTrials, p);
run;


/***********************************************************************************************/
/**************************POISSON EXAMPLE********************************************/
/***********************************************************************************************/

/*Using the above example, I attempt to find the same mean computed in this 
example using proc nlmixed: http://www.craigmile.com/peter/teaching/673/notes/SAS_likelihood.pdf*/
data Poisson;  
input x @@;
datalines;
6 5 8 8 13 11 7 8 7 10 8 4 3 12 5 11 9 15 12 6
;

/*The MLE for lambda here is 8.4*/
ods select ParameterEstimates;
proc nlmixed data=Poisson;
   parms lambda=1;          
   bounds lambda>0;
   model x ~ poisson(lambda);
run;

proc sort data=Poisson;
by x; run;

/*We know analytically the MLE of a poisson with parameter theta is X-bar, which is the sample mean*/
/*This confirms that the MLE for our sample data is 8.4 which proc nlmixed calculated.*/
proc means data=Poisson;
	var x;
	output out=averaged_data;
run; 

/***********************************************************************************************/
/**************************NORMAL EXAMPLE*********************************************/
/***********************************************************************************************/

/*Attempting again with a normal distribution, and randomly generated data*/
/*Let x be a r. var. equal to the cost of a medical procedure*/
/*estimate the mean and variance if both are unknown*/

data Normal;
call streaminit(123);       
do i = 1 to 10;
   x = rand("Uniform") * 1000;
   output;
end;
drop i; 
run;

/*for X~N(mu, sigma^2) both unknown, the MLE's of mu-hat and sigma^2 -hat are 
X-bar and V^2 respectively*/
ods select ParameterEstimates;
proc nlmixed data=Normal ;
   parms mean=0 variance=1;          
   bounds .M <= mean <= .I;
   bounds variance >= 0; 
   model x ~ normal(mean, variance);
run;
