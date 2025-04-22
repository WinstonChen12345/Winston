//+------------------------------------------------------------------+
//|                                          Falcon EA Template v2.0
//|                                        Copyright 2015,Lucas Liew 
//|                                  lucas@blackalgotechnologies.com 
//+------------------------------------------------------------------+
#include <01_GetHistoryOrder.mqh>
#include <02_OrderProfitToCSV.mqh>
#include <08_TerminalNumber.mqh>
#include <10_isNewBar.mqh>
#include <12_ReadDataFromDSS.mqh>
#include <16_LogMarketType.mqh>
#include <19_AssignMagicNumber.mqh>
#include <DSS_Functions.mqh>

#property copyright "Copyright 2015, Black Algo Technologies Pte Ltd"
#property copyright "Copyright 2020, Vladimir Zhbanko"
#property link      "lucas@blackalgotechnologies.com"
#property link      "https://vladdsm.github.io/myblog_attempt/"
#property version   "2.001"  
#property strict
/* 
DSS_Bot: 
# v 1.010
Parameters to add breakeven 10 pips for T3 account
Fix time to close order to account for the weekends
# v 1.011
Unify function to read rl policy into ReadDatafromDSS Include file
Fix code to close positions after pre-defined number of bars
Add fail safe to operations with an arrays
# v 1.012
Fixed limit to stop opening new positions when free margin is < 500% on T3
Change default number of trades for T1
# v 2.001
General update and recheck 20220415
rework init
*/

//+------------------------------------------------------------------+
//| Setup                                               
//+------------------------------------------------------------------+
extern string  Header1="----------EA General Settings-----------";
extern string  StrategyNumber                   = "39";
extern int     TerminalType                     = 1;         //0 mean slave, 1 mean master
extern bool    R_Management                     = true;      //R_Management true will enable Decision Support Centre (using R)
extern int     Slippage                         = 3; // In Pips
extern bool    IsECNbroker                      = false; //Is your broker an ECN
extern bool    OnJournaling                     = True; // Add EA updates in the Journal Tab
extern bool    EnableDashboard                  = True; // Turn on Dashboard

extern string  Header2="----------Trading Rules Variables -----------";
extern int     lower_PredictorM                 = 15;  // predictor period lower timeframe in minutes
extern int     higher_PredictorM                = 15;   //predictor period higher timeframe in minutes
extern int     period_Bars_CloseOrder           = 60;   //period in minutes to count order close bars
extern bool    closeAllOnFridays                = False; //close all orders on Friday 1hr before market closure
extern bool    use_market_type                  = True; //use market type trading policy
extern bool    use_two_models                   = False; //use two models for predictions
extern bool    UseDSSInfoList                   = True; //option to track DSS info using a ticket number

extern string  Header3="----------Position Sizing Settings-----------";
extern string  Lot_explanation                  = "If IsSizingOn = true, Lots variable will be ignored";
extern double  Lots                             = 0.01;
extern bool    IsSizingOn                       = False;
extern double  Risk                             = 1; // Risk per trade (in percentage)
extern int     MaxPositionsAllowed              = 10;
extern double  MaxFreeMarginLimit               = 500; //Perc of Margin level above which it's still allowed to open trades

extern string  Header4="----------TP & SL Settings-----------";
extern bool    UseFixedStopLoss                 = True; // If this is false and IsSizingOn = True, sizing algo will not be able to calculate correct lot size. 
extern double  FixedStopLoss                    = 0; // Hard Stop in Pips. Will be overridden if vol-based SL is true 
extern bool    IsVolatilityStopOn               = True;
extern double  VolBasedSLMultiplier             = 6; // Stop Loss Amount in units of Volatility

extern bool    UseFixedTakeProfit               = True;
extern double  FixedTakeProfit                  = 0; // Hard Take Profit in Pips. Will be overridden if vol-based TP is true 
extern bool    IsVolatilityTakeProfitOn         = True;
extern double  VolBasedTPMultiplier             = 6; // Take Profit Amount in units of Volatility

