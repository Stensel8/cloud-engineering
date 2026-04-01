# Architecting the Cloud

> Schoolopdracht - Cloud Engineering-specialisatie, Jaar 3, Q3 (5 EC)
> Duo: [Stensel8](https://github.com/Stensel8) & [Hintenhaus04](https://github.com/Hintenhaus04)

**Inleverdatum: 5 april 2026** als ZIP-bestand, met daarin twee mappen op naam van beide studenten.

## Over deze module

Best practices voor hybrid en public cloudarchitecturen, met de nadruk op **Amazon Web Services (AWS)** en **Microsoft Azure**. Ontwerpen van highly available en schaalbare cloudinfrastructuren en adviseren over belangrijke ontwerpkeuzes op basis van bedrijfsbehoeften.

## Leerdoelen

- Inzicht krijgen in cloudinfrastructuren, met name organisatorische en operationele aspecten
- Klantbehoeften analyseren en een cloudoplossing aanbevelen op basis van best practices
- Een (hybride) cloudarchitectuur ontwerpen op basis van weloverwogen keuzes die voldoen aan gegeven bedrijfsbehoeften

## Deliverables

### Individueel

- [ ] 4 modules afgerond van de AWS Cloud Architecting-cursus, met screenshot van minstens 70/100 punten per module:
  - [ ] Module 11 (verplicht)
  - [ ] Module 14 (verplicht)
  - [ ] Twee aanvullende modules naar keuze *(uitgezonderd modules 1, 2 en 17)*
  - Screenshots opslaan in [Individueel/AWS-Modules/](Individueel/AWS-Modules/)

### Duo

**Casus Zwarte Cross:** huidige situatie beschreven en nieuwe situatie ontworpen

- [ ] Sten
- [ ] Wout
- Bestanden in [Duo/Casus-Zwarte-Cross/](Duo/Casus-Zwarte-Cross/)

**Presentatie EU/Sovereign Cloud** (minstens 15 minuten presentatie + 15 minuten discussie)

- [ ] Sten
- [ ] Wout
- Slides in [Duo/Presentaties/EU-Sovereign-Cloud/](Duo/Presentaties/EU-Sovereign-Cloud/)

**Aanwezig bij alle andere duo-presentaties en samenvattingen gemaakt**

- [ ] Sten
- [ ] Wout
- Notulen in [Duo/Presentaties/Notulen/](Duo/Presentaties/Notulen/)

**Azure FinCloud-opdracht** (CAF: Strategy- en Ready-fase)

- [ ] Sten
- [ ] Wout
- Platform landing zone ontworpen en aangemaakt (1x)
- Application landing zone(s) ontworpen en aangemaakt
- Bestanden in [Duo/Azure-FinCloud/](Duo/Azure-FinCloud/)

## Presentaties

Elke duo verzint een onderwerp voor een korte presentatie. Hieronder het overzicht van de presentaties die zijn bijgewoond, inclusief de eigen presentatie.

| Nr. | Onderwerp | Presentatoren | Notities |
|-----|-----------|---------------|---------|
| 3 | EU/Sovereign Cloud | Stensel8 & Hintenhaus04 | Eigen presentatie |
| 9 | *(bonus presentatie)* | - | Bijgewoond |
| *(overige)* | Zie notulen | - | [Duo/Presentaties/Notulen/](Duo/Presentaties/Notulen/) |

## Azure Cloud Adoption Framework (CAF)

De Azure-opdracht volgt het [Microsoft Cloud Adoption Framework](https://learn.microsoft.com/nl-nl/azure/cloud-adoption-framework/). De nadruk ligt op twee fasen:

| Fase | Omschrijving |
|------|-------------|
| Strategy | Uitleg over het CAF; motivatie en zakelijke rechtvaardiging voor cloudmigratie |
| Ready | Landing zones ontwerpen en inrichten in Azure |

Je maakt twee typen landing zones:

- **Platform landing zone:** eenmalig aangemaakt, biedt gedeelde services voor alle applicaties (netwerk, identiteit, beheer)
- **Application landing zone:** per applicatie of team, bouwt voort op het platform

Referentie: [Azure Landing Zones - Microsoft Learn](https://learn.microsoft.com/nl-nl/azure/cloud-adoption-framework/ready/landing-zone/)

## Mappenstructuur

| Map | Inhoud |
|-----|--------|
| [Individueel/AWS-Modules/](Individueel/AWS-Modules/) | Screenshots van AWS Cloud Architecting-modulevoltooiingen |
| [Duo/Casus-Zwarte-Cross/](Duo/Casus-Zwarte-Cross/) | Architectuurdocument: huidige en nieuwe situatie |
| [Duo/Presentaties/EU-Sovereign-Cloud/](Duo/Presentaties/EU-Sovereign-Cloud/) | Slides van de eigen presentatie |
| [Duo/Presentaties/Notulen/](Duo/Presentaties/Notulen/) | Samenvattingen van bijgewoonde presentaties |
| [Duo/Azure-FinCloud/](Duo/Azure-FinCloud/) | FinCloud-opdracht: CAF-strategie, platform en application landing zones |
