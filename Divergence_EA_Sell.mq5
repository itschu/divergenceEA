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
input int interval = 30;
input double ls = 0.04;
input double slippage = 40;
input int lotlimit = 100;
int macd_max = 0;
int price_max = 0;
double lot = 0;
double newLot_sell = 0;
double mult_fact = 2;
int numofmultiples_sell = 0;
int identifier_sell = 0;
double loop = 0;
int num_firstlot = 1;
double multiplier = 100000;
int lineCounter = 1;

double macdhigh[2] = {0, 0};
double pricehigh[2] = {0, 0};
datetime times[2] = {0, 0};

double first_sell = 0;
double thrd_highestlot_sell = 0;
double sec_highestlot_sell = 0;
double highestlot_sell = 0;

int macd = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 2, PRICE_CLOSE);

void OnTick(){
   trade.SetExpertMagicNumber(thisEAMagicNumber);   
   datetime rightbartime = iTime(_Symbol,PERIOD_CURRENT, 0);
   if(rightbartime != globalbartime){
      highpoint_search();
      checkDivergenceSell();
      globalbartime = rightbartime;
   }
}

void checkDivergenceSell(){
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
   int takeProfit = 100;
   int num = 0;
   for(int i = PositionsTotal()-1; i >= 0; i--){
      string sym = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         num += 1;
      } 
   }
   if (num > 0){
      double firstTP = 0;
      int num_2 = 0;
      for(int i = 0; i <= PositionsTotal()-1; i++){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            firstTP = PositionGetDouble(POSITION_TP);
            num_2 += 1;
         }   
      }
      // check if trades open is only one then call the function to open the second position
      if((num_2 <= num_firstlot)&&((highestlot_sell + interval*_Point) <= Bid)){
         //call the function and pass the following arguments into it
         trade.Sell(lot, NULL, Bid, NULL, firstTP, NULL);
         thrd_highestlot_sell = sec_highestlot_sell;
         sec_highestlot_sell = highestlot_sell;
         highestlot_sell = Bid;
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         for(int i = PositionsTotal()-1; i >= 0; i--){ 
            string sym = PositionGetSymbol(i);
            if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
               break;
            }   
         }
         double latestLot_sell = 0;
         if (numofmultiples_sell == 0){
            latestLot_sell = PositionGetDouble(POSITION_VOLUME);
            latestLot_sell = NormalizeDouble(latestLot_sell * mult_fact, 2);
         }else{
            latestLot_sell = newLot_sell * mult_fact;
         }
         //open more positions
         if (num_2 > num_firstlot){
            if(((highestlot_sell + interval*_Point) <= Bid) && (latestLot_sell < lotlimit)){
               trade.Sell(latestLot_sell, NULL, Bid, NULL, NULL, NULL);
               thrd_highestlot_sell = sec_highestlot_sell;
               sec_highestlot_sell = highestlot_sell;
               highestlot_sell = Bid;
               /**call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
               the argument of the first open price*/
               uniformPointCalculator_sell();
            }else{
               if(((highestlot_sell + interval*_Point) <= Bid) && (latestLot_sell > lotlimit)){
                  if (numofmultiples_sell == 0){
                     newLot_sell = PositionGetDouble(POSITION_VOLUME);
                     newLot_sell = newLot_sell*mult_fact;
                     identifier_sell = numofmultiples_sell+1;
                     loop = MathCeil(newLot_sell/lotlimit);
                     for(int i=1; i<=loop; i++){
                        if(i == loop){
                           double lastLot_sell = newLot_sell - (lotlimit * (i-1));
                           trade.Sell(NormalizeDouble(lastLot_sell, 2), NULL, Bid, NULL, NULL, identifier_sell);
                        }else{
                           trade.Sell(lotlimit, NULL, Bid, NULL, NULL, identifier_sell);
                        }
                     }
                     thrd_highestlot_sell = sec_highestlot_sell;
                     sec_highestlot_sell = highestlot_sell;
                     highestlot_sell = Bid;
                     numofmultiples_sell += 1;
                     uniformPointCalculator_sell();
                   }else{
                     if (numofmultiples_sell > 0){
                        newLot_sell = newLot_sell*mult_fact;
                        identifier_sell = numofmultiples_sell+1;
                        loop = MathCeil(newLot_sell/lotlimit);
                        for(int i=1; i<=loop; i++){
                           if(i == loop){
                              double lastLot_sell = newLot_sell - (lotlimit * (loop-1));
                              trade.Sell(NormalizeDouble(lastLot_sell, 2), NULL, Bid, NULL, NULL, identifier_sell);
                           }else{
                              trade.Sell(lotlimit, NULL, Bid, NULL, NULL, identifier_sell);
                           }
                        }
                        thrd_highestlot_sell = sec_highestlot_sell;
                        sec_highestlot_sell = highestlot_sell;
                        highestlot_sell = Bid;
                        numofmultiples_sell += 1;
                        uniformPointCalculator_sell();
                      }
                   }
                }       
             }
          }       
       }
       if ((macdhigh[0] != 0) && (macdhigh[1] != 0)){
          higharray_update();
       }
   }else{
      if ((macdhigh[0] != 0) && (macdhigh[1] != 0)){
         if ((pricehigh[1] > pricehigh[0]) && (macdhigh[1] < macdhigh[0])){
            //Checks for Regular Divergence
            numofmultiples_sell = 0;
            lot = ls;
            trade.Sell(lot, NULL, Bid, NULL, NULL, NULL);
               
            higharray_update();
               
            first_sell = Bid;
            thrd_highestlot_sell = 0;
            sec_highestlot_sell = 0;
            highestlot_sell = Bid;
               
            //get the details such as opening price and position id from the first opened positions
            double newTp = 0;
            ulong newTicket = 0;
            for(int i = 0; i <= PositionsTotal()-1; i++){ 
               string sym = PositionGetSymbol(i);
               if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
                  newTicket = PositionGetInteger(POSITION_TICKET);
                  break;
               }   
            }
            //add the take profit defined earlier to the opening price
            newTp = highestlot_sell - takeProfit*_Point;
            
            //modiify the first opened positions take profit and stop loss
            if (Bid < newTp){
               trade.PositionClose(newTicket);
            }else{
               trade.PositionModify(newTicket, 0, newTp);
            }   
         }else if((pricehigh[1] < pricehigh[0]) && (macdhigh[1] > macdhigh[0])){
            //Checks for Hidden Divergence
            numofmultiples_sell = 0;
            lot = ls;
            trade.Sell(lot, NULL, Bid, NULL, NULL, NULL);
               
            higharray_update();
               
            first_sell = Bid;
            thrd_highestlot_sell = 0;
            sec_highestlot_sell = 0;
            highestlot_sell = Bid;
               
            //get the details such as opening price and position id from the first opened positions
            double newTp = 0;
            ulong newTicket = 0;
            for(int i = 0; i <= PositionsTotal()-1; i++){ 
               string sym = PositionGetSymbol(i);
               if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
                  newTicket = PositionGetInteger(POSITION_TICKET);
                  break;
               }   
            }
            //add the take profit defined earlier to the opening price
            newTp = highestlot_sell - takeProfit*_Point;
            
            //modiify the first opened positions take profit and stop loss
            if (Bid < newTp){
               trade.PositionClose(newTicket);
            }else{
               trade.PositionModify(newTicket, 0, newTp);
            }
         }else{
            higharray_update();   
         }
      }
   }
}

