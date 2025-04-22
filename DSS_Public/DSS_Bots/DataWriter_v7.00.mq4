//+------------------------------------------------------------------+
//|                                                   DataWriter.mq4 |
//|                                 Copyright 2021, Vladimir Zhbanko |
//+------------------------------------------------------------------+
#include <12_ReadDataFromDSS.mqh>


#property copyright "Copyright 2021, Vladimir Zhbanko"
#property link      "https://vladdsm.github.io/myblog_attempt/"
#property version   "7.01"
#property strict
#define EANAME "DataWriter_v7.01"

/*
PURPOSE: Retrieve price and Indicator data for an asset 
USE: Data will be used for Decision Support System in R

VERSION: Option to collect pattern data into separate folders

HOW TO USE:

https://www.udemy.com/course/your-home-trading-environment/?referralCode=9EAD4CC112A476678658
https://www.udemy.com/course/your-trading-robot/?referralCode=529DCD0085D40BEC410C

*/


extern string           Header1 = "-----EA Main Settings-------";

extern int              UseBarsCollect        = 2400;    
extern ENUM_TIMEFRAMES  chartPeriod           = 60;   // Choose the timeframe to retrive the data
extern bool             UseBest_Input         = True; //Choose True to enable writing best input to the sandbox
extern bool             Use6_01               = False;
extern bool             Use6_02               = False;
extern bool             Use6_03               = False;
extern bool             Use6_04               = False;
extern bool             Use6_05               = False;
extern bool             Use6_06               = False;
extern bool             Use6_07               = False;
extern bool             Use6_08               = False;
extern bool             Use6_09               = False;
extern bool             Use6_10               = False;
extern bool             Use6_11               = False;

extern bool             ShowScreenComments    = True;

enum ENUM_PAIR_SELECTION
  {
   Manual=0,   // Own Pair list
   Core7=1,    // Core 7
   Core14=2,   // Core 14
   Core28=3,   // All 28 pairs
   AUDPairs=6, // AUD pairs
   CADPairs=8, // CAD pairs
   EURPairs=5, // EUR pairs
   GBPPairs=7, // GBP pairs
   JPYPairs=4, // JPY pairs
   NZDPairs=9, // NZD pairs
   NoAUDPairs=10, // No AUD pairs
   NoCADPairs=11, // No CAD pairs
   NoEURPairs=12, // No EUR pairs
   NoGBPPairs=13, // No GBP pairs
   NoJPYPairs=14, // No JPY pairs
   NoNZDPairs=15, // No NZD pairs 
   ActiveChart=100 // Active Chart
  };
extern ENUM_PAIR_SELECTION   PairsTrading                = Core28; // Pair Selection ------------------------
extern string                OwnPairs                   = "";

string FileNamePrx1 = "AI_CP";
string FileNamePrx2 = "AI_OP";
string FileNamePrx3 = "AI_LP";
string FileNamePrx4 = "AI_HP";
string FileNameRsi1 = "AI_RSI";
string FileNameBull = "AI_BullPow";
string FileNameBear = "AI_BearPow";
string FileNameAtr1 = "AI_Atr8";
string FileNameMacd = "AI_Macd";
string FileNameStoch = "AI_Stoch";

string FileNameMix = "AI_RSIADX";
string FileTick = StringConcatenate("TickSize_",FileNameMix,".csv");

string commentText;

//Heiken Ashi variables
color color1 = Red;
color color2 = White;
color color3 = Red;
color color4 = White;
#define HAHIGH      0
#define HALOW       1
#define HAOPEN      2
#define HACLOSE     3 

//+------------------------------------------------------------------+
//Internal variables declaration
//+------------------------------------------------------------------+
string Core7Pairs[] =  {"AUDUSD","EURUSD","GBPUSD","NZDUSD","USDCAD","USDCHF","USDJPY"};
string Core14Pairs[] = {"AUDJPY","AUDUSD","CHFJPY","EURCHF","EURGBP","EURJPY","EURUSD","GBPCHF","GBPJPY","GBPUSD","NZDJPY","NZDUSD","USDCHF","USDJPY"};
string Core28Pairs[] = {"AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADCHF","CADJPY","CHFJPY","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD","GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","NZDCAD","NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"};
string JPYPairs[] = {"AUDJPY","CADJPY","CHFJPY","EURJPY","GBPJPY","NZDJPY","USDJPY"};
string EURPairs[] = {"EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD"};
string AUDPairs[] = {"AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","EURAUD","GBPAUD"};
string GBPPairs[] = {"GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","EURGBP"};
string CADPairs[] = {"CADCHF","CADJPY","AUDCAD","EURCAD","GBPCAD","NZDCAD","USDCAD"};
string NZDPairs[] = {"NZDCAD","NZDCHF","NZDJPY","NZDUSD","AUDNZD","EURNZD","GBPNZD"};
string NoJPYPairs[] = {"AUDCAD","AUDCHF","AUDNZD","AUDUSD","CADCHF","EURAUD","EURCAD","EURCHF","EURGBP","EURNZD","EURUSD","GBPAUD","GBPCAD","GBPCHF","GBPNZD","GBPUSD","NZDCAD","NZDCHF","NZDUSD","USDCAD","USDCHF"};
string NoEURPairs[] = {"AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADCHF","CADJPY","CHFJPY","GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","NZDCAD","NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"};
string NoAUDPairs[] = {"CADCHF","CADJPY","CHFJPY","EURCAD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD","GBPCAD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","NZDCAD","NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"};
string NoGBPPairs[] = {"AUDCAD","AUDCHF","AUDJPY","AUDNZD","AUDUSD","CADCHF","CADJPY","CHFJPY","EURAUD","EURCAD","EURCHF","EURJPY","EURNZD","EURUSD","NZDCAD","NZDCHF","NZDJPY","NZDUSD","USDCAD","USDCHF","USDJPY"};
string NoCADPairs[] = {"AUDCHF","AUDJPY","AUDNZD","AUDUSD","CHFJPY","EURAUD","EURCHF","EURGBP","EURJPY","EURNZD","EURUSD","GBPAUD","GBPCHF","GBPJPY","GBPNZD","GBPUSD","NZDCHF","NZDJPY","NZDUSD","USDCHF","USDJPY"};
string NoNZDPairs[] = {"AUDCAD","AUDCHF","AUDJPY","AUDUSD","CADCHF","CADJPY","CHFJPY","EURAUD","EURCAD","EURCHF","EURGBP","EURJPY","EURUSD","GBPAUD","GBPCAD","GBPCHF","GBPJPY","GBPUSD","USDCAD","USDCHF","USDJPY"};
string ActiveChart[] = {NULL};

string pairs[];

string dss_input = "0_00x";

