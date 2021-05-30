#!/bin/bash

## Download large figure datasets that could not be hosted on GitHub.

## Requirements:
###  wget executable

# Fig1_data
wget https://zenodo.org/record/4855526/files/Fig1_data.zip
# Fig4_data
wget https://zenodo.org/record/4855526/files/Fig4_data.zip
# SuppFig2_data
wget https://zenodo.org/record/4855526/files/SuppFig2_data.zip
# SuppFig4_data
wget https://zenodo.org/record/4855526/files/SuppFig4_data.zip


## unzip all datasets
for file in *.zip
do
  unzip $file
done

## clean up
rm -r __MACOSX/
