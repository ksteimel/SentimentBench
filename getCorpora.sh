#!/bin/bash
wget http://ai.stanford.edu/~amaas/data/sentiment/aclImdb_v1.tar.gz
tar -xzvf aclImdb_v1.tar.gz
#the unsupervised portion isn't used for this benchmark so I will be dropping it
rm -rf aclImdb/train/unsup
