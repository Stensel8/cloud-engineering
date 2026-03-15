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

Een publiek subnet in de VPC. `MapPublicIpOnLaunch: true` zorgt dat elke instance automatisch een publiek IP krijgt bij het starten.

```yaml
PubliekSubnet:
  Type: AWS::EC2::Subnet
  Properties:
    VpcId: !Ref MyfirstVPC
    CidrBlock: 10.0.1.0/24
    MapPublicIpOnLaunch: true
    Tags:
      - Key: Name
        Value: publiek-subnet
```
---

## 3. Internet Gateway

Een internet gateway koppelt de VPC aan het internet. Zonder deze resource kan verkeer de VPC niet verlaten.

```yaml
InternetGateway:
  Type: AWS::EC2::InternetGateway
  Properties:
    Tags:
      - Key: Name
        Value: myfirst-igw
```

---

## 4. Internet Gateway Attachment

De attachment koppelt de internet gateway expliciet aan de VPC. CloudFormation maakt deze koppeling niet automatisch.

```yaml
IGWAttachment:
  Type: AWS::EC2::VPCGatewayAttachment
  Properties:
    VpcId: !Ref MyfirstVPC
    InternetGatewayId: !Ref InternetGateway
```

---

## 5. Routetabel

De routetabel bepaalt waar uitgaand verkeer naartoe wordt gestuurd. Een route `0.0.0.0/0` via de internet gateway maakt het subnet publiek.

```yaml
PubliekeRoutetabel:
  Type: AWS::EC2::RouteTable
  Properties:
    VpcId: !Ref MyfirstVPC
    Tags:
      - Key: Name
        Value: publieke-routetabel

DefaultRoute:
  Type: AWS::EC2::Route
  DependsOn: IGWAttachment
  Properties:
    RouteTableId: !Ref PubliekeRoutetabel
    DestinationCidrBlock: 0.0.0.0/0
    GatewayId: !Ref InternetGateway
```

`DependsOn: IGWAttachment` garandeert dat de attachment klaar is voordat de route wordt aangemaakt. `0.0.0.0/0` stuurt al het uitgaande verkeer via de internet gateway.

---

## 6. Routetabel-associatie

De associatie koppelt de routetabel aan het subnet. Zonder deze koppeling gebruikt het subnet de standaard routetabel van de VPC.

```yaml
SubnetRoutetabelAssociatie:
  Type: AWS::EC2::SubnetRouteTableAssociation
  Properties:
    SubnetId: !Ref PubliekSubnet
    RouteTableId: !Ref PubliekeRoutetabel
```

---

## 7. Beveiligingsgroep

De beveiligingsgroep bepaalt welk verkeer de EC2-instance mag bereiken. Poort 22 (SSH) voor beheer, poort 80 (HTTP) en poort 443 (HTTPS) voor webverkeer.

```yaml
WebBeveiligingsgroep:
  Type: AWS::EC2::SecurityGroup
  Properties:
    GroupDescription: Sta HTTP en SSH toe
    VpcId: !Ref MyfirstVPC
    SecurityGroupIngress:
      - IpProtocol: tcp
        FromPort: 22
        ToPort: 22
        CidrIp: 0.0.0.0/0
      - IpProtocol: tcp
        FromPort: 80
        ToPort: 80
        CidrIp: 0.0.0.0/0
      - IpProtocol: tcp
        FromPort: 443
        ToPort: 443
        CidrIp: 0.0.0.0/0
    Tags:
      - Key: Name
        Value: web-beveiligingsgroep
```

Uitgaand verkeer is standaard volledig open. Poort 22 is voor SSH-beheer, poort 80 voor HTTP en poort 443 voor HTTPS-verkeer naar nginx.

---

## 8. EC2-instance

De EC2-instance draait in het publieke subnet en installeert nginx automatisch via UserData.

