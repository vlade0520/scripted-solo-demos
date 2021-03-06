#!/bin/bash

. $(dirname ${BASH_SOURCE})/../../util.sh

SOURCE_DIR=$PWD

desc "Canary analysis with Gloo and Flagger"
run "kubectl -n test get pod"

desc "Deploy podinfo app and hpa"
run "kubectl -n test apply -f $(relative deployment.yaml)"

desc "Run load generator"
run "helm upgrade -i flagger-loadtester flagger/loadtester --namespace=test"
run "kubectl -n test get pod -w"
backtotop

PODNAME=$(kubectl get pod -n test | grep podinfo | awk '{ print $1}')
desc "Call podinfo locally with curl"
run "kubectl -n test exec -it $PODNAME curl localhost:9898"
backtotop

backtotop

run "cat $(relative gloo-vs.yaml)"
run "kubectl -n test apply -f $(relative gloo-vs.yaml)"
run "kubectl -n test get virtualservice "
backtotop

desc "Define the canary parameters"
run "cat $(relative podinfo-canary.yaml)"
backtotop

run "kubectl apply -f $(relative podinfo-canary.yaml)"
backtotop

run "watch kubectl get canaries -n test"
backtotop

URL=$(glooctl proxy url)
tmux split-window -v -d -c $SOURCE_DIR
tmux select-pane -t 0
tmux send-keys -t 1 "while true; do curl $URL; sleep .5; done" C-m

read -s
# should we show all the artifacts it creates?
desc "See all of the artifacts that flagger ceated to drive the traffic control loop"
run "kubectl -n test get deploy"
run "kubectl -n test get svc"
run "kubectl -n test get upstreamgroup -o yaml"

backtotop

desc "Let's trigger a canary by changing the deployment (change to a new docker image)"
run "kubectl -n test set image deployment/podinfo podinfod=quay.io/stefanprodan/podinfo:1.4.1"
backtotop

desc "Let's watch the flagger events as it detects the change and spins out a canary"
run "kubectl -n test describe canary/podinfo"

run "watch kubectl get canaries -n test"
backtotop

desc "Rollback"
run "kubectl -n test set image deployment/podinfo podinfod=quay.io/stefanprodan/podinfo:1.4.2"

tmux send-keys -t 1 C-c
read -s

tmux send-keys -t 1 "while true; do curl $URL/status/500; sleep .5; done" C-m

run "watch kubectl get canaries -n test"