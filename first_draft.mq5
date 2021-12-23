//+------------------------------------------------------------------+
//|                                                   divergence.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"

int OnInit(){
   return(INIT_SUCCEEDED);
}
  
void OnDeinit(const int reason){
}

#include<Trade\Trade.mqh>
CTrade trade;

datetime globalbartime;
input int thisEAMagicNumber = 0x110001;
double lastPointStoch = 0;
double currentPointStoch = 0;
double lastPointPrice = 0;
double currentPointPrice = 0;

void OnTick(){
   trade.SetExpertMagicNumber(thisEAMagicNumber);   
   datetime rightbartime = iTime(_Symbol,PERIOD_CURRENT, 0);
   if(rightbartime != globalbartime){
      checkDivergenceBuy();
      globalbartime = rightbartime;
   }
}

void checkDivergenceBuy(){
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   MqlRates PriceInfo[];
   ArraySetAsSeries(PriceInfo, true);
   int data = CopyRates(_Symbol, PERIOD_CURRENT, 0, 5, PriceInfo);
   
   int stoch = iStochastic(_Symbol, PERIOD_CURRENT, 8, 3, 3, MODE_SMA, STO_LOWHIGH);
   double stochGreenLine[];  
   double stochRedLine[];
   
   ArraySetAsSeries(stochGreenLine, true);
   ArraySetAsSeries(stochRedLine, true);
   
   CopyBuffer(stoch,0,0,3, stochGreenLine);
   CopyBuffer(stoch,1,0,3, stochRedLine);
   
   if((stochGreenLine[0] > stochRedLine[0]) && (stochGreenLine[1] < stochRedLine[1])){
      lastPointStoch = currentPointStoch;
      currentPointStoch = stochRedLine[1];
      
      lastPointPrice = currentPointPrice;
      currentPointPrice = PriceInfo[0].low;
      Comment(lastPointStoch,"\n",currentPointStoch,"\n\n",lastPointPrice,"\n",currentPointPrice);
      
      if(lastPointStoch != 0 && currentPointStoch != 0){
      
         if(PriceInfo[1].low < PriceInfo[2].low && PriceInfo[1].low < PriceInfo[3].low){ 
            if((lastPointStoch > currentPointStoch) && (lastPointPrice < currentPointPrice)){
               double tp = Ask + 0.0010;
               double sl = Ask - 0.0008;
               for(int i=0; i<=2; i++){
                  if(PositionsTotal() < 3)
                     trade.Buy(0.01, NULL, Ask, sl, tp, NULL);
               }
            }
         }
      }
   }
}
