//+------------------------------------------------------------------+
//|                                          Volatility.mq4 |
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
input int      WorkPeriod=PERIOD_M5;
input int      MaxTrades=2;
input bool     bDebug=true;
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
    double BandUp[8] = {0,0,0,0,0,0,0,0};
    double BandUpMain[8] = {0,0,0,0,0,0,0,0};
    double BandLow[8] = {0,0,0,0,0,0,0,0};
    double BandLowMain[8] = {0,0,0,0,0,0,0,0};
    double OpenPrice = 0;
    double dStopLoss = 0;
    static uint   LastBuyTick = 0;
    static uint   LastSellTick = 0;
    double val=iStdDev(NULL,WorkPeriod,20,0,MODE_LWMA,PRICE_TYPICAL,0);
//---
// initial data checks
// it is important to make sure that the expert works with a normal
// chart and the user did not make any mistakes setting external 
// variables (Lots, StopLoss, TakeProfit, 
// TrailingStop) in our case, we check TakeProfit
// on a chart of less than 100 bars
//---
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
    for(i=0;i<8;i++)
    {
        BandUp[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_HIGH,MODE_UPPER,i);
        BandUpMain[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_HIGH,MODE_MAIN,i);
        BandLow[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_LOW,MODE_LOWER,i);
        BandLowMain[i]=iBands(NULL,WorkPeriod,20,2,0,PRICE_LOW,MODE_MAIN,i);
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
        //--- check for long position (BUY) possibility
        if(High[7]<BandUp[7] && High[6]<BandUp[6] && High[5]<BandUp[5] &&
            High[4]<BandUp[4] && High[3]<BandUp[3] && 
            High[2]>BandUp[2] && High[1]>BandUp[1] &&
            (Bid+15*Point)>BandUp[0] && (bBuyOpened==false))
        {
            if(bDebug==true)
            {
                Print("Bid+15*Point=",(int)(((Bid+15*Point)-BandUp[0])*100000), 
                      ",H[1]=",(int)((High[1]-BandUp[1])*100000),
                      ",H[2]=",(int)((High[2]-BandUp[2])*100000),
                      ",H[3]=",(int)((BandUp[3]-High[3])*100000),
                      ",H[4]=",(int)((BandUp[4]-High[4])*100000),
                      ",H[5]=",(int)((BandUp[5]-High[5])*100000),
                      ",H[6]=",(int)((BandUp[6]-High[6])*100000),
                      ",H[7]=",(int)((BandUp[7]-High[7])*100000));
            }
            //--- Ticket interval must bigger than WorkPeriod
            if((GetTickCount()-LastBuyTick)<(uint)WorkPeriod*60*1000*6) return;
            bBuyOpened = true;
            ticket=OrderSend(Symbol(),OP_BUY,Lots,Ask,3,Ask-StopLoss*Point,Ask+TakeProfit*Point,"Buy:"+(string)val,111,0,Green);
            Print("Symbol=",Symbol(), 
                "    OP_BUY=",OP_BUY,
                "    Lots=",Lots,
                "    Ask=",Ask,
                "    Ask-StopLoss*Point=",Ask-StopLoss*Point,
                "    Ask+TakeProfit*Point=",Ask+TakeProfit*Point,
                "    Band beta buy",
                "    111"
                "    0");
            if(ticket>0)
            {
                if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                    Print("BUY order opened : ",OrderOpenPrice());
                OpenPrice = OrderOpenPrice();
                dStopLoss = OpenPrice-StopLoss*Point;
                if(dStopLoss>BandUpMain[0]) dStopLoss=BandUpMain[0];
                if(!OrderModify(ticket,OpenPrice,dStopLoss,OpenPrice+TakeProfit*Point,0,Green))
                    Print("OrderModify error ",GetLastError());
            }
            else
                Print("Error opening BUY order : ",GetLastError());
            LastBuyTick = GetTickCount();
            return;
        }
        //--- check for short position (SELL) possibility
        if(Low[7]>BandLow[7] && Low[6]>BandLow[6] && Low[5]>BandLow[5] &&
            Low[4]>BandLow[4] && Low[3]>BandLow[3] && 
            Low[2]<BandLow[2] && Low[1]<BandLow[1] && 
            Bid<BandLow[0] && (bSellOpened==false))
        {
            if(bDebug==true)
            {
                Print("Bid=",(int)((BandLow[0]-Bid)*100000), 
                      ",L[1]=",(int)((BandLow[1]-Low[1])*100000),
                      ",L[2]=",(int)((BandLow[2]-Low[2])*100000),
                      ",L[3]=",(int)((Low[3]-BandLow[3])*100000),
                      ",L[4]=",(int)((Low[4]-BandLow[4])*100000),
                      ",L[5]=",(int)((Low[5]-BandLow[5])*100000),
                      ",L[6]=",(int)((Low[6]-BandLow[6])*100000),
                      ",L[7]=",(int)((Low[7]-BandLow[7])*100000));
            }
            //--- Ticket interval must bigger than WorkPeriod
            if((GetTickCount()-LastSellTick)<(uint)WorkPeriod*60*1000*6) return;
            bSellOpened = true;
            ticket=OrderSend(Symbol(),OP_SELL,Lots,Bid,3,Bid+StopLoss*Point,Bid-TakeProfit*Point,"Sell:"+(string)val,222,0,Red);
            Print("Symbol=",Symbol(), 
                "    OP_SELL=",OP_SELL,
                "    Lots=",Lots,
                "    Bid=",Bid,
                "    Bid+StopLoss*Point=",Bid+StopLoss*Point,
                "    Bid-TakeProfit*Point=",Bid-TakeProfit*Point,
                "    Band beta sell",
                "    222"
                "    0");
            if(ticket>0)
            {
                if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
                    Print("SELL order opened : ",OrderOpenPrice());
                OpenPrice = OrderOpenPrice();
                dStopLoss = OpenPrice+StopLoss*Point;
                if(dStopLoss<BandLowMain[0]) dStopLoss=BandLowMain[0];
                if(!OrderModify(ticket,OpenPrice,dStopLoss+15,OpenPrice-TakeProfit*Point,0,Green))
                    Print("OrderModify error ",GetLastError());
            }
            else
                Print("Error opening SELL order : ",GetLastError());
            LastSellTick = GetTickCount();
            return;
        }
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
