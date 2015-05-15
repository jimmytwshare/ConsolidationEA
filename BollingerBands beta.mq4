//+------------------------------------------------------------------+
//|                                          BollingerBands beta.mq4 |
//|                                      Copyright 2015, Jimmy Chang |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2015, Jimmy Chang"
#property link      "http://www.mql5.com"
#property version   "1.00"
#property strict
//--- input parameters
input double   TakeProfit=50.0;
input double   StopLoss=80.0;
input double   Lots=0.1;
input double   TrailingStop=35.0;
input int      WorkPeriod=PERIOD_M1;
input int      MaxTrades=2;
input bool     ConsolidateMode=false;
bool bBuyOpened = false;
bool bSellOpened = false;
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
//---
    int    cnt,ticket,total;
    int i;
    double BandUp[6] = {0,0,0,0,0,0};
    double BandMain[6] = {0,0,0,0,0,0};
    double BandLow[6] = {0,0,0,0,0,0};
    double OpenPrice = 0;
    double dStopLoss = 0;
	bool   bConsolidate=ConsolidateMode;
	double val=iStdDev(NULL,WorkPeriod,20,0,MODE_SMA,PRICE_CLOSE,0);
//---
// initial data checks
// it is important to make sure that the expert works with a normal
// chart and the user did not make any mistakes setting external 
// variables (Lots, StopLoss, TakeProfit, 
// TrailingStop) in our case, we check TakeProfit
// on a chart of less than 100 bars
//---
	if(WorkPeriod==PERIOD_M1)
	{
		if(val<0.0003) bConsolidate=true;
		else bConsolidate=false;
	}
	else if(WorkPeriod==PERIOD_M5)
	{
		if(val<0.0008) bConsolidate=true;
		else bConsolidate=false;
	}
    if(Bars<100)
    {
        Print("bars less than 100");
        return;
    }
    if(TakeProfit<10)
    {
        Print("TakeProfit less than 10");
        return;
    }
