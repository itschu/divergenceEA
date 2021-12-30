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
input int interval = 40;
double lot = 0.01;

double macdlow[2] = {0, 0};
double pricelow[2] = {0, 0};

double sec_highestlot_buy = 0;
double highestlot_buy = 0;

int macd = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 2, PRICE_CLOSE);

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
   int takeProfit = 100;
   int num = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--){
      string sym = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         num += 1;
      }
   }
   if (num != 0){
      if ((highestlot_buy - Ask) > interval){
         lot = lot*2.5;
         trade.Buy(lot, NULL, Ask, NULL, NULL, NULL);
         sec_highestlot_buy = highestlot_buy;
         highestlot_buy = Ask;
         //uniformPointCalculator_buy();
      }
   }else{
      if ((macdlow[0] == 0) && (macdlow[1] == 0)){
         MqlRates PriceInfo[];
         ArraySetAsSeries(PriceInfo, true);
         CopyRates(_Symbol, PERIOD_CURRENT, 1, 4, PriceInfo);
      
         double macdLineArray[];  
         ArraySetAsSeries(macdLineArray, true);
         CopyBuffer(macd,0,0,3, macdLineArray);
         
         int macd_min = ArrayMinimum(macdLineArray,WHOLE_ARRAY,0);
         
         if (macdLineArray[macd_min] == macdLineArray[1]){
            macdlow[0] = macdLineArray[1];
            pricelow[0] = PriceInfo[3].close;
         }     
      }else{
         MqlRates PriceInfo[];
         ArraySetAsSeries(PriceInfo, true);
         CopyRates(_Symbol, PERIOD_CURRENT, 1, 4, PriceInfo);
      
         double macdLineArray[];  
         ArraySetAsSeries(macdLineArray, true);
         CopyBuffer(macd,0,0,3, macdLineArray);
         
         int macd_min = ArrayMinimum(macdLineArray,WHOLE_ARRAY,0);
         
         if (macdLineArray[macd_min] == macdLineArray[1]){
            macdlow[1] = macdLineArray[1];
            pricelow[1] = PriceInfo[3].close;
            if ((pricelow[1] < pricelow[0]) && macdlow[1] > macdlow[0]){
               trade.Buy(lot, NULL, Ask, NULL, NULL, NULL);
               
               macdlow[0] = 0;
               macdlow[1] = 0;
               pricelow[0] = 0;
               pricelow[1] = 0;
               
               sec_highestlot_buy = 0;
               highestlot_buy = Ask;
               
               //get the details such as opening price and position id from the first opened positions
               double newTp = 0;
               ulong newTicket = 0;
               for(int i = 0; i <= PositionsTotal()-1; i++){ 
                  string sym = PositionGetSymbol(i);
                  if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
                     newTicket = PositionGetInteger(POSITION_TICKET);
                     break;
                  }   
               }
               //add the take profit defined earlier to the opening price
               newTp = highestlot_buy + takeProfit*_Point;
               
               //modiify the first opened positions take profit and stop loss
               if (Ask > newTp){
                  trade.PositionClose(newTicket);
               }else{
                  trade.PositionModify(newTicket, 0, newTp);
               }   
            }else{
               macdlow[0] = macdlow[1];
               macdlow[1] = 0;
               pricelow[0] = pricelow[1];
               pricelow[1] = 0;   
            }
         }
      }
   }
}

void uniformPointCalculator_buy(){
   double nextTPSL = sec_highestlot_buy + 50*_Point;   
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   
   //loop through all positions that are currently open
   for(int i = PositionsTotal()-1; i >= 0; i--){
      //get the details from the current position such as opening price, lot size, and position id 
      //so we can modify it
      string symbols = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         ulong posTicket = PositionGetInteger(POSITION_TICKET);
         if (Ask > nextTPSL){
            trade.PositionClose(posTicket);
         }else{
            trade.PositionModify(posTicket, 0, nextTPSL);
         }
      }        
   }    
}