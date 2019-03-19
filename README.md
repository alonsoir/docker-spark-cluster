# Spark Cluster with Docker & docker-compose

# General

A simple spark standalone cluster for your testing environment purposses. A *docker-compose up* away from you solution for your spark development environment.

The Docker compose will create the following containers:

container|Ip address
---|---
spark-master|10.5.0.2
spark-worker-1|10.5.0.3
spark-worker-2|10.5.0.4
spark-worker-3|10.5.0.5

# Installation

The following steps will make you run your spark cluster's containers.

## Pre requisites

* Docker installed

* Docker compose  installed

* A spark Application Jar to play with(Optional)

## Build the images

The first step to deploy the cluster will be the build of the custom images, these builds can be performed with the *build-images.sh* script. 

The executions is as simple as the following steps:

```sh
chmod +x build-images.sh
./build-images.sh
```

This will create the following docker images:

* spark-base:2.3.1: A base image based on java:alpine-jdk-8 wich ships scala, python3 and spark 2.3.1

* spark-master:2.3.1: A image based on the previously created spark image, used to create a spark master containers.

* spark-worker:2.3.1: A image based on the previously created spark image, used to create spark worker containers.

* spark-submit:2.3.1: A image based on the previously created spark image, used to create spark submit containers(run, deliver driver and die gracefully).

## Run the docker-compose

The final step to create your test cluster will be to run the compose file:

```sh
docker-compose up
```

## Validate your cluster

Just validate your cluster accesing the spark UI on each worker & master URL.

### Spark Master

http://10.5.0.2:8080/

![alt text](docs/spark-master.png "Spark master UI")

### Spark Worker 1

http://10.5.0.3:8081/

![alt text](docs/spark-worker-1.png "Spark worker 1 UI")

### Spark Worker 2

http://10.5.0.4:8081/

![alt text](docs/spark-worker-2.png "Spark worker 2 UI")

### Spark Worker 3

http://10.5.0.5:8081/

![alt text](docs/spark-worker-3.png "Spark worker 3 UI")

# Resource Allocation 

This cluster is shipped with three workers and one spark master, each of these has a particular set of resource allocation(basically RAM & cpu cores allocation).

* The default CPU cores allocation for each spark worker is 1 core.

* The default RAM for each spark-worker is 1024 MB.

* The default RAM allocation for spark executors is 256mb.

* The default RAM allocation for spark driver is 128mb

* If you wish to modify this allocations just edit the env/spark-worker.sh file.

# Binded Volumes

To make app running easier I've shipped two volume mounts described in the following chart:

Host Mount|Container Mount|Purposse
---|---|---
/tmp/spark-apps|/opt/spark-apps|Used to make available your app's jars on all workers & master
/tmp/spark-data|/opt/spark-data| Used to make available your app's data on all workers & master

This is basically a dummy DFS created from docker Volumes...(maybe not...)

# Run a sample application

Now let`s make a **wild spark submit** to validate the distributed nature of our new toy following these steps:

## Create a Scala spark app

The first thing you need to do is to make a spark application. Our spark-submit image is designed to run scala code (soon will ship pyspark support guess I was just lazy to do so..).

In my case I am using the typical word count example from Databricks called  [mini-complete-sample](https://github.com/databricks/learning-spark/tree/master/mini-complete-example).

You can make or use your own scala app, I 've just used this one because I had it at hand. I know, i am too lazy to use another one, but finally i had to adjust it a bit, because it is outdated, spark version, it has to be provided... 
I have added my own jar to this repo, learning-spark-mini-example_2.11-0.0.1.jar, use it.

## Upload a file to do a wordcount from it.

With Docker up and running, you can copy whatever file you want to /tmp/spark-data, in my case, this README.md file.

## Ship your jar & dependencies on the Workers and Master (Running the app using docker)

A necesary step to make a **spark-submit** is to copy your application bundle into all workers, also any configuration file or input file you need.

Luckily for us we are using docker volumes so, you just have to copy your app and configs into /tmp/spark-apps, and your input files into /tmp/spark-files.

```bash
#Copy spark application into all workers's app folder
cp learning-spark-mini-example_2.11-0.0.1.jar /tmp/spark-apps/

#Copy spark application configs into all workers's app folder, if needed.
# cp -r /home/workspace/crimes-app/config /mnt/spark-apps

# Copy the file to be processed to all workers's data folder. I am going to use this README file
cp README.md /tmp/spark-data/
```

## Check the successful copy of the data and app jar (Optional)

This is not a necessary step, just if you are curious you can check if your app code and files are in place before running the spark-submit.

```sh
# Worker 1 Validations
docker exec -ti spark-worker-1 ls -l /opt/spark-apps

docker exec -ti spark-worker-1 ls -l /opt/spark-data

# Worker 2 Validations
docker exec -ti spark-worker-2 ls -l /opt/spark-apps

docker exec -ti spark-worker-2 ls -l /opt/spark-data

# Worker 3 Validations
docker exec -ti spark-worker-3 ls -l /opt/spark-apps

docker exec -ti spark-worker-3 ls -l /opt/spark-data
```
After running one of this commands you have to see your app's jar and files.


## Use docker spark-submit

```bash
#Creating some variables to make the docker run command more readable. (bash)
#App jar environment used by the spark-submit image
SPARK_APPLICATION_JAR_LOCATION="/opt/spark-apps/learning-spark-mini-example-2.11-0.0.1.jar"
# I am using fish shell, so in my particular case, i have to use:
set SPARK_APPLICATION_JAR_LOCATION /opt/spark-apps/learning-spark-mini-example-2.11-0.0.1.jar
#App main class environment used by the spark-submit image
SPARK_APPLICATION_MAIN_CLASS="com.oreilly.learningsparkexamples.mini.scala.WordCount"
set SPARK_APPLICATION_MAIN_CLASS com.oreilly.learningsparkexamples.mini.scala.WordCount
# Extra submit args used by the spark-submit image
# SPARK_SUBMIT_ARGS="--conf spark.executor.extraJavaOptions='-Dconfig-path=/opt/spark-apps/dev/config.conf'"
set SPARK_SUBMIT_ARGS "spark.executor.extraJavaOptions=-XX:+PrintGCDetails -XX:+PrintGCTimeStamps"

