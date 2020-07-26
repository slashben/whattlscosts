#!/bin/bash
SERVER_YAML=yamls/tls-nginx/nginx-server.yaml
TESTER_YAML=yamls/jmeter/jmeter-master.yaml
TESTER_CERTIFICATE=yamls/jmeter/certificate.jks
TESTER_FILE_SMALL=yamls/jmeter/small.jmx
TESTER_FILE_MEDIUM=yamls/jmeter/medium.jmx
TESTER_FILE_BIG=yamls/jmeter/big.jmx
NAMESPACE=tls-nginx-nginx

# Clean up if missed for some reason
kubectl delete namespace $NAMESPACE &> /dev/null
kubectl create namespace $NAMESPACE || exit 1

kubectl -n $NAMESPACE create configmap java-certificate-keystore --from-file=keyfile=$TESTER_CERTIFICATE || exit 1
kubectl -n $NAMESPACE create configmap jmeter-testfiles --from-file=small.jmx=$TESTER_FILE_SMALL --from-file=media.jmx=$TESTER_FILE_MEDIUM --from-file=big.jmx=$TESTER_FILE_BIG || exit 1
kubectl -n $NAMESPACE apply -f $SERVER_YAML || exit 1
kubectl -n $NAMESPACE apply -f $TESTER_YAML || exit 1

sudo rm -rf /tmp/jmetertestlogs/test1.jtl /tmp/jmetertestlogs/test1_html
sleep 15

TESTER_COMMAND="jmeter -n -t /test/J4K8sAgentNetTest.jmx -q /test/user.properties -Jserver.rmi.ssl.disable=true -JThreads=4 -JDuration=120 -l /tmp/test1.jtl -e -o /tmp/test1_html"
TESTER_POD=`kubectl -n $NAMESPACE get pods -o name | grep jmeter`

echo "Start of benchmarking"

kubectl -n $NAMESPACE exec $TESTER_POD -- $TESTER_COMMAND

echo "End of benchmarking"

python3 summarize.py /tmp/jmetertestlogs/test1.jtl

# Clean up the mess... ;)
kubectl delete namespace $NAMESPACE

