#!/usr/bin/env bash
# Доставка статического ресурса на devops-vm
# Использование: scripts/deploy.sh [--dry-run]

set -euo pipefail

REMOTE="devops" # псевдоним из ~/.ssh/config
REMOTE_DIR="/var/www/devops-site"
SITE_URL="https://devops.local"
CA_CERT="${HOME}/devops.crt"
LOCAL_DIR="./site/"

# 1. Разбор аргумента --dry-run
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# 2. Проверки по требованиям 4 и 5
if [[ ! -f "${LOCAL_DIR}index.html" ]]; then
    echo "Ошибка: файл site/index.html не найден!" >&2
    exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
    echo "Ошибка: в репозитории есть незафиксированные изменения!" >&2
    exit 1
fi

# 3. Синхронизация каталога
RSYNC_OPTS="-avz --delete --chmod=D755,F644"
if [[ "$DRY_RUN" == "true" ]]; then
    RSYNC_OPTS="$RSYNC_OPTS --dry-run"
fi

rsync $RSYNC_OPTS -e "ssh -o BatchMode=yes" "${LOCAL_DIR}" "${REMOTE}:${REMOTE_DIR}/"

# 4. При --dry-run — завершение с кодом 0
if [[ "$DRY_RUN" == "true" ]]; then
    exit 0
fi

# 5. Проверка доступности
if ! curl -f -s --cacert "$CA_CERT" -I "$SITE_URL" > /dev/null; then
    echo "Ошибка: ресурс $SITE_URL недоступен!" >&2
    exit 1
fi

echo "Успешно задеплоено: $(git rev-parse --short HEAD)"
exit 0