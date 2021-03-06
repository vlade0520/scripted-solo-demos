source ./env.sh


### Set up cluster 1

kubectl --context $CLUSTER_1 create -f resources/$ADMIRAL_VERSION/remotecluster.yaml
kubectl --context $CLUSTER_1 create -f resources/$ADMIRAL_VERSION/demosinglecluster.yaml


### Set up cluster 2

kubectl --context $CLUSTER_2 create -f resources/$ADMIRAL_VERSION/remotecluster.yaml


### Create secrets for cluster 1 and 2 on the management plane cluster
./resources/scripts/cluster-secret.sh $CLUSTER_1 $CLUSTER_1 admiral
./resources/scripts/cluster-secret.sh $CLUSTER_1 $CLUSTER_2 admiral