/*
Content:

1. Function writeDataCP          collect Close Price data   
2. Function writeDataOP          collect Open Price data
3. Function writeDataLP          collect Low Price data
4. Function writeDataHP          collect High Price data
5. Function writeDataRSI         collect Rsi data
6. Function writeDataBullPow     collect BullPower data
7. Function writeDataBearPow     collect BearPower data
8. Function writeDataAtr         collect Atr data
9. Function writeDataMacd        collect MACD data 
10.Function writeDataStoch       collect Stoch data 
*/
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
      
   if(PairsTrading == 0)StringSplit(OwnPairs,',',pairs);
   if(PairsTrading == 1)ArrayCopy(pairs,Core7Pairs);
   if(PairsTrading == 2)ArrayCopy(pairs,Core14Pairs);
   if(PairsTrading == 3)ArrayCopy(pairs,Core28Pairs);
   if(PairsTrading == 4)ArrayCopy(pairs,JPYPairs);
   if(PairsTrading == 5)ArrayCopy(pairs,EURPairs);
   if(PairsTrading == 6)ArrayCopy(pairs,AUDPairs);
   if(PairsTrading == 7)ArrayCopy(pairs,GBPPairs);
   if(PairsTrading == 8)ArrayCopy(pairs,CADPairs);
   if(PairsTrading == 9)ArrayCopy(pairs,NZDPairs);
   if(PairsTrading == 10)ArrayCopy(pairs,NoJPYPairs);
   if(PairsTrading == 11)ArrayCopy(pairs,NoEURPairs);
   if(PairsTrading == 12)ArrayCopy(pairs,NoAUDPairs);
   if(PairsTrading == 13)ArrayCopy(pairs,NoGBPPairs);
   if(PairsTrading == 14)ArrayCopy(pairs,NoCADPairs);
   if(PairsTrading == 15)ArrayCopy(pairs,NoNZDPairs);
   if(PairsTrading == 100)ArrayCopy(pairs,ActiveChart);
 
   if(ArraySize(pairs) <= 0){Print("No pairs to trade");return(INIT_FAILED);}
   
   if(UseBest_Input)dss_input = StringReadDataFromDSS("read_dss_input");
   
   if(Use6_01)FolderCreate("6_01");
   if(Use6_02)FolderCreate("6_02");
   if(Use6_03)FolderCreate("6_03");
   if(Use6_04)FolderCreate("6_04");
   if(Use6_05)FolderCreate("6_05");
   if(Use6_06)FolderCreate("6_06");
   if(Use6_07)FolderCreate("6_07");
   if(Use6_08)FolderCreate("6_08");
   if(Use6_09)FolderCreate("6_09");
   if(Use6_10)FolderCreate("6_10");
   if(Use6_11)FolderCreate("6_11");
      
     collectTickSize (FileTick);  
     
     if (IsTesting()== false) 
               {
              
               for(int c = 0; c < ArraySize(pairs); c++)
                     {if(UseBest_Input) collectAndWrite(pairs[c],dss_input,FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, True);
                      if(Use6_01) collectAndWrite(pairs[c],"6_01",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_02) collectAndWrite(pairs[c],"6_02",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_03) collectAndWrite(pairs[c],"6_03",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_04) collectAndWrite(pairs[c],"6_04",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_05) collectAndWrite(pairs[c],"6_05",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_06) collectAndWrite(pairs[c],"6_06",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_07) collectAndWrite(pairs[c],"6_07",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_08) collectAndWrite(pairs[c],"6_08",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_09) collectAndWrite(pairs[c],"6_09",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_10) collectAndWrite(pairs[c],"6_10",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_11) collectAndWrite(pairs[c],"6_11",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                     if (ShowScreenComments) Comment(commentText); }
               }
     
     
            //show dashboard
      
      if (ShowScreenComments) Comment("\n Initial files should be written, they will be updated on every new bar ...");
      
      return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   // should generate unique time every minute https://www.mql5.com/en/forum/133366

   
      static datetime Time0;
   if(Time0 == Time[0])
     {
      
     }
     else
       {
           //code that only executed in the beginning and once every bar
           //  record time to variable
            Time0 = Time[0];
            
            //comment
            commentText = StringConcatenate("\n",EANAME); 
            
            if (IsTesting()== true)
               {
               collectAndWrite(Symbol(), "6_01", FileNameMix+Symbol()+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, True);
               }
               
            if (IsTesting()== false) 
               {
               
               if(UseBest_Input)dss_input = StringReadDataFromDSS("read_dss_input");
               
               for(int c = 0; c < ArraySize(pairs); c++)
                     {if(UseBest_Input) collectAndWrite(pairs[c],dss_input,FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, True);
                      if(Use6_01) collectAndWrite(pairs[c],"6_01",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_02) collectAndWrite(pairs[c],"6_02",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_03) collectAndWrite(pairs[c],"6_03",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_04) collectAndWrite(pairs[c],"6_04",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_05) collectAndWrite(pairs[c],"6_05",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_06) collectAndWrite(pairs[c],"6_06",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_07) collectAndWrite(pairs[c],"6_07",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_08) collectAndWrite(pairs[c],"6_08",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_09) collectAndWrite(pairs[c],"6_09",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_10) collectAndWrite(pairs[c],"6_10",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(Use6_11) collectAndWrite(pairs[c],"6_11",FileNameMix+pairs[c]+IntegerToString(chartPeriod)+".csv", chartPeriod, UseBarsCollect, False);
                      if(ShowScreenComments) Comment(commentText); }
               }
            

      
      if(ShowScreenComments) Comment(commentText);

         
      }
      
      
  }
//+------------------------------------------------------------------+

double bar_type(string sym, int peri, int shiftbar)
{
                     //bars characterization
                     double iHg = iHigh(sym, peri,shiftbar);
                     double iLw = iLow(sym, peri,shiftbar);
                     double iOp = iOpen(sym, peri,shiftbar);
                     double iCs = iClose(sym, peri,shiftbar);
                     //bar type +10 bull; -10 bear
                     double bartype = 0;
                     if(iOp < iCs) bartype = 100;
                     if(iOp > iCs) bartype = 0;
                     if(iOp == iCs)bartype = 50;
                       
                     return(bartype);
}


double bar_type_heiken(string sym, int peri, int shiftbar)
{
                  

                     //bars characterization
                     double iHg = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HAHIGH,shiftbar);
                     double iLw = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HALOW,shiftbar);
                     double iOp = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HAOPEN,shiftbar);
                     double iCs = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HACLOSE,shiftbar);
                     //bar type +10 bull; -10 bear
                     double bartype = 0;
                     if(iOp < iCs) bartype = 100;
                     if(iOp > iCs) bartype = 0;
                     if(iOp == iCs)bartype = 50;
                      
                       
                     return(bartype);
}



double high_whisk(string sym, int peri, int shiftbar)
{
                     //bars characterization
                     double iHg = iHigh(sym, peri,shiftbar);
                     double iLw = iLow(sym, peri,shiftbar);
                     double iOp = iOpen(sym, peri,shiftbar);
                     double iCs = iClose(sym, peri,shiftbar);
                     //% of the higher whisker
                     double hWisk = 0;
                     // bullish
                     if(iOp < iCs) hWisk = 100*((iHg-iCs)/(iHg-iLw));
                     // bearish
                     if(iOp > iCs) hWisk = 100*((iHg-iOp)/(iHg-iLw));;
                     return(hWisk);
}

double high_whisk_heiken(string sym, int peri, int shiftbar)
{
                     //bars characterization
                     double iHg = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HAHIGH,shiftbar );
                     double iLw = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HALOW,shiftbar );
                     double iOp = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HAOPEN,shiftbar );
                     double iCs = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HACLOSE,shiftbar );
                     //% of the higher whisker
                     double hWisk = 0;
                     // bullish
                     if(iOp < iCs) hWisk = 100*((iHg-iCs)/(iHg-iLw));
                     // bearish
                     if(iOp > iCs) hWisk = 100*((iHg-iOp)/(iHg-iLw));;
                     return(hWisk);

}

double low_whisk(string sym, int peri, int shiftbar)
{
                     //bars characterization
                     double iHg = iHigh(sym, peri,shiftbar);
                     double iLw = iLow(sym, peri,shiftbar);
                     double iOp = iOpen(sym, peri,shiftbar);
                     double iCs = iClose(sym, peri,shiftbar);
                     //% of the lower whisker
                     double lWisk = 0;
                     // bullish
                     if(iOp < iCs) lWisk = 100*((iOp-iLw)/(iHg-iLw));
                     // bearish
                     if(iOp > iCs) lWisk = 100*((iCs-iLw)/(iHg-iLw));;
                     return(lWisk);
}