void highpoint_search(){
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double pricehigh_array[5] = {0, 0, 0, 0, 0};
   if ((macdhigh[0] == 0) && (macdhigh[1] == 0)){
      MqlRates PriceInfo[];
      ArraySetAsSeries(PriceInfo, true);
      CopyRates(_Symbol, PERIOD_CURRENT, 1, 5, PriceInfo);
      pricehigh_array[0] = PriceInfo[0].high; pricehigh_array[1] = PriceInfo[1].high; pricehigh_array[2] = PriceInfo[2].high;
      pricehigh_array[3] = PriceInfo[3].high; pricehigh_array[4] = PriceInfo[4].high;
      
      double macdLineArray[];  
      ArraySetAsSeries(macdLineArray, true);
      //CopyBuffer(macd,0,1,5, macdLineArray); //MACD Bars
         
      CopyBuffer(macd,1,1,5, macdLineArray); //MACD Moving Avg
      macd_max = ArrayMaximum(macdLineArray, 0, WHOLE_ARRAY);
      price_max = ArrayMaximum(pricehigh_array, 0, WHOLE_ARRAY);
         
      if ((macdLineArray[2] == macdLineArray[macd_max]) && (macdLineArray[macd_max] > 0)){
         macdhigh[0] = macdLineArray[2];
         pricehigh[0] = pricehigh_array[price_max];
         times[0] = PriceInfo[price_max].time;
      }     
   }else{
      MqlRates PriceInfo[];
      ArraySetAsSeries(PriceInfo, true);
      CopyRates(_Symbol, PERIOD_CURRENT, 1, 5, PriceInfo);
      pricehigh_array[0] = PriceInfo[0].high; pricehigh_array[1] = PriceInfo[1].high; pricehigh_array[2] = PriceInfo[2].high;
      pricehigh_array[3] = PriceInfo[3].high; pricehigh_array[4] = PriceInfo[4].high;
      
      double macdLineArray[];  
      ArraySetAsSeries(macdLineArray, true);
      //CopyBuffer(macd,0,1,5, macdLineArray); //MACD Bars
      
      CopyBuffer(macd,1,1,5, macdLineArray); //MACD Moving Avg  
      macd_max = ArrayMaximum(macdLineArray, 0, WHOLE_ARRAY);
      price_max = ArrayMaximum(pricehigh_array, 0, WHOLE_ARRAY);
         
      if ((macdLineArray[2] == macdLineArray[macd_max]) && (macdLineArray[macd_max] > 0)){
         macdhigh[1] = macdLineArray[2];
         pricehigh[1] = pricehigh_array[price_max];
         times[1] = PriceInfo[price_max].time;
         string lineName = "TrendLine_"+ lineCounter;
         ObjectCreate(_Symbol, lineName, OBJ_TREND, 0 , times[0], pricehigh[0], times[1], pricehigh[1]);
         lineCounter++;
         if ((PriceInfo[price_max].high - slippage*_Point) > Ask){
            higharray_update();   
         }
      }
   }
}

void higharray_update(){
   macdhigh[0] = macdhigh[1];
   macdhigh[1] = 0;
   pricehigh[0] = pricehigh[1];
   pricehigh[1] = 0;
   times[0] = times[1];
   times[1] = 0;
}

void uniformPointCalculator_sell(){
   double nextTPSL = sec_highestlot_sell - 60*_Point;   
   double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);  
   
   //loop through all positions that are currently open
   for(int i = PositionsTotal()-1; i >= 0; i--){
      //get the details from the current position such as opening price, lot size, and position id 
      //so we can modify it
      string symbols = PositionGetSymbol(i);
      if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_SELL) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
         ulong posTicket = PositionGetInteger(POSITION_TICKET);
         if (Bid < nextTPSL){
            trade.PositionClose(posTicket);
         }else{
            trade.PositionModify(posTicket, 0, nextTPSL);
         }
      }        
   }    
}


