# Assignment 3: Cloud Orchestration

## Over deze opdracht

De opdracht was om de infrastructuur te beheren via Terraform en de applicatie op Google Cloud Platform (GCP) te draaien in een Kubernetes-cluster. Ansible moest daarna het cluster configureren en logs verzamelen.

We zijn er grotendeels in geslaagd: de AWS-resources draaien via Terraform en het Kubernetes-cluster op GCP staat er. Met Ansible hebben we echter nog niet alles voor elkaar gekregen. De playbooks zijn geschreven en getest, maar de configuratie van het cluster en de logverzameling werken nog niet volledig zoals bedoeld.

## Leerdoelen

Het leerdoel was: werken met orkestratie- en configuratietools (Kubernetes, Terraform, Ansible) in een multi-cloud omgeving.

**Grotendeels behaald.** Terraform en Kubernetes werken goed. Ansible is deels werkend; de playbooks zijn er, maar de uitvoering loopt nog tegen problemen aan.

## Requirements

| Requirement | Status | Bewijs |
|---|---|---|
| REQ-15: AWS-resources uitgerold met Terraform | Behaald | `terraform/modules/aws/` bevat vijf modules: `base_stack`, `rds-stack`, `efs_stack`, `elk_stack` en `buildserver_stack`. Elke module roept de bijbehorende CloudFormation-template aan uit `terraform/templates/`. `main.tf` stuurt de volgorde via `depends_on`. |
| REQ-16: Applicatie uitgerold op GCP via IaC | Behaald | GKE-cluster aangemaakt in `terraform/modules/gcp/gke_cluster/main.tf`. Ansible-playbook `playbooks/gke_config.yml` haalt Terraform-outputs op, authenticeert met GCP en deployt de applicatie op het cluster via `include_role: gke_config`. |
| REQ-17: Gebruikers bereiken de applicatie via één extern IP-adres | Gedeeltelijk | `terraform/modules/gcp/loadbalancer/main.tf` maakt een `google_compute_global_address`, backend service, URL map en forwarding rule aan. Het statische IP-adres wordt als Terraform-output beschikbaar gesteld via `output "external_ip"`. Koppeling met het GKE-cluster via Ingress-controller is niet volledig getest. |
| REQ-18: Docker-images gehost op Artifact Registry | Gedeeltelijk | `terraform/modules/gcp/artifact_registry/main.tf` maakt een Docker-repository aan in `europe-west4`. Het image-pad `europe-west4-docker.pkg.dev/<project>/<repo>` wordt door Ansible dynamisch samengesteld in `playbooks/gke_config.yml`. Het automatisch pushen van images vanuit de Buildserver werkt nog niet volledig. |
| REQ-19: Kubernetes-cluster op GCP | Behaald | `terraform/modules/gcp/gke_cluster/main.tf` definieert een GKE-cluster (`cloudshirt-gke`) in `europe-west4` met private nodes, Workload Identity, Calico network policy en Binary Authorization. Een node pool met twee `e2-medium`-nodes wordt apart aangemaakt. |
| REQ-20: Cluster met 5 replica's van de applicatie | Gedeeltelijk | `ansible/roles/vars/main.yml` stelt `replica_count: 5` in. Dit wordt via de Jinja2-template `roles/gke_config/templates/deployment.yml.j2` in het Kubernetes Deployment-manifest gezet onder `spec.replicas`. Ansible werkt nog niet volledig, dus uitrol is niet bevestigd. |
| REQ-21: Ansible configureert het Kubernetes-cluster | Gedeeltelijk | `playbooks/gke_config.yml` haalt Terraform-outputs op, stelt kubeconfig in via `gcloud container clusters get-credentials`, maakt de namespace aan, zet een RDS-secret en deployt beide services (`eshopwebmvc`, `eshoppublicapi`) via de rol `gke_config`. Ingress-manifest gebruikt `kubernetes.io/ingress.class: gce` met padregels voor `/` en `/api`. |
| REQ-22: Ansible verzamelt logbestanden van de applicatie | Gedeeltelijk | `ansible/roles/log_collection/tasks/main.yml` haalt logs op met `kubernetes.core.k8s_log` voor elke pod in de namespace en schrijft ze weg als lokale `.log`-bestanden. Optioneel worden AWS CloudWatch-loggroepen opgehaald. Upload naar GCS via `gsutil cp` is geïmplementeerd maar werkt nog niet betrouwbaar. |

## Keuzes

Voor de AWS-kant laten de Terraform-modules de bestaande CloudFormation-templates aanroepen. Zo hoeven we de templates niet opnieuw te schrijven en is Terraform verantwoordelijk voor de levenscyclus: aanmaken, bijwerken en verwijderen.

We draaien de applicatie op GCP en houden de database en logging op AWS. Dat sluit aan bij het multi-cloud leerdoel van de module.

Het Kubernetes-cluster staat op GCP via GKE. De worker-nodes zijn niet direct bereikbaar van buitenaf; beheer gaat via de cluster-API. Voor het labgebruik hebben we tijdelijk alle IP-adressen toegelaten op de API-server, wat in een echte productieomgeving niet zou mogen.

Artifact Registry staat in dezelfde regio als het cluster (`europe-west4`), zodat het ophalen van images snel gaat.

Terraform-outputs worden door Ansible automatisch opgehaald, zodat je geen waarden handmatig hoeft over te typen tussen de twee tools.

## Uitrollen

Je hebt nodig: Terraform 1.6+, Google Cloud SDK, kubectl, Ansible en AWS-credentials.

**Stap 1: variabelen instellen**

Maak een `terraform.tfvars`-bestand aan in de `terraform/`-map:

```hcl
project_id               = "jouw-gcp-project-id"
gcp_region               = "europe-west4"
gcp_repo_name            = "cloudshirt-docker"
db_password              = "jouw-database-wachtwoord"
gcp_service_account_json = "<base64-encoded service account JSON>"
cfn_notification_sns_arn = ""
```

Je kunt het serviceaccount-bestand base64-encoderen via:

```bash
base64 -w 0 jouw-key.json
```

Of in PowerShell:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("jouw-key.json"))
```

**Stap 2: Terraform uitvoeren**

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Dit rolt de AWS-stacks en de GCP-resources uit.

**Stap 3: Ansible uitvoeren**

```bash
cd ansible
ansible-playbook playbooks/gke_config.yml
```

Dit haalt de Terraform-outputs op, verbindt met het cluster en probeert de applicatie te deployen.

**Stap 4: logverzameling**

```bash
ansible-playbook playbooks/log_collector.yml
```

**Opruimen:**

```bash
cd terraform
terraform destroy
```

## Aanbevelingen

De Terraform-state wordt nu lokaal opgeslagen. In een teamomgeving wil je die in een gedeelde opslag bewaren zodat iedereen met dezelfde staat werkt.

Gevoelige waarden zoals het database-wachtwoord en het serviceaccount staan nu als variabele in Terraform. In productie haal je die op uit een secrets-beheerder.

HTTPS staat niet aan op de load balancer. In productie koppel je een certificaat.

De Ansible-kant verdient meer aandacht. De playbooks werken gedeeltelijk, maar voor een stabiele productie-uitrol is meer testen nodig.
