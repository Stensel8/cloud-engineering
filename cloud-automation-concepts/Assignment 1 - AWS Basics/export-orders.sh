#!/usr/bin/env bash
#
# export-orders.sh
# ----------------
# Exporteert de ordertabel (dbo.Orders) uit de CloudShirt SQL Server-database
# naar een CSV-bestand en uploadt dit naar de S3-bucket — maar alleen als er
# iets veranderd is (efficiënte uploads).
#
# Configuratie wordt gelezen uit /mnt/efs/ (gedeeld bestandssysteem op EFS),
# zodat het script werkt op elke EC2-instance in de ASG zonder hardcoded waarden.
#
# Gebruik:
#   ./export-orders.sh
#
# Automatisch uitvoeren (dagelijks om 02:00):
#   Voeg toe aan crontab via: crontab -e
#   0 2 * * * /home/ec2-user/export-orders.sh >> /var/log/export-orders.log 2>&1
#
# Vereisten op de EC2-instance:
#   - bcp en sqlcmd (mssql-tools) geïnstalleerd
#   - AWS CLI geconfigureerd
#   - EFS gemount op /mnt/efs
#   - Bestanden op EFS: rds-endpoint, s3-name, db-password

set -euo pipefail   # Afbreken bij fout, ongedefinieerde variabele of pipe-fout

# ---------------------------------------------------------------------------
# Configuratiebestanden (geschreven door CloudFormation UserData bij deployment)
# ---------------------------------------------------------------------------
readonly EFS_DIR="/mnt/efs"
readonly ENDPOINT_FILE="$EFS_DIR/rds-endpoint"
readonly BUCKET_FILE="$EFS_DIR/s3-name"
readonly PASSWORD_FILE="$EFS_DIR/db-password"   # wachtwoord opgeslagen op EFS, niet in dit script

# Tijdelijke bestanden voor de export
readonly EXPORT_CSV="/tmp/orders.csv"
readonly TEMP_CSV="/tmp/orders_tmp.csv"

# Database-instellingen
readonly DB_USER="csadmin"
readonly DB_NAME="Microsoft.eShopOnWeb.CatalogDb"
readonly DB_TABLE="dbo.Orders"

# mssql-tools toevoegen aan het pad
export PATH="$PATH:/opt/mssql-tools/bin"

# ---------------------------------------------------------------------------
# Hulpfunctie: foutmelding tonen en afsluiten
# ---------------------------------------------------------------------------
fail() {
    echo "FOUT: $1" >&2
    exit 1
}

# ---------------------------------------------------------------------------
# Stap 1: controleer of EFS-configuratiebestanden aanwezig zijn
# ---------------------------------------------------------------------------
echo "=== CloudShirt order-export gestart ==="
echo "Tijdstip: $(date)"

[ -f "$ENDPOINT_FILE" ] || fail "RDS-endpoint bestand niet gevonden: $ENDPOINT_FILE"
[ -f "$BUCKET_FILE"   ] || fail "S3-bucket bestand niet gevonden: $BUCKET_FILE"
[ -f "$PASSWORD_FILE" ] || fail "Wachtwoordbestand niet gevonden: $PASSWORD_FILE"

# Lees configuratiewaarden (strip witruimte)
DB_ENDPOINT=$(tr -d '[:space:]' < "$ENDPOINT_FILE")
S3_BUCKET=$(tr -d '[:space:]' < "$BUCKET_FILE")
DB_PASSWORD=$(tr -d '[:space:]' < "$PASSWORD_FILE")

echo "RDS-endpoint : $DB_ENDPOINT"
echo "S3-bucket    : $S3_BUCKET"

# ---------------------------------------------------------------------------
# Stap 2: exporteer de ordertabel naar een tijdelijk CSV-bestand
#
# bcp-opties:
#   out         - exporteer uit de database (in = importeren)
#   -c          - tekenmodus (geen binair)
#   -t,         - komma als kolomscheidingsteken
#   -b 10000    - batchgrootte (vermijdt time-outs bij grote tabellen)
# ---------------------------------------------------------------------------
echo ""
echo "Exporteren: $DB_TABLE uit $DB_NAME..."

bcp "$DB_TABLE" out "$TEMP_CSV" \
    -c -t, \
    -S "$DB_ENDPOINT" \
    -d "$DB_NAME" \
    -U "$DB_USER" \
    -P "$DB_PASSWORD" \
    -b 10000 \
    || fail "bcp-export mislukt. Controleer de verbinding met de database."

# ---------------------------------------------------------------------------
# Stap 3: vergelijk met het vorige exportbestand
#
# Als er geen wijzigingen zijn, is een nieuwe upload niet nodig.
# Dit bespaart S3-schrijfoperaties en datadoorvoer.
# ---------------------------------------------------------------------------
if [ -f "$EXPORT_CSV" ]; then
    echo ""
    echo "Vergelijken met vorige export..."

    if diff -q "$TEMP_CSV" "$EXPORT_CSV" > /dev/null 2>&1; then
        echo "Geen wijzigingen gevonden — upload overgeslagen."
        rm -f "$TEMP_CSV"
        exit 0
    fi

    echo "Wijzigingen gedetecteerd — bezig met uploaden."
else
    echo "Geen vorige export gevonden — eerste upload."
fi

# ---------------------------------------------------------------------------
# Stap 4: vervang het oude exportbestand en upload naar S3
# ---------------------------------------------------------------------------
mv "$TEMP_CSV" "$EXPORT_CSV"

echo ""
echo "Uploaden naar s3://$S3_BUCKET/exports/orders.csv ..."

aws s3 cp "$EXPORT_CSV" "s3://$S3_BUCKET/exports/orders.csv" \
    || fail "Upload naar S3 mislukt."

echo ""
echo "=== Export succesvol voltooid ==="