#We have to use the same network as the spark cluster(internally the image resolves spark master as spark://spark-master:7077)

docker run --network docker-spark-cluster_spark-network -v /tmp/spark-apps:/opt/spark-apps --env SPARK_APPLICATION_JAR_LOCATION=$SPARK_APPLICATION_JAR_LOCATION --env SPARK_APPLICATION_MAIN_CLASS=$SPARK_APPLICATION_MAIN_CLASS spark-submit:2.4.0

```

After running this you will see an output pretty much like this:

```bash
Running Spark using the REST application submission protocol.
2018-09-23 15:17:52 INFO  RestSubmissionClient:54 - Submitting a request to launch an application in spark://spark-master:6066.
2018-09-23 15:17:53 INFO  RestSubmissionClient:54 - Submission successfully created as driver-20180923151753-0000. Polling submission state...
2018-09-23 15:17:53 INFO  RestSubmissionClient:54 - Submitting a request for the status of submission driver-20180923151753-0000 in spark://spark-master:6066.
2018-09-23 15:17:53 INFO  RestSubmissionClient:54 - State of driver driver-20180923151753-0000 is now RUNNING.
2018-09-23 15:17:53 INFO  RestSubmissionClient:54 - Driver is running on worker worker-20180923151711-10.5.0.4-45381 at 10.5.0.4:45381.
2018-09-23 15:17:53 INFO  RestSubmissionClient:54 - Server responded with CreateSubmissionResponse:
{
  "action" : "CreateSubmissionResponse",
  "message" : "Driver successfully submitted as driver-20180923151753-0000",
  "serverSparkVersion" : "2.3.1",
  "submissionId" : "driver-20180923151753-0000",
  "success" : true
}
```
## (Troubleshooting. Running the app using spark-submit command)

After you have the jar file inside folder:

~/s/docker-spark-cluster> docker exec -ti spark-master /bin/bash
bash-4.3# ls opt/spark-apps/
learning-spark-mini-example_2.11-0.0.1.jar

bash-4.3# spark/bin/spark-submit --class com.oreilly.learningsparkexamples.mini.scala.WordCount --master spark://spark-master:7077 /opt/spark-apps/learning-spark-mini-example_2.11-0.0.1.jar /opt/spark-data/README.md /opt/spark-data/output-2
...
2019-03-19 12:26:45 WARN  NioEventLoop:146 - Selector.select() returned prematurely 512 times in a row; rebuilding Selector io.netty.channel.nio.SelectedSelectionKeySetSelector@daa72fb.
2019-03-19 12:26:45 INFO  NioEventLoop:101 - Migrated 1 channel(s) to the new Selector.
2019-03-19 12:26:45 INFO  MemoryStore:54 - MemoryStore cleared
2019-03-19 12:26:45 INFO  BlockManager:54 - BlockManager stopped
2019-03-19 12:26:45 INFO  BlockManagerMaster:54 - BlockManagerMaster stopped
2019-03-19 12:26:45 INFO  OutputCommitCoordinator$OutputCommitCoordinatorEndpoint:54 - OutputCommitCoordinator stopped!
2019-03-19 12:26:45 INFO  SparkContext:54 - Successfully stopped SparkContext
2019-03-19 12:26:45 INFO  ShutdownHookManager:54 - Shutdown hook called
2019-03-19 12:26:45 INFO  ShutdownHookManager:54 - Deleting directory /tmp/spark-bec6ba85-f0d5-49dd-8f98-99aab60e4018
2019-03-19 12:26:45 INFO  ShutdownHookManager:54 - Deleting directory /tmp/spark-3d780320-6b6a-49e9-85e4-33ba83f1f8b7

# Summary (What have I done :O?)

* We compiled the necessary docker images to run spark master and worker containers.

* We created a spark standalone cluster using 3 worker nodes and 1 master node using docker && docker-compose.

* Copied the resources necessary to run a sample application.

* Submitted an application to the cluster using a **spark-submit** docker image.

* We ran a distributed application at home(just need enough cpu cores and RAM to do so).

# Why a standalone cluster?

* This is intended to be used for test purposses, basically a way of running distributed spark apps on your laptop or desktop.

* Right now I don't have enough resources to make a Yarn, Mesos or Kubernetes based cluster :(.

* This will be useful to use CI/CD pipelines for your spark apps(A really difficult and hot topic)

# TODO

* Update spark version from 2.3.1 to 2.4.0. DONE!
* Change /mnt to /tmp in order to work within OSX. DONE!

# TROUBLESHOOTING

* Make sure that the test jar is compiled with the spark cluster version, in this case I write this, it is version 2.4.0 and make sure you also use provided in the pom.xml to make sure you are also using the spark jar hosted in the spark cluster driver and workers.

* Currently, to launch the work, I have to log into the spark driver and launch the work using the following command:

spark/bin/spark-submit --class com.oreilly.learningsparkexamples.mini.scala.WordCount --master spark://spark-master:7077 /opt/spark-apps/learning-spark-mini-example_2.11-0.0.1.jar /opt/spark-data/README.md /opt/spark-data/output



