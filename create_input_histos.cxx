//#include "create_input_histos.h"

#include "TFile.h"
#include "TCanvas.h"
#include "TTree.h"
#include "TString.h"
#include <sstream>
#include "TH1.h"
#include "TF1.h"
#include "TString.h"
#include "Environment.h"
#include <iostream>
#include <fstream>
#include <TMath.h>
#include "TKey.h"
#include "TLegend.h"
#include "TString.h"
#include "TGraphErrors.h"
#include "TIterator.h"

//using namespace RooFit ;
using namespace std;

void create_input_histos(){

  //TString dirPath = "/net/scratch_cms/institut_3a/gueth/condor/root_output/analyses/checked_emu_selection/";

  Char_t file_title[400];
  Char_t dir_title[400];  
  Char_t dir_title_syst[400];  

  //outfile for all histos
  TFile *outfile = new TFile("root_out/out.root","recreate");

  //outfile for all text to be used as input for the limit cfgs
  ofstream myfile;
  myfile.open ("txt_out/normalization.txt");

  double mass_min=200;
  double mass_max=2000;
  double limit_lower=mass_min;
  double limit_upper=mass_max;  

  int bin_limit_max_histo=5000,;
  int bin_limit_lower=1;
  int bin_limit_upper=bin_limit_max_histo;  

  int step_size=100;

  int N_points=(int)(mass_max-mass_min)/(double)step_size;

  double masses[400];
  double num_total[400];
  double num_signal[400];

  for(int n=0; n<400; n++)
  {
    masses[n]=0.;
    num_total[n]=0.;
    num_signal[n]=0.;

  }  

  TF1* fit_resolution = new TF1("fit_resolution","[0]+[1]*x+[2]*pow(x,2)+[3]*pow(x,3)",mass_min,mass_max);

  fit_resolution->SetParameter(0,1.45866e-02);
  fit_resolution->SetParameter(1,1.53660e-05);  
  fit_resolution->SetParameter(2,-3.62388e-09);
  fit_resolution->SetParameter(3,3.24659e-13);  

  TFile* file_background=new TFile("/net/scratch_cms/institut_3a/erdweg/public/RPV_for_limit_test.root");
  TH1F* bkg_tot=(TH1F*)file_background->Get("h1_0_emu_Mass");

  outfile->cd();
  bkg_tot->Write("bkg_tot");
     
  myfile << "bkg " << " tot " << " " << bkg_tot->Integral(1,bin_limit_max_histo) << "\n";


  //###############
  //prepare signals
  //###############


  const int num_samples=(int)((mass_max-mass_min)/(double)step_size+1);
  
  double mass_sig=(double)mass_min;
  double resolution=5.;
  //double width=1.;
  
  TF1* gauss = new TF1("gauss","TMath::Gaus(x,[0],[1])",mass_sig-8*resolution,mass_sig+8*resolution);

  TF1* fit_acceff;

  fit_acceff = new TF1("fit_acceff","[0]+[1]/(x+[2])+[3]*x",mass_min,mass_max);  
  fit_acceff->SetParameter(0,7.55423e-01);
  fit_acceff->SetParameter(1,-8.69475e+01);  
  fit_acceff->SetParameter(2,6.13939e+01);
  fit_acceff->SetParameter(3,-3.29666e-05); 
 
  double xsec=1.0;

  for(int k=0;k<num_samples;k++)
    {
      TH1F* signal_temp;
      
      sprintf(file_title,"root_out/out_mass_%d.root",(int)mass_sig);

      sprintf(dir_title,"txt_out/normalization_Mass_%d_input_histos.txt",(int)mass_sig);

      ofstream myfile_temp;
     
      //cout << "Mass point: " << mass_sig << endl;

      myfile_temp.open(dir_title);

      TFile* outfile_signal = new TFile(file_title,"recreate");
      outfile_signal->cd();

      resolution=mass_sig*(fit_resolution->Eval(mass_sig));
      double acceff=fit_acceff->Eval(mass_sig);

      limit_lower=mass_sig-6*resolution;
      limit_upper=mass_sig+6*resolution;
      
      //cout << "limit low: " << limit_lower << endl;
      //cout << "limit up: " << limit_upper << endl;     


      if(mass_sig>=800.)limit_upper=4950.;
      bin_limit_lower=(int)limit_lower;
      bin_limit_upper=(int)limit_upper;	


      int counter_histos=0;

      TKey *key;
      TIter next(outfile->GetListOfKeys());

      while ((key = (TKey*)next())) {

	TH1 *h1 = (TH1*)key->ReadObj();
	TString *name = new TString(h1->GetName());
	
        //cout << "TString " << name->Data() << endl;

	for(int n=1;n<(bin_limit_lower);n++)
	  {
	    h1->SetBinContent(n,0.);
	    h1->SetBinError(n,0.);	    
	  }
	for(int m=(bin_limit_upper+1);m<bin_limit_max_histo;m++)
	  {
	    h1->SetBinContent(m,0.);
	    h1->SetBinError(m,0.);	    
	  }	


	myfile_temp << "bkg " << "bkg_tot" << " " << h1->Integral(1,bin_limit_max_histo) << "\n"; 

	h1->Write("bkg_tot");
	h1->Write("data_obs");

	num_total[k]=h1->Integral(1,bin_limit_max_histo);

	counter_histos++;

	delete name;
	delete h1;

      }

      //set the signal PDFs here

 
      sprintf(file_title,"LQD_001_LLE_001_MSnl_%d",(int)mass_sig);

      get_environment(file_title);
	  
      //xsec=fit_xsec->Eval(mass_sig)/1000.;
      
      xsec=BGcrosssection;
      
      gauss->SetParameter(0,mass_sig);
      gauss->SetParameter(1,resolution);      
      
      signal_temp=new TH1F("signal_temp","",bin_limit_max_histo,0.,(double)bin_limit_max_histo); 	  
      signal_temp->FillRandom("gauss",5000);
      signal_temp->Sumw2();
      signal_temp->Scale(xsec*BGweight*acceff*lumi_scale/5000.);
       
  //cout << "signal xsec: " << xsec << endl;

  for(int n=1;n<(bin_limit_lower);n++)
    {
      signal_temp->SetBinContent(n,0.);
      signal_temp->SetBinError(n,0.);
    }
  for(int m=(bin_limit_upper+1);m<bin_limit_max_histo;m++)
    {
      signal_temp->SetBinContent(m,0.);
      signal_temp->SetBinError(m,0.);	    
    }
  
  cout << "signal mass: " << mass_sig << " N events: " << signal_temp->Integral(1,bin_limit_max_histo) << endl; 

  num_signal[k]=signal_temp->Integral(1,bin_limit_max_histo);

  outfile_signal->cd();
  signal_temp->Write("signal");

  myfile << "signal " << mass_sig << " " << signal_temp->Integral(1,bin_limit_max_histo) << "\n";
  myfile_temp << "signal " << mass_sig << " " << signal_temp->Integral(1,bin_limit_max_histo) << "\n";

  masses[k]=mass_sig;

  mass_sig += step_size;
      
  delete signal_temp;

  myfile_temp.close();

}


      TGraphErrors* graph_tot=new TGraphErrors(N_points,masses,num_total);      
      TGraphErrors* graph_signal=new TGraphErrors(N_points,masses,num_signal);            


      graph_tot->SetLineWidth(2);
      graph_tot->SetMarkerStyle(21);
      graph_tot->SetMarkerSize(1.0);      
      graph_tot->SetLineColor(2);   

      graph_signal->SetLineWidth(2);
      graph_signal->SetMarkerStyle(21);
      graph_signal->SetMarkerSize(1.0);      
      graph_signal->SetLineColor(4);  

 
      graph_tot->Draw("Al,same");   
      graph_signal->Draw("l,same");  

      TLegend *leg_example = new TLegend(0.5,0.7,0.9,0.9);
      leg_example->SetFillColor(0);
      leg_example->SetTextFont(42);

      leg_example->AddEntry(graph_tot, "background","l"); 
      leg_example->AddEntry(graph_signal, "RPV signal LLE=LQD=0.01","l");
      leg_example->Draw("same");


      //close the output txt file:
      myfile.close();
    
      delete gauss;

}


