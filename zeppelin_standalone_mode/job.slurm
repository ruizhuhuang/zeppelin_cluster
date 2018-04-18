#!/bin/bash
#SBATCH -J Envirotyping_Analysis	   # job name
#SBATCH -o premium.out        # output and error file name (%j expands to jobID)
#SBATCH -N 3              # total number of nodes
#SBATCH -n 3
#SBATCH -p hadoop   	   # queue (partition) -- normal, development, etc.
#SBATCH -t 8:00:00        # run time (hh:mm:ss) - 4 hours
#SBATCH -A Trump-Tweets_-The-Fi    #TG-CCR150011    # project name


#load R module
module load Rstats


#SPARK_CONF=/etc/spark/conf/
export SPARK_HOME=/work/00791/xwj/maverick/run_spark/spark-2.1.1-bin-hadoop2.7
SPARK_CONF=${SPARK_HOME}/conf
export SPARK_CONF_DIR=~/.spark/$SLURM_JOBID/conf
export ZEPPELIN_HOME=/work/00791/xwj/maverick/run_spark/zeppelin-0.7.1-bin-all

NODE_LIST=`scontrol show hostnames $SLURM_NODELIST`
NODE_HOSTNAME=`hostname`

echo "TACC: NODE_LIST: $NODE_LIST"
echo "TACC: NODE_HOSTNAME: $NODE_HOSTNAME"



#Copy conf templates into ~/.spark/conf
if [ ! -d ~/.spark ]; then
    mkdir ~/.spark
fi

if [ -d ~/.spark/conf ]; then
    rm -rf ~/.spark/conf
fi

mkdir ~/.spark/$SLURM_JOBID
mkdir $SPARK_CONF_DIR
#cp -r $SPARK_CONF/ ~/.spark/conf/
cp $SPARK_CONF/* $SPARK_CONF_DIR

#Update slaves with worker nodes
for n in `echo $NODE_LIST | cut -d " " -f2-`;
do
    echo adding $n
    echo $n >> ${SPARK_CONF_DIR}/slaves
done

#Update spark-defaults.conf
echo "spark.executor.memory   16g" >> ${SPARK_CONF_DIR}/spark-defaults.conf
echo "spark.locality.wait   3000" >> ${SPARK_CONF_DIR}/spark-defaults.conf

#Update spark-env.sh
cat $SPARK_CONF/spark-env.sh | sed "s/TSOHRETSAM/$NODE_HOSTNAME/g" | sed "s/EMITNUR/tmp\/spark/g" > ${SPARK_CONF_DIR}/spark-env.sh

#Set env variable
#export SPARK_CONF_DIR=~/.spark/conf
#export SPARK_HOME=/work/00791/xwj/maverick/run_spark/spark-2.1.1-bin-hadoop2.7

sed -i "/export SPARK_/d" ~/.bashrc
echo "export SPARK_CONF_DIR=$SPARK_CONF_DIR" >> ~/.bashrc
echo "export SPARK_HOME=$SPARK_HOME" >> ~/.bashrc

# chmod /tmp/spark/run and /tmp/spark/log to 777
for n in `echo $NODE_LIST | cut -d " " -f1-`;
do
    echo ssh $n "mkdir -p /tmp/spark/{run,log}; chmod -R 777 /tmp/spark"
    ssh $n "mkdir -p /tmp/spark/{run,log}; chmod -R 777 /tmp/spark"
done

$SPARK_HOME/sbin/start-all.sh

#map application port to login port
#   e.g. port namenode:8088
#WEBUI_RS_PORT="$RS_PORT_PREFIX`echo $NODE_HOSTNAME | perl -ne 'print $1.$2.$3 if /c\d(\d\d)-(\d)\d(\d)/;'`"
LOGIN_RS_PORT=`awk -v min=51000 -v max=60000 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
#echo "TACC: got login node port $HADOOP_RS_PORT for hadoop web UI"
ssh -f -g -N -R $LOGIN_RS_PORT:$NODE_HOSTNAME:18080 login1
LOGIN_RS_PORT2=`awk -v min=51000 -v max=60000 'BEGIN{srand(); print int(min+rand()*(max-min+1))}'`
ssh -f -g -N -R $LOGIN_RS_PORT2:$NODE_HOSTNAME:4040 login1

export SPARK_MASTER_URL="spark:\\/\\/${NODE_HOSTNAME}:7077"
echo "export SPARK_MASTER_URL=spark://${NODE_HOSTNAME}:7077" >> ~/.bashrc

#echo "TACC: got login node port $LOGIN_RS_PORT for application"
echo "SPARK master is running at $SPARK_MASTER_URL"
export LOGIN_NODE=login1.`cut -d "." -f 2- <<< $NODE_HOSTNAME`
echo "Spark cluster UI is at http://$LOGIN_NODE:$LOGIN_RS_PORT"
echo "Spark job UI is at http://$LOGIN_NODE:$LOGIN_RS_PORT2"

source ./start_zeppelin_premium.sh $ZEPPELIN_HOME $SPARK_MASTER_URL

#echo "sleep $(( $SLURM_TACC_RUNLIMIT_MINS * 60)) to hold the cluster alive"
sleep $(( $SLURM_TACC_RUNLIMIT_MINS * 60))

#clean up cluster
$SPARK_HOME/sbin/stop-all.sh
rm -rf /tmp/spark


