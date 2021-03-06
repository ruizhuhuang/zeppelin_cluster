#/bin/bash
#prepare and run zeppelin 

echo "Prepare to run Zeppelin in $1 with spark at $2"
export ZEPPELIN_HOME=$1

export Z_LOCAL=~/.zeppelin
export SPARK_MASTER_URL=$2

export PREMIUM_LIB=\"/work/00791/xwj/EnviroTyping/premium/Rlibs/stampede2\"


# add PREMIUM_LIB as the first search path for R lib 
echo  ".libPaths(c($PREMIUM_LIB, .libPaths()))" > ~/.Rprofile

#echo $SPARK_MASTER_URL $2

EXEC=${ZEPPELIN_HOME}/bin/zeppelin-daemon.sh


APP_PID=(`ps aux | grep "ZeppelinServer" | awk '{print $2}'`)
if [  ${#APP_PID[@]} -ge 2 ]; then
  echo "There are existing ZeppelinServer process (${APP_PID[0]}) running on this node, Pleae quit it first."
  return 
fi


# move .zeppelin to user's home directory
if [ ! -d "$Z_LOCAL" ]; then
  mkdir -p $Z_LOCAL
  cp -r $ZEPPELIN_HOME/.zeppelin/* $Z_LOCAL
fi

#echo sed -i "s/export MASTER=.*/export MASTER=$SPARK_MASTER_URL/g" $Z_LOCAL/conf/zeppelin-env.sh
echo sed -i 's/export MASTER=.*/export MASTER=$SPARK_MASTER_URL/mg; s#export SPARK_SUBMIT_OPTIONS=.*#export SPARK_SUBMIT_OPTIONS="--master yarn --deploy-mode client --driver-memory 4g  --executor-memory 3g --num-executors 12 --executor-cores 2 --conf spark.r.command=$TACC_R_BIN/Rscript --conf spark.executor.extraLibraryPath=$LD_LIBRARY_PATH"#mg' $Z_LOCAL/conf/zeppelin-env.sh
sed -i 's/export MASTER=.*/export MASTER=$SPARK_MASTER_URL/mg; s#export SPARK_SUBMIT_OPTIONS=.*#export SPARK_SUBMIT_OPTIONS="--master yarn --deploy-mode client --driver-memory 4g  --executor-memory 3g --num-executors 12 --executor-cores 2 --conf spark.r.command=$TACC_R_BIN/Rscript --conf spark.executor.extraLibraryPath=$LD_LIBRARY_PATH"#mg' $Z_LOCAL/conf/zeppelin-env.sh

# add LD_LIBRARY_PATH for R to work
# echo sed -i 's#export SPARK_SUBMIT_OPTIONS=.*#export SPARK_SUBMIT_OPTIONS="--master yarn --deploy-mode client --driver-memory 4g  --executor-memory 3g --num-executors 12 --executor-cores 2 --conf spark.r.command=$TACC_R_BIN/Rscript --conf spark.executor.extraLibraryPath=$LD_LIBRARY_PATH"#g; s#export SPARK_SUBMIT_OPTIONS=.*#export SPARK_SUBMIT_OPTIONS="--master yarn --deploy-mode client --driver-memory 4g  --executor-memory 3g --num-executors 12 --executor-cores 2 --conf spark.r.command=$TACC_R_BIN/Rscript --conf spark.executor.extraLibraryPath=$LD_LIBRARY_PATH"#g' $Z_LOCAL/conf/zeppelin-env.sh
#sed -i 's#export SPARK_SUBMIT_OPTIONS=.*#export SPARK_SUBMIT_OPTIONS="--master yarn --deploy-mode client --driver-memory 4g  --executor-memory 3g --num-executors 12 --executor-cores 2 --conf spark.r.command=$TACC_R_BIN/Rscript --conf spark.executor.extraLibraryPath=$LD_LIBRARY_PATH"#g' $Z_LOCAL/conf/zeppelin-env.sh

if [ -f "$Z_LOCAL/conf/interpreter.json" ]; then
        sed -i "s/\"master\":.*/\"master\": \"$SPARK_MASTER_URL\",/g" $Z_LOCAL/conf/interpreter.json
fi

#########################################################
# comment out if don't need NLP jar
# source $ZEPPELIN_HOME/load_nlp_jar.sh $Z_LOCAL
#########################################################

rm -rf ${Z_LOCAL}/zeppelin.lock 
LOCAL_RS_PORT=8080

echo $EXEC --config ${Z_LOCAL}/conf/ start 
$EXEC --config ${Z_LOCAL}/conf/ start

MY_PID=$$
APP_PID=(`ps aux | grep "ZeppelinServer" | awk '{print $2}'`)
if [  ${#APP_PID[@]} -eq 1 ]; then
  echo "ZeppelinServer failed to start"
  return
else
  echo "$SLURM_JOBID ${APP_PID[0]} $NODE_HOSTNAME $MY_PID" > ${Z_LOCAL}/zeppelin.lock
fi


#just wait 30 seconds for zeppelin server to start 
sleep 30 
#if [ -f "$Z_LOCAL/conf/interpreter.json" ]; then 
#	sed -i "s/\"master\":.*/\"master\":\"$SPARK_MASTER_URL\"/g" $Z_LOCAL/conf/interpreter.json 
#fi
LOGIN_RS_PORT=`awk -v min=51000 -v max=60000 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
#ssh -f -g -N -R $LOGIN_RS_PORT:127.0.0.1:$LOCAL_RS_PORT login1
CLUSTER=`hostname | cut -d "." -f 2-`
ssh -f -g -N -R $LOGIN_RS_PORT:127.0.0.1:$LOCAL_RS_PORT login1

echo "Zeppelin UI is at http://${CLUSTER}:$LOGIN_RS_PORT"







