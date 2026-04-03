#!/bin/bash
# ─────────────────────────────────────────────────────
#  Архивдин Үнү — быстрая установка
#  Запуск: bash setup.sh
# ─────────────────────────────────────────────────────
set -e

BACKEND_REPO="https://github.com/Manas-DE-Archieve/archivdin-backend.git"
FRONTEND_REPO="https://github.com/Manas-DE-Archieve/archivdin-frontend.git"
TESTDATA_REPO="https://github.com/Manas-DE-Archieve/test_data.git"

echo ""
echo "╔══════════════════════════════════════╗"
echo "║      Архивдин Үнү — Setup            ║"
echo "╚══════════════════════════════════════╝"
echo ""

# ── 1. Клонирование репозиториев ──
echo "📦 Клонирование репозиториев..."

if [ ! -d "../archivdin-backend" ]; then
  echo "  → backend..."
  git clone "$BACKEND_REPO" ../archivdin-backend
else
  echo "  ✓ backend уже существует (git pull)"
  git -C ../archivdin-backend pull --quiet
fi

if [ ! -d "../archivdin-frontend" ]; then
  echo "  → frontend..."
  git clone "$FRONTEND_REPO" ../archivdin-frontend
else
  echo "  ✓ frontend уже существует (git pull)"
  git -C ../archivdin-frontend pull --quiet
fi

if [ ! -d "../archivdin-test-data" ]; then
  echo "  → test data (seed)..."
  git clone "$TESTDATA_REPO" ../archivdin-test-data
else
  echo "  ✓ test data уже существует (git pull)"
  git -C ../archivdin-test-data pull --quiet
fi

# ── 2. Окружение ──
echo ""
echo "⚙️  Настройка окружения..."
if [ ! -f ".env" ]; then
  cp .env.example .env
  echo ""
  echo "  ┌─────────────────────────────────────────────────┐"
  echo "  │  Заполни три переменные в .env:                 │"
  echo "  │                                                  │"
  echo "  │  DB_PASSWORD   — придумай сложный пароль        │"
  echo "  │  OPENAI_API_KEY — твой ключ sk-...              │"
  echo "  │  JWT_SECRET    — случайная строка 64 символа    │"
  echo "  │                                                  │"
  echo "  │  Генерация JWT_SECRET:                          │"
  echo "  │  python3 -c \"import secrets;                    │"
  echo "  │    print(secrets.token_hex(32))\"               │"
  echo "  └─────────────────────────────────────────────────┘"
  echo ""
  if command -v nano &>/dev/null; then
    read -p "  Открыть .env в редакторе? (y/n): " yn
    [[ "$yn" == "y" ]] && nano .env
  else
    echo "  Открой файл .env и заполни переменные, затем запусти setup.sh снова."
    exit 0
  fi
fi

# Проверяем что ключевые переменные заполнены
source .env 2>/dev/null || true
if [[ "${OPENAI_API_KEY}" == "sk-..." ]] || [[ -z "${OPENAI_API_KEY}" ]]; then
  echo "  ❌ OPENAI_API_KEY не заполнен в .env"
  exit 1
fi
if [[ "${DB_PASSWORD}" == "change_me_strong_password" ]] || [[ -z "${DB_PASSWORD}" ]]; then
  echo "  ❌ DB_PASSWORD не заполнен в .env"
  exit 1
fi

# ── 3. Запуск ──
echo ""
echo "🚀 Запуск Docker Compose..."
docker compose up -d --build

# ── 4. Ждём бэкенд ──
echo ""
echo "⏳ Ожидание готовности бэкенда..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:8000/health &>/dev/null; then
    echo "  ✓ Backend готов"
    break
  fi
  sleep 2
  echo -n "."
done

# ── 5. Генерируем факты ──
echo ""
echo "✨ Генерация исторических фактов из документов..."
docker compose exec -T backend python scripts/generate_facts.py || echo "  (пропущено — запустите позже вручную)"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅  Всё готово!                              ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Frontend:  http://localhost:3000             ║"
echo "║  Backend:   http://localhost:8000/docs        ║"
echo "╠══════════════════════════════════════════════╣"
echo "║  Первый вход → зарегистрируйся               ║"
echo "║  Назначить super_admin:                       ║"
echo "║  docker compose exec db psql -U postgres \\   ║"
echo "║    archive -c \"UPDATE users SET              ║"
echo "║    role='super_admin'                         ║"
echo "║    WHERE email='your@email.com';\"            ║"
echo "╚══════════════════════════════════════════════╝"