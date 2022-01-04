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
int macd_min = 0;
int price_min = 0;
double lot = 0;
double newLot_buy = 0;
double mult_fact = 2;
int numofmultiples_buy = 0;
int identifier_buy = 0;
double loop = 0;
int num_firstlot = 1;
double multiplier = 100000;
int lineCounter = 1;

double macdlow[2] = {0, 0};
double pricelow[2] = {0, 0};
datetime times[2] = {0, 0};

double first_buy = 0;
double thrd_highestlot_buy = 0;
double sec_highestlot_buy = 0;
double highestlot_buy = 0;

int macd = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 2, PRICE_CLOSE);

void OnTick(){
   trade.SetExpertMagicNumber(thisEAMagicNumber);   
   datetime rightbartime = iTime(_Symbol,PERIOD_CURRENT, 0);
   if(rightbartime != globalbartime){
      lowpoint_search();
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
   if (num > 0){
      double firstTP = 0;
      int num_2 = 0;
      for(int i = 0; i <= PositionsTotal()-1; i++){ 
         string sym = PositionGetSymbol(i);
         if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY)  && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
            firstTP = PositionGetDouble(POSITION_TP);
            num_2 += 1;
         }   
      }
      if((num_2 <= num_firstlot) && ((highestlot_buy - interval*_Point) >= Ask)){
         //call the function and pass the following arguments into it
         trade.Buy(lot, NULL, Ask, NULL, firstTP, NULL);
         thrd_highestlot_buy = sec_highestlot_buy;
         sec_highestlot_buy = highestlot_buy;
         highestlot_buy = Ask;
      }else{
         // check if trades open is greater than or equals to two, then call the function to open subsequent positions
         for(int i = PositionsTotal()-1; i >= 0; i--){ 
            string sym = PositionGetSymbol(i);
            if((PositionGetInteger(POSITION_TYPE) == ORDER_TYPE_BUY) && (PositionGetInteger(POSITION_MAGIC) == thisEAMagicNumber)){
               break;
            }   
         }
         double latestLot_buy = 0;
         if (numofmultiples_buy == 0){
            latestLot_buy = PositionGetDouble(POSITION_VOLUME);
            latestLot_buy = NormalizeDouble(latestLot_buy * mult_fact, 2);
         }else{
            latestLot_buy = newLot_buy * mult_fact;
         }
         if (num_2 > num_firstlot){
            if(((highestlot_buy - interval*_Point) >= Ask) && (latestLot_buy < lotlimit)){
               trade.Buy(latestLot_buy, NULL, Ask, NULL, NULL, NULL);
               thrd_highestlot_buy = sec_highestlot_buy;
               sec_highestlot_buy = highestlot_buy;
               highestlot_buy = Ask;
               /** call the function that will be used to modify all the positions and adjust the stop loss / take profit and pass in
               the argument of the first open price*/
               uniformPointCalculator_buy();
            }else{
               if(((highestlot_buy - interval*_Point) >= Ask) && (latestLot_buy > lotlimit)){
                  if (numofmultiples_buy == 0){
                     newLot_buy = PositionGetDouble(POSITION_VOLUME);
                     newLot_buy = newLot_buy*mult_fact;
                     identifier_buy = numofmultiples_buy+1;
                     loop = MathCeil(newLot_buy/lotlimit);
                     for(int i=1; i<=loop; i++){
                        if(i == loop){
                           double lastLot_buy = newLot_buy - (lotlimit * (i-1));
                           trade.Buy(NormalizeDouble(lastLot_buy, 2), NULL, Ask, NULL, NULL, identifier_buy);
                        }else{
                           trade.Buy(lotlimit, NULL, Ask, NULL, NULL, identifier_buy);
                        }    
                     }
                     thrd_highestlot_buy = sec_highestlot_buy;
                     sec_highestlot_buy = highestlot_buy;
                     highestlot_buy = Ask;
                     numofmultiples_buy += 1;
                     uniformPointCalculator_buy();
                   }else{
                     if (numofmultiples_buy > 0){
                        newLot_buy = newLot_buy*mult_fact;
                        identifier_buy = numofmultiples_buy+1;
                        loop = MathCeil(newLot_buy/lotlimit);
                        for(int i=1; i<=loop; i++){
                           if(i == loop){
                              double lastLot_buy = newLot_buy - (lotlimit * (loop-1));
                              trade.Buy(NormalizeDouble(lastLot_buy, 2), NULL, Ask, NULL, NULL, identifier_buy);
                           }else{
                              trade.Buy(lotlimit, NULL, Ask, NULL, NULL, identifier_buy);
                           }
                        }
                        thrd_highestlot_buy = sec_highestlot_buy;
                        sec_highestlot_buy = highestlot_buy;
                        highestlot_buy = Ask;
                        numofmultiples_buy += 1;
                        uniformPointCalculator_buy(); 
                     }
                  }
               }       
            }       
         }
      }
      if ((macdlow[0] != 0) && (macdlow[1] != 0)){
         lowarray_update();
      }
   }else{
      if ((macdlow[0] != 0) && (macdlow[1] != 0)){
         if ((pricelow[1] < pricelow[0]) && (macdlow[1] > macdlow[0])){
            //Checks for Regular Divergence
            numofmultiples_buy = 0;
            lot = ls;
            trade.Buy(lot, NULL, Ask, NULL, NULL, NULL);
               
            lowarray_update();
               
            first_buy = Ask;
            thrd_highestlot_buy = 0;
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
         }else if((pricelow[1] > pricelow[0]) && (macdlow[1] < macdlow[0])){
            //Checks for Hidden Divergence
            numofmultiples_buy = 0;
            lot = ls;
            trade.Buy(lot, NULL, Ask, NULL, NULL, NULL);
               
            lowarray_update();
               
            first_buy = Ask;
            thrd_highestlot_buy = 0;
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
            lowarray_update();   
         }
      }
   }
}

