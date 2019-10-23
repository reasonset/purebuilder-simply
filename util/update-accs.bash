#!/bin/bash

for i in "$@"
do
  pbsimply-pandoc.rb "$i"
  pbsimply-accsindex.rb "$i"
done