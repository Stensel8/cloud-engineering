# Week 1 - Uitwerking

Uitwerking van [Werkopdracht 1.1](../Opdracht/README.md): een VPC met publiek subnet uitbreiden tot een werkende EC2-omgeving via CloudFormation.

Het volledige template: [stensel-stack.yaml](stensel-stack.yaml)

---

## 1. VPC

De VPC vormt het netwerk waarop alle andere resources worden geplaatst. CIDR-blok `10.0.0.0/16` geeft ruimte voor meerdere subnets.

```yaml
MyfirstVPC:
  Type: AWS::EC2::VPC
  Properties:
    CidrBlock: 10.0.0.0/16
    Tags:
      - Key: Name
        Value: myfirstVPC
      - Key: Omgeving
        Value: Productie
```

---

## 2. Subnet

```yaml
````
---

## 3. Internet Gateway

Een internet gateway koppelt de VPC aan het internet. Zonder deze resource kan verkeer de VPC niet verlaten.

<!-- Voeg hier de code toe nadat je de internet gateway aan de template hebt toegevoegd -->

---

## 4. Internet Gateway Attachment

De attachment koppelt de internet gateway expliciet aan de VPC. CloudFormation maakt deze koppeling niet automatisch.

<!-- Voeg hier de code toe nadat je de attachment aan de template hebt toegevoegd -->

---

## 5. Routetabel

De routetabel bepaalt waar uitgaand verkeer naartoe wordt gestuurd. Een route `0.0.0.0/0` via de internet gateway maakt het subnet publiek.

<!-- Voeg hier de code toe nadat je de routetabel aan de template hebt toegevoegd -->

---

## 6. Routetabel-associatie

De associatie koppelt de routetabel aan het subnet. Zonder deze koppeling gebruikt het subnet de standaard routetabel van de VPC.

<!-- Voeg hier de code toe nadat je de associatie aan de template hebt toegevoegd -->

---

## 7. Beveiligingsgroep

De beveiligingsgroep bepaalt welk verkeer de EC2-instance mag bereiken. Minimaal poort 80 (HTTP) voor nginx en poort 22 (SSH) voor beheer.

<!-- Voeg hier de code toe nadat je de beveiligingsgroep aan de template hebt toegevoegd -->

---

## 8. EC2-instance

De EC2-instance draait in het publieke subnet en installeert nginx automatisch via UserData.

<!-- Voeg hier de code toe nadat je de EC2-instance aan de template hebt toegevoegd -->

---

## Deployment

Voer deze commando's uit vanuit de map `Week 1/Uitwerking/`. Vervang `<jouw-key-naam>` door de naam van je bestaande EC2 key pair.

<details>
<summary>Stack aanmaken</summary>

```bash
aws cloudformation create-stack \
  --stack-name stensel-stack \
  --template-body file://stensel-stack.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=<jouw-key-naam> \
  --region us-east-1
```

</details>

<details>
<summary>Status controleren</summary>

```bash
aws cloudformation describe-stacks \
  --stack-name stensel-stack \
  --region us-east-1
```

</details>

<details>
<summary>Outputs bekijken (IP-adres en nginx-URL)</summary>

```bash
aws cloudformation describe-stacks \
  --stack-name stensel-stack \
  --region us-east-1 \
  --query "Stacks[0].Outputs"
```

</details>

<details>
<summary>Events bekijken (bij fouten)</summary>

```bash
aws cloudformation describe-stack-events \
  --stack-name stensel-stack \
  --region us-east-1
```

</details>

<details>
<summary>Stack bijwerken (na wijzigingen in de template)</summary>

```bash
aws cloudformation update-stack \
  --stack-name stensel-stack \
  --template-body file://stensel-stack.yaml \
  --parameters ParameterKey=KeyName,ParameterValue=<jouw-key-naam> \
  --region us-east-1
```

</details>

<details>
<summary>Stack verwijderen</summary>

```bash
aws cloudformation delete-stack \
  --stack-name stensel-stack \
  --region us-east-1
```

</details>
