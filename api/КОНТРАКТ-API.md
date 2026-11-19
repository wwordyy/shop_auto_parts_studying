# Контракт учебного API «Магазин автозапчастей»

Базовый адрес по умолчанию: `http://localhost:8080/api`

Клиент запускайте так: `flutter run -d chrome --web-port=5555`

Сервер: `node mock-server.js --port 8080 --origin http://localhost:5555`

---

## 1. Общие соглашения

- Формат обмена — JSON, кодировка UTF-8.
- Заголовок `Content-Type: application/json` обязателен для запросов с телом.
- Идентификаторы целочисленные, начинаются с 1.
- Даты передаются строкой в формате ISO 8601.
- Все ответы со списками возвращают одинаковую оболочку с постраничной разбивкой.

### 1.1. Оболочка списка

```json
{
  "items": [],
  "page": 1,
  "size": 10,
  "total": 24,
  "totalPages": 3
}
```

### 1.2. Формат ошибки

| Код | Смысл | Тело |
|---|---|---|
| 400 | Некорректный запрос | `{ "message": "..." }` |
| 401 | Не аутентифицирован либо токен истёк | `{ "message": "..." }` |
| 403 | Роль не имеет права на операцию | `{ "message": "..." }` |
| 404 | Объект не найден | `{ "message": "..." }` |
| 409 | Конфликт: нарушено ограничение целостности | `{ "message": "..." }` |
| 422 | Ошибка валидации полей | `{ "message": "...", "errors": { "sku": "..." } }` |
| 500 | Внутренняя ошибка сервера | `{ "message": "..." }` |

Ключи объекта `errors` совпадают с именами полей модели.

---

## 2. Аутентификация

`POST /api/auth/register`, `POST /api/auth/login`, `POST /api/auth/refresh`, `GET /api/auth/me`, `POST /api/auth/logout`.

Ответ login:

```json
{
  "accessToken": "...",
  "refreshToken": "...",
  "expiresIn": 900,
  "user": { "id": 1, "username": "admin", "fullName": "Администратор", "role": "admin" }
}
```

| Логин | Пароль | Роль |
|---|---|---|
| `admin` | `admin123` | `admin` |
| `manager` | `manager123` | `manager` |
| `buyer` | `buyer123` | `buyer` |

| Операция | buyer | manager | admin |
|---|---|---|---|
| Просмотр каталога | да | да | да |
| Создание, изменение, логическое удаление | нет | да | да |
| Физическое удаление и восстановление | нет | нет | да |
| Продажа со склада | нет | да | да |

---

## 3. Ресурсы

Единообразный CRUD для `parts`, `brands`, `categories`, `cars`, `customers`.

- `GET /api/{res}?search=&sort=name,asc&page=1&size=10&includeDeleted=false`
- `GET /api/{res}/{id}`
- `POST /api/{res}` — роль не ниже `manager`
- `PUT /api/{res}/{id}`
- `DELETE /api/{res}/{id}` — логическое
- `DELETE /api/{res}/{id}?hard=true` — физическое, только `admin`
- `POST /api/{res}/bulk-delete` — `{ "ids": [1, 2] }`
- `POST /api/{res}/{id}/restore` — только `admin`

Дополнительно для запчастей:

- фильтры: `categoryId`, `brandId`, `carModelId`, `yearFrom`, `yearTo`
- `POST /api/parts/{id}/sell` — `{ "quantity": 1 }`. Если `stockAvailable` меньше количества — `409`.

Удаление бренда, категории или автомобиля, на которые ссылаются запчасти, возвращает `409`.

Повтор артикула запчасти и email клиента — `422`.

---

## 4. Модели

На запись уходят идентификаторы (`brandId`, `categoryIds`, `carModelIds`), в ответе приходят и id, и развёрнутые объекты.

### `Part`

```json
{
  "id": 1,
  "name": "Свеча зажигания Bosch Super Plus",
  "sku": "FR7DC+",
  "year": 2022,
  "price": 390,
  "brandId": 1,
  "brand": { "id": 1, "name": "Bosch" },
  "categoryIds": [1],
  "categories": [{ "id": 1, "name": "Двигатель" }],
  "carModelIds": [6, 7, 8],
  "carModels": [{ "id": 6, "name": "Solaris", "maker": "Hyundai" }],
  "stockTotal": 40,
  "stockAvailable": 28,
  "deletedAt": null
}
```

### `Brand`

```json
{ "id": 1, "name": "Bosch", "country": "Германия", "foundedYear": 1886, "deletedAt": null }
```

### `Category`

```json
{ "id": 1, "name": "Двигатель", "description": "Свечи, ремни, датчики двигателя", "deletedAt": null }
```

### `Car`

```json
{ "id": 1, "name": "Camry", "maker": "Toyota", "yearFrom": 2018, "yearTo": 2024, "deletedAt": null }
```

### `Customer`

```json
{
  "id": 1,
  "fullName": "Иван Петров",
  "email": "ivan.petrov@mail.ru",
  "phone": "+79001234567",
  "card": { "number": "AP-1001", "issuedAt": "2023-02-10T00:00:00.000Z", "discountPercent": 5, "active": true },
  "deletedAt": null
}
```

---

## 5. Схема данных

```
Brand 1 ──< M Part M >──< M Category
                   M
                   │
                   ∨
                   M Car

Customer 1 ── 1 LoyaltyCard
```

- бренд → запчасть: один ко многим;
- запчасть ↔ категория: многие ко многим;
- запчасть ↔ автомобиль: многие ко многим;
- клиент ↔ карта лояльности: один к одному.

---

## 6. CORS

Сервер отдаёт:

```
Access-Control-Allow-Origin: http://localhost:5555
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
Access-Control-Allow-Headers: Content-Type, Authorization
Access-Control-Max-Age: 86400
```

Метод `OPTIONS` отвечает `204`.

Служебные адреса: `GET /api/__health`, `POST /api/__reset`, параметры `?__delay=1500` и `?__fail=500`.