//--- to simplify the coding and speed up access data are put into internal variables
    for(i=0;i<6;i++)
    {
        BandUp[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_CLOSE,MODE_UPPER,i);
        BandMain[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_CLOSE,MODE_MAIN,i);
        BandLow[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_CLOSE,MODE_LOWER,i);
    }
    total=OrdersTotal();
    if(total<MaxTrades)
    {
        //--- no opened orders identified
        if(AccountFreeMargin()<(1000*Lots))
        {
            Print("We have no money. Free Margin = ",AccountFreeMargin());
            return;
        }
		if(bConsolidate==false)
		{
			//--- check for long position (BUY) possibility
			if(High[1]<BandUp[1] && High[2]<BandUp[2] && High[3]<BandUp[3] &&
				High[4]<BandUp[4] && High[5]<BandUp[5] && (Bid+15*Point)>BandUp[0] && (bBuyOpened==false))
			{
				bBuyOpened = true;
				ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"Band beta buy",16384,0,Green);
				Print("Symbol=",Symbol(), 
					"    OP_BUY=",OP_BUY,
					"    Lots=",Lots,
					"    Ask=",Ask,
					"    Ask-2*TakeProfit*Point=",Ask-2*TakeProfit*Point,
					"    Ask+TakeProfit*Point=",Ask+TakeProfit*Point,
					"    Band beta buy",
					"    16384"
					"    0");
				if(ticket>0)
				{
					if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
						Print("BUY order opened : ",OrderOpenPrice());
					OpenPrice = OrderOpenPrice();
					dStopLoss = OpenPrice-StopLoss*Point;
					if(dStopLoss<BandMain[0]) dStopLoss=BandMain[0];
					if(!OrderModify(ticket,OpenPrice,dStopLoss,OpenPrice+TakeProfit*Point,0,Green))
						Print("OrderModify error ",GetLastError());
				}
				else
					Print("Error opening BUY order : ",GetLastError());
				return;
			}
			//--- check for short position (SELL) possibility
			if(Low[1]>BandLow[1] && Low[2]>BandLow[2] && Low[3]>BandLow[3] &&
				Low[4]>BandLow[4] && Low[5]>BandLow[5] && Bid<BandLow[0] && (bSellOpened==false))
			{
				bSellOpened = true;
				ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"Band beta sell",16384,0,Red);
				Print("Symbol=",Symbol(), 
					"    OP_SELL=",OP_SELL,
					"    Lots=",Lots,
					"    Bid=",Bid,
					"    Bid+2*TakeProfit*Point=",Bid+2*TakeProfit*Point,
					"    Bid-TakeProfit*Point=",Bid-TakeProfit*Point,
					"    Band beta sell",
					"    16384"
					"    0");
				if(ticket>0)
				{
					if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
						Print("SELL order opened : ",OrderOpenPrice());
					OpenPrice = OrderOpenPrice();
					dStopLoss = OpenPrice+StopLoss*Point;
					if(dStopLoss>BandMain[0]) dStopLoss=BandMain[0];
					if(!OrderModify(ticket,OpenPrice,dStopLoss,OpenPrice-TakeProfit*Point,0,Green))
						Print("OrderModify error ",GetLastError());
				}
				else
					Print("Error opening SELL order : ",GetLastError());
				return;
			}
		} // if(bConsolidate==false)
		else if(bConsolidate==true)
		{
			//--- check for short position (SELL) possibility
			if(High[1]<BandUp[1] && High[2]<BandUp[2] && High[3]<BandUp[3] &&
				High[4]<BandUp[4] && High[5]<BandUp[5] && Bid>BandUp[0] && (bSellOpened==false))
			{
				bSellOpened = true;
				ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"Consolidation sell",16384,0,Red);
				Print("Symbol=",Symbol(), 
					"    OP_SELL=",OP_SELL,
					"    Lots=",Lots,
					"    Bid=",Bid,
					"    Bid+2*TakeProfit*Point=",Bid+2*TakeProfit*Point,
					"    Bid-TakeProfit*Point=",Bid-TakeProfit*Point,
					"    Consolidation sell",
					"    16384"
					"    0");
				if(ticket>0)
				{
					if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
						Print("SELL order opened : ",OrderOpenPrice());
					OpenPrice = OrderOpenPrice();
					dStopLoss = OpenPrice+StopLoss*Point;
					if(dStopLoss>BandMain[0]) dStopLoss=BandMain[0];
					if(!OrderModify(ticket,OpenPrice,dStopLoss,OpenPrice-TakeProfit*Point,0,Green))
						Print("OrderModify error ",GetLastError());
				}
				else
					Print("Error opening SELL order : ",GetLastError());
				return;
			}
			//--- check for long position (BUY) possibility
			if(Low[1]>BandLow[1] && Low[2]>BandLow[2] && Low[3]>BandLow[3] &&
				Low[4]>BandLow[4] && Low[5]>BandLow[5] && Bid<BandLow[0] && (bBuyOpened==false))
			{
				bBuyOpened = true;
				ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"Consolidation buy",16384,0,Green);
				Print("Symbol=",Symbol(), 
					"    OP_BUY=",OP_BUY,
					"    Lots=",Lots,
					"    Ask=",Ask,
					"    Ask-2*TakeProfit*Point=",Ask-2*TakeProfit*Point,
					"    Ask+TakeProfit*Point=",Ask+TakeProfit*Point,
					"    Consolidation buy",
					"    16384"
					"    0");
				if(ticket>0)
				{
					if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
						Print("BUY order opened : ",OrderOpenPrice());
					OpenPrice = OrderOpenPrice();
					dStopLoss = OpenPrice-StopLoss*Point;
					if(dStopLoss<BandMain[0]) dStopLoss=BandMain[0];
					if(!OrderModify(ticket,OpenPrice,dStopLoss,OpenPrice+TakeProfit*Point,0,Green))
						Print("OrderModify error ",GetLastError());
				}
				else
					Print("Error opening BUY order : ",GetLastError());
				return;
			}
		} // if(bConsolidate==true)
    } // end of if(total<2)
    
    bBuyOpened=false;
    bSellOpened=false;
    //--- it is important to enter the market correctly, but it is more important to exit it correctly...   
    for(cnt=0;cnt<total;cnt++)
    {
        if(!OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES))
            continue;
        if(OrderType()<=OP_SELL &&   // check for opened position both OP_BUY=0 and OP_SELL=1
            OrderSymbol()==Symbol())  // check for symbol
        {
            //--- long position is opened
            if(OrderType()==OP_BUY)
            {
                bBuyOpened=true;
				//--- should it be closed?
				if(bConsolidate==true && Bid>OrderOpenPrice() &&
				   Bid>BandUp[0])
				{
					if(!OrderClose(OrderTicket(),OrderLots(),Bid,3,Violet))
						Print("OrderClose error ",GetLastError());
					return;
				}
				//else Print("Bid>BandUp[0]"," Bid=",Bid," BandUp[0]=",BandUp[0]);
                //--- check for trailing stop
                if(TrailingStop>0)
                {
                    if(Bid-OrderOpenPrice()>Point*TrailingStop)
                    {
                        if(OrderStopLoss()<Bid-Point*TrailingStop)
                        {
                            //--- modify order and exit
                            if(!OrderModify(OrderTicket(),OrderOpenPrice(),Bid-Point*TrailingStop,Bid+Point*TakeProfit,0,Green))
                                Print("OrderModify error ",GetLastError());
                            return;
                        }
                    }
                }
            }
            else // go to short position
            {
                bSellOpened=true;
				//--- should it be closed?
				if(bConsolidate==true && Ask<OrderOpenPrice() &&
				   Bid<BandLow[0])
				{
					if(!OrderClose(OrderTicket(),OrderLots(),Ask,3,Violet))
						Print("OrderClose error ",GetLastError());
					return;
				}
				//else Print("Bid<BandLow[0]"," Bid=",Bid," BandLow[0]=",BandLow[0]);
                //--- check for trailing stop
                if(TrailingStop>0)
                {
                    if((OrderOpenPrice()-Ask)>(Point*TrailingStop))
                    {
                        if((OrderStopLoss()>(Ask+Point*TrailingStop)) || (OrderStopLoss()==0))
                        {
                            //--- modify order and exit
                            if(!OrderModify(OrderTicket(),OrderOpenPrice(),Ask+Point*TrailingStop,Ask-Point*TakeProfit,0,Red))
                                Print("OrderModify error ",GetLastError());
                            return;
                        }
                    }
                }
            }
        }
    } // end of for(cnt=0;cnt<total;cnt++)
//---
}
