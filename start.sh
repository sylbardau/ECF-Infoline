#!/bin/bash
# start.sh - installation de l'infra InfoLine sur AWS

echo ">>> 1. Terraform apply..."
cd Terraform && terraform apply -auto-approve && cd ..

if [ $? -ne 0 ]; then
  echo ">>> ERREUR : terraform apply a échoué. Arrêt du script."
  exit 1
fi

echo ">>> Infra construite. Bonjour !"

echo ">>> 2. Connexion kubectl..."
aws eks update-kubeconfig --region eu-west-3 --name infoline-cluster

echo ">>> 3. Installation ECK..."
kubectl create -f https://download.elastic.co/downloads/eck/3.4.1/crds.yaml
kubectl apply -f https://download.elastic.co/downloads/eck/3.4.1/operator.yaml

echo ">>> 4. Déploiement des manifestes..."
kubectl create namespace infoline --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -f K8s/elasticsearch.yaml

echo ">>> Cluster prêt !"
kubectl get nodes
kubectl get pods -A

echo ">>> vérification de l'etat"
kubectl get elasticsearch -n infoline

echo ">>> récupération du mot de passe elastic"
kubectl kubectl get secret infoline-es-es-elastic-user -n infoline -o jsonpath='{.data.elastic}' | base64 --decode; echo/s