OPTIONS SASAUTOS=('/wrds/wrdsmacros/', SASAUTOS) MAUTOSOURCE SOURCE NOCENTER LS=80 PS=MAX;
%INCLUDE "~/UTILITIES/UTILITIES.GENERAL.sas";

LIBNAME HOME "/scratch/uvanl";

LIBNAME CRSP "/wrds/crsp/sasdata/a_stock";
LIBNAME COMPG "/wrds/comp/sasdata/global";

/* TEST PROC EXPAND FUNCTION                                                  */

PROC EXPAND
    DATA = CRSP.MSF (KEEP = PERMNO DATE RET)
    OUT = LEAD_LAG
    METHOD = NONE;

    BY PERMNO;
    ID DATE;

    CONVERT RET = RET_L1 / TRANSFORMOUT =  (LAG 1);
    CONVERT RET = RET_F1 / TRANSFORMOUT =  (LEAD 1);
RUN;


PROC PRINT DATA= LEAD_LAG (OBS=100);
RUN;

/* COMPUSTAT GLOBAL SECURITIES FILE                                           */
DATA G_SECD;
    SET COMPG.G_SECD (KEEP = GVKEY IID DATADATE CSHOC PRCCD);
RUN;

/* DAILY -> MONTHLY                                                           */
PROC SQL;
    CREATE TABLE GSECDSLO AS
        SELECT *
        FROM COMPG.G_SECD
        WHERE FIC = "SVN";
RUN;
QUIT;



PROC EXPAND
    DATA = COMPG.G_SECD
    OUT = G_SECD_QTR
    FROM = DAY
    TO = QTR;

    BY _CHARACTER_;
    ID DATADATE;
    
    CONVERT _NUMERIC_ = _NUMERIC_ / OBSERVED = END;
RUN;


PROC EXPAND
    DATA = GSECDSLO
    OUT = GSECDSLO_M
    FROM = DAY
    TO = MONTH;

    BY GVKEY IID;
    ID DATADATE;
    
    CONVERT _NUMERIC_ = _NUMERIC_ / OBSERVED = END;
RUN;

PROC PRINT DATA = GSECDSLO_M (OBS = 100);
RUN;


PROC EXPAND
    DATA = COMPG.G_SECD (KEEP = GVKEY IID DATADATE CSHOC PRCCD)
    OUT = LEAD_LAG
    METHOD = NONE;

    BY PERMNO;
    ID DATE;

    CONVERT RET = RET_L1 / TRANSFORMOUT =  (LAG 1);
    CONVERT RET = RET_F1 / TRANSFORMOUT =  (LEAD 1);
RUN;


/* MAKE HISTOGRAM OF RETURNS                                                  */
PROC GDEVICE NOFS;
       LIST _ALL_;
RUN;


ODS TRACE ON;

ODS PDF FILE = "~/PLOTS/HistogramOfReturns.pdf";
GOPTIONS RESET=GLOBAL DEVICE=PDF GACCESS=SASGAEDT GSFMODE=REPLACE;
TITLE "HISTOGRAM OF RETURNS";
PROC UNIVARIATE DATA=LEAD_LAG NOPRINT;
    HISTOGRAM RET;
RUN;
QUIT;
ODS PDF CLOSE;