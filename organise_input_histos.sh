#!/bin/bash

#input txt for limits

if [ $# -ne 2 ]
then
    echo "You have to provide the approach to limit setting as input:
          shape

          AND

          name of the directory used for the limit calculation
          "
    exit 0
fi

echo "MAKE sure that you edited EmuSpectrum_input_histos*.txt which is used as input for the limit calculation!!!!!"
sleep 5

mass_min=300
mass_int_1=500
mass_int_2=700
mass_max=1900

mass_binning=200
mass_binning_2=200
mass_binning_3=200

./create_input_dirs.sh $2 ${mass_min} ${mass_int_1} ${mass_binning}
./create_input_dirs.sh $2 $((${mass_int_1} + ${mass_binning_2})) ${mass_int_2} ${mass_binning_2}
./create_input_dirs.sh $2 $((${mass_int_2} + ${mass_binning_3})) ${mass_max} ${mass_binning_3}

if [ "$1" == "shape" ]
then

    ./prepare_run.sh $2 ${mass_min} ${mass_int_1} ${mass_binning}
    ./prepare_run.sh $2 $((${mass_int_1} + ${mass_binning_2})) ${mass_int_2} ${mass_binning_2} no_delete_flag
    ./prepare_run.sh $2 $((${mass_int_2} + ${mass_binning_3})) ${mass_max} ${mass_binning_3} no_delete_flag    

    if ! [ -f EmuSpectrum_input_histos.txt ]
	then
	echo "file EmuSpectrum_input_histos.txt needed as input is missing. Exiting ..."
	exit 0
    fi
    
    mass=${mass_min}
    
    while [ $mass -le ${mass_max} ] 
      do

      echo $mass

      if [ -d $2/input_masses/Mass_${mass}_input ]
	  then
	  rm -f $2/input_masses/Mass_${mass}_input/*
      else
	  mkdir $2/input_masses/Mass_${mass}_input
      fi

      
      if ! [ -f root_out/out_mass_${mass}.root ]
	  then
	  echo "Did not find root file with histos for mass point: ${mass}"
	  continue
      else
	  cp root_out/out_mass_${mass}.root $2/input_masses/Mass_${mass}_input
	  cp root_out/out_mass_${mass}.root $2/output_masses/Mass_${mass}_output
	  
      fi
      
      if ! [ -f txt_out/normalization_Mass_${mass}_input_histos.txt ]
	  then
	  echo "Did not find normalization txt file with histos for mass point: ${mass}"
	  continue
      else
	  cp txt_out/normalization_Mass_${mass}_input_histos.txt $2/input_masses/Mass_${mass}_input/normalization.txt
      fi  
      
      if [ -f $2/input_masses/Mass_${mass}_input/EmuSpectrum_input_histos.txt ]
	  then
	  rm -f $2/input_masses/Mass_${mass}_input/EmuSpectrum_input_histos.txt
      fi
      
      cp EmuSpectrum_input_histos.txt $2/input_masses/Mass_${mass}_input/tmp.txt
      
      number_signal_events=$(cat $2/input_masses/Mass_${mass}_input/normalization.txt | grep "signal $mass" | awk '{print $3}')
      num_bkg_events=$(cat $2/input_masses/Mass_${mass}_input/normalization.txt | grep "bkg" | awk '{print $3}')
      
      
      
  #rates=`echo @rate_signal@`
      rates=`echo ${number_signal_events} ${num_bkg_events}`

      sed -e s/@root_input_file@/out_mass_${mass}.root/g -e s/@rate_signal@/${number_signal_events}/g -e s/@num_observed_events@/${num_bkg_events}/g -e s/@rates@/"${rates}"/g $2/input_masses/Mass_${mass}_input/tmp.txt >> $2/input_masses/Mass_${mass}_input/EmuSpectrum_input_histos.txt
      
      cp $2/input_masses/Mass_${mass}_input/EmuSpectrum_input_histos.txt $2/output_masses/Mass_${mass}_output/EmuSpectrum_input_histos.txt

      rm -f $2/input_masses/Mass_${mass}_input/tmp.txt
      
      if [ $mass -lt $mass_int_1 ]
	  then
	  let mass=$mass+${mass_binning}
      elif [ $mass -ge $mass_int_1 ] && [ $mass -lt $mass_int_2 ]
	  then
	  let mass=$mass+${mass_binning_2}
      elif [ $mass -ge $mass_int_2 ]
	  then
	  let mass=$mass+${mass_binning_3}
      fi      

    done
    
    if [ -f nohup.out ]
	then
	rm -f nohup.out
    fi

fi


exit