double low_whisk_heiken(string sym, int peri, int shiftbar)
{
                     //bars characterization
                     double iHg = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HAHIGH,shiftbar );
                     double iLw = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HALOW,shiftbar );
                     double iOp = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HAOPEN,shiftbar );
                     double iCs = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HACLOSE,shiftbar );
                    //% of the lower whisker
                     double lWisk = 0;
                     // bullish
                     if(iOp < iCs) lWisk = 100*((iOp-iLw)/(iHg-iLw));
                     // bearish
                     if(iOp > iCs) lWisk = 100*((iCs-iLw)/(iHg-iLw));;
                     return(lWisk);
}

double bar_body(string sym, int peri, int shiftbar)
{
                     //bars characterization
                     double iHg = iHigh(sym, peri,shiftbar);
                     double iLw = iLow(sym, peri,shiftbar);
                     double iOp = iOpen(sym, peri,shiftbar);
                     double iCs = iClose(sym, peri,shiftbar);
                     //% of the lower whisker
                     double bBody = 0;
                     // bullish
                     if(iOp < iCs) bBody = 100*((iCs-iOp)/(iHg-iLw));
                     // bearish
                     if(iOp > iCs) bBody = 100*((iOp-iCs)/(iHg-iLw));
                     if(iOp == iCs) bBody = 0;
                     return(bBody);
}

double bar_body_heiken(string sym, int peri, int shiftbar)
{
                     //bars characterization
                     double iHg = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HAHIGH,shiftbar );
                     double iLw = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HALOW,shiftbar );
                     double iOp = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HAOPEN,shiftbar );
                     double iCs = iCustom(sym,peri,"Heiken Ashi", color1,color2,color3,color4,HACLOSE,shiftbar );
                    //% of the lower whisker
                     double bBody = 0;
                     // bullish
                     if(iOp < iCs) bBody = 100*((iCs-iOp)/(iHg-iLw));
                     // bearish
                     if(iOp > iCs) bBody = 100*((iOp-iCs)/(iHg-iLw));
                     if(iOp == iCs) bBody = 0;
                     return(bBody);
}



