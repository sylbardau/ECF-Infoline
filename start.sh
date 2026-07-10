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
  wait_for_health kibana infoline-kb
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
  print_credentials
  print_access_info
}

main