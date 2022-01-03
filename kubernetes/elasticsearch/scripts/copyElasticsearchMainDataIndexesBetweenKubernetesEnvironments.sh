#!/bin/bash
if [ -z "$1" ]; then
  echo "Please enter source Kubernetes CONTEXT as 1st argument like SharedCluster-Prod:";
  read -r S_KUBE_NS;
  if [ -z "$S_KUBE_NS" ]; then
    echo "No source Kubernetes CONTEXT, exit 1";
    exit 1;
  fi
else
  S_KUBE_NS="$1";
fi
if [ -z "$2" ]; then
  echo "Please enter destination Kubernetes CONTEXT as 2nd argument like SharedCluster-Acc:";
  read -r D_KUBE_NS;
  if [ -z "$D_KUBE_NS" ]; then
    echo "No destination Kubernetes CONTEXT, exit 2";
    exit 2;
  fi
else
  D_KUBE_NS="$2";
fi

kubectl config use-context "$S_KUBE_NS";
for POD in $(kubectl get pods|grep elasticsearch-data|awk '{print $1}');do
  kubectl config use-context "$S_KUBE_NS";
  kubectl port-forward "$POD" 9201:9200 &

  kubectl config use-context "$D_KUBE_NS";
  kubectl port-forward "$POD" 9202:9200 &

  #sleep 20;
  echo "### Please <<<WAIT FOR>>> 2 sets of 'Forwarding from...' message and <<<PRESS ENTER>>> to continue with forwarded ports connected to pod: '$POD'";echo '';
  read a;

  echo "### Reading all indexes from";echo '';
  for S_IDX in $(curl http://localhost:9201/_aliases?pretty|grep -v '    "'|grep -v '}'|grep -v '"\.'|grep '"'|awk -F '"' '{print $2}');do
    echo "### $POD has elasticsearch index: '$S_IDX'";echo '';
    echo "### Copying ANALYZER next:";echo '';
    elasticdump \
      --input="http://localhost:9201/$S_IDX" \
      --output="http://localhost:9202/$S_IDX" \
      --type=analyzer
    echo "### Copying MAPPING next:";echo '';
    elasticdump \
      --input="http://localhost:9201/$S_IDX" \
      --output="http://localhost:9202/$S_IDX" \
      --type=mapping
    echo "### Copying DATA next:";echo '';
    elasticdump \
      --input="http://localhost:9201/$S_IDX" \
      --output="http://localhost:9202/$S_IDX" \
      --type=data
  done
  
  kill -9 "$(pgrep -f "port-forward $POD 9201:9200")";
  kill -9 "$(pgrep -f "port-forward $POD 9202:9200")";
done
