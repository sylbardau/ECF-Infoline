#!/bin/bash
NAMESPACE="infoline"

echo ">>> Vérification que Kibana est opérationel"
if ! kubectl get svc infoline-kb-kb-http -n "$NAMESPACE" &>/dev/null; then
  echo ">>> ERREUR : le service Kibana n'existe pas. As-tu lancé start.sh ?"
  exit 1
fi

echo ">>> Mot de passe 'elastic' :"
kubectl get secret infoline-es-es-elastic-user -n "$NAMESPACE" \
  -o jsonpath='{.data.elastic}' | base64 --decode
echo

echo ">>> Ouverture du tunnel vers Kibana (Ctrl+C pour fermer)..."
echo ">>> https://localhost:5601"
kubectl port-forward -n "$NAMESPACE" svc/infoline-kb-kb-http 5601:5601