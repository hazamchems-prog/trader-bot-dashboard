//+------------------------------------------------------------------+
//| RiskEA_50EUR.mq5                                                 |
//| Expert Advisor simple - Risque max 50 €                          |
//| Mode : manuel (tu décides d'entrer)                              |
//+------------------------------------------------------------------+
#property copyright "Trader Bot - hazamchems"
#property version   "1.00"
#property strict

//--- Inputs
input double   RiskEUR          = 50.0;    // Risque maximum en €
input double   StopLossPips     = 50.0;    // Stop Loss en pips
input double   TakeProfitPips   = 75.0;    // Take Profit en pips (R:R 1:1.5)
input double   MaxLot           = 0.10;    // Lot maximum autorisé
input double   MinLot           = 0.01;    // Lot minimum
input int      MagicNumber      = 20261116;// Magic number
input string   TradeComment     = "RiskEA_50EUR";

//--- Variables globales
bool     waitingConfirmation = false;
string   pendingDirection    = "";
double   pendingLot          = 0;
double   pendingSL           = 0;
double   pendingTP           = 0;

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   Print("RiskEA_50EUR initialisé | Risque max = ", RiskEUR, " €");
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Calcul du lot pour un risque donné                               |
//+------------------------------------------------------------------+
double CalculateLot(double stopPips)
{
   if(stopPips <= 0) return MinLot;

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double point     = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int    digits    = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   // Pour la plupart des paires forex : 1 pip = 10 points (5 digits) ou 1 point (3 digits)
   double pipValue = tickValue;
   if(digits == 5 || digits == 3)
      pipValue = tickValue * 10;

   // Lot = Risque € / (Stop en pips * valeur d'un pip pour 1 lot)
   double lot = RiskEUR / (stopPips * pipValue);

   // Arrondi à la baisse selon le step du broker
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   lot = MathFloor(lot / lotStep) * lotStep;

   // Bornes de sécurité
   if(lot < MinLot) lot = MinLot;
   if(lot > MaxLot) lot = MaxLot;

   double minVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxVol = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   if(lot < minVol) lot = minVol;
   if(lot > maxVol) lot = maxVol;

   return NormalizeDouble(lot, 2);
}

//+------------------------------------------------------------------+
//| Affiche les infos sur le graphique                               |
//+------------------------------------------------------------------+
void ShowInfo(double lot, double sl, double tp)
{
   string info = "";
   info += "=== RiskEA 50€ ===\n";
   info += "Lot calculé : " + DoubleToString(lot, 2) + "\n";
   info += "Stop Loss   : " + DoubleToString(sl, _Digits) + "\n";
   info += "Take Profit : " + DoubleToString(tp, _Digits) + "\n";
   info += "Risque max  : " + DoubleToString(RiskEUR, 0) + " €\n";
   info += "\nCliquez sur le bouton pour confirmer";

   Comment(info);
}

//+------------------------------------------------------------------+
//| Prépare un ordre BUY                                             |
//+------------------------------------------------------------------+
void PrepareBuy()
{
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   double sl = NormalizeDouble(ask - StopLossPips * point * ((digits==5||digits==3)?10:1), digits);
   double tp = NormalizeDouble(ask + TakeProfitPips * point * ((digits==5||digits==3)?10:1), digits);
   double lot = CalculateLot(StopLossPips);

   pendingDirection = "BUY";
   pendingLot = lot;
   pendingSL = sl;
   pendingTP = tp;
   waitingConfirmation = true;

   ShowInfo(lot, sl, tp);
   Print("BUY préparé | Lot=", lot, " SL=", sl, " TP=", tp);
}

//+------------------------------------------------------------------+
//| Prépare un ordre SELL                                            |
//+------------------------------------------------------------------+
void PrepareSell()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);

   double sl = NormalizeDouble(bid + StopLossPips * point * ((digits==5||digits==3)?10:1), digits);
   double tp = NormalizeDouble(bid - TakeProfitPips * point * ((digits==5||digits==3)?10:1), digits);
   double lot = CalculateLot(StopLossPips);

   pendingDirection = "SELL";
   pendingLot = lot;
   pendingSL = sl;
   pendingTP = tp;
   waitingConfirmation = true;

   ShowInfo(lot, sl, tp);
   Print("SELL préparé | Lot=", lot, " SL=", sl, " TP=", tp);
}

