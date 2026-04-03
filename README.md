# Архивдин Үнү — Deploy

Репозиторий для запуска всего проекта одной командой.

## Репозитории проекта

| Репо | Описание |
|------|----------|
| [archivdin-backend](https://github.com/Manas-DE-Archieve/archivdin-backend) | FastAPI + PostgreSQL + pgvector |
| [archivdin-frontend](https://github.com/Manas-DE-Archieve/archivdin-frontend) | React + Vite + Tailwind |
| [test_data](https://github.com/Manas-DE-Archieve/test_data) | Seed-данные: 20 карточек + 8 документов |
| **archivdin-deploy** ← ты здесь | Docker Compose + setup |

## Структура на диске

```
~/projects/
├── archivdin-backend/      ← клонируется автоматически
├── archivdin-frontend/     ← клонируется автоматически
├── archivdin-test-data/    ← клонируется автоматически
│   ├── seed.json           (20 карточек репрессированных)
│   ├── documents/          (8 архивных документов для RAG)
│   └── queries.md          (тестовые вопросы)
└── archivdin-deploy/       ← этот репо
    ├── docker-compose.yml
    ├── docker-compose.prod.yml
    ├── .env.example
    └── setup.sh
```

## Быстрый старт

```bash
git clone https://github.com/Manas-DE-Archieve/archivdin-deploy.git
cd archivdin-deploy
bash setup.sh
```

Скрипт автоматически:
1. Клонирует backend, frontend и test_data
2. Просит заполнить `.env`
3. Собирает и запускает Docker
4. Загружает seed-данные (20 персон + 8 документов)
5. Генерирует исторические факты из документов

## Вручную (шаг за шагом)

```bash
# 1. Клонировать все репозитории рядом
git clone https://github.com/Manas-DE-Archieve/archivdin-backend.git  ../archivdin-backend
git clone https://github.com/Manas-DE-Archieve/archivdin-frontend.git ../archivdin-frontend
git clone https://github.com/Manas-DE-Archieve/test_data.git          ../archivdin-test-data

# 2. Настроить .env
cp .env.example .env
nano .env

# 3. Запустить
docker compose up -d

# 4. После старта — сгенерировать факты
docker compose exec backend python scripts/generate_facts.py
```

## Переменные окружения (.env)

```env
DB_PASSWORD=придумай_сложный_пароль
OPENAI_API_KEY=sk-...
JWT_SECRET=случайная_строка_64_символа
```

Генерация JWT_SECRET:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

## Обновление

```bash
# Обновить все репозитории
git -C ../archivdin-backend pull
git -C ../archivdin-frontend pull
git -C ../archivdin-test-data pull

# Пересобрать и перезапустить
docker compose up -d --build
```

## Назначить администратора

```bash
docker compose exec db psql -U postgres archive -c \
  "UPDATE users SET role='super_admin' WHERE email='your@email.com';"
```

## ⚠️ Про .env

- Файл `.env` в `.gitignore` — **никогда не попадёт в git**
- `git pull` в любом репо — `.env` **не трогается**
- `docker compose down` — данные БД **сохраняются** (том `postgres_data`)
- `docker compose down -v` — ⚠️ **удаляет данные**, использовать только при полном сбросе