extern string  Header5="----------Hidden TP & SL Settings-----------";

extern bool    UseHiddenStopLoss                = False;
extern double  FixedStopLoss_Hidden             = 0; // In Pips. Will be overridden if hidden vol-based SL is true 
extern bool    IsVolatilityStopLossOn_Hidden    = False;
extern double  VolBasedSLMultiplier_Hidden      = 0; // Stop Loss Amount in units of Volatility

extern bool    UseHiddenTakeProfit              = False;
extern double  FixedTakeProfit_Hidden           = 0; // In Pips. Will be overridden if hidden vol-based TP is true 
extern bool    IsVolatilityTakeProfitOn_Hidden  = False;
extern double  VolBasedTPMultiplier_Hidden      = 0; // Take Profit Amount in units of Volatility

extern string  Header6="----------Breakeven Stops Settings-----------";
extern bool    UseBreakevenStops                = False;
extern double  BreakevenBuffer                  = 0; // In pips

extern string  Header7="----------Hidden Breakeven Stops Settings-----------";
extern bool    UseHiddenBreakevenStops          = False;
extern double  BreakevenBuffer_Hidden           = 0; // In pips

extern string  Header8="----------Trailing Stops Settings-----------";
extern bool    UseTrailingStops                 = False;
extern double  TrailingStopDistance             = 0; // In pips
extern double  TrailingStopBuffer               = 0; // In pips

extern string  Header9="----------Hidden Trailing Stops Settings-----------";
extern bool    UseHiddenTrailingStops           = False;
extern double  TrailingStopDistance_Hidden      = 0; // In pips
extern double  TrailingStopBuffer_Hidden        = 0; // In pips

extern string  Header10="----------Volatility Trailing Stops Settings-----------";
extern bool    UseVolTrailingStops              = False;
extern double  VolTrailingDistMultiplier        = 0; // VolTrailingDistMultiplier In units of ATR
extern double  VolTrailingBuffMultiplier        = 0; // VolTrailingBuffMultiplier In units of ATR

extern string  Header11="----------Hidden Volatility Trailing Stops Settings-----------";
extern bool    UseHiddenVolTrailing             = False;
extern double  VolTrailingDistMultiplier_Hidden = 0; // In units of ATR
extern double  VolTrailingBuffMultiplier_Hidden = 0; // In units of ATR

extern string  Header12="----------Volatility Measurement Settings-----------";
extern int     atr_period                       = 14;

extern string  Header13="----------Set Max Loss Limit-----------";
extern bool    IsLossLimitActivated             = False;
extern double  LossLimitPercent                 = 50;

extern string  Header14="----------Set Max Volatility Limit-----------";
extern bool    IsVolLimitActivated              = False;
extern double  VolatilityMultiplier             = 3; // In units of ATR
extern int     ATRTimeframe                     = 60; // In minutes
extern int     ATRPeriod                        = 14;

string  InternalHeader1="----------Errors Handling Settings-----------";
int     RetryInterval=100; // Pause Time before next retry (in milliseconds)
int     MaxRetriesPerTick=10;

string  InternalHeader2="----------Service Variables-----------";

double Stop,Take;
double StopHidden,TakeHidden;
int YenPairAdjustFactor;
int    P;
double myATR;
double AccountMarginLvlPerc;

// TDL 3: Declaring Variables (and the extern variables above)
int CrossTriggered1, CrossTriggered2, CrossTriggered3;

int OrderNumber;
int HiddenSLList[][2]; // First dimension is for position ticket numbers, second is for the SL Levels
int HiddenTPList[][2]; // First dimension is for position ticket numbers, second is for the TP Levels
int HiddenBEList[];    // First dimension is for position ticket numbers
int HiddenTrailingList[][2]; // First dimension is for position ticket numbers, second is for the hidden trailing stop levels
int VolTrailingList[][2]; // First dimension is for position ticket numbers, second is for recording of volatility amount (one unit of ATR) at the time of trade
int HiddenVolTrailingList[][3]; // First dimension is for position ticket numbers, second is for the hidden trailing stop levels, third is for recording of volatility amount (one unit of ATR) at the time of trade

