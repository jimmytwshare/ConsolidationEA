//+------------------------------------------------------------------+
//|                                             NumerationBuffer.mq4 |
//|                                      Copyright 2015, Jimmy Chang |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Jimmy Chang"
#property link      "http://www.mql5.com"
#property version   "1.00"

//---- indicator settings
#property indicator_chart_window
#property indicator_buffers 4
//--- input parameters
input int      WorkPeriod=PERIOD_M1;
//---- indicator buffers
double ExtYellowBuffer[];
double ExtRedBuffer[];
double ExtBlueBuffer[];
double ExtGreenBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit(void)
{
    IndicatorDigits(Digits);
//---- line shifts when drawing
    SetIndexShift(0,0);
    SetIndexShift(1,0);
    SetIndexShift(2,0);
    SetIndexShift(3,0);
//---- first positions skipped when drawing
    //SetIndexDrawBegin(0,0);
//---- 2 indicator buffers mapping
    SetIndexBuffer(0,ExtYellowBuffer);
    SetIndexBuffer(1,ExtRedBuffer);
    SetIndexBuffer(2,ExtBlueBuffer);
    SetIndexBuffer(3,ExtGreenBuffer);
//---- drawing settings
    //SetIndexStyle(0,DRAW_LINE);
    SetIndexStyle(0,DRAW_ARROW,EMPTY,3,clrYellow);
    SetIndexStyle(1,DRAW_ARROW,EMPTY,3,clrRed);
    SetIndexStyle(2,DRAW_ARROW,EMPTY,3,clrBlue);
    SetIndexStyle(3,DRAW_ARROW,EMPTY,3,clrGreen);
//---- index labels
    SetIndexLabel(0,"Buy");
    SetIndexLabel(1,"Sell");
    SetIndexLabel(2,"BollingerBands");
    SetIndexLabel(3,"Volatility");
  }
//+------------------------------------------------------------------+
//| BollingerBands Consolidation                                     |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
    int limit=rates_total-prev_calculated;
    double BandUp[9] = {0,0,0,0,0,0,0,0,0};
    double BandLow[9] = {0,0,0,0,0,0,0,0,0};
    int i=0;
	string sConsolidate;
    double val=iStdDev(NULL,WorkPeriod,20,0,MODE_SMA,PRICE_CLOSE,0);
   
    for(i=1;i<=8;i++)
    {
        BandUp[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_CLOSE,MODE_UPPER,i);
        BandLow[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_CLOSE,MODE_LOWER,i);
    }
//---- main loop
    for(i=0; i<limit; i++)
    {
        ExtYellowBuffer[i]=0;
        ExtRedBuffer[i]=0;
        ExtBlueBuffer[i]=0;
        ExtGreenBuffer[i]=0;
    }

    if(high[1]<BandUp[1])
    {
        ExtYellowBuffer[1]=high[1];
        if(high[2]<BandUp[2])
        {
            ExtYellowBuffer[2]=high[2];
            if(high[3]<BandUp[3])
            {
                ExtYellowBuffer[3]=high[3];
                if(high[4]<BandUp[4])
                {
                    ExtYellowBuffer[4]=high[4];
                    if(high[5]<BandUp[5])
                    {
                        ExtYellowBuffer[5]=high[5];
                        if(WorkPeriod==PERIOD_M1)
                        {
                            if(val<0.0003) ExtGreenBuffer[0]=close[0];
                        }
                        else if(WorkPeriod==PERIOD_M5)
                        {
                            if(val<0.0008) ExtGreenBuffer[0]=close[0];
                        }
                    }
                }
            }
        }
    }
   
    if(BandLow[1]<low[1])
    {
        ExtRedBuffer[1]=low[1];
        if(BandLow[2]<low[2])
        {
            ExtRedBuffer[2]=low[2];
            if(BandLow[3]<low[3])
            {
                ExtRedBuffer[3]=low[3];
                if(BandLow[4]<low[4])
                {
                    ExtRedBuffer[4]=low[4];
                    if(BandLow[5]<low[5])
                    {
                        ExtRedBuffer[5]=low[5];               
                        if(WorkPeriod==PERIOD_M1)
                        {
                            if(val<0.0003) ExtGreenBuffer[0]=close[0];
                        }
                        else if(WorkPeriod==PERIOD_M5)
                        {
                            if(val<0.0008) ExtGreenBuffer[0]=close[0];
                        }
                    }
                }
            }
        }
    }
    //Print("rates_total",rates_total," prev_calculated", prev_calculated," limit",limit);
    if(high[1]>BandUp[1] && high[2]>BandUp[2] && high[3]>BandUp[3] &&
       high[4]<BandUp[4] && high[5]<BandUp[5] && high[6]<BandUp[6] &&
       high[7]<BandUp[7] && high[8]<BandUp[8])
    {
        ExtBlueBuffer[0]=open[0];
    }
    if(BandLow[1]>low[1] && BandLow[2]>low[2] && BandLow[3]>low[3] &&
       BandLow[4]<low[4] && BandLow[5]<low[5] && BandLow[6]<low[6] &&
       BandLow[7]<low[7] && BandLow[8]<low[8])
    {
        ExtBlueBuffer[0]=open[0];
    }
    
	if(WorkPeriod==PERIOD_M1)
	{
		if(val<0.0003) sConsolidate="Consolidate";
		else sConsolidate="Beta";
	}
	else if(WorkPeriod==PERIOD_M5)
	{
		if(val<0.0008) sConsolidate="Consolidate";
		else sConsolidate="Beta";
	}
    ObjectCreate("ObjName1", OBJ_LABEL, 0, 0, 0);
	ObjectSetText("ObjName1","Volatility: "+val+"-"+sConsolidate,12, "Verdana", clrYellow);
    ObjectSet("ObjName1", OBJPROP_CORNER, 0);
    ObjectSet("ObjName1", OBJPROP_XDISTANCE, 20);
    ObjectSet("ObjName1", OBJPROP_YDISTANCE, 20);
    
    ObjectCreate("ObjName2", OBJ_LABEL, 0, 0, 0);
    ObjectSetText("ObjName2","Bid: "+Bid,12, "Verdana", clrRed);
    ObjectSet("ObjName2", OBJPROP_CORNER, 0);
    ObjectSet("ObjName2", OBJPROP_XDISTANCE, 20);
    ObjectSet("ObjName2", OBJPROP_YDISTANCE, 40);
    
    ObjectCreate("ObjName3", OBJ_LABEL, 0, 0, 0);
    ObjectSetText("ObjName3","Ask: "+Ask,12, "Verdana", clrGreenYellow);
    ObjectSet("ObjName3", OBJPROP_CORNER, 0);
    ObjectSet("ObjName3", OBJPROP_XDISTANCE, 20);
    ObjectSet("ObjName3", OBJPROP_YDISTANCE, 60);
//---- done
    return(rates_total);
}
//+------------------------------------------------------------------+
