# Week 4 - Opdrachten

## Werkopdracht 4.1: AWS CLI-script voor meerdere stacks

**Vereisten:**
- Een CloudFormation-template die minimaal één EC2-instance met Node.js deployt (gebruik de templates van vorige weken)
- AWS CLI versie 2 geïnstalleerd: [Installatiegids AWS CLI v2](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-windows.html)
- AWS CLI geconfigureerd voor AWS Academy in regio `us-east-1`
- Download je credentials via de AWS Learner Labs-pagina via de knop "Account Details"

**Configureer de AWS CLI:**

```bash
aws configure
```

Referentie: [AWS CLI configureren](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)

**Jouw script moet de volgende stappen uitvoeren:**

1. CloudFormation CLI-commando om de netwerk-basisstack te deployen
2. CloudFormation CLI-commando om de EC2-stack te deployen
3. S3 CLI-commando om een S3-bucket aan te maken
4. EC2 CLI-commando `aws ec2 describe-network-interfaces` om netwerkinformatie op te halen
5. S3 CLI-commando om de netwerkinformatie te uploaden naar de S3-bucket

**Test je script** en verifieer dat de netwerkinformatie zichtbaar is in de S3-bucket.

**Resources:**
- [AWS CLI referentiegids](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/index.html#available-services)
- [S3 CLI gebruikersgids](https://docs.aws.amazon.com/cli/latest/userguide/cli-services-s3-commands.html)

---

## Werkopdracht 4.2: EFS-bestandssysteem deployen

Deploy eerst de multi-AZ basistemplate. Maak daarna een CloudFormation-template `wk4-demo-efs.yml` die een EFS aanmaakt.

**Let op:** Schakel DNS Hostnames in op je VPC, anders werken de EFS Mount Targets niet.
Zie: [EnableDnsHostnames](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ec2-vpc.html#cfn-aws-ec2-vpc-EnableDnsHostnames)

**Jouw template moet bevatten:**
- Een Elastic File System (EFS): [CloudFormation EFS](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-filesystem.html)
- Twee Mount Targets (één per publiek subnet): [CloudFormation EFS Mount Target](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-efs-mounttarget.html)
- Zorg dat poort 2049 (TCP) bereikbaar is via de beveiligingsgroep

**Validatie:** Start handmatig twee EC2-instances via de AWS Console. SSH in op instance 1, mount het EFS-bestandssysteem en maak een testbestand aan:

```bash
touch /mnt/efs/test.txt
echo 'This is a test file' > /mnt/efs/test.txt
cat /mnt/efs/test.txt
```

SSH in op instance 2, mount het bestandssysteem opnieuw en verifieer dat het testbestand zichtbaar is:

```bash
cat /mnt/efs/test.txt
```

Bedenk: hoe zou je logbestanden en backups van instances naar een centrale opslagplaats kunnen sturen?

**Resources:**
- [EFS - How it works](https://docs.aws.amazon.com/efs/latest/ug/how-it-works.html)
- [EFS testgids](https://docs.aws.amazon.com/efs/latest/ug/wt1-test.html)
