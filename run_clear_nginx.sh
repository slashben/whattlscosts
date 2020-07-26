#!/bin/bash
SERVER_YAML=yamls/clear-nginx/nginx-server.yaml
TESTER_YAML=yamls/jmeter/jmeter-master.yaml
TESTER_CERTIFICATE=yamls/jmeter/certificate.jks
TESTER_FILE_SMALL=yamls/jmeter/small.jmx
TESTER_FILE_MEDIUM=yamls/jmeter/medium.jmx
TESTER_FILE_BIG=yamls/jmeter/big.jmx
NAMESPACE=clear-nginx

# Clean up if missed for some reason
kubectl delete namespace $NAMESPACE &> /dev/null
kubectl create namespace $NAMESPACE || exit 1

kubectl -n $NAMESPACE create configmap jmeter-test-conf-extra --from-file=certificate.jks=$TESTER_CERTIFICATE --from-file=small.jmx=$TESTER_FILE_SMALL --from-file=medium.jmx=$TESTER_FILE_MEDIUM --from-file=big.jmx=$TESTER_FILE_BIG || exit 1
kubectl -n $NAMESPACE apply -f $SERVER_YAML || exit 1
kubectl -n $NAMESPACE apply -f $TESTER_YAML || exit 1

sudo rm -rf /tmp/jmetertestlogs/*
sleep 30

kubectl -n $NAMESPACE get pods
TESTER_SMALL_COMMAND="jmeter -n -t /test-extra/small.jmx -q /test/user.properties -JThreads=4 -JHttpMethod=http -JDuration=120 -l /tmp/test_small.jtl -e -o /tmp/test_small_html"
TESTER_MEDIUM_COMMAND="jmeter -n -t /test-extra/medium.jmx -q /test/user.properties -JThreads=4 -JHttpMethod=http -JDuration=120 -l /tmp/test_medium.jtl -e -o /tmp/test_medium_html"
TESTER_BIG_COMMAND="jmeter -n -t /test-extra/big.jmx -q /test/user.properties -JThreads=4 -JHttpMethod=http -JDuration=120 -l /tmp/test_big.jtl -e -o /tmp/test_big_html"
TESTER_POD=`kubectl -n $NAMESPACE get pods -o name | grep jmeter`

echo "Start of benchmarking"

kubectl -n $NAMESPACE exec $TESTER_POD -- $TESTER_SMALL_COMMAND
kubectl -n $NAMESPACE exec $TESTER_POD -- $TESTER_MEDIUM_COMMAND
kubectl -n $NAMESPACE exec $TESTER_POD -- $TESTER_BIG_COMMAND

echo "End of benchmarking"

#read -p "Press any key to resume ..."

echo "Small results"
python3 summarize.py /tmp/jmetertestlogs/test_small.jtl
echo "Medium results"
python3 summarize.py /tmp/jmetertestlogs/test_medium.jtl
echo "Big results"
python3 summarize.py /tmp/jmetertestlogs/test_big.jtl

# Clean up the mess... ;)
kubectl delete namespace $NAMESPACE

