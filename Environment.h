#include "TSystem.h"
#include "TString.h"
#include "TEnv.h"

#include <iostream>
#include <fstream>
#include <iomanip>
#include <sstream>
#include <cstring>

using namespace std;

Double_t lumi_scale;
Int_t bgno;

  double BGnumberofevents;
  double BGcrosssection;
  double BGweight;

void errormsg(TString var) {
    cout << endl;
    cout << "  ERROR : Environment variable(s) not properly set or missing : " << var << endl;
    cout << "          Exiting." << endl;
    cout << endl;
    exit(0);
}

void get_environment(TString background) {

  TEnv *xs = new TEnv("INPUT");

  TString *base = new TString("/user/gueth/limits_soeren/xs_signal_13TeV.cfg");
  //TString *bbase = new TString(*base);  

  const char* ret;
  ret = gSystem->FindFile(".", *base);

  /*
  cout << *base << endl;
  cout << ret << endl;
  */

  /*
  if (!strstr(ret, *base)) {
    cout << endl;
    cout << "  ERROR : Configuration file '" << *bbase << "' not found in current path !" << endl;
    cout << "          Exiting." << endl;
    cout << endl;
    exit(0);
  }  
  */

  xs->ReadFile("/user/gueth/limits_soeren/xs_signal_13TeV.cfg", kEnvChange);  

  lumi_scale = xs->GetValue("lumi", -1.);
  if (lumi_scale<0) errormsg("lumi"); 

  BGnumberofevents = xs->GetValue(background+".Nev", -1.);
  BGcrosssection   = xs->GetValue(background+".xs", -1.);
  BGweight         = xs->GetValue(background+".weight", -1.);    


  if (BGnumberofevents<0 || BGcrosssection<0 || BGweight<0)
    {errormsg(background);}

  delete base;

}