void collectAndWrite(string symboll, string foldname, string filename, int charPer1, int barsCollect, bool dssInput)
// function to record 28 currencies pairs close price to the file (file to be used by all R scripts)
 {
 
 int digits = (int)MarketInfo(symboll, MODE_DIGITS);
   
string data;    //identifier that will be used to collect data string
string filepath;
datetime TIME;  //Time index
               if(!dssInput)filepath = foldname+"\\"+filename; //dss_input == False creates sub folders with simulation data
               if(dssInput)filepath = filename; //dss_input == True creates files in the sandbox
                 
               // delete file if it's exist
               FileDelete(filepath);
               // open file handle
               int handle = FileOpen(filepath,FILE_CSV|FILE_READ|FILE_WRITE);
                FileSeek(handle,0,SEEK_SET);
               // generate data now using for loop
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               //----Fill the arrays
               if(StringCompare(foldname, "6_01")== 0)
                 {
                              
                  //loop j calculates surfaces and angles from beginning of the day
                  for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                    {
                      TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                      data = string(TIME); 
                       
                        string ind[18];
                        
                        ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                        ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                        ind[2]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j),digits);
                        ind[3]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+2),digits);
                        ind[4]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+3),digits);
                        ind[5]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+5),digits);
                        ind[6]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+8),digits);
                        ind[7]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+13),digits);
                        ind[8]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+21),digits);
                        ind[9]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+34),digits);
                        ind[10] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j),digits);
                        ind[11] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+2),digits);
                        ind[12] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+3),digits);
                        ind[13] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+5),digits);
                        ind[14] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+8),digits);
                        ind[15] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+13),digits);
                        ind[16] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+21),digits);
                        ind[17] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+34),digits);
                        
                        for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                        
                        FileWrite(handle,data);   //write data to the file during each for loop iteration
                    }
                  
                  //             
                   FileClose(handle);        //close file when data write is over
                  //---------------------------------------------------------------------------------------------

                 }
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               //----Fill the arrays
               if(StringCompare(foldname, "6_02")== 0)
                 {
                              
                  //loop j calculates surfaces and angles from beginning of the day
                  for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                    {
                      TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                      data = string(TIME); 
                       
                        string ind[18];
                        
                        ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                        ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                        
                        ind[2]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j),digits);
                        ind[3] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j),digits);
                        
                        ind[4]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+2),digits);
                        ind[5] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+2),digits);
                        
                        ind[6]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+3),digits);
                        ind[7] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+3),digits);
                        
                        ind[8]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+5),digits);
                        ind[9] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+5),digits);
                        
                        ind[10]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+8),digits);
                        ind[11] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+8),digits);
                        
                        ind[12]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+13),digits);
                        ind[13] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+13),digits);
                        
                        ind[14]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+21),digits);
                        ind[15] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+21),digits);
                        
                        ind[16]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+34),digits);
                        ind[17] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+34),digits);
                        
                        for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                        
                        FileWrite(handle,data);   //write data to the file during each for loop iteration
                    }
                  
                  //             
                   FileClose(handle);        //close file when data write is over
                  //---------------------------------------------------------------------------------------------

                 }
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================          
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               //----Fill the arrays
               if(StringCompare(foldname, "6_03")== 0)
                 {
                              
                  //loop j calculates surfaces and angles from beginning of the day
                  for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                    {
                      TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                      data = string(TIME); 
                       
                        string ind[18];
                        
                        ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                        ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                        
                        ind[2]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j),digits);
                        ind[3] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j),digits);
                        
                        ind[4]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+2),digits);
                        ind[5] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+2),digits);
                        
                        ind[6]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+3),digits);
                        ind[7] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+3),digits);
                        
                        ind[8]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+4),digits);
                        ind[9] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+4),digits);
                        
                        ind[10]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+5),digits);
                        ind[11] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+5),digits);
                        
                        ind[12]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+6),digits);
                        ind[13] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+6),digits);
                        
                        ind[14]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+7),digits);
                        ind[15] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+7),digits);
                        
                        ind[16]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+8),digits);
                        ind[17] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+8),digits);
                        
                        for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                        
                        FileWrite(handle,data);   //write data to the file during each for loop iteration
                    }
                  
                  //             
                   FileClose(handle);        //close file when data write is over
                  //---------------------------------------------------------------------------------------------

                 }
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================                            
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               //----Fill the arrays
               if(StringCompare(foldname, "6_04")== 0)
                 {
                              
                  //loop j calculates surfaces and angles from beginning of the day
                  for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                    {
                      TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                      data = string(TIME); 
                       
                        string ind[42];
                        
                        ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                        ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                        
                        ind[2] = DoubleToStr(high_whisk(symboll, charPer1, j));
                        ind[3] = DoubleToStr(low_whisk(symboll, charPer1, j));
                        ind[4] = DoubleToStr(bar_body(symboll, charPer1, j));
                        ind[5]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j),digits);
                        ind[6] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j),digits);

                        ind[7] = DoubleToStr(high_whisk(symboll, charPer1, j+2));
                        ind[8] = DoubleToStr(low_whisk(symboll, charPer1, j+2));
                        ind[9] = DoubleToStr(bar_body(symboll, charPer1, j+2));
                        ind[10]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+2),digits);
                        ind[11] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+2),digits);

                        ind[12] = DoubleToStr(high_whisk(symboll, charPer1, j+3));
                        ind[13] = DoubleToStr(low_whisk(symboll, charPer1, j+3));
                        ind[14] = DoubleToStr(bar_body(symboll, charPer1, j+3));
                        ind[15]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+3),digits);
                        ind[16] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+3),digits);

                        ind[17] = DoubleToStr(high_whisk(symboll, charPer1, j+5));
                        ind[18] = DoubleToStr(low_whisk(symboll, charPer1, j+5));
                        ind[19] = DoubleToStr(bar_body(symboll, charPer1, j+5));
                        ind[20]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+5),digits);
                        ind[21] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+5),digits);

                        ind[22] = DoubleToStr(high_whisk(symboll, charPer1, j+8));
                        ind[23] = DoubleToStr(low_whisk(symboll, charPer1, j+8));
                        ind[24] = DoubleToStr(bar_body(symboll, charPer1, j+8));
                        ind[25]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+8),digits);
                        ind[26] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+8),digits);

                        ind[27] = DoubleToStr(high_whisk(symboll, charPer1, j+13));
                        ind[28] = DoubleToStr(low_whisk(symboll, charPer1, j+13));
                        ind[29] = DoubleToStr(bar_body(symboll, charPer1, j+13));
                        ind[30]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+13),digits);
                        ind[31] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+13),digits);

                        ind[32] = DoubleToStr(high_whisk(symboll, charPer1, j+21));
                        ind[33] = DoubleToStr(low_whisk(symboll, charPer1, j+21));
                        ind[34] = DoubleToStr(bar_body(symboll, charPer1, j+21));
                        ind[35]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+21),digits);
                        ind[36] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+21),digits);
                        
                        ind[37] = DoubleToStr(high_whisk(symboll, charPer1, j+34));
                        ind[38] = DoubleToStr(low_whisk(symboll, charPer1, j+34));
                        ind[39] = DoubleToStr(bar_body(symboll, charPer1, j+34));
                        ind[40]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+34),digits);
                        ind[41] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+34),digits);
                                                
                        for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                        
                        FileWrite(handle,data);   //write data to the file during each for loop iteration
                    }
                  
                  //             
                   FileClose(handle);        //close file when data write is over
                  //---------------------------------------------------------------------------------------------

                 }
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================

               if(StringCompare(foldname, "6_05")== 0)
                 {
                        //loop j calculates surfaces and angles from beginning of the day
                     for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                       {
                         TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                         data = string(TIME); 
                          
                        string ind[42];
                          
                        ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                        ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                        
                        ind[2] = DoubleToStr(high_whisk(symboll, charPer1, j));
                        ind[3] = DoubleToStr(low_whisk(symboll, charPer1, j));
                        ind[4] = DoubleToStr(bar_body(symboll, charPer1, j));
                        ind[5]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j),digits);
                        ind[6] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j),digits);

                        ind[7] = DoubleToStr(high_whisk(symboll, charPer1, j+2));
                        ind[8] = DoubleToStr(low_whisk(symboll, charPer1, j+2));
                        ind[9] = DoubleToStr(bar_body(symboll, charPer1, j+2));
                        ind[10]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+2),digits);
                        ind[11] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+2),digits);

                        ind[12] = DoubleToStr(high_whisk(symboll, charPer1, j+3));
                        ind[13] = DoubleToStr(low_whisk(symboll, charPer1, j+3));
                        ind[14] = DoubleToStr(bar_body(symboll, charPer1, j+3));
                        ind[15]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+3),digits);
                        ind[16] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+3),digits);

                        ind[17] = DoubleToStr(high_whisk(symboll, charPer1, j+4));
                        ind[18] = DoubleToStr(low_whisk(symboll, charPer1, j+4));
                        ind[19] = DoubleToStr(bar_body(symboll, charPer1, j+4));
                        ind[20]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+4),digits);
                        ind[21] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+4),digits);

                        ind[22] = DoubleToStr(high_whisk(symboll, charPer1, j+5));
                        ind[23] = DoubleToStr(low_whisk(symboll, charPer1, j+5));
                        ind[24] = DoubleToStr(bar_body(symboll, charPer1, j+5));
                        ind[25]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+5),digits);
                        ind[26] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+5),digits);

                        ind[27] = DoubleToStr(high_whisk(symboll, charPer1, j+6));
                        ind[28] = DoubleToStr(low_whisk(symboll, charPer1, j+6));
                        ind[29] = DoubleToStr(bar_body(symboll, charPer1, j+6));
                        ind[30]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+6),digits);
                        ind[31] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+6),digits);

                        ind[32] = DoubleToStr(high_whisk(symboll, charPer1, j+7));
                        ind[33] = DoubleToStr(low_whisk(symboll, charPer1, j+7));
                        ind[34] = DoubleToStr(bar_body(symboll, charPer1, j+7));
                        ind[35]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+7),digits);
                        ind[36] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+7),digits);
                        
                        ind[37] = DoubleToStr(high_whisk(symboll, charPer1, j+8));
                        ind[38] = DoubleToStr(low_whisk(symboll, charPer1, j+8));
                        ind[39] = DoubleToStr(bar_body(symboll, charPer1, j+8));
                        ind[40]  = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+8),digits);
                        ind[41] = DoubleToStr(iADX(symboll,charPer1, 8,PRICE_MEDIAN, MODE_MAIN,j+8),digits);
      
                                                
                           
                           for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                           
                           FileWrite(handle,data);   //write data to the file during each for loop iteration
                       }
                     
                     //             
                      FileClose(handle);        //close file when data write is over
                     //---------------------------------------------------------------------------------------------
                 }           
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================

               if(StringCompare(foldname, "6_06")== 0)
                 {
                        //loop j calculates surfaces and angles from beginning of the day
                     for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                       {
                         TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                         data = string(TIME); 
                          
                           string ind[70];
                           
                          
                           ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                           ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                           
                           ind[2] = DoubleToStr(bar_type(symboll, charPer1, j));
                           ind[3] = DoubleToStr(high_whisk(symboll, charPer1, j));
                           ind[4] = DoubleToStr(low_whisk(symboll, charPer1, j));
                           ind[5] = DoubleToStr(bar_body(symboll, charPer1, j));
                           
                           ind[6] = DoubleToStr(bar_type(symboll, charPer1, j+1));
                           ind[7] = DoubleToStr(high_whisk(symboll, charPer1, j+1));
                           ind[8] = DoubleToStr(low_whisk(symboll, charPer1, j+1));
                           ind[9] = DoubleToStr(bar_body(symboll, charPer1, j+1));
                           
                           ind[10] = DoubleToStr(bar_type(symboll, charPer1, j+2));
                           ind[11] = DoubleToStr(high_whisk(symboll, charPer1, j+2));
                           ind[12] = DoubleToStr(low_whisk(symboll, charPer1, j+2));
                           ind[13] = DoubleToStr(bar_body(symboll, charPer1, j+2));
                           
                           ind[14] = DoubleToStr(bar_type(symboll, charPer1, j+3));
                           ind[15] = DoubleToStr(high_whisk(symboll, charPer1, j+3));
                           ind[16] = DoubleToStr(low_whisk(symboll, charPer1, j+3));
                           ind[17] = DoubleToStr(bar_body(symboll, charPer1, j+3));
                           
                           ind[18] = DoubleToStr(bar_type(symboll, charPer1, j+4));
                           ind[19] = DoubleToStr(high_whisk(symboll, charPer1, j+4));
                           ind[20] = DoubleToStr(low_whisk(symboll, charPer1, j+4));
                           ind[21] = DoubleToStr(bar_body(symboll, charPer1, j+4));
                           
                           ind[22] = DoubleToStr(bar_type(symboll, charPer1, j+5));
                           ind[23] = DoubleToStr(high_whisk(symboll, charPer1, j+5));
                           ind[24] = DoubleToStr(low_whisk(symboll, charPer1, j+5));
                           ind[25] = DoubleToStr(bar_body(symboll, charPer1, j+5));
                           
                           ind[26] = DoubleToStr(bar_type(symboll, charPer1, j+6));
                           ind[27] = DoubleToStr(high_whisk(symboll, charPer1, j+6));
                           ind[28] = DoubleToStr(low_whisk(symboll, charPer1, j+6));
                           ind[29] = DoubleToStr(bar_body(symboll, charPer1, j+6));
                           
                           ind[30] = DoubleToStr(bar_type(symboll, charPer1, j+7));
                           ind[31] = DoubleToStr(high_whisk(symboll, charPer1, j+7));
                           ind[32] = DoubleToStr(low_whisk(symboll, charPer1, j+7));
                           ind[33] = DoubleToStr(bar_body(symboll, charPer1, j+7));
                           
                           ind[34] = DoubleToStr(bar_type(symboll, charPer1, j+8));
                           ind[35] = DoubleToStr(high_whisk(symboll, charPer1, j+8));
                           ind[36] = DoubleToStr(low_whisk(symboll, charPer1, j+8));
                           ind[37] = DoubleToStr(bar_body(symboll, charPer1, j+8));
                           
                           ind[38] = DoubleToStr(bar_type(symboll, charPer1, j+9));
                           ind[39] = DoubleToStr(high_whisk(symboll, charPer1, j+9));
                           ind[40] = DoubleToStr(low_whisk(symboll, charPer1, j+9));
                           ind[41] = DoubleToStr(bar_body(symboll, charPer1, j+9));
                           
                           ind[42] = DoubleToStr(bar_type(symboll, charPer1, j+10));
                           ind[43] = DoubleToStr(high_whisk(symboll, charPer1, j+10));
                           ind[44] = DoubleToStr(low_whisk(symboll, charPer1, j+10));
                           ind[45] = DoubleToStr(bar_body(symboll, charPer1, j+10));
                           
                           ind[46] = DoubleToStr(bar_type(symboll, charPer1, j+11));
                           ind[47] = DoubleToStr(high_whisk(symboll, charPer1, j+11));
                           ind[48] = DoubleToStr(low_whisk(symboll, charPer1, j+11));
                           ind[49] = DoubleToStr(bar_body(symboll, charPer1, j+11));
                           
                           ind[50] = DoubleToStr(bar_type(symboll, charPer1, j+12));
                           ind[51] = DoubleToStr(high_whisk(symboll, charPer1, j+12));
                           ind[52] = DoubleToStr(low_whisk(symboll, charPer1, j+12));
                           ind[53] = DoubleToStr(bar_body(symboll, charPer1, j+12));
                           
                           ind[54] = DoubleToStr(bar_type(symboll, charPer1, j+13));
                           ind[55] = DoubleToStr(high_whisk(symboll, charPer1, j+13));
                           ind[56] = DoubleToStr(low_whisk(symboll, charPer1, j+13));
                           ind[57] = DoubleToStr(bar_body(symboll, charPer1, j+13));
                           
                           ind[58] = DoubleToStr(bar_type(symboll, charPer1, j+14));
                           ind[59] = DoubleToStr(high_whisk(symboll, charPer1, j+14));
                           ind[60] = DoubleToStr(low_whisk(symboll, charPer1, j+14));
                           ind[61] = DoubleToStr(bar_body(symboll, charPer1, j+14));
                           
                           ind[62] = DoubleToStr(bar_type(symboll, charPer1, j+15));
                           ind[63] = DoubleToStr(high_whisk(symboll, charPer1, j+15));
                           ind[64] = DoubleToStr(low_whisk(symboll, charPer1, j+15));
                           ind[65] = DoubleToStr(bar_body(symboll, charPer1, j+15));
                           
                           ind[66] = DoubleToStr(bar_type(symboll, charPer1, j+16));
                           ind[67] = DoubleToStr(high_whisk(symboll, charPer1, j+16));
                           ind[68] = DoubleToStr(low_whisk(symboll, charPer1, j+16));
                           ind[69] = DoubleToStr(bar_body(symboll, charPer1, j+16));
                           
                           for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                           
                           FileWrite(handle,data);   //write data to the file during each for loop iteration
                       }
                     
                     //             
                      FileClose(handle);        //close file when data write is over
                     //---------------------------------------------------------------------------------------------
                 }           
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================

               if(StringCompare(foldname, "6_07")== 0)
                 {
                        //loop j calculates surfaces and angles from beginning of the day
                     for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                       {
                         TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                         data = string(TIME); 
                          
                           string ind[34];
                           
                          
                           ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                           ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                           
                           ind[2] = DoubleToStr(bar_type(symboll, charPer1, j));
                           ind[3] = DoubleToStr(high_whisk(symboll, charPer1, j));
                           ind[4] = DoubleToStr(low_whisk(symboll, charPer1, j));
                           ind[5] = DoubleToStr(bar_body(symboll, charPer1, j));
                           
                           ind[6] = DoubleToStr(bar_type(symboll, charPer1, j+1));
                           ind[7] = DoubleToStr(high_whisk(symboll, charPer1, j+1));
                           ind[8] = DoubleToStr(low_whisk(symboll, charPer1, j+1));
                           ind[9] = DoubleToStr(bar_body(symboll, charPer1, j+1));
                           
                           ind[10] = DoubleToStr(bar_type(symboll, charPer1, j+3));
                           ind[11] = DoubleToStr(high_whisk(symboll, charPer1, j+3));
                           ind[12] = DoubleToStr(low_whisk(symboll, charPer1, j+3));
                           ind[13] = DoubleToStr(bar_body(symboll, charPer1, j+3));
                           
                           ind[14] = DoubleToStr(bar_type(symboll, charPer1, j+5));
                           ind[15] = DoubleToStr(high_whisk(symboll, charPer1, j+5));
                           ind[16] = DoubleToStr(low_whisk(symboll, charPer1, j+5));
                           ind[17] = DoubleToStr(bar_body(symboll, charPer1, j+5));
                           
                           ind[18] = DoubleToStr(bar_type(symboll, charPer1, j+8));
                           ind[19] = DoubleToStr(high_whisk(symboll, charPer1, j+8));
                           ind[20] = DoubleToStr(low_whisk(symboll, charPer1, j+8));
                           ind[21] = DoubleToStr(bar_body(symboll, charPer1, j+8));
                           
                           ind[22] = DoubleToStr(bar_type(symboll, charPer1, j+13));
                           ind[23] = DoubleToStr(high_whisk(symboll, charPer1, j+13));
                           ind[24] = DoubleToStr(low_whisk(symboll, charPer1, j+13));
                           ind[25] = DoubleToStr(bar_body(symboll, charPer1, j+13));
                           
                           ind[26] = DoubleToStr(bar_type(symboll, charPer1, j+21));
                           ind[27] = DoubleToStr(high_whisk(symboll, charPer1, j+21));
                           ind[28] = DoubleToStr(low_whisk(symboll, charPer1, j+21));
                           ind[29] = DoubleToStr(bar_body(symboll, charPer1, j+21));
                           
                           ind[30] = DoubleToStr(bar_type(symboll, charPer1, j+34));
                           ind[31] = DoubleToStr(high_whisk(symboll, charPer1, j+34));
                           ind[32] = DoubleToStr(low_whisk(symboll, charPer1, j+34));
                           ind[33] = DoubleToStr(bar_body(symboll, charPer1, j+34));
                           
                           for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                           
                           FileWrite(handle,data);   //write data to the file during each for loop iteration
                       }
                     
                     //             
                      FileClose(handle);        //close file when data write is over
                     //---------------------------------------------------------------------------------------------
                 }           
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================        
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================

               if(StringCompare(foldname, "6_08")== 0)
                 {
                        //loop j calculates surfaces and angles from beginning of the day
                     for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                       {
                         TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                         data = string(TIME); 
                          
                        string ind[42];
                          
                        ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                        ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                        
                        ind[2] = DoubleToStr(high_whisk(symboll, charPer1, j));
                        ind[3] = DoubleToStr(low_whisk(symboll, charPer1, j));
                        ind[4] = DoubleToStr(bar_body(symboll, charPer1, j));
                        ind[5]  = DoubleToStr(iRSI(symboll,charPer1, 5, PRICE_MEDIAN, j),digits);
                        ind[6] = DoubleToStr(iRSI(symboll,charPer1, 14, PRICE_MEDIAN, j),digits);

                        ind[7] = DoubleToStr(high_whisk(symboll, charPer1, j+2));
                        ind[8] = DoubleToStr(low_whisk(symboll, charPer1, j+2));
                        ind[9] = DoubleToStr(bar_body(symboll, charPer1, j+2));
                        ind[10]  = DoubleToStr(iRSI(symboll,charPer1, 5, PRICE_MEDIAN, j+2),digits);
                        ind[11] = DoubleToStr(iRSI(symboll,charPer1, 14, PRICE_MEDIAN, j+2),digits);

                        ind[12] = DoubleToStr(high_whisk(symboll, charPer1, j+3));
                        ind[13] = DoubleToStr(low_whisk(symboll, charPer1, j+3));
                        ind[14] = DoubleToStr(bar_body(symboll, charPer1, j+3));
                        ind[15]  = DoubleToStr(iRSI(symboll,charPer1, 5, PRICE_MEDIAN, j+3),digits);
                        ind[16] = DoubleToStr(iRSI(symboll,charPer1, 14, PRICE_MEDIAN, j+3),digits);

                        ind[17] = DoubleToStr(high_whisk(symboll, charPer1, j+4));
                        ind[18] = DoubleToStr(low_whisk(symboll, charPer1, j+4));
                        ind[19] = DoubleToStr(bar_body(symboll, charPer1, j+4));
                        ind[20]  = DoubleToStr(iRSI(symboll,charPer1, 5, PRICE_MEDIAN, j+4),digits);
                        ind[21] = DoubleToStr(iRSI(symboll,charPer1, 14, PRICE_MEDIAN, j+4),digits);

                        ind[22] = DoubleToStr(high_whisk(symboll, charPer1, j+5));
                        ind[23] = DoubleToStr(low_whisk(symboll, charPer1, j+5));
                        ind[24] = DoubleToStr(bar_body(symboll, charPer1, j+5));
                        ind[25]  = DoubleToStr(iRSI(symboll,charPer1, 5, PRICE_MEDIAN, j+5),digits);
                        ind[26] = DoubleToStr(iRSI(symboll,charPer1, 14, PRICE_MEDIAN, j+5),digits);

                        ind[27] = DoubleToStr(high_whisk(symboll, charPer1, j+6));
                        ind[28] = DoubleToStr(low_whisk(symboll, charPer1, j+6));
                        ind[29] = DoubleToStr(bar_body(symboll, charPer1, j+6));
                        ind[30]  = DoubleToStr(iRSI(symboll,charPer1, 5, PRICE_MEDIAN, j+6),digits);
                        ind[31] = DoubleToStr(iRSI(symboll,charPer1, 14, PRICE_MEDIAN, j+6),digits);

                        ind[32] = DoubleToStr(high_whisk(symboll, charPer1, j+7));
                        ind[33] = DoubleToStr(low_whisk(symboll, charPer1, j+7));
                        ind[34] = DoubleToStr(bar_body(symboll, charPer1, j+7));
                        ind[35]  = DoubleToStr(iRSI(symboll,charPer1, 5, PRICE_MEDIAN, j+7),digits);
                        ind[36] = DoubleToStr(iRSI(symboll,charPer1, 14, PRICE_MEDIAN, j+7),digits);
                        
                        ind[37] = DoubleToStr(high_whisk(symboll, charPer1, j+8));
                        ind[38] = DoubleToStr(low_whisk(symboll, charPer1, j+8));
                        ind[39] = DoubleToStr(bar_body(symboll, charPer1, j+8));
                        ind[40]  = DoubleToStr(iRSI(symboll,charPer1, 5, PRICE_MEDIAN, j+8),digits);
                        ind[41] = DoubleToStr(iRSI(symboll,charPer1, 14, PRICE_MEDIAN, j+8),digits);
      
                                                
                           
                           for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                           
                           FileWrite(handle,data);   //write data to the file during each for loop iteration
                       }
                     
                     //             
                      FileClose(handle);        //close file when data write is over
                     //---------------------------------------------------------------------------------------------
                 }           
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================                      
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================

               if(StringCompare(foldname, "6_09")== 0)
                 {
                        //loop j calculates surfaces and angles from beginning of the day
                     
                                                
                     for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                       {
                         TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                         data = string(TIME); 
                          
                        string ind[70];
                          
                           ind[0]  = DoubleToStr(iCustom(symboll,charPer1,"Heiken Ashi", color1,color2,color3,color4,HACLOSE,j),digits);
                           ind[1]  = DoubleToStr(iCustom(symboll,charPer1,"Heiken Ashi", color1,color2,color3,color4,HACLOSE,j+34),digits);
                              
                           ind[2] = DoubleToStr(bar_type_heiken(symboll, charPer1, j));
                           ind[3] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j));
                           ind[4] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j));
                           ind[5] = DoubleToStr(bar_body_heiken(symboll, charPer1, j));
                           
                           ind[6] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+1));
                           ind[7] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+1));
                           ind[8] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+1));
                           ind[9] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+1));
                           
                           ind[10] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+2));
                           ind[11] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+2));
                           ind[12] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+2));
                           ind[13] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+2));
                           
                           ind[14] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+3));
                           ind[15] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+3));
                           ind[16] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+3));
                           ind[17] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+3));
                           
                           ind[18] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+4));
                           ind[19] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+4));
                           ind[20] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+4));
                           ind[21] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+4));
                           
                           ind[22] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+5));
                           ind[23] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+5));
                           ind[24] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+5));
                           ind[25] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+5));
                           
                           ind[26] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+6));
                           ind[27] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+6));
                           ind[28] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+6));
                           ind[29] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+6));
                           
                           ind[30] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+7));
                           ind[31] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+7));
                           ind[32] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+7));
                           ind[33] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+7));
                           
                           ind[34] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+8));
                           ind[35] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+8));
                           ind[36] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+8));
                           ind[37] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+8));
                           
                           ind[38] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+9));
                           ind[39] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+9));
                           ind[40] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+9));
                           ind[41] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+9));
                           
                           ind[42] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+10));
                           ind[43] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+10));
                           ind[44] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+10));
                           ind[45] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+10));
                           
                           ind[46] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+11));
                           ind[47] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+11));
                           ind[48] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+11));
                           ind[49] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+11));
                           
                           ind[50] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+12));
                           ind[51] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+12));
                           ind[52] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+12));
                           ind[53] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+12));
                           
                           ind[54] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+13));
                           ind[55] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+13));
                           ind[56] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+13));
                           ind[57] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+13));
                           
                           ind[58] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+14));
                           ind[59] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+14));
                           ind[60] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+14));
                           ind[61] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+14));
                           
                           ind[62] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+15));
                           ind[63] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+15));
                           ind[64] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+15));
                           ind[65] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+15));
                           
                           ind[66] = DoubleToStr(bar_type_heiken(symboll, charPer1, j+16));
                           ind[67] = DoubleToStr(high_whisk_heiken(symboll, charPer1, j+16));
                           ind[68] = DoubleToStr(low_whisk_heiken(symboll, charPer1, j+16));
                           ind[69] = DoubleToStr(bar_body_heiken(symboll, charPer1, j+16));    
                           
                           for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                           
                           FileWrite(handle,data);   //write data to the file during each for loop iteration
                       }
                     
                     //             
                      FileClose(handle);        //close file when data write is over
                     //---------------------------------------------------------------------------------------------
                 }           
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               
              if(StringCompare(foldname, "6_10")== 0)
                 {
                        //loop j calculates surfaces and angles from beginning of the day
                     for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                       {
                         TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                         data = string(TIME); 
                          
                           string ind[70];
                     

                     
                     
                     ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                     ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                     
                     ind[2] = DoubleToStr(bar_type(symboll, charPer1, j));
                     ind[3] = DoubleToStr(high_whisk(symboll, charPer1, j));
                     ind[4] = DoubleToStr(low_whisk(symboll, charPer1, j));
                     ind[5] = DoubleToStr(bar_body(symboll, charPer1, j));
                     
                     ind[6] = DoubleToStr(bar_type(symboll, charPer1, j+1));
                     ind[7] = DoubleToStr(high_whisk(symboll, charPer1, j+1));
                     ind[8] = DoubleToStr(low_whisk(symboll, charPer1, j+1));
                     ind[9] = DoubleToStr(bar_body(symboll, charPer1, j+1));
                     
                     ind[10] = DoubleToStr(bar_type(symboll, charPer1, j+2));
                     ind[11] = DoubleToStr(high_whisk(symboll, charPer1, j+2));
                     ind[12] = DoubleToStr(low_whisk(symboll, charPer1, j+2));
                     ind[13] = DoubleToStr(bar_body(symboll, charPer1, j+2));
                     
                     ind[14] = DoubleToStr(bar_type(symboll, charPer1, j+3));
                     ind[15] = DoubleToStr(high_whisk(symboll, charPer1, j+3));
                     ind[16] = DoubleToStr(low_whisk(symboll, charPer1, j+3));
                     ind[17] = DoubleToStr(bar_body(symboll, charPer1, j+3));
                     
                     ind[18] = DoubleToStr(bar_type(symboll, charPer1, j+4));
                     ind[19] = DoubleToStr(high_whisk(symboll, charPer1, j+4));
                     ind[20] = DoubleToStr(low_whisk(symboll, charPer1, j+4));
                     ind[21] = DoubleToStr(bar_body(symboll, charPer1, j+4));
                     
                     ind[22] = DoubleToStr(bar_type(symboll, charPer1, j+5));
                     ind[23] = DoubleToStr(high_whisk(symboll, charPer1, j+5));
                     ind[24] = DoubleToStr(low_whisk(symboll, charPer1, j+5));
                     ind[25] = DoubleToStr(bar_body(symboll, charPer1, j+5));
                     
                     ind[26] = DoubleToStr(bar_type(symboll, charPer1, j+6));
                     ind[27] = DoubleToStr(high_whisk(symboll, charPer1, j+6));
                     ind[28] = DoubleToStr(low_whisk(symboll, charPer1, j+6));
                     ind[29] = DoubleToStr(bar_body(symboll, charPer1, j+6));
                     
                     ind[30] = DoubleToStr(bar_type(symboll, charPer1, j+7));
                     ind[31] = DoubleToStr(high_whisk(symboll, charPer1, j+7));
                     ind[32] = DoubleToStr(low_whisk(symboll, charPer1, j+7));
                     ind[33] = DoubleToStr(bar_body(symboll, charPer1, j+7));
                     
                     ind[34] = DoubleToStr(bar_type(symboll, charPer1, j+8));
                     ind[35] = DoubleToStr(high_whisk(symboll, charPer1, j+8));
                     ind[36] = DoubleToStr(low_whisk(symboll, charPer1, j+8));
                     ind[37] = DoubleToStr(bar_body(symboll, charPer1, j+8));
                     
                     ind[38] = DoubleToStr(bar_type(symboll, charPer1, j+9));
                     ind[39] = DoubleToStr(high_whisk(symboll, charPer1, j+9));
                     ind[40] = DoubleToStr(low_whisk(symboll, charPer1, j+9));
                     ind[41] = DoubleToStr(bar_body(symboll, charPer1, j+9));
                     
                     ind[42] = DoubleToStr(bar_type(symboll, charPer1, j+10));
                     ind[43] = DoubleToStr(high_whisk(symboll, charPer1, j+10));
                     ind[44] = DoubleToStr(low_whisk(symboll, charPer1, j+10));
                     ind[45] = DoubleToStr(bar_body(symboll, charPer1, j+10));
                     
                     ind[46] = DoubleToStr(bar_type(symboll, charPer1, j+11));
                     ind[47] = DoubleToStr(high_whisk(symboll, charPer1, j+11));
                     ind[48] = DoubleToStr(low_whisk(symboll, charPer1, j+11));
                     ind[49] = DoubleToStr(bar_body(symboll, charPer1, j+11));
                     
                     ind[50] = DoubleToStr(bar_type(symboll, charPer1, j+12));
                     ind[51] = DoubleToStr(high_whisk(symboll, charPer1, j+12));
                     ind[52] = DoubleToStr(low_whisk(symboll, charPer1, j+12));
                     ind[53] = DoubleToStr(bar_body(symboll, charPer1, j+12));
                     
                     ind[54] = DoubleToStr(bar_type(symboll, charPer1, j+13));
                     ind[55] = DoubleToStr(high_whisk(symboll, charPer1, j+13));
                     ind[56] = DoubleToStr(low_whisk(symboll, charPer1, j+13));
                     ind[57] = DoubleToStr(bar_body(symboll, charPer1, j+13));
                     
                     ind[58] = DoubleToStr(bar_type(symboll, charPer1, j+14));
                     ind[59] = DoubleToStr(high_whisk(symboll, charPer1, j+14));
                     ind[60] = DoubleToStr(low_whisk(symboll, charPer1, j+14));
                     ind[61] = DoubleToStr(bar_body(symboll, charPer1, j+14));
                     
                     ind[62] = DoubleToStr(bar_type(symboll, charPer1, j+15));
                     ind[63] = DoubleToStr(high_whisk(symboll, charPer1, j+15));
                     ind[64] = DoubleToStr(low_whisk(symboll, charPer1, j+15));
                     ind[65] = DoubleToStr(bar_body(symboll, charPer1, j+15));
                     
                     ind[66] = DoubleToStr(bar_type(symboll, charPer1, j+16));
                     ind[67] = DoubleToStr(high_whisk(symboll, charPer1, j+16));
                     ind[68] = DoubleToStr(low_whisk(symboll, charPer1, j+16));
                     ind[69] = DoubleToStr(bar_body(symboll, charPer1, j+16));
                     
                          
                           for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                           
                           FileWrite(handle,data);   //write data to the file during each for loop iteration
                       }
                     
                     //             
                      FileClose(handle);        //close file when data write is over
                     //---------------------------------------------------------------------------------------------
                 }    
                 
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================                                                                       
               if(StringCompare(foldname, "6_11")== 0)
                 {
                        //loop j calculates surfaces and angles from beginning of the day
                     for(int j = 1; j < barsCollect; j++)    //j scrolls through bars of the day
                       {
                         TIME = iTime(symboll, charPer1, j);  //Time of the bar of the applied chart symbol
                         data = string(TIME); 
                          
                           string ind[87];
                           
                           ind[0]  = DoubleToStr(iClose(symboll,charPer1,j),digits);
                           ind[1]  = DoubleToStr(iClose(symboll,charPer1,j+34),digits);
                           
                           ind[2] = DoubleToStr(bar_type(symboll, charPer1, j));
                           ind[3] = DoubleToStr(high_whisk(symboll, charPer1, j));
                           ind[4] = DoubleToStr(low_whisk(symboll, charPer1, j));
                           ind[5] = DoubleToStr(bar_body(symboll, charPer1, j));
                           ind[6] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j),digits);                     
                                                
                           ind[7] = DoubleToStr(bar_type(symboll, charPer1, j+1));
                           ind[8] = DoubleToStr(high_whisk(symboll, charPer1, j+1));
                           ind[9] = DoubleToStr(low_whisk(symboll, charPer1, j+1));
                           ind[10] = DoubleToStr(bar_body(symboll, charPer1, j+1));
                           ind[11] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+1),digits);
                           
                           ind[12] = DoubleToStr(bar_type(symboll, charPer1, j+2));
                           ind[13] = DoubleToStr(high_whisk(symboll, charPer1, j+2));
                           ind[14] = DoubleToStr(low_whisk(symboll, charPer1, j+2));
                           ind[15] = DoubleToStr(bar_body(symboll, charPer1, j+2));
                           ind[16] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+2),digits);
                           
                           ind[17] = DoubleToStr(bar_type(symboll, charPer1, j+3));
                           ind[18] = DoubleToStr(high_whisk(symboll, charPer1, j+3));
                           ind[19] = DoubleToStr(low_whisk(symboll, charPer1, j+3));
                           ind[20] = DoubleToStr(bar_body(symboll, charPer1, j+3));
                           ind[21] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+3),digits);
                           
                           ind[22] = DoubleToStr(bar_type(symboll, charPer1, j+4));
                           ind[23] = DoubleToStr(high_whisk(symboll, charPer1, j+4));
                           ind[24] = DoubleToStr(low_whisk(symboll, charPer1, j+4));
                           ind[25] = DoubleToStr(bar_body(symboll, charPer1, j+4));
                           ind[26] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+4),digits);
                           
                           ind[27] = DoubleToStr(bar_type(symboll, charPer1, j+5));
                           ind[28] = DoubleToStr(high_whisk(symboll, charPer1, j+5));
                           ind[29] = DoubleToStr(low_whisk(symboll, charPer1, j+5));
                           ind[30] = DoubleToStr(bar_body(symboll, charPer1, j+5));
                           ind[31] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+5),digits);
                           
                           ind[32] = DoubleToStr(bar_type(symboll, charPer1, j+6));
                           ind[33] = DoubleToStr(high_whisk(symboll, charPer1, j+6));
                           ind[34] = DoubleToStr(low_whisk(symboll, charPer1, j+6));
                           ind[35] = DoubleToStr(bar_body(symboll, charPer1, j+6));
                           ind[36] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+6),digits);
                           
                           ind[37] = DoubleToStr(bar_type(symboll, charPer1, j+7));
                           ind[38] = DoubleToStr(high_whisk(symboll, charPer1, j+7));
                           ind[39] = DoubleToStr(low_whisk(symboll, charPer1, j+7));
                           ind[40] = DoubleToStr(bar_body(symboll, charPer1, j+7));
                           ind[41] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+7),digits);
                           
                           ind[42] = DoubleToStr(bar_type(symboll, charPer1, j+8));
                           ind[43] = DoubleToStr(high_whisk(symboll, charPer1, j+8));
                           ind[44] = DoubleToStr(low_whisk(symboll, charPer1, j+8));
                           ind[45] = DoubleToStr(bar_body(symboll, charPer1, j+8));
                           ind[46] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+8),digits);
                           
                           ind[47] = DoubleToStr(bar_type(symboll, charPer1, j+9));
                           ind[48] = DoubleToStr(high_whisk(symboll, charPer1, j+9));
                           ind[49] = DoubleToStr(low_whisk(symboll, charPer1, j+9));
                           ind[50] = DoubleToStr(bar_body(symboll, charPer1, j+9));
                           ind[51] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+9),digits);
                           
                           ind[52] = DoubleToStr(bar_type(symboll, charPer1, j+10));
                           ind[53] = DoubleToStr(high_whisk(symboll, charPer1, j+10));
                           ind[54] = DoubleToStr(low_whisk(symboll, charPer1, j+10));
                           ind[55] = DoubleToStr(bar_body(symboll, charPer1, j+10));
                           ind[56] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+10),digits);
                           
                           ind[57] = DoubleToStr(bar_type(symboll, charPer1, j+11));
                           ind[58] = DoubleToStr(high_whisk(symboll, charPer1, j+11));
                           ind[59] = DoubleToStr(low_whisk(symboll, charPer1, j+11));
                           ind[60] = DoubleToStr(bar_body(symboll, charPer1, j+11));
                           ind[61] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+11),digits);
                           
                           ind[62] = DoubleToStr(bar_type(symboll, charPer1, j+12));
                           ind[63] = DoubleToStr(high_whisk(symboll, charPer1, j+12));
                           ind[64] = DoubleToStr(low_whisk(symboll, charPer1, j+12));
                           ind[65] = DoubleToStr(bar_body(symboll, charPer1, j+12));
                           ind[66] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+12),digits);
                           
                           ind[67] = DoubleToStr(bar_type(symboll, charPer1, j+13));
                           ind[68] = DoubleToStr(high_whisk(symboll, charPer1, j+13));
                           ind[69] = DoubleToStr(low_whisk(symboll, charPer1, j+13));
                           ind[70] = DoubleToStr(bar_body(symboll, charPer1, j+13));
                           ind[71] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+13),digits);
                           
                           ind[72] = DoubleToStr(bar_type(symboll, charPer1, j+14));
                           ind[73] = DoubleToStr(high_whisk(symboll, charPer1, j+14));
                           ind[74] = DoubleToStr(low_whisk(symboll, charPer1, j+14));
                           ind[75] = DoubleToStr(bar_body(symboll, charPer1, j+14));
                           ind[76] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+14),digits);
                           
                           ind[77] = DoubleToStr(bar_type(symboll, charPer1, j+15));
                           ind[78] = DoubleToStr(high_whisk(symboll, charPer1, j+15));
                           ind[79] = DoubleToStr(low_whisk(symboll, charPer1, j+15));
                           ind[80] = DoubleToStr(bar_body(symboll, charPer1, j+15));
                           ind[81] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+15),digits);
                           
                           ind[82] = DoubleToStr(bar_type(symboll, charPer1, j+16));
                           ind[83] = DoubleToStr(high_whisk(symboll, charPer1, j+16));
                           ind[84] = DoubleToStr(low_whisk(symboll, charPer1, j+16));
                           ind[85] = DoubleToStr(bar_body(symboll, charPer1, j+16));
                           ind[86] = DoubleToStr(iRSI(symboll,charPer1, 8, PRICE_MEDIAN, j+16),digits);
                           
                          
                           for(int i=0;i<ArraySize(ind);i++) data = data + ","+ind[i];   
                           
                           FileWrite(handle,data);   //write data to the file during each for loop iteration
                       }
                     
                     //             
                      FileClose(handle);        //close file when data write is over
                     //---------------------------------------------------------------------------------------------
                 }  
               // ===================================================================================================
               // +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
               // ===================================================================================================
               
               
               
               
               
         
  }




void collectTickSize( string filename)
// function to record 28 currencies pairs close price to the file (file to be used by all R scripts)
 {
 
 
string data;    //identifier that will be used to collect data string

               // delete file if it's exist
               FileDelete(filename);
               // open file handle
               int handle = FileOpen(filename,FILE_CSV|FILE_READ|FILE_WRITE);
                FileSeek(handle,0,SEEK_SET);
               // generate data now using for loop
               //----Fill the arrays
                     for(int c = 0; c < ArraySize(pairs); c++)
                     {
                        string ind  = DoubleToStr(MarketInfo(pairs[c],MODE_TICKSIZE),5);
                        data = pairs[c] + ","+ind;   
                        FileWrite(handle,data);   //write data to the file during each for loop iteration
                }
               
               //             
                FileClose(handle);        //close file when data write is over
               //---------------------------------------------------------------------------------------------
         
  }