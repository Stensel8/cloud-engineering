# Week 1 - Opdrachten

## Werkopdracht 1.1: CloudFormation-template uitbreiden

Tijdens de les wordt gedemonstreerd hoe je een VPC met een publiek subnet deployt via CloudFormation, inclusief een EC2-instance met nginx.

**Doel:** Breid de basis CloudFormation-template ([w1_practical.yml](../Bestanden/w1_practical.yml)) uit met de ontbrekende componenten.

![Infrastructuuroverzicht werkopdracht](workshop-infrastructuur.avif)

De template bevat al:
- Een VPC
- Een publiek subnet

Voeg de volgende resources toe:
- Een internet gateway
- Een routetabel
- Een koppeling tussen de routetabel en het subnet
- Een beveiligingsgroep
- Een EC2-instance

**Let op:**
- Vergeet de internet gateway attachment niet.
- Vergeet de routetabel-associatie niet.
- Referentiedocumentatie voor alle ondersteunde resources: [AWS CloudFormation Resource Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)
- Informatie over EC2 key pairs: [AWS EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)

**Extra:** Installeer nginx via UserData. Gebruik op Amazon Linux 2:

```bash
amazon-linux-extras install nginx1
systemctl enable nginx
systemctl start nginx
```

Referentie: [nginx installatiegids](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/)

---

## Werkopdracht 1.2: Visual Studio Code instellen

Installeer Visual Studio Code en de CloudFormation Linter-extensie.

> **Let op:** Het lesmateriaal verwijst naar de extensie [cform-VSCode](https://github.com/aws-scripting-guy/cform-VSCode) van aws-scripting-guy. Die extensie is sinds 2022 niet meer onderhouden en werkt niet meer correct met moderne VS Code-versies. Gebruik in plaats daarvan de officieel ondersteunde **CloudFormation Linter**-extensie.

**Installeer cfn-lint:**

```powershell
pip install cfn-lint
```

**Installeer de VS Code-extensie:**

Zoek in VS Code naar `kddejong.vscode-cfn-lint` en installeer deze.

De extensie gebruikt automatisch het pad uit `.vscode/settings.json`, dat al is ingesteld in deze repository.

---

---

## Huiswerk 1.1: Nginx-instance deployen

Mocht je de werkopdracht nog niet hebben afgerond: deploy een EC2-instance in een publiek subnet en installeer nginx op een geautomatiseerde manier.

**Resources:**
- [nginx installeren op Ubuntu](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/#prebuilt_ubuntu)
- Vergeet de nginx-service niet te starten: `service nginx start`

---

## Huiswerk 1.2: Multi-AZ CloudFormation-template

![Infrastructuuroverzicht huiswerk](huiswerk-infrastructuur.avif)

Maak een CloudFormation-template die een VPC aanmaakt met twee Availability Zones. Elke AZ bevat een publiek en een privaat subnet. De VPC moet een internet gateway bevatten met correcte routering voor de publieke subnets. Een NAT-gateway voor de private subnets is **niet** vereist.

**Resources:**
- [AWS CloudFormation Resource Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)
- [AWS Availability Zones documentatie](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html)
