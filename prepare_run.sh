#!/bin/sh

if [ $# -ne 4 ] && [ $# -ne 5 ] 
then
    echo "usage: ./prepare_run.sh ${input_dir} ${mass_min} ${mass_max} ${mass_binning} <no_delete_flag>"
    exit 0
fi

mass_min=$2
mass_max=$3
mass_binning=$4

n_tries_expected=25
n_tries_observed=100
#n_toys_tot=n_toys_single*n_toys_files
n_toys_single=5
n_toys_files=50
TWOn_toys_files=50

mass=${mass_min}

if [ $# -eq 4 ]
then
    if [ -e $1/run.sh ]
	then
	rm -f $1/run.sh
    fi
    
    touch $1/run.sh
    chmod u+x $1/run.sh

    if [ -e $1/run_condor.sh ]
	then
	rm -f $1/run_condor.sh
    fi

    touch $1/run_condor.sh
    chmod u+x $1/run_condor.sh
fi

    while [ $mass -le ${mass_max} ] 
      do
      
      if [ -e $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}.sh ]
	  then
	  rm -f $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}.sh
      fi
      
      touch $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_expected.sh
      touch $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_observed.sh

      echo "cd /user/gueth/limits_soeren/$1/output_masses/Mass_${mass}_output/" >> $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_expected.sh
      echo "cd /user/gueth/limits_soeren/$1/output_masses/Mass_${mass}_output/" >> $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_observed.sh

      echo "combine -M MarkovChainMC -H ProfileLikelihood EmuSpectrum_input_histos.txt --tries ${n_tries_observed} -s -1 -m 50 -n observed > /dev/null" >> $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_observed.sh

      Nfiles=0
      while [ $Nfiles -le ${n_toys_files} ]
      do
	echo "combine -M MarkovChainMC -H ProfileLikelihood EmuSpectrum_input_histos.txt --tries ${n_tries_expected} -t ${n_toys_single} -s -1 > /dev/null" >> $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_expected.sh
	let Nfiles=$Nfiles+1
      done

      chmod u+x $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_expected.sh
      chmod u+x $1/output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_observed.sh     

      echo "nohup ./output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_expected.sh &" >> $1/run.sh

      #now setup for condor

      if [ -e $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_expected.sh ]
	  then
	  rm -f $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_expected.sh
      fi
     if [ -e $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_observed.sh ]
	  then
	  rm -f $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_observed.sh
      fi
      
      touch $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_expected.sh

      sed -e s/@TRY@/${n_tries_expected}/g -e s/@TOY@/${n_toys_single}/g -e s/@DIR@/${1}/g -e s/@MASS@/${mass}/g run_limit_condor_template.cfg >> $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}.cfg
      sed -e s/@TRY@/${n_tries_observed}/g -e s/@DIR@/${1}/g -e s/@MASS@/${mass}/g run_limit_condor_template_observed.cfg >> $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_observed.cfg

      echo "cd /user/gueth/limits_soeren/$1/output_masses/Mass_${mass}_output/condor" >> $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_expected.sh
      echo "cd /user/gueth/limits_soeren/$1/output_masses/Mass_${mass}_output/condor" >> $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_observed.sh
      Nfiles=0
      while [ $Nfiles -le ${n_toys_files} ]
      do
	echo "condor_submit run_limit_condor_Mass_${mass}.cfg" >> $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_expected.sh
	echo "sleep 1" >> $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_expected.sh
	let Nfiles=$Nfiles+1
      done
      echo "condor_submit run_limit_condor_Mass_${mass}_observed.cfg" >> $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_observed.sh

      chmod u+x $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_expected.sh
      chmod u+x $1/output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_observed.sh

      echo "nohup ./output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_expected.sh &" >> $1/run_condor.sh
      echo "sleep ${TWOn_toys_files}" >> $1/run_condor.sh

      let mass=$mass+${mass_binning}
      done

   
    mass=${mass_min}
  
    while [ $mass -le ${mass_max} ] 
      do

      echo "nohup ./output_masses/Mass_${mass}_output/condor/run_limit_condor_Mass_${mass}_observed.sh &" >> $1/run_condor.sh	
      echo "sleep ${n_toys_files}" >> $1/run_condor.sh
      echo "nohup ./output_masses/Mass_${mass}_output/run_limit_Mass_${mass}_observed.sh &" >> $1/run.sh

      let mass=$mass+${mass_binning}
      done

exit