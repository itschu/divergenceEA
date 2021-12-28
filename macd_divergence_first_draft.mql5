//+------------------------------------------------------------------+
//|                                                   divergence.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


long authorizedUser = 160194868;
input long key = 0;

int OnInit(){
   long currentUser = AccountInfoInteger(ACCOUNT_LOGIN);
   //if(currentUser == authorizedUser){
   /**
      the possibilities are limitless we can give a key that you will manually have to input when loading the EA or just check for the account id / login
   */
   if(key == authorizedUser){
      Alert("Authorization of account successfull");
      return(INIT_SUCCEEDED);
   }else{
      Alert("Unauthorized account, please purchase ");
      return(INIT_FAILED);
   }
}
  
void OnDeinit(const int reason){
}

#include<Trade\Trade.mqh>
CTrade trade;

datetime globalbartime;
input int thisEAMagicNumber = 0x110001;

double lastMacdLow = 0;
double lastThirdMacdLow = 0;
double prevMacdLow = 0;
double currentMacdLow = 0;

double lastPricePoint = 0;
double lastThirdPricePoint = 0;
double prevPricePoint = 0;
double currentPricePoint = 0;

double lastPriceTime = 0;
double lastThirdPriceTime = 0;
double prevPriceTime = 0;
double currentPriceTime = 0;

bool tradeTaken = true;

int tradeCounter = 0;

double lot = 0.01;

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
   CopyRates(_Symbol, PERIOD_CURRENT, 0, 5, PriceInfo);
   
   int macd = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
   double macdLineArray[];  
   
   ArraySetAsSeries(macdLineArray, true);
   
   CopyBuffer(macd,0,0,5, macdLineArray);
   
   if(macdLineArray[0] < 0){
      if(macdLineArray[0] > macdLineArray[1] && macdLineArray[1] > macdLineArray[2] &&  macdLineArray[2] > macdLineArray[3] &&  macdLineArray[3] < macdLineArray[4] ){
         lastMacdLow = lastThirdMacdLow;
         lastThirdMacdLow = prevMacdLow;
         prevMacdLow = currentMacdLow;
         currentMacdLow = macdLineArray[3];
         
         lastPricePoint = lastThirdPricePoint;
         lastThirdPricePoint = prevPricePoint;
         prevPricePoint = currentPricePoint;
         currentPricePoint = PriceInfo[3].low;
         
         lastPriceTime = lastThirdPriceTime;
         lastThirdPriceTime = prevPriceTime;
         prevPriceTime = currentPriceTime;
         currentPriceTime = PriceInfo[3].time;
         tradeTaken = false;
      }
      
      if(prevMacdLow != 0 && currentMacdLow != 0 && PositionsTotal() == 0){
         double tp = Ask + 0.0005;
         double sl = Ask - 0.0008;
         
         if((prevMacdLow < currentMacdLow) && (prevPricePoint > currentPricePoint) && tradeTaken == false  && (currentPriceTime - prevPriceTime) > 4000){
            //trade.Buy(lot, NULL, Ask, NULL, NULL, NULL);
            trade.Buy(lot, NULL, Ask, sl, tp, NULL);
            tradeTaken = true;   
            string lineName = "Trend Line" + tradeCounter;
            drawLine(lineName, prevPriceTime, prevPricePoint, currentPriceTime, currentPricePoint);
            drawLine(lineName+"sW", prevPriceTime, prevMacdLow, currentPriceTime, currentMacdLow, 1);
            
         }else if((prevMacdLow > currentMacdLow) && (prevPricePoint < currentPricePoint) && tradeTaken == false && (currentPriceTime - prevPriceTime) > 4000){
            trade.Buy(lot, NULL, Ask, sl, tp, NULL);
            tradeTaken = true;
            string lineName = "Trend Line" + tradeCounter;
            drawLine(lineName, prevPriceTime, prevPricePoint, currentPriceTime, currentPricePoint);
            drawLine(lineName+"sW", prevPriceTime, prevMacdLow, currentPriceTime, currentMacdLow, 1);
            Comment(currentPriceTime -prevPriceTime);
         }else if((lastThirdMacdLow < currentMacdLow) && (lastThirdPricePoint > currentPricePoint) && tradeTaken == false && (currentPriceTime - lastThirdPriceTime) > 4000){
            trade.Buy(lot, NULL, Ask, sl, tp, NULL);
            tradeTaken = true;
            string lineName = "Trend Line" + tradeCounter;
            drawLine(lineName, lastThirdPriceTime, lastThirdPricePoint, currentPriceTime, currentPricePoint);
            drawLine(lineName+"sW", lastThirdPriceTime, lastThirdMacdLow, currentPriceTime, currentMacdLow, 1);
            Comment(currentPriceTime - lastThirdPriceTime);
         }else if((lastThirdMacdLow > currentMacdLow) && (lastThirdPricePoint < currentPricePoint) && tradeTaken == false && (currentPriceTime - lastThirdPriceTime) > 4000){
            trade.Buy(lot, NULL, Ask, sl, tp, NULL);
            tradeTaken = true;
            string lineName = "Trend Line" + tradeCounter;
            drawLine(lineName, lastThirdPriceTime, lastThirdPricePoint, currentPriceTime, currentPricePoint);
            drawLine(lineName+"sW", lastThirdPriceTime, lastThirdMacdLow, currentPriceTime, currentMacdLow, 1);
            Comment(currentPriceTime - lastThirdPriceTime);
         }else if((lastMacdLow < currentMacdLow) && (lastPricePoint > currentPricePoint) && tradeTaken == false && (currentPriceTime - lastPriceTime) > 4000){
            /** trade.Buy(lot, NULL, Ask, sl, tp, NULL);
            tradeTaken = true;
            string lineName = "Trend Line" + tradeCounter;
            drawLine(lineName, lastPriceTime, lastPricePoint, currentPriceTime, currentPricePoint);
            Comment("condiition 5"); **/
         }else if((lastMacdLow > currentMacdLow) && (lastPricePoint < currentPricePoint) && tradeTaken == false && (currentPriceTime - lastPriceTime) > 4000){
            /** trade.Buy(lot, NULL, Ask, sl, tp, NULL);
            tradeTaken = true;
            string lineName = "Trend Line" + tradeCounter;
            drawLine(lineName, lastPriceTime, lastPricePoint, currentPriceTime, currentPricePoint);
            Comment("condiition 6"); **/
         }
      }
   }
   
   tradeCounter++;
}

void drawLine(string name, double time1, double price1, double time2, double price2, int window = 0){
   ObjectCreate(_Symbol, name, OBJ_TREND, window , time1, price1, time2, price2);
   ObjectSetInteger(window, name, OBJPROP_COLOR, clrAntiqueWhite);
}
