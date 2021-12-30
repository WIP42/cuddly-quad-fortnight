#!/bin/bash
for POD in $(kubectl get pods|grep elasticsearch|awk '{print $1}');do
  kubectl port-forward "$POD" 9200:9200 &
  #sleep 20;
  echo "Please <<<WAIT FOR>>> 'Forwarding from...' message and <<<PRESS ENTER>>> to continue with forwarded ports connected to pod: '$POD'";echo '';
  read a;

  echo "Reenable shard allocation";echo '';
  curl -X PUT "localhost:9200/_cluster/settings?pretty" -H 'Content-Type: application/json' -d' {"persistent": {"cluster.routing.allocation.enable": null}}';

  echo "Restart machine learning jobs";echo '';
  curl -X POST "localhost:9200/_ml/set_upgrade_mode?enabled=false&pretty";

  #echo "Press Ctrl-C to stop port forwarding from $POD"
  #fg;
  kill -9 "$(pgrep -f "port-forward $POD 9200:9200")";
done

