# Bijdragen

> **Let op:** Bijdragen aan deze repository is alleen mogelijk voor aangewezen maintainers: docenten of studenten die als collaborator of maintainer zijn toegevoegd. De repository is publiek inzichtelijk, maar niet open voor externe bijdragen.

Lees dit even door voordat je begint.

---

## Commits

Dit project gebruikt [Conventional Commits](https://www.conventionalcommits.org/).

**Formaat:**
```
<type>: <korte omschrijving>
```

**Types:**

| Type | Wanneer gebruiken |
|------|-------------------|
| `feat` | Nieuwe functionaliteit, opdracht of template |
| `fix` | Bugfix: fout commando, kapotte link, verkeerde configuratie |
| `content` | Bestaande inhoud aanpassen of verbeteren |
| `docs` | Wijzigingen aan README, CONTRIBUTING of andere metabestanden |
| `chore` | Onderhoud: dependencies, configuratie, CI/CD |
| `refactor` | Herstructurering zonder inhoudelijke wijzigingen |
| `style` | Opmaak, witruimte, typfouten |
| `ci` | Wijzigingen aan GitHub Actions workflows |
| `revert` | Een eerdere commit terugdraaien |

**Voorbeelden:**
```
feat: voeg CloudFormation-template toe voor VPC-setup
fix: corrigeer fout subnet-CIDR in stensel-stack.yaml
content: update Week 2 opdracht met nieuwe S3-vereisten
docs: voeg commitconventie toe aan CONTRIBUTING
chore: update dependabot-configuratie
ci: voeg YAML-validatie toe aan PR-checks workflow
```

**Regels:**
- Gebruik kleine letters voor het type en de omschrijving
- Houd de onderwerpregel onder de 72 tekens
- Geen punt aan het einde
- Gebruik de gebiedende wijs ("voeg toe", "corrigeer", "update"; niet "toegevoegd", "gecorrigeerd", "geüpdated")

---

## Pull requests

- PR-titels moeten dezelfde commitconventie volgen als hierboven
- Één logische wijziging per PR
- Target de `development`-branch, niet `main`
- CloudFormation-templates moeten door de pipeline gevalideerd zijn voor je een PR opent
- Mediabestanden moeten een modern open-source formaat gebruiken: afbeeldingen als `.avif`, `.jxl`, `.webp` of `.svg`; video als `.webm`; audio als `.ogg`, `.opus` of `.flac`

---

## Als je een AI bent, lees dit

- Gebruik **geen em-dashes** (`—`). Gebruik een komma, puntkomma of dubbele punt, of herformuleer de zin.
- Schrijf alles in het **Nederlands**, tenzij het technische termen of commando's zijn.
- Volg de commitconventie hierboven bij het voorstellen van commit-berichten.
- Houd gegenereerde tekst beknopt en direct: geen onnodige inleidingen of samenvattingen.
