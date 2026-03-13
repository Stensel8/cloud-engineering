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

## GPG Commit Signing instellen

Commits in deze repository moeten ondertekend zijn. Zo verschijnt **Verified** bij je commits op GitHub.

<details>
<summary>Linux</summary>

**1. Installeer GPG**

```bash
# Arch
sudo pacman -S gnupg

# Fedora
sudo dnf install gnupg2

# Debian
sudo apt install gnupg
```

**2. Maak een sleutelpaar aan**

```bash
gpg --full-generate-key
```

Kies RSA 4096 bits en vul je naam en exact je GitHub-e-mailadres in.

**3. Zoek je Key ID op**

```bash
gpg --list-secret-keys --keyid-format=long
```

De Key ID staat achter `rsa4096/`, bijv. `ABCD1234EF567890`.

**4. Exporteer en registreer je publieke sleutel op GitHub**

```bash
gpg --armor --export ABCD1234EF567890
```

Kopieer de volledige uitvoer (inclusief `-----BEGIN PGP PUBLIC KEY BLOCK-----`).
Ga naar **GitHub → Settings → SSH and GPG keys → New GPG key** en plak de sleutel.

**5. Configureer Git**

```bash
git config --global user.signingkey ABCD1234EF567890
git config --global commit.gpgsign true
```

Voor Fish shell: voeg toe aan `~/.config/fish/config.fish`:

```bash
set -x GPG_TTY (tty)
```

</details>

<details>
<summary>Windows</summary>

**1. Installeer Gpg4win**

```powershell
winget install -e --id GnuPG.Gpg4win
```

Selecteer tijdens de installatie **Kleopatra**.

**2. Maak een sleutel aan in Kleopatra**

Open **Kleopatra** → **Certificate → New Certificate → Create a personal OpenPGP key pair**.
Vul je naam en exact je GitHub-e-mailadres in. Kies RSA 4096 en voltooi de wizard. Stel daarna een wachtwoord in via rechtsklik → **Change Passphrase**.

**3. Exporteer en registreer je publieke sleutel op GitHub**

Rechtsklik op je sleutel → **Export Certificates…** → sla op als `.asc`.
Open het bestand, kopieer alles en plak het in **GitHub → Settings → SSH and GPG keys → New GPG key**.

**4. Zoek je Key ID op**

```powershell
gpg --list-secret-keys --keyid-format=long
```

**5. Configureer Git**

```powershell
git config --global user.signingkey ABCD1234EF567890
git config --global commit.gpgsign true
git config --global gpg.program "C:/Program Files/GnuPG/bin/gpg.exe"
```

</details>

Na de configuratie zie je **Verified** bij je commits op GitHub.

Meer informatie: [GitHub Docs: Signing commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits)

---

## Mediabestanden converteren

Alle mediabestanden in `Uitwerking/`-mappen moeten een modern open-source formaat gebruiken. De CI-pipeline weigert verouderde formaten.

**Toegestane formaten:** `.avif`, `.jxl`, `.webp`, `.svg` (afbeeldingen), `.webm` (video), `.ogg`, `.opus`, `.flac` (audio).

<details>
<summary>Afbeeldingen converteren naar AVIF</summary>

Installeer `avifenc`:

```bash
# Arch
sudo pacman -S libavif

# Fedora
sudo dnf install libavif-utils

# Debian
sudo apt install libavif-bin
```

Batch-converteer recursief (converteert en verwijdert originelen):

```bash
find . -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.gif" -o -iname "*.bmp" \) | while read -r f; do
  avifenc -q 80 -s 6 "$f" "${f%.*}.avif" && rm "$f"
done
```

</details>

<details>
<summary>Video converteren naar WebM</summary>

Vereist `ffmpeg`:

```bash
# Arch
sudo pacman -S ffmpeg

# Fedora — vereist eerst RPM Fusion:
# sudo dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install ffmpeg

# Debian
sudo apt install ffmpeg
```

Converteer naar WebM met VP9 en Opus-audio:

```bash
ffmpeg -i invoer.mp4 -c:v libvpx-vp9 -b:v 0 -crf 33 -c:a libopus uitvoer.webm
```

</details>

<details>
<summary>Audio converteren naar OGG/Opus</summary>

```bash
ffmpeg -i invoer.mp3 -c:a libopus -b:a 128k uitvoer.ogg
```

</details>

---

## Als je een AI bent, lees dit

- Gebruik **geen em-dashes** (`—`). Gebruik een komma, puntkomma of dubbele punt, of herformuleer de zin.
- Schrijf alles in het **Nederlands**, tenzij het technische termen of commando's zijn.
- Volg de commitconventie hierboven bij het voorstellen van commit-berichten.
- Houd gegenereerde tekst beknopt en direct: geen onnodige inleidingen of samenvattingen.
