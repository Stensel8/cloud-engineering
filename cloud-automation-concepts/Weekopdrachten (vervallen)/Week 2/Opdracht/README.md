# Week 2 - Opdrachten

## Werkopdracht 2.1: Instances en load balancer deployen

Maak de infrastructuur zoals hieronder beschreven. Splits de template op in de volgende YAML-bestanden:

- Een basisbestand: [w2_base_multi_az.yml](../Bestanden/w2_base_multi_az.yml) (al beschikbaar)
- Een template voor de instances (bijvoorbeeld `w2_assignment_1_instances.yml`)
- Een template voor de load balancer (bijvoorbeeld `w2_assignment_1_alb.yml`)

![Infrastructuuroverzicht opdracht 2.1](opdracht2-1-infrastructuur.avif)

**Vereisten:**
- Deploy twee EC2-instances in het publieke subnet
- Installeer de webapplicatie van [github.com/TimothySealy/cac-simple-webapp](https://github.com/TimothySealy/cac-simple-webapp)
- Zorg dat de load balancer het verkeer verdeelt over beide instances
- Bij herladen van de pagina moet de hostnaam van een andere instance verschijnen

**Resources:**
- [AWS CloudFormation Resource Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)
- [Node.js installeren op Amazon Linux 2](https://docs.aws.amazon.com/sdk-for-javascript/v2/developer-guide/setting-up-node-on-ec2-instance.html)
- Tip: stel `PORT=80` in via `export PORT=80` zodat de app op poort 80 luistert

---

## Werkopdracht 2.2: Auto scaling group

![Infrastructuuroverzicht opdracht 2.2](opdracht2-2-infrastructuur.avif)

Maak een CloudFormation-template die een auto scaling group aanmaakt met een gewenste capaciteit van twee instances. Splits de template als volgt:

- Een basisbestand: [w2_base_multi_az.yml](../Bestanden/w2_base_multi_az.yml)
- Een template voor de auto scaling group en load balancer (bijvoorbeeld `w2_autoscaling.yml`)

**Vereisten:**
- Instances draaien in verschillende Availability Zones
- Instances zijn load balanced
- De auto scaling group schaalt op basis van "Request count per target"
- De template bevat: een Launch Configuration, een Auto Scaling Group en een Auto Scaling Policy

**Tip:** Stel de request count per target laag in (bijvoorbeeld 1) om de autoscaler makkelijk te triggeren. Monitor in CloudWatch of de alarm wordt geactiveerd.

**Resources:**
- [AWS CloudFormation Resource Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)

---

## Huiswerk 2.1: NAT-gateway template

![Infrastructuuroverzicht huiswerk 2](huiswerk2-infrastructuur.avif)

Maak de infrastructuur zoals beschreven. Verdeel de template in de volgende YAML-bestanden:

- Een basisbestand: [w2_base_multi_az.yml](../Bestanden/w2_base_multi_az.yml)
- Een template voor de instances (bijvoorbeeld `w2_homework_instance.yml`)
- Een template voor de NAT-gateway en routering (bijvoorbeeld `w2_homework_nat.yml`)

**Vereisten:**
- Je kunt via SSH naar de instance in het private subnet via de instance in het publieke subnet
- Op de instance in het private subnet geeft `curl google.com` een response terug met als titel "301 Moved"

**Resources:**
- [AWS CloudFormation Resource Reference](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-template-resource-type-ref.html)
