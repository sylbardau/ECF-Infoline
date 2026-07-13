#!/bin/bash
# start.sh - installation de l'infra InfoLine sur AWS

set -uo pipefail

#ajout de variable
NAMESPACE="infoline"
REGION="eu-west-3"
CLUSTER_NAME="infoline-cluster"
ECK_VERSION="3.4.1"

apply_terraform() {
  echo ">>> 1. Terraform apply..."
  (cd Terraform && terraform apply -auto-approve)
  if [ $? -ne 0 ]; then
    echo ">>> ERREUR : terraform apply a échoué. Arrêt du script."
    exit 1
  fi
  echo ">>> Infra construite."
}
connect_kubectl() {
echo ">>> 2. Connexion kubectl..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
}

install_eck() {
  echo ">>> 3. Installation ECK..."
  if ! kubectl get crd elasticsearches.elasticsearch.k8s.elastic.co &>/dev/null; then
    kubectl create -f "https://download.elastic.co/downloads/eck/${ECK_VERSION}/crds.yaml"
  else
    echo "    CRDs déjà présents, skip."
  fi
  kubectl apply -f "https://download.elastic.co/downloads/eck/${ECK_VERSION}/operator.yaml"
}


wait_for_health() {
  local kind=$1 name=$2 timeout=300 interval=10 elapsed=0
  echo ">>> Attente de $kind/$name (health=green)..."
  while [ $elapsed -lt $timeout ]; do
    health=$(kubectl get "$kind" "$name" -n "$NAMESPACE" -o jsonpath='{.status.health}' 2>/dev/null)
    [ "$health" == "green" ] && { echo ">>> $kind/$name prêt (green)."; return 0; }
    echo "    ... ${health:-inconnu} (${elapsed}s/${timeout}s)"
    sleep $interval
    elapsed=$((elapsed + interval))
  done
  echo ">>> ERREUR : $kind/$name pas green après ${timeout}s."
  return 1
}

deploy_elasticsearch() {
  echo ">>> 4. Déploiement Elasticsearch..."
  kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -f K8s/elasticsearch.yaml
  wait_for_health elasticsearch infoline-es
}

deploy_kibana() {
  echo ">>> 5. Déploiement Kibana..."
  kubectl apply -f K8s/kibana.yaml
  if [ $? -ne 0 ]; then
    echo ">>> ERREUR : application du manifest kibana.yaml échouée. Arrêt du script."
    exit 1
  fi
  if ! wait_for_health kibana infoline-kb; then
    echo ">>> ERREUR : Kibana n'est pas prêt. Arrêt du script."
    kubectl get pods -n "$NAMESPACE"
    exit 1
  fi
}

PF_LOG="/tmp/infoline-kibana-portforward.log"
PF_PID_FILE="/tmp/infoline-kibana-portforward.pid"
 
start_port_forward() {
  echo ">>> 6. Lancement du port-forward Kibana en arrière-plan..."
 
  # tue un éventuel port-forward déjà en cours sur ce service pour éviter les conflits
  if [ -f "$PF_PID_FILE" ] && kill -0 "$(cat "$PF_PID_FILE")" 2>/dev/null; then
    echo "    Port-forward déjà actif (PID $(cat "$PF_PID_FILE")), arrêt avant relance."
    kill "$(cat "$PF_PID_FILE")" 2>/dev/null
    sleep 1
  fi
 
  nohup kubectl port-forward -n "$NAMESPACE" svc/infoline-kb-kb-http 5601:5601 \
    > "$PF_LOG" 2>&1 &
  echo $! > "$PF_PID_FILE"
  sleep 2
 
  if kill -0 "$(cat "$PF_PID_FILE")" 2>/dev/null; then
    echo ">>> Port-forward actif (PID $(cat "$PF_PID_FILE"))."
  else
    echo ">>> ERREUR : le port-forward n'a pas démarré. Voir $PF_LOG :"
    cat "$PF_LOG"
    exit 1
  fi
}
 
print_credentials() {
  echo ">>> Mot de passe utilisateur 'elastic' :"
  kubectl get secret infoline-es-es-elastic-user -n "$NAMESPACE" \
    -o jsonpath='{.data.elastic}' | base64 --decode
  echo
}

print_access_info() {
  echo ">>> Accès Kibana :"
  echo "    kubectl port-forward -n $NAMESPACE svc/infoline-kb-kb-http 5601:5601"
  echo "    puis https://localhost:5601 (login: elastic)"
}

main() {
  apply_terraform
  connect_kubectl
  install_eck
  deploy_elasticsearch
  deploy_kibana
  kubectl get pods -n "$NAMESPACE"
  start_port_forward
  print_credentials
  print_access_info
}

main