/* We import the data on Bitcoin */
/* Assumes bitcoin.csv is in the SAME directory as this SAS script */
PROC IMPORT datafile = "bitcoin.csv" 
     dbms = csv
     out = WORK.Bitcoin;
getnames = yes;
RUN;

/* We select the period of the bubble explosion that interests us */
/* The period starts 500 days before the crash */
DATA WORK.BitcoinTransition;
    set WORK.Bitcoin;
    where Date >= '27NOV2019'd and Date < '10APR2021'd; /* crash on April 10, 2021 */
	Index = -500 + _N_ - 1; /* We add an index which gives the distance of the crash */
RUN;

/* We can plot this crash of the Bitcoin price */
PROC SGPLOT data=WORK.BitcoinTransition;
    series x=Index y=Close;
    xaxis label="Index";
    yaxis label="Bitcoin Price";
RUN;



/* We use the Gaussian kernel smoothing method */
PROC IML;
	use WORK.BitcoinTransition;
	read all var {Close} into p;;
	close WORK.BitcoinTransition;

	start G(x,sigma);
		g=1/(sqrt(2*constant('PI'))*sigma)*exp(-x##2/(2*sigma##2));
		return(G);
	finish G;

	sigma=13;
	ma=j(nrow(p),1,0);
	
	do j=1 to nrow(p);
		i=(j-nrow(p):j-1)`;
		w=g(i,sigma);
		XX=p[j-i];
		ma[j]=sum(W#XX)/w[+];
	end;

	denoise=(p-ma); /* We will calculate the indicators on denoise */
	Index = -500:-1;

	/* We add denoise and Index to a new table */
	create DenoiseData var {"Index" "denoise"};
	append;
	close DenoiseData;

	/* We calculate different leading indicators : AR(1) coefficient, 
	the standard deviation, the skewness and the Kendall tau */
	wind = nrow(denoise)/2;
	results = j(nrow(denoise)-wind, 5, .);
	do t=1 to nrow(denoise)-wind;
		Y=denoise[t:wind+(t-1)];
		Y1=Y[1:nrow(Y)-1];
		Y2=Y[2:nrow(Y)];
		
		C=Corr(Y1||Y2);
		CoeffAR1 = C[1,2];
		stddev=std(Y);
		skw=skewness(Y);
		C2=Corr(Y1||Y2,"Kendall");
		ktauAR1 = C2[1,2];
		
		results[t,] = wind+(t-1) || CoeffAR1 || stddev || skw || ktauAR1;
	end;
	
	create ParamData from results[colname={"Index" "CoeffAR1" "stddev" 
	"Skewness" "KendalltauAR1"}];
    append from results;
    close ParamData;
QUIT;

/* We can plot the denoise value */
PROC SGPLOT data=DenoiseData;
    vbar Index / response=denoise barwidth=0.02;
    xaxis label="Index" fitpolicy=thin;
    yaxis label="Residuals";
RUN;

/* We can also plot the value of different leading indicators */
PROC SGPLOT DATA=ParamData;
    SCATTER X=Index Y=CoeffAR1;
    XAXIS LABEL="Index";
    YAXIS LABEL="AR(1) Coefficient";
RUN;

PROC SGPLOT DATA=ParamData;
    SCATTER X=Index Y=stddev;
    XAXIS LABEL="Index";
    YAXIS LABEL="Standard Deviation";
RUN;

PROC SGPLOT DATA=ParamData;
    SCATTER X=Index Y=Skewness;
    XAXIS LABEL="Index";
    YAXIS LABEL="Skewness";
RUN;

PROC SGPLOT DATA=ParamData;
    SCATTER X=Index Y=KendallTauAR1;
    XAXIS LABEL="Index";
    YAXIS LABEL="AR(1) Kendall's Tau";
RUN;



/* We will then test the robustness of the indicators */
PROC IML;
	use WORK.BitcoinTransition;
	read all var {Close} into p;;
	close WORK.BitcoinTransition;

	start G(x,sigma);
		g=1/(sqrt(2*constant('PI'))*sigma)*exp(-x##2/(2*sigma##2));
		return(G);
	finish G;
	
	results2 = j(201600, 3, .);
	tab=1;
	do s=5 to 20 by 0.01;
		ma=j(nrow(p),1,0);
	
		do j=1 to nrow(p);
			i=(j-nrow(p):j-1)`;
			w=g(i,s);
			XX=p[j-i];
			ma[j]=sum(W#XX)/w[+];
		end;

		denoise=(p-ma);
		
		do wind=125 to 250 by 1;
			do t=1 to nrow(denoise)-wind;
				Y=denoise[t:wind+(t-1)];
				Y1=Y[1:nrow(Y)-1];
				Y2=Y[2:nrow(Y)];
			end;
			
			C=Corr(Y1||Y2,"Kendall");
			ktauAR1 = C[1,2];
			
			results2[tab,] = s || wind || ktauAR1 ;
			tab=tab+1;
		end;
	end;
	
	create ParamData2 from results2[colname={"Sigma" "Window" "KendallTauAR1"}];
    append from results2;
    close ParamData2;
QUIT;

/* We can represent this with a heatmap */
ods graphics / NXYBINSMAX=250000;
PROC SGPLOT data=ParamData2;
    heatmapparm x=Sigma y=Window colorresponse=KendallTauAR1 / 
        colormodel=(darkblue blue dodgerblue cyan lightgreen yellowgold 
        yellow orange orangered red darkred black);
    xaxis label="Filtering Bandwidth" grid;
    yaxis label="Rolling Window Size" grid;
RUN;