// each order ticket should be tracking it's own info
int DSSInfoList[][3]; // First dimension is for position ticket numbers, second is for the Hold time list, third is for the Market Type
                      // Array will be used in the following functions: 
                      // UpdateDSSInfoList - function to update status of array to clean elements if needed
                      // SetDSSInfoList - record needed data at the moment of order opening

string  InternalHeader3="----------Decision Support Variables-----------";
int MagicNumber, myTerminal;
bool     TradeAllowed = true; 
bool     isMarketTypePolicyON = true;
bool FlagBuy, FlagSell;       //boolean flags to limit direction of trades
datetime ReferenceTime;       //used for order history
int     MyMarketType;         //used to recieve market status from AI
//used to recieve prediction from AI 
int TimeMaxHold; 
//LP - Lower Timeframe Predictor; HP - Higher Timeframe Predictor      
double    AIChangeLP, AIChangeHP, 
          AItriggerLP, AItriggerHP,
          AItimeholdLP, AItimeholdHP,
          AImaxperfLP, AImaxperfHP,
          AIminperfLP, AIminperfHP,
          MyMarketTypeConf;
bool isFridayActive = false;

//+------------------------------------------------------------------+
//| End of Setup                                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert Initialization                                    
//+------------------------------------------------------------------+
int init()
  {
   //Automatically Assign magic number
   myTerminal = T_Num();
   MagicNumber = AssignMagicNumber(Symbol(), StrategyNumber, myTerminal);
   //Automatically derive terminal number and money management settings
   if(myTerminal == 1)
     {
      OnJournaling                     = False; // Add EA updates in the Journal Tab
      IsSizingOn                       = False;
      Lots                             = 0.01; // Min Risk per trade
      MaxPositionsAllowed              = 50;
      TerminalType                     = 1;
      VolBasedTPMultiplier             = 10;
      VolBasedSLMultiplier             = 7; // Stop Loss Amount in units of Volatility
      UseBreakevenStops                = False;
      BreakevenBuffer                  = 20; // In pips
     }
      if(myTerminal == 2) //settings for the test terminal
     {
      IsSizingOn                       = False;
      Risk                             = 1; // Risk per trade (in percentage)
      MaxPositionsAllowed              = 50;
      TerminalType                     = 1;
      VolBasedTPMultiplier             = 10;
      VolBasedSLMultiplier             = 7; // Stop Loss Amount in units of Volatility
      UseBreakevenStops                = False;
      BreakevenBuffer                  = 20; // In pips (distance to start activating breakeven stop
      UseTrailingStops                 = False;
      TrailingStopDistance             = 20; // In pips (distance to be maintained from price to stop loss)
      TrailingStopBuffer               = 20; // In pips (buffer to add to distance to start activating the trailing stop)
     }  
   if(myTerminal == 3)
     {
      OnJournaling                     = False; // Add EA updates in the Journal Tab
      IsSizingOn                       = True;
      Risk                             = 2; // Risk per trade (in percentage)
      MaxPositionsAllowed              = 1;
      TerminalType                     = 0;
      VolBasedTPMultiplier             = 10;
      VolBasedSLMultiplier             = 7; // Stop Loss Amount in units of Volatility
      UseBreakevenStops                = False;
      BreakevenBuffer                  = 30; // In pips
      UseTrailingStops                 = False;
      TrailingStopDistance             = 20; // In pips
      TrailingStopBuffer               = 20; // In pips
      
     }
   
//------------- Decision Support Centre
// Robot must check the sandbox for the file SystemControlxxx.csv
// If it's does not exist then the robot is writing the file for the first time
//    
   //1. Check if file exists or not
   string fileName = "SystemControl"+string(MagicNumber)+".csv";//create the name of the file same for all symbols...
      // try to open the file   
      int handle=FileOpen(fileName,FILE_READ|FILE_CSV,"@"); FileClose(handle);
      if(handle==-1)
         {Comment("Init Status: File SystemControlxx does not exist yet, writing this file first time...");
          Sleep(2000);
          //FileClose(handle);
          //write the file for the first time
          int handle1 = FileOpen(fileName,FILE_CSV|FILE_READ|FILE_WRITE); FileSeek(handle1,0,SEEK_END);
               string data = string(MagicNumber)+","+string(TerminalType);
               FileWrite(handle1,data);  FileClose(handle1);
               //end of writing to file
               Comment("Init Status: File SystemControlxx is written, trade is '1'/not '0' allowed", string(TerminalType));
               Sleep(2000);}
       else
         {
            //read content of the file
            TradeAllowed = BoolReadDataFromDSS(MagicNumber, 0, "read_command");  
            Comment("Init Status: File SystemControlxx exists, checking status of this file...");
            Sleep(1200);
            //2. Check status of the file
            if(TradeAllowed == true && TerminalType == 0)
              {
                //settings changed, update this file
                int handle1 = FileOpen(fileName,FILE_CSV|FILE_READ|FILE_WRITE); FileSeek(handle1,0,SEEK_END);
                     string data = string(MagicNumber)+","+string(TerminalType);
                     FileWrite(handle1,data);  FileClose(handle1);
                     //end of writing to file
                     Comment("Init Status: File SystemControlxx is updated, trade is '1'/not '0' allowed", string(TerminalType));
                     Sleep(2000);
              }
            else if(TradeAllowed == false && TerminalType == 0)
              {
               Comment("Init Status: Trade is not allowed");
               Sleep(1500);
              }
            else if(TradeAllowed == true && TerminalType == 1)
              {
               Comment("Init Status: Trade is allowed");
               Sleep(1500);
              }     
         }
         
    
//---------                         
//---------             
   ReferenceTime = TimeCurrent(); // record time for order history function         
//---------             
   
   P=GetP(); // To account for 5 digit brokers. Used to convert pips to decimal place
   YenPairAdjustFactor=GetYenAdjustFactor(); // Adjust for YenPair

//----------(Hidden) TP, SL and Breakeven Stops Variables-----------  

// If EA disconnects abruptly and there are open positions from this EA, records form these arrays will be gone.
   if(UseHiddenStopLoss) ArrayResize(HiddenSLList,MaxPositionsAllowed,0);
   if(UseHiddenTakeProfit) ArrayResize(HiddenTPList,MaxPositionsAllowed,0);
   if(UseHiddenBreakevenStops) ArrayResize(HiddenBEList,MaxPositionsAllowed,0);
   if(UseHiddenTrailingStops) ArrayResize(HiddenTrailingList,MaxPositionsAllowed,0);
   if(UseVolTrailingStops) ArrayResize(VolTrailingList,MaxPositionsAllowed,0);
   if(UseHiddenVolTrailing) ArrayResize(HiddenVolTrailingList,MaxPositionsAllowed,0);
   if(UseDSSInfoList) ArrayResize(DSSInfoList,MaxPositionsAllowed,0);
   
// Restore records of Array DSSInfoList using the flat file
   if(UseDSSInfoList) RestoreDSSInfoList(OnJournaling, Symbol(), MagicNumber, DSSInfoList);
   

   start();
   return(0);
  }
