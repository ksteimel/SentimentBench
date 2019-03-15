#!/bin/bash
# curl -O http://ai.stanford.edu/~amaas/data/sentiment/aclImdb_v1.tar.gz
curl -O https://ksteimel.duckdns.org/assets/documents/aclImdb_v1.tar.gz
tar -xzvf aclImdb_v1.tar.gz
#the unsupervised portion isn't used for this benchmark so I will be dropping it
rm -rf aclImdb/train/unsup
