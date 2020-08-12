
proc contents data=sashelp.baseball; run; 

/*To get an idea of what our data looks like, let's select the top few rows*/
proc sql outobs=10; 
select * 
from sashelp.baseball;
quit; 

/*instead of using a SQL step, we can also use proc print and use the option obs argument*/
proc print data=sashelp.baseball (obs=10); run; 

/*Let's say we want to identify the range of salaries players are paid and then we want to do some additional analysis from there;
alpha=0.1 specifies a 90% confidence limit and clm indicates two-sided confidence; note that we're performing all of this by Division*/

proc means data=sashelp.baseball alpha=0.1 clm; 
	class Division; 
	var Salary; 
	output out=SummaryStats 
		lclm=LowerConfidence
		uclm=UpperConfidence
		mean=AvgSalary 
		max=MaxSalary
		min=MinSalary
		stddev=StdDeviation; 
run; 

/*We now have the average, max, and min salary stored in the data set SummaryStats*/
proc sql; 
	create table Adjusted_SQL as 
	select 
		a.salary, 
		a.name, 
		a.salary - b.AvgSalary as surplus, 
		a.salary / b.AvgSalary as ratio_to_avg,
		(case when 
			a.salary < b.UpperConfidence and a.salary > b.LowerConfidence then "InsideCI" 
			else "OutsideCI" 
			end) as ConfidenceStatus,
		a.nHits,
		a.salary / a.nHits as dollars_per_hit, 
		a.salary / a.nHome as dollars_per_hr, 
		a.salary / a.nRuns as dollars_per_run
	from sashelp.baseball a 
	left join SummaryStats b
	on a.Division = b.Division;
quit; 


/*We can do the exact same thing we did with the SQL Step above using a Data step, although it takes a few extra sorting steps*/
/*At this stage, I need the sashelp data set sorted although I don't have permission. I'm just copying this into a new data set so I'm allowed to perform that*/

data baseball; set sashelp.baseball; run; 

proc sort data=baseball; by Division; run; 
proc sort data=SummaryStats; by Division; run; 

data Adjusted_Data; 
merge baseball SummaryStats;

surplus = salary - AvgSalary;
ratio_to_avg = salary / AvgSalary;

if salary < UpperConfidence and salary > LowerConfidence then ConfidenceStatus="InsideCI";
else ConfidenceStatus="OutsideCI";

dollars_per_hit = 	salary / nHits;
dollars_per_hr = salary / nHome;
dollars_per_run = salary / nRuns;

by Division; 
run; 


/*In a similar vein to the above, if we want to compare any data point as a ratio to the salary, instead of manually typing out 
every single column and dividing by salary like I did above, we can use a do loop inside a data step along with an array of the 
variables we want to compare*/

data baseball_array; 
set sashelp.baseball;

array original(9) nAtBat nHits nHome nRuns nRBI nBB nOuts nAssts nError;
array stat(9);

do i = 1 to 9; 
	if salary ne null 
		then stat(i) = salary / original(i);
end; 

keep stat1-stat9; 

run; 


/*plotting our data ====================================================================*/

proc print data=Adjusted_Data; run; 

proc sgplot data=ADJUSTED_DATA;
scatter y=nHits x=Team; 
run; 

/*let's plot by dollars_per_hit*/

proc sort data=ADJUSTED_DATA; 
by descending dollars_per_hit; 

proc gchart data=ADJUSTED_DATA;
title1 "Dollars Per Hit According to Frequency";
vbar dollars_per_hit;
run; 

/*a basic linear regression. Is the number of at bats related to the number of home runs a player hits? 
It looks like given our R^2 of 0.32, nAtBat is predictive of nHome, which makes sense*/

ods graphics on; 
proc reg data=ADJUSTED_DATA;
model nAtBat=nHome; 
run; 
ods graphics off;
