#!/bin/bash

# This script needs document directory is already generated (.indexes.rbm is exist)
# and ACCS serial document directory has .accs.yaml configuration file.

find -name ".indexes.rbm" | while read
do
  pbsimply-pandoc.rb "$REPLY"
done

find -name ".accs.yaml" | while read
do
  pbsimply-accsindex.rb "$REPLY"
done