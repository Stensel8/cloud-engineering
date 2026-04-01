# Week 3 - Opdrachten

## Werkopdracht 3.1: CloudWatch-alarm instellen

**Vereisten:** Je hebt een template nodig die minimaal één EC2-instance aanmaakt. Gebruik de templates van de vorige weken.

Pas je CloudFormation-template aan zodat:

1. Een SNS-topic wordt aangemaakt voor het versturen van notificaties
2. Je e-mailadres aan het SNS-topic wordt toegevoegd (bevestig de e-mail na deployment)
3. Een CloudWatch-alarm wordt aangemaakt dat triggert wanneer de `NetworkOut` van de EC2-instance boven de 1000 bytes uitkomt gedurende 1 minuut
4. De alarm een bericht publiceert naar het SNS-topic

**Test het alarm** door de EC2-instance te stoppen en te controleren of je een e-mail ontvangt.

---

## Werkopdracht 3.2: RDS-database deployen

![Infrastructuuroverzicht RDS opdracht](opdracht3-rds-infrastructuur.avif)

Maak een CloudFormation-template die een RDS PostgreSQL-database aanmaakt. Gebruik [w2_base_multi_az.yml](../Bestanden/w2_base_multi_az.yml) als basis.

Gebruik de todo-webapplicatie van [github.com/looking4ward/cac-simple-webapp](https://github.com/looking4ward/cac-simple-webapp) (branch `todos-postgres`).

**Vereisten:** De template bevat de volgende parameters:
- `DatabaseName`: naam van de database
- `UserName`: gebruikersnaam
- `Password`: wachtwoord
- `DatabaseClass`: instance type (bijv. `db.t3.micro`)

Kies PostgreSQL als database-engine.

**Resources:**
- [Amazon RDS documentatie](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html)
- [CloudFormation RDS documentatie](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_RDS.html)

---

## Huiswerk 3.1: MongoDB todo-website deployen

![Infrastructuuroverzicht MongoDB huiswerk](huiswerk3-mongo-infrastructuur.avif)

Maak een CloudFormation-template die een todo-website met MongoDB-database deployt. Gebruik [w2_base_multi_az.yml](../Bestanden/w2_base_multi_az.yml) als basis.

Gebruik de webapplicatie van [github.com/TimothySealy/cac-simple-webapp](https://github.com/TimothySealy/cac-simple-webapp) (branch `todos`). Voer uit: `git checkout todos-postgres`.

**Handige tips:**
- Begin met MongoDB werkend te krijgen in het publieke subnet
- Gebruik een script om MongoDB in te richten, en zet dit daarna in de `UserData` van je CloudFormation-template
- Vergeet de beveiligingsgroep voor MongoDB niet (standaard poort: 27017)
- MongoDB bindt standaard aan `127.0.0.1`. Gebruik onderstaand commando om dit aan te passen:

```bash
sudo sed -i 's/127.0.0.1/0.0.0.0/' /etc/mongod.conf
```

**Resources:**
- [MongoDB installeren op Red Hat/Amazon Linux](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-red-hat/)
- [MongoDB op Amazon Linux 2023](https://www.mongodb.com/docs/manual/administration/install-community/?linux-distribution=amazon)
- [Robo 3T (GUI voor MongoDB)](https://robomongo.org/)
- [Mongo shell commando's](https://www.mongodb.com/docs/mongodb-shell/reference/methods/)
