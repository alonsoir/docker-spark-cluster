#Copy spark application into all workers's app folder
cp learning-spark-mini-example_2.11-0.0.1.jar /tmp/spark-apps/

#Copy spark application configs into all workers's app folder, if needed.
# cp -r /home/workspace/crimes-app/config /mnt/spark-apps

# Copy the file to be processed to all workers's data folder. I am going to use this README file
cp README.md /tmp/spark-data/

# Worker 1 Validations
docker exec -ti spark-worker-1 ls -l /opt/spark-apps

docker exec -ti spark-worker-1 ls -l /opt/spark-data

# Worker 2 Validations
docker exec -ti spark-worker-2 ls -l /opt/spark-apps

docker exec -ti spark-worker-2 ls -l /opt/spark-data

# Worker 3 Validations
docker exec -ti spark-worker-3 ls -l /opt/spark-apps

docker exec -ti spark-worker-3 ls -l /opt/spark-data

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

docker run --network docker-spark-cluster_spark-network -v /tmp/spark-apps:/opt/spark-apps --env SPARK_APPLICATION_ARGS="/opt/spark-data/README.md /opt/spark-data/output-7" --env SPARK_APPLICATION_JAR_LOCATION=$SPARK_APPLICATION_JAR_LOCATION --env SPARK_APPLICATION_MAIN_CLASS=$SPARK_APPLICATION_MAIN_CLASS spark-submit:2.4.0


