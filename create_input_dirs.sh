#!/bin/bash

if [ $# -ne 4 ]
then
    echo "Please give the name of the directory and input for the mass settings ..."
    exit 0
fi

step_size=$4

massStart=$2
massMax=$3

  if ! [ -d $1 ]
      then
      mkdir $1
      mkdir $1/input_masses
      mkdir $1/output_masses
      else
          if [ -d $1/input_masses ]
	      then
	      echo "$1/input_masses already exists! Check if this is o.k."
#	      rm -rf $1/input_masses/*
	      else
	      mkdir $1/input_masses
	  fi
          if [ -d $1/output_masses ]
	      then
	      echo "$1/output_masses already exists! Check if this is o.k."
#	      rm -rf $1/output_masses/*
	      else
	      mkdir $1/output_masses
	  fi
  fi


while [ $massStart -le $massMax ]
do

  #create in-out-directories

  if ! [ -d $1/input_masses/Mass_${massStart}_input ]
      then
      mkdir $1/input_masses/Mass_${massStart}_input 
      
  fi    
  if ! [ -d $1/output_masses/Mass_${massStart}_output ]
      then
      mkdir $1/output_masses/Mass_${massStart}_output
      mkdir $1/output_masses/Mass_${massStart}_output/condor
  fi    

cp root_out/out_mass_${massStart}.root $1/input_masses/Mass_${massStart}_input
cp txt_out/normalization_Mass_${massStart}_input_histos.txt $1/input_masses/Mass_${massStart}_input  

cp root_out/out_mass_${massStart}.root $1/output_masses/Mass_${massStart}_output
cp txt_out/normalization_Mass_${massStart}_input_histos.txt $1/output_masses/Mass_${massStart}_output



  let massStart=$massStart+${step_size}

done

exit 0