//+------------------------------------------------------------------+
//| Exécute l'ordre après confirmation                               |
//+------------------------------------------------------------------+
void ExecuteTrade()
{
   if(!waitingConfirmation) return;

   MqlTradeRequest request = {};
   MqlTradeResult  result  = {};

   request.action    = TRADE_ACTION_DEAL;
   request.symbol    = _Symbol;
   request.volume    = pendingLot;
   request.deviation = 20;
   request.magic     = MagicNumber;
   request.comment   = TradeComment;
   request.sl        = pendingSL;
   request.tp        = pendingTP;

   if(pendingDirection == "BUY")
   {
      request.type  = ORDER_TYPE_BUY;
      request.price = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   }
   else
   {
      request.type  = ORDER_TYPE_SELL;
      request.price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   }

   if(!OrderSend(request, result))
   {
      Print("Erreur OrderSend : ", GetLastError(), " | ", result.retcode);
   }
   else
   {
      Print("Ordre envoyé | Ticket=", result.order, " | Lot=", pendingLot);
   }

   waitingConfirmation = false;
   Comment("");
}

//+------------------------------------------------------------------+
//| Boutons sur le graphique                                         |
//+------------------------------------------------------------------+
void CreateButtons()
{
   ObjectCreate(0, "BtnBuy", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "BtnBuy", OBJPROP_XDISTANCE, 10);
   ObjectSetInteger(0, "BtnBuy", OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, "BtnBuy", OBJPROP_XSIZE, 80);
   ObjectSetInteger(0, "BtnBuy", OBJPROP_YSIZE, 30);
   ObjectSetString(0, "BtnBuy", OBJPROP_TEXT, "BUY");
   ObjectSetInteger(0, "BtnBuy", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "BtnBuy", OBJPROP_BGCOLOR, clrGreen);
   ObjectSetInteger(0, "BtnBuy", OBJPROP_CORNER, CORNER_LEFT_UPPER);

   ObjectCreate(0, "BtnSell", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "BtnSell", OBJPROP_XDISTANCE, 100);
   ObjectSetInteger(0, "BtnSell", OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, "BtnSell", OBJPROP_XSIZE, 80);
   ObjectSetInteger(0, "BtnSell", OBJPROP_YSIZE, 30);
   ObjectSetString(0, "BtnSell", OBJPROP_TEXT, "SELL");
   ObjectSetInteger(0, "BtnSell", OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, "BtnSell", OBJPROP_BGCOLOR, clrFireBrick);
   ObjectSetInteger(0, "BtnSell", OBJPROP_CORNER, CORNER_LEFT_UPPER);

   ObjectCreate(0, "BtnConfirm", OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, "BtnConfirm", OBJPROP_XDISTANCE, 190);
   ObjectSetInteger(0, "BtnConfirm", OBJPROP_YDISTANCE, 30);
   ObjectSetInteger(0, "BtnConfirm", OBJPROP_XSIZE, 100);
   ObjectSetInteger(0, "BtnConfirm", OBJPROP_YSIZE, 30);
   ObjectSetString(0, "BtnConfirm", OBJPROP_TEXT, "CONFIRMER");
   ObjectSetInteger(0, "BtnConfirm", OBJPROP_COLOR, clrBlack);
   ObjectSetInteger(0, "BtnConfirm", OBJPROP_BGCOLOR, clrGold);
   ObjectSetInteger(0, "BtnConfirm", OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| Gestion des clics                                                |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == "BtnBuy")
      {
         ObjectSetInteger(0, "BtnBuy", OBJPROP_STATE, false);
         PrepareBuy();
      }
      else if(sparam == "BtnSell")
      {
         ObjectSetInteger(0, "BtnSell", OBJPROP_STATE, false);
         PrepareSell();
      }
      else if(sparam == "BtnConfirm")
      {
         ObjectSetInteger(0, "BtnConfirm", OBJPROP_STATE, false);
         ExecuteTrade();
      }
   }
}

//+------------------------------------------------------------------+
//| Expert tick                                                      |
//+------------------------------------------------------------------+
void OnTick()
{
   static bool buttonsCreated = false;
   if(!buttonsCreated)
   {
      CreateButtons();
      buttonsCreated = true;
   }
}

//+------------------------------------------------------------------+
//| Deinit                                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ObjectDelete(0, "BtnBuy");
   ObjectDelete(0, "BtnSell");
   ObjectDelete(0, "BtnConfirm");
   Comment("");
}
//+------------------------------------------------------------------+