void lowpoint_search(){
   double Ask=NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
   double pricelow_array[5] = {0, 0, 0, 0, 0};
   if ((macdlow[0] == 0) && (macdlow[1] == 0)){
      MqlRates PriceInfo[];
      ArraySetAsSeries(PriceInfo, true);
      CopyRates(_Symbol, PERIOD_CURRENT, 1, 5, PriceInfo);
      pricelow_array[0] = PriceInfo[0].low; pricelow_array[1] = PriceInfo[1].low; pricelow_array[2] = PriceInfo[2].low;
      pricelow_array[3] = PriceInfo[3].low; pricelow_array[4] = PriceInfo[4].low;
      
      double macdLineArray[];  
      ArraySetAsSeries(macdLineArray, true);
      //CopyBuffer(macd,0,1,5, macdLineArray); //MACD Bars
         
      CopyBuffer(macd,1,1,5, macdLineArray); //MACD Moving Avg
      macd_min = ArrayMinimum(macdLineArray, 0, WHOLE_ARRAY);
      price_min = ArrayMinimum(pricelow_array, 0, WHOLE_ARRAY);
         
      if ((macdLineArray[2] == macdLineArray[macd_min]) && (macdLineArray[macd_min] < 0)){
         macdlow[0] = macdLineArray[2];
         pricelow[0] = pricelow_array[price_min];
         times[0] = PriceInfo[price_min].time;
      }     
   }else{
      MqlRates PriceInfo[];
      ArraySetAsSeries(PriceInfo, true);
      CopyRates(_Symbol, PERIOD_CURRENT, 1, 5, PriceInfo);
      pricelow_array[0] = PriceInfo[0].low; pricelow_array[1] = PriceInfo[1].low; pricelow_array[2] = PriceInfo[2].low;
      pricelow_array[3] = PriceInfo[3].low; pricelow_array[4] = PriceInfo[4].low;
      
      double macdLineArray[];  
      ArraySetAsSeries(macdLineArray, true);
      //CopyBuffer(macd,0,1,5, macdLineArray); //MACD Bars
      
      CopyBuffer(macd,1,1,5, macdLineArray); //MACD Moving Avg  
      macd_min = ArrayMinimum(macdLineArray, 0, WHOLE_ARRAY);
      price_min = ArrayMinimum(pricelow_array, 0, WHOLE_ARRAY);
         
      if ((macdLineArray[2] == macdLineArray[macd_min]) && (macdLineArray[macd_min] < 0)){
         macdlow[1] = macdLineArray[2];
         pricelow[1] = pricelow_array[price_min];
         times[1] = PriceInfo[price_min].time;
         string lineName = "TrendLine_"+ lineCounter;
         ObjectCreate(_Symbol, lineName, OBJ_TREND, 0 , times[0], pricelow[0], times[1], pricelow[1]);
         lineCounter++;
         if ((PriceInfo[price_min].low + slippage*_Point) < Ask){
            lowarray_update();   
         }
      }
   }
}

void lowarray_update(){
   macdlow[0] = macdlow[1];
   macdlow[1] = 0;
   pricelow[0] = pricelow[1];
   pricelow[1] = 0;
   times[0] = times[1];
   times[1] = 0;
}

void uniformPointCalculator_buy(){
   double nextTPSL = sec_highestlot_buy + 60*_Point;   
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


