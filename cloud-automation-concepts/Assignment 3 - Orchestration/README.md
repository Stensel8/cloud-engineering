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
| REQ-15: AWS-resources uitgerold met Terraform | Behaald | `terraform/modules/aws/` bevat modules voor het netwerk, de database, EFS, ELK en de Buildserver |
| REQ-16: Applicatie uitgerold op GCP via IaC | Behaald | GKE-cluster uitgerold via Terraform; applicatie wordt via Ansible op het cluster gezet |
| REQ-17: Gebruikers bereiken de applicatie via één extern IP-adres | Gedeeltelijk | Load balancer met statisch IP-adres is aangemaakt via Terraform, maar de koppeling met het cluster is niet volledig getest |
| REQ-18: Docker-images gehost op Artifact Registry | Gedeeltelijk | Artifact Registry is aangemaakt via Terraform; het automatisch pushen van images is niet volledig werkend |
| REQ-19: Kubernetes-cluster op GCP | Behaald | GKE-cluster uitgerold via Terraform in `europe-west4` |
| REQ-20: Cluster met 5 replica's van de applicatie | Gedeeltelijk | Ansible-playbook configureert 5 replica's, maar Ansible werkt nog niet volledig |
| REQ-21: Ansible configureert het Kubernetes-cluster | Gedeeltelijk | Playbook en rol zijn geschreven, maar de uitvoering loopt nog tegen problemen aan |
| REQ-22: Ansible verzamelt logbestanden van de applicatie | Gedeeltelijk | Playbook is geschreven en haalt logs op via kubectl; upload naar GCS werkt nog niet betrouwbaar |

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
