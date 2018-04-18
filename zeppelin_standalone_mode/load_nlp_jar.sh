#!/bin/bash

export Z_LOCAL=$1

sed -i 's#export SPARK_SUBMIT_OPTIONS=.*#export SPARK_SUBMIT_OPTIONS="--master $MASTER --driver-memory 4g  --executor-memory 2g --num-executors 12 --executor-cores 2 --conf spark.jars=/home/00791/xwj/lib/spark-corenlp_2.11-0.3.0.jar,/home/00791/xwj/lib/stanford-english-corenlp-2016-10-31-models.jar --conf spark.jars.packages=edu.stanford.nlp:stanford-corenlp:3.7.0 --conf spark.jars.excludes=org.apache.commons:commons-lang3"#g' $Z_LOCAL/conf/zeppelin-env.sh
