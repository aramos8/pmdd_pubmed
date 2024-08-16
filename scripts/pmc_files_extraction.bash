#!/bin/bash

## A bash script to extract all the PMC files obtained through their FTP service
## Adapted from https://askubuntu.com/questions/1240999/extracting-multiple-tar-gz-files-and-copying-the-files-present-in-sub-directorie


for arc in ./*.tar.gz; 
  do 
    tar xvf $arc && \
    for dir in */;
        do
            mv $dir/*.xml  /Volumes/Vault/PMC/PMC_files && \
            rm -r $dir; 
        done
  done
