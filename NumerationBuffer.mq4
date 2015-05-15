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
#property indicator_buffers 2
//--- input parameters
input int      WorkPeriod=PERIOD_M1;
//---- indicator buffers
double ExtYellowBuffer[];
double ExtRedBuffer[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit(void)
{
    IndicatorDigits(Digits);
//---- line shifts when drawing
    SetIndexShift(0,0);
    SetIndexShift(1,0);
//---- first positions skipped when drawing
    //SetIndexDrawBegin(0,0);
//---- 2 indicator buffers mapping
    SetIndexBuffer(0,ExtYellowBuffer);
    SetIndexBuffer(1,ExtRedBuffer);
//---- drawing settings
    //SetIndexStyle(0,DRAW_LINE);
    SetIndexStyle(0,DRAW_ARROW,EMPTY,3,clrYellow);
    SetIndexStyle(1,DRAW_ARROW,EMPTY,3,clrRed);
//---- index labels
    SetIndexLabel(0,"Buy");
    SetIndexLabel(1,"Sell");
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
    double BandUp[6] = {0,0,0,0,0,0};
    double BandLow[6] = {0,0,0,0,0,0};
    int i=0;
    double val=0;
	string sConsolidate;
   
    for(i=1;i<=5;i++)
    {
        BandUp[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_CLOSE,MODE_UPPER,i);
        BandLow[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_CLOSE,MODE_LOWER,i);
    }
//---- main loop
    for(i=0; i<limit; i++)
    {
        ExtYellowBuffer[i]=0;
        ExtRedBuffer[i]=0;
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
                        ExtYellowBuffer[5]=high[5];
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
                        ExtRedBuffer[5]=low[5];               
                }
            }
        }
    }
    //Print("rates_total",rates_total," prev_calculated", prev_calculated," limit",limit);
    
    val=iStdDev(NULL,WorkPeriod,20,0,MODE_SMA,PRICE_CLOSE,0);
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
    ObjectCreate("ObjName", OBJ_LABEL, 0, 0, 0);
	ObjectSetText("ObjName","Volatility: "+val+"-"+sConsolidate,20, "Verdana", clrYellow);
    ObjectSet("ObjName", OBJPROP_CORNER, 0);
    ObjectSet("ObjName", OBJPROP_XDISTANCE, 20);
    ObjectSet("ObjName", OBJPROP_YDISTANCE, 20);
    
    ObjectCreate("ObjName2", OBJ_LABEL, 0, 0, 0);
    ObjectSetText("ObjName2","Bid: "+Bid,20, "Verdana", clrRed);
    ObjectSet("ObjName2", OBJPROP_CORNER, 0);
    ObjectSet("ObjName2", OBJPROP_XDISTANCE, 20);
    ObjectSet("ObjName2", OBJPROP_YDISTANCE, 60);
    
    ObjectCreate("ObjName3", OBJ_LABEL, 0, 0, 0);
    ObjectSetText("ObjName3","Ask: "+Ask,20, "Verdana", clrGreenYellow);
    ObjectSet("ObjName3", OBJPROP_CORNER, 0);
    ObjectSet("ObjName3", OBJPROP_XDISTANCE, 20);
    ObjectSet("ObjName3", OBJPROP_YDISTANCE, 100);
//---- done
    return(rates_total);
}
//+------------------------------------------------------------------+
