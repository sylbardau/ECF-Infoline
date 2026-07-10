#!/bin/bash
# stop.sh - Destruction de l'infra InfoLine

echo ">>> Terraform destroy..."
cd Terraform && terraform destroy -auto-approve

echo ">>> Infra détruite. Bonne soirée !"