```yaml
WebInstance:
  Type: AWS::EC2::Instance
  Properties:
    ImageId: '{{resolve:ssm:/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2}}'
    InstanceType: t2.micro
    KeyName: !Ref KeyName
    SubnetId: !Ref PubliekSubnet
    SecurityGroupIds:
      - !Ref WebBeveiligingsgroep
    UserData:
      Fn::Base64: |
        #!/bin/bash
        amazon-linux-extras install nginx1 -y
        systemctl enable nginx
        systemctl start nginx
    Tags:
      - Key: Name
        Value: web-instance
```

`ImageId` gebruikt een SSM-parameter om automatisch de nieuwste Amazon Linux 2 AMI op te halen, zodat je de AMI-ID niet handmatig hoeft bij te houden. `Fn::Base64` converteert het UserData-script naar het vereiste formaat; het script wordt uitgevoerd bij de eerste boot.

---

## Voorbereiding: EC2 key pair

Genereer een sleutelpaar lokaal in deze map:

```powershell
ssh-keygen -t ed25519 -f id_ed25519 -C "week1-cloud-engineering"
```

Dit genereert twee bestanden: `id_ed25519` (private) en `id_ed25519.pub` (public). Beide staan in `.gitignore` en worden nooit gecommit.

Importeer daarna de publieke sleutel naar AWS onder een naam:

```
aws ec2 import-key-pair --key-name week1-key --public-key-material fileb://id_ed25519.pub --region us-east-1
```

**Hoe het verder werkt:** bij het aanmaken van de stack via `aws cloudformation create-stack` geef je `week1-key` mee als parameter. AWS zoekt dan de bijbehorende publieke sleutel op en plaatst die automatisch in `~/.ssh/authorized_keys` op de EC2-instance. De private key verlaat je laptop nooit.

---

## Deployment

Voer deze commando's uit vanuit de map `Week 1/Uitwerking/`.

<details>
<summary>Stack aanmaken</summary>

```
aws cloudformation create-stack --stack-name stensel-stack --template-body file://stensel-stack.yaml --parameters ParameterKey=KeyName,ParameterValue=week1-key --region us-east-1
```

</details>

<details>
<summary>Status controleren</summary>

```
aws cloudformation describe-stacks --stack-name stensel-stack --region us-east-1
```

</details>

<details>
<summary>Outputs bekijken (IP-adres en nginx-URL)</summary>

```
aws cloudformation describe-stacks --stack-name stensel-stack --region us-east-1 --query "Stacks[0].Outputs"
```

</details>

<details>
<summary>Events bekijken (bij fouten)</summary>

```
aws cloudformation describe-stack-events --stack-name stensel-stack --region us-east-1
```

</details>

<details>
<summary>Stack bijwerken (na wijzigingen in de template)</summary>

```
aws cloudformation update-stack --stack-name stensel-stack --template-body file://stensel-stack.yaml --parameters ParameterKey=KeyName,ParameterValue=week1-key --region us-east-1
```

</details>

<details>
<summary>Stack verwijderen</summary>

```
aws cloudformation delete-stack --stack-name stensel-stack --region us-east-1
```

</details>

---

## SSH-verbinding

Haal het publieke IP op uit de stack outputs en verbind:

```
ssh -i id_ed25519 ec2-user@<publiek-ip>
```

Of voeg een shortcut toe aan `C:\Users\<jouw-naam>\.ssh\config`:

```
Host week1
    HostName <publiek-ip>
    User ec2-user
    IdentityFile C:\Users\<jouw-naam>\Documents\GitHub\cloud-engineering\cloud-automation-concepts\Week 1\Uitwerking\id_ed25519
```

Daarna volstaat `ssh week1`.

---

## Bijlagen

### Screenshots

![CloudFormation stack deployed](screenshot-stack-deployed.avif)

![Uitwerking overzicht](image.avif)

### Schermopname

De volledige uitwerking als schermopname (WebM/AV1):

[demo-week1.webm](demo-week1.webm)
