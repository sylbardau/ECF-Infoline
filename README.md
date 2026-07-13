# ECF-Infoline

Projet réalisé dans le cadre de l'ECF DevOps chez STUDI. InfoLine est une application web (frontend Angular + API Spring Boot) déployée sur AWS via une infrastructure Kubernetes (EKS), provisionnée avec Terraform et livrée en continu via GitHub Actions.

## Architecture

```
                         ┌───────────────────────┐
                         │        GitHub         │
                         │  Actions (CI/CD)      │
                         └──────────┬────────────┘
                                    │ build & push images
                                    ▼
                         ┌─────────────────────────┐
                         │  GHCR (ghcr.io)         │
                         │  infoline-api / -front  │
                         └──────────┬──────────────┘
                                    │ kubectl apply
                                    ▼
┌─────────────────────────────── AWS ─────────────────────────────────┐
│  VPC (10.0.0.0/16, 2 AZ eu-west-3a/b)                               │
│                                                                     │
│   ┌─────────────── EKS cluster "infoline-cluster" ────────────────┐ │
│   │  Namespace "infoline"                                         │ │
│   │   - Deployment + HPA: infoline-frontend (nginx, LoadBalancer) │ │
│   │   - Deployment + HPA: infoline-backend (Spring Boot)          │ │
│   │   - Elasticsearch + Kibana (ECK operator)                     │ │
│   └──────────────────────────┬────────────────────────────────────┘ │
│                              │ JDBC (5432)                          │
│                              ▼                                      │
│                    RDS PostgreSQL (subnets privés)                  │
│                                                                     │
│   Lambda "infoline-login" (optionnelle, désactivée par défaut)      │
└─────────────────────────────────────────────────────────────────────┘
```

## Stack technique

- **Frontend** : Angular 22, servi en production par Nginx
- **Backend** : Spring Boot 4 / Java 21, exposé sur le port 8080
- **Base de données** : PostgreSQL 15 (Amazon RDS)
- **Orchestration** : Kubernetes (Amazon EKS 1.36)
- **Infrastructure as Code** : Terraform (>= 1.15, provider AWS ~> 6.50)
- **Observabilité** : Elasticsearch + Kibana 8.13, déployés via l'opérateur ECK
- **CI/CD** : GitHub Actions, images publiées sur GitHub Container Registry (GHCR)
- **Fonction serverless** : AWS Lambda (Java 21) pour le login, désactivable via variable Terraform

## Structure du dépôt

```
ECF-Infoline/
├── Applications/
│   ├── Backend/        # API Spring Boot (Maven)
│   └── Frontend/       # Application Angular
├── K8s/                 # Manifests Kubernetes (backend, frontend, Elasticsearch, Kibana)
├── Terraform/
│   ├── VPC/             # Réseau (VPC, subnets, security group nodes EKS)
│   ├── EKS/              # Cluster Kubernetes managé
│   ├── RDS/              # Base de données PostgreSQL
│   └── lambda/           # Fonction Lambda de login
├── .github/workflows/   # Pipelines CI/CD (backend, frontend, terraform)
├── start.sh              # Déploiement de l'infra + ECK/Kibana
└── stop.sh               # Destruction de l'infra
```

## Prérequis

- AWS CLI configuré avec des identifiants ayant les droits sur VPC, EKS, RDS, IAM, Lambda et Secrets Manager
- Terraform >= 1.15
- kubectl
- Docker (pour builder les images en local)
- Java 21 et Maven (backend)
- Node.js 22 et npm (frontend)

## Déploiement de l'infrastructure

Le script `start.sh` orchestre le déploiement complet :

1. `terraform apply` sur le dossier `Terraform/` (VPC, EKS, RDS, Lambda)
2. Connexion de `kubectl` au cluster EKS créé
3. Installation de l'opérateur ECK (Elastic Cloud on Kubernetes, v3.4.1)
4. Déploiement d'Elasticsearch (`K8s/elasticsearch.yaml`) et attente du statut `green`
5. Déploiement de Kibana (`K8s/kibana.yaml`) et attente du statut `green`
6. Lancement d'un port-forward vers Kibana (`localhost:5601`) en arrière-plan
7. Affichage du mot de passe de l'utilisateur `elastic` et des informations d'accès

```bash
./start.sh
```

Pour détruire l'infrastructure :

```bash
./stop.sh
```

Les backends/frontends applicatifs (`infoline-backend`, `infoline-frontend`) sont eux déployés automatiquement par les pipelines CI/CD lors d'un push sur `DEV`, et non par `start.sh`.

## CI/CD (GitHub Actions)

| Workflow | Déclencheur | Étapes |
|---|---|---|
| `backend.yml` | push sur `DEV` (chemin `Applications/Backend/**`), PR vers `main` | tests Maven → build & push image sur GHCR → déploiement sur EKS (`K8s/backend-deploy.yaml`, secret RDS injecté depuis Secrets Manager) |
| `frontend.yml` | push sur `DEV` (chemin `Applications/Frontend/**`), PR vers `main` | tests + build Angular → build & push image sur GHCR → déploiement sur EKS (`K8s/frontend-deploy.yaml`) |
| `terraform.yml` | push sur `AWS`/`main`, PR vers `main` | `terraform fmt`/`validate`, puis `terraform apply` sur `main` |
| `terraform-destroy.yml` | déclenchement manuel avec confirmation | `terraform destroy` |

Images publiées :
- `ghcr.io/sylbardau/infoline-api`
- `ghcr.io/sylbardau/infoline-front`

## Infrastructure Terraform

- **VPC** : `10.0.0.0/16` sur 2 zones de disponibilité (`eu-west-3a/b`), subnets publics/privés, une seule NAT gateway (contrainte budget)
- **EKS** : cluster `infoline-cluster` (Kubernetes 1.36), node group managé `t3.small` (1 à 3 nœuds), addons `vpc-cni`, `kube-proxy`, `coredns`
- **RDS** : PostgreSQL 15 (`db.t3.micro`), mot de passe maître géré par AWS Secrets Manager, sans Multi-AZ (coûts réduits, à activer en prod)
- **Lambda** : fonction `infoline-login` (Java 21), désactivée par défaut (`deploy_lambda_function = false`), à activer une fois le JAR livré par l'équipe dev
- **Backend state** : stocké dans le bucket S3 `ecf-infoline-965932218164` (verrouillage via `use_lockfile`)

## Développement local

**Backend**

```bash
cd Applications/Backend
./mvnw spring-boot:run
```

**Frontend**

```bash
cd Applications/Frontend
npm install
npm start
```

L'application est alors accessible sur `http://localhost:4200`.

## Notes

- Les manifests `K8s/backend-deploy.yaml` et `K8s/frontend-deploy.yaml` contiennent des placeholders (`<IMAGE_TAG>`, `<DB_HOST>`) substitués automatiquement par les pipelines CI/CD.
- Le backend ne dispose pas encore de `spring-boot-starter-actuator` : les probes Kubernetes du pod backend sont donc en TCP en attendant l'ajout de vraies probes HTTP.
- Le stockage Elasticsearch est actuellement en `emptyDir` (éphémère) — à faire évoluer vers un volume persistant pour un usage au-delà de la démonstration.