//+------------------------------------------------------------------+
//| End of Expert Initialization                            
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert Deinitialization                                  
//+------------------------------------------------------------------+
int deinit()
  {
//----

//----
   return(0);
  }
//+------------------------------------------------------------------+
//| End of Expert Deinitialization                          
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert start                                             
//+------------------------------------------------------------------+
int start()
  {
 
   OrderProfitToCSV(myTerminal);                      //write previous orders profit results for auto analysis in R
//----------Order management through R - run this code only once per bar...
   if(R_Management && isNewBar())
     {
         
         //code that only executed once a bar
         
         MyMarketType = (int)ReadDataFromDSS(Symbol(), 60, "read_mt");            //read analytical output from the Decision Support System
         MyMarketTypeConf = ReadDataFromDSS(Symbol(), 60, "read_mt_conf");
         //get the Reinforcement Learning policy for specific Market Type
         if(TerminalType == 0 && use_market_type == true)
           {
            isMarketTypePolicyON = BoolReadDataFromDSS(MagicNumber, MyMarketType, "read_rlpolicy");
           } else
               {
                isMarketTypePolicyON = true;
               }
         
         /* Variables
         //LP - Lower Timeframe Predictor; HP - Higher Timeframe Predictor      
          AIChangeLP, AIChangeHP, 
          AItriggerLP, AItriggerHP,
          AItimeholdLP, AItimeholdHP,
          AImaxperfLP, AImaxperfHP,
          AIminperfLP, AIminperfHP,
          */
         if(use_two_models)
           {
               //predicted price change on Lower Timeframe
            AIChangeLP = ReadDataFromDSS(Symbol(),lower_PredictorM, "read_change");
            AIChangeHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_change");
            //derived trigger level
            AItriggerLP = ReadDataFromDSS(Symbol(),lower_PredictorM, "read_trigger");
            AItriggerHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_trigger");
            
            //derived time to hold the order
            AItimeholdLP = ReadDataFromDSS(Symbol(),lower_PredictorM, "read_timehold");
            AItimeholdHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_timehold");
            //derived model performance
            AImaxperfLP = ReadDataFromDSS(Symbol(),lower_PredictorM, "read_maxperf");  
            AImaxperfHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_maxperf");  
            //derived minimum value of model performance 'min_quantile'
            AIminperfLP = ReadDataFromDSS(Symbol(),lower_PredictorM, "read_quantile"); 
            AIminperfHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_quantile"); 
            
            TimeMaxHold = int(AItimeholdLP * period_Bars_CloseOrder); //time to max hold the order in minutes
            
          } 
         if(!use_two_models)
           {
               //predicted price change on Lower Timeframe
            AIChangeLP = 0;
            AIChangeHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_change");
            //derived trigger level
            AItriggerLP = 0;
            AItriggerHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_trigger");
            
            //derived time to hold the order
            AItimeholdLP = 0;
            AItimeholdHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_timehold");
            //derived model performance
            AImaxperfLP = 0;  
            AImaxperfHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_maxperf");  
            //derived minimum value of model performance 'min_quantile'
            AIminperfLP = 0; 
            AIminperfHP = ReadDataFromDSS(Symbol(),higher_PredictorM, "read_quantile"); 
            
            TimeMaxHold = int(AItimeholdHP * period_Bars_CloseOrder); //time to max hold the order in minutes

          }  
         //check trading conditions
      
         FlagBuy   = GetTradeFlagConditionDSS_Bot(AIChangeLP, //predicted change from DSS
                                           AIChangeHP,
                                           AItriggerLP,
                                           AItriggerHP, //absolute value to enter trade
                                           AImaxperfLP,
                                           AImaxperfHP,
                                           AIminperfLP,
                                           AIminperfHP,
                                           MyMarketType,
                                           MyMarketTypeConf,
                                           "buy",
                                           use_two_models); //which direction to check "buy" "sell"
             
         FlagSell = GetTradeFlagConditionDSS_Bot(AIChangeLP, //predicted change from DSS
                                          AIChangeHP,
                                          AItriggerLP,
                                          AItriggerHP, //absolute value to enter trade
                                          AImaxperfLP,
                                          AImaxperfHP,
                                          AIminperfLP,
                                          AIminperfHP,
                                          MyMarketType,
                                          MyMarketTypeConf,
                                          "sell",
                                          use_two_models); //which direction to check "buy" "sell"

         
         //TradeAllowed is checking Macroeconomic events (derived from Decision Support System)          
         TradeAllowed = BoolReadDataFromDSS(MagicNumber, 0, "read_command");    //read command from R to make sure trading is allowed

       
     }
     

//----------Variables to be Refreshed-----------

   OrderNumber=0; // OrderNumber used in Entry Rules
   AccountMarginLvlPerc = 100*AccountEquity()/(AccountMargin()+0.00001);
   if(AccountMarginLvlPerc < MaxFreeMarginLimit) TradeAllowed = false;
   
   CrossTriggered1=0;
   
        //----------Entry & Exit Variables-----------
   //Entry variables, we want to open order only at the beginning of every new bar:
   if(IsNewCandle())
     {
      //Alert("I am in at new bar!");
      if(FlagBuy) CrossTriggered1=1;
      if(FlagSell) CrossTriggered1=2;
     }
     
   //Exit variables:
   if(closeAllOnFridays)
     {
      //check if it's Friday and 1 hr before market closure
      if(Hour()== 23 && DayOfWeek()== 5)
        {
         isFridayActive = true;
        } else
            {
             isFridayActive = false;
            }
        
     }
    /* Using timer to close trades
    
    //1. Predicted to Buy --> wait until the time to keep the order is elapsed
   
    //2. Predicted to Sell --> wait until the time to keep the order is elapsed

    */  

//----------TP, SL, Breakeven and Trailing Stops Variables-----------

   myATR=iATR(NULL,PERIOD_H1,atr_period,1);

   if(UseFixedStopLoss==False) 
     {
      Stop=0;
        }  else {
      Stop=VolBasedStopLoss(IsVolatilityStopOn,FixedStopLoss,myATR,VolBasedSLMultiplier,P);
     }

   if(UseFixedTakeProfit==False) 
     {
      Take=0;
        
        }  else {
      Take=VolBasedTakeProfit(IsVolatilityTakeProfitOn,FixedTakeProfit,myATR,VolBasedTPMultiplier,P);
     }


   if(UseBreakevenStops) BreakevenStopAll(OnJournaling,RetryInterval,BreakevenBuffer,MagicNumber,P);
   if(UseTrailingStops) TrailingStopAll(OnJournaling,TrailingStopDistance,TrailingStopBuffer,RetryInterval,MagicNumber,P);
   if(UseVolTrailingStops) {
      UpdateVolTrailingList(OnJournaling,RetryInterval,MagicNumber,VolTrailingList);
      ReviewVolTrailingStop(OnJournaling,VolTrailingDistMultiplier,VolTrailingBuffMultiplier,RetryInterval,MagicNumber,P,VolTrailingList);
   }
//----------(Hidden) TP, SL, Breakeven and Trailing Stops Variables-----------  

   if(UseHiddenStopLoss) TriggerStopLossHidden(OnJournaling,RetryInterval,MagicNumber,Slippage,P,HiddenSLList);
   if(UseHiddenTakeProfit) TriggerTakeProfitHidden(OnJournaling,RetryInterval,MagicNumber,Slippage,P,HiddenTPList);
   if(UseHiddenBreakevenStops) { 
      UpdateHiddenBEList(OnJournaling,RetryInterval,MagicNumber,HiddenBEList);
      SetAndTriggerBEHidden(OnJournaling,BreakevenBuffer,MagicNumber,Slippage,P,RetryInterval,HiddenBEList);
   }
   if(UseHiddenTrailingStops) {
      UpdateHiddenTrailingList(OnJournaling,RetryInterval,MagicNumber,HiddenTrailingList);
      SetAndTriggerHiddenTrailing(OnJournaling,TrailingStopDistance_Hidden,TrailingStopBuffer_Hidden,Slippage,RetryInterval,MagicNumber,P,HiddenTrailingList);
   }
   if(UseHiddenVolTrailing) {
      UpdateHiddenVolTrailingList(OnJournaling,RetryInterval,MagicNumber,HiddenVolTrailingList);
      TriggerAndReviewHiddenVolTrailing(OnJournaling,VolTrailingDistMultiplier_Hidden,VolTrailingBuffMultiplier_Hidden,Slippage,RetryInterval,MagicNumber,P,HiddenVolTrailingList);
   }
          //----------DSS Info Array management -----------
   if(UseDSSInfoList)UpdateDSSInfoList(OnJournaling,RetryInterval,MagicNumber,DSSInfoList);


//----------Exit Rules (All Opened Positions)-----------

   // TDL 2: Setting up Exit rules. Modify the ExitSignal() function to suit your needs.
   //Alert("Ticket "+(string)DSSInfoList[0][0]+"Time hold "+(string)DSSInfoList[0][1]);

   if(UseDSSInfoList)
     {
                                     
   if(CountPosOrders(MagicNumber,OP_BUY)>=1 && (ExitSignalOnTimerTicketBars(2, MagicNumber, period_Bars_CloseOrder, DSSInfoList)==2 || isFridayActive == true))
     { // Close Long Positions
      CloseOrderPositionTimerBars(OP_BUY, OnJournaling, MagicNumber, period_Bars_CloseOrder, DSSInfoList, Slippage, P, RetryInterval); 
      UpdateDSSInfoList(OnJournaling,RetryInterval,MagicNumber,DSSInfoList);
     }                                          //We need to change this function to use Tickets in arrays
   if(CountPosOrders(MagicNumber,OP_SELL)>=1 && (ExitSignalOnTimerTicketBars(1, MagicNumber, period_Bars_CloseOrder, DSSInfoList)==1 || isFridayActive == true))
     { // Close Short Positions
      CloseOrderPositionTimerBars(OP_SELL, OnJournaling, MagicNumber, period_Bars_CloseOrder, DSSInfoList, Slippage, P, RetryInterval);
      UpdateDSSInfoList(OnJournaling,RetryInterval,MagicNumber,DSSInfoList);
     }

     } else
         {
             if(CountPosOrders(MagicNumber,OP_BUY)>=1 && (ExitSignalOnTimerMagic(2, MagicNumber, TimeMaxHold)==2 || isFridayActive == true))
              { // Close Long Positions
               CloseOrderPosition(OP_BUY, OnJournaling, MagicNumber, Slippage, P, RetryInterval); 
              }                                          //We need to change this function to use Tickets in arrays
             if(CountPosOrders(MagicNumber,OP_SELL)>=1 && (ExitSignalOnTimerMagic(1, MagicNumber, TimeMaxHold)==1 || isFridayActive == true))
              { // Close Short Positions
               CloseOrderPosition(OP_SELL, OnJournaling, MagicNumber, Slippage, P, RetryInterval);
              }
         }              
//----------Entry Rules (Market and Pending) -----------

   if(IsLossLimitBreached(IsLossLimitActivated,LossLimitPercent,OnJournaling,EntrySignal(CrossTriggered1))==False) 
      if(IsVolLimitBreached(IsVolLimitActivated,VolatilityMultiplier,ATRTimeframe,ATRPeriod)==False)
         if(IsMaxPositionsReached(MaxPositionsAllowed,MagicNumber,OnJournaling)==False)
           {
            if(!isFridayActive && TradeAllowed && isMarketTypePolicyON && FlagBuy && EntrySignal(CrossTriggered1)==1)
              { // Open Long Positions
               OrderNumber=OpenPositionMarket(OP_BUY,GetLot(IsSizingOn,Lots,Risk,YenPairAdjustFactor,Stop,P),Stop,Take,MagicNumber,Slippage,OnJournaling,P,IsECNbroker,MaxRetriesPerTick,RetryInterval);
   
               // Log current MarketType to the file in the sandbox
               LogMarketTypeInfo(MagicNumber, OrderNumber, MyMarketType, TimeMaxHold);
               
               // Log current Market Type and Time to Hold order in the arrays
               if(UseDSSInfoList) SetDSSInfoList(OnJournaling,TimeMaxHold,MyMarketType, OrderNumber, MagicNumber, DSSInfoList);
   
               // Set Stop Loss value for Hidden SL
               if(UseHiddenStopLoss) SetStopLossHidden(OnJournaling,IsVolatilityStopLossOn_Hidden,FixedStopLoss_Hidden,myATR,VolBasedSLMultiplier_Hidden,P,OrderNumber,HiddenSLList);
   
               // Set Take Profit value for Hidden TP
               if(UseHiddenTakeProfit) SetTakeProfitHidden(OnJournaling,IsVolatilityTakeProfitOn_Hidden,FixedTakeProfit_Hidden,myATR,VolBasedTPMultiplier_Hidden,P,OrderNumber,HiddenTPList);
               
               // Set Volatility Trailing Stop Level           
               if(UseVolTrailingStops) SetVolTrailingStop(OnJournaling,RetryInterval,myATR,VolTrailingDistMultiplier,MagicNumber,P,OrderNumber,VolTrailingList);
               
               // Set Hidden Volatility Trailing Stop Level 
               if(UseHiddenVolTrailing) SetHiddenVolTrailing(OnJournaling,myATR,VolTrailingDistMultiplier_Hidden,MagicNumber,P,OrderNumber,HiddenVolTrailingList);
             
              }
   
            if(!isFridayActive && TradeAllowed && isMarketTypePolicyON && FlagSell && EntrySignal(CrossTriggered1)==2)
              { // Open Short Positions
               OrderNumber=OpenPositionMarket(OP_SELL,GetLot(IsSizingOn,Lots,Risk,YenPairAdjustFactor,Stop,P),Stop,Take,MagicNumber,Slippage,OnJournaling,P,IsECNbroker,MaxRetriesPerTick,RetryInterval);
   
               // Log current MarketType to the file in the sandbox
               LogMarketTypeInfo(MagicNumber, OrderNumber, MyMarketType, TimeMaxHold);
               
               // Log current Market Type and Time to Hold order in the arrays
               if(UseDSSInfoList) SetDSSInfoList(OnJournaling,TimeMaxHold,MyMarketType, OrderNumber, MagicNumber, DSSInfoList);
   
               // Set Stop Loss value for Hidden SL
               if(UseHiddenStopLoss) SetStopLossHidden(OnJournaling,IsVolatilityStopLossOn_Hidden,FixedStopLoss_Hidden,myATR,VolBasedSLMultiplier_Hidden,P,OrderNumber,HiddenSLList);
   
               // Set Take Profit value for Hidden TP
               if(UseHiddenTakeProfit) SetTakeProfitHidden(OnJournaling,IsVolatilityTakeProfitOn_Hidden,FixedTakeProfit_Hidden,myATR,VolBasedTPMultiplier_Hidden,P,OrderNumber,HiddenTPList);
               
               // Set Volatility Trailing Stop Level 
               if(UseVolTrailingStops) SetVolTrailingStop(OnJournaling,RetryInterval,myATR,VolTrailingDistMultiplier,MagicNumber,P,OrderNumber,VolTrailingList);
                
               // Set Hidden Volatility Trailing Stop Level  
               if(UseHiddenVolTrailing) SetHiddenVolTrailing(OnJournaling,myATR,VolTrailingDistMultiplier_Hidden,MagicNumber,P,OrderNumber,HiddenVolTrailingList);
             
              }
           }

//----------Pending Order Management-----------
/*
        Not Applicable (See Desiree for example of pending order rules).
   */

//----
    //adding dashboard
    if(EnableDashboard==True) ShowDashboardDSS_Bot("Magic Number ", MagicNumber,
                                            "Market Type ", MyMarketType,
                                            "MyMarketTypeConf ", MyMarketTypeConf,
                                            "AI PriceChange Lower Period", AIChangeLP,
                                            "AItrigger L Period", AItriggerLP,
                                            "AI PriceChange Higher Period", AIChangeHP,
                                            "AItrigger H Period", AItriggerHP,
                                            "AItimehold L Period Bars", AItimeholdHP,
                                            "AI Act Maxperf LP", AImaxperfLP,
                                            "AI Perf Trigger LP", AIminperfLP,
                                            "AI Act Maxperf HP", AImaxperfHP,
                                            "AI Perf Trigger HP", AIminperfHP); 

   return(0);
  }
//+------------------------------------------------------------------+
//| End of expert start function                                     |
//+------------------------------------------------------------------+