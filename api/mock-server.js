#!/usr/bin/env node
/**
 * Мок-сервер учебного API «Магазин автозапчастей».
 *
 * Реализует контракт из файла КОНТРАКТ-API.md.
 * Зависимостей нет — нужен только Node.js 18 или новее.
 *
 *   node mock-server.js
 *   node mock-server.js --port 8080 --origin http://localhost:5555
 *   PORT=10000 ORIGIN=https://wwordyy.github.io,http://localhost:5555 node mock-server.js
 *
 * Данные хранятся в памяти и сбрасываются при перезапуске
 * либо запросом POST /api/__reset
 *
 * Учебные возможности:
 *   ?__delay=1500   задержка ответа в миллисекундах (проверка индикатора загрузки)
 *   ?__fail=500     принудительный код ошибки (проверка обработки ошибок)
 */

'use strict';

const http = require('node:http');
const crypto = require('node:crypto');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(process.env.PORT || arg('port', 8080));
const HOST = process.env.HOST || '0.0.0.0';
const ORIGINS = String(
  process.env.ORIGIN ||
    arg(
      'origin',
      'http://localhost:5555,http://127.0.0.1:5555,https://wwordyy.github.io',
    ),
)
  .split(',')
  .map((item) => item.trim())
  .filter(Boolean);
const SECRET = 'учебный-ключ-не-для-продакшена';
const ACCESS_TTL = Number(arg('ttl', 900));
const REFRESH_TTL = 60 * 60 * 24 * 7;

function b64url(buf) {
  return Buffer.from(buf).toString('base64url');
}

function sign(payload) {
  const withId = { ...payload, jti: crypto.randomUUID() };
  const body = b64url(JSON.stringify(withId));
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, mac] = token.split('.');
  const expected = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  if (mac !== expected) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp * 1000 < Date.now()) return null;
  return payload;
}

let db;

const brandProducedCategories = {
  1: [1, 2, 4, 5, 7],
  2: [1, 4],
  3: [5],
  4: [2],
  5: [3, 6],
  6: [4, 6, 7],
  7: [1, 4],
  8: [3],
  9: [8],
  10: [7, 8],
};

function seed() {
  db = {
    seq: {},
    brands: [],
    categories: [],
    cars: [],
    parts: [],
    customers: [],
    cards: [],
    users: [],
    refreshTokens: new Set(),
  };

  const Brand = (name, country, foundedYear) => push('brands', { name, country, foundedYear });
  const Cat = (name, description) => push('categories', { name, description });
  const Car = (name, maker, yearFrom, yearTo) => push('cars', { name, maker, yearFrom, yearTo });

  Brand('Bosch', 'Германия', 1886);
  Brand('NGK', 'Япония', 1936);
  Brand('Mann-Filter', 'Германия', 1941);
  Brand('Brembo', 'Италия', 1961);
  Brand('Sachs', 'Германия', 1895);
  Brand('Valeo', 'Франция', 1923);
  Brand('Denso', 'Япония', 1949);
  Brand('KYB', 'Япония', 1919);
  Brand('Mobil', 'США', 1866);
  Brand('Castrol', 'Великобритания', 1899);

  Cat('Двигатель', 'Свечи, ремни, датчики двигателя');
  Cat('Тормозная система', 'Колодки, диски, суппорты');
  Cat('Подвеска', 'Амортизаторы и стойки');
  Cat('Электрика', 'Генераторы, стартеры, датчики');
  Cat('Фильтры', 'Масляные, воздушные, салонные');
  Cat('Трансмиссия', 'Сцепление и связанные узлы');
  Cat('Охлаждение', 'Помпы, термостаты, антифриз');
  Cat('Масла и жидкости', 'Моторные масла и техжидкости');

  Car('Camry', 'Toyota', 2018, 2024);
  Car('RAV4', 'Toyota', 2019, 2024);
  Car('Polo', 'Volkswagen', 2015, 2022);
  Car('Tiguan', 'Volkswagen', 2017, 2024);
  Car('3 Series', 'BMW', 2019, 2024);
  Car('Solaris', 'Hyundai', 2017, 2024);
  Car('Rio', 'Kia', 2017, 2023);
  Car('Vesta', 'Lada', 2015, 2024);
  Car('Octavia', 'Skoda', 2017, 2024);
  Car('Focus', 'Ford', 2015, 2022);

  const P = (name, sku, year, price, brandId, categoryIds, carModelIds, stockTotal, stockAvailable) =>
    push('parts', {
      name,
      sku,
      year,
      price,
      brandId,
      categoryIds,
      carModelIds,
      stockTotal,
      stockAvailable,
    });

  P('Свеча зажигания Bosch Super Plus', 'FR7DC+', 2022, 390, 1, [1], [6, 7, 8], 40, 28);
  P('Свеча зажигания NGK Laser Iridium', 'ILZKR7B-11S', 2023, 1450, 2, [1], [1, 2], 24, 18);
  P('Масляный фильтр Mann W 712/95', 'W71295', 2021, 620, 3, [5], [3, 9, 10], 30, 21);
  P('Воздушный фильтр Mann C 27 192', 'C27192', 2020, 980, 3, [5], [4, 9], 18, 12);
  P('Салонный фильтр Mann CU 2939', 'CU2939', 2022, 870, 3, [5], [3, 4, 9], 22, 16);
  P('Тормозные колодки Brembo P 85 125', 'P85125', 2023, 4890, 4, [2], [5], 12, 7);
  P('Тормозной диск Brembo 09.9772.11', '09977211', 2022, 6720, 4, [2], [5], 10, 6);
  P('Амортизатор KYB Excel-G 334238', '334238', 2021, 5340, 8, [3], [1, 2], 14, 9);
  P('Амортизатор Sachs 317 572', '317572', 2020, 4980, 5, [3], [3, 10], 16, 11);
  P('Комплект сцепления Sachs 3000 951 011', '3000951011', 2019, 12490, 5, [6], [6, 7], 8, 4);
  P('Комплект сцепления Valeo 826494', '826494', 2021, 11200, 6, [6], [3, 9], 7, 3);
  P('Щётки стеклоочистителя Valeo 574307', '574307', 2024, 1890, 6, [4], [4, 9], 20, 15);
  P('Генератор Denso DAN1055', 'DAN1055', 2018, 18750, 7, [4], [1, 2], 5, 2);
  P('Стартер Denso DSN940', 'DSN940', 2019, 15400, 7, [4], [1, 5], 6, 3);
  P('Моторное масло Mobil 1 5W-30 4л', 'MOB5W30-4', 2024, 4590, 9, [8], [1, 2, 5], 25, 19);
  P('Моторное масло Castrol EDGE 5W-40 4л', 'CST5W40-4', 2023, 4320, 10, [8], [3, 6, 8], 26, 20);
  P('Антифриз Castrol Radicool 5л', 'CSTRAD-5', 2022, 2180, 10, [7, 8], [6, 7, 8], 18, 13);
  P('Термостат Bosch 1 987 724 001', '1987724001', 2020, 1760, 1, [7], [6, 7], 15, 10);
  P('Ремень ГРМ Bosch 1 987 949 565', '1987949565', 2021, 2890, 1, [1], [3, 9, 10], 12, 8);
  P('Кислородный датчик NGK 95801', 'NGK95801', 2022, 7650, 2, [1, 4], [1, 5], 9, 5);
  P('Тормозные колодки Bosch 0 986 494 136', '0986494136', 2023, 3120, 1, [2], [6, 7, 8], 20, 14);
  P('Стойка стабилизатора KYB KS1094', 'KS1094', 2020, 1540, 8, [3], [6, 8], 17, 12);
  P('Масляный фильтр Bosch 0 451 103 316', '0451103316', 2024, 540, 1, [5], [6, 7, 10], 35, 27);
  P('Помпа охлаждения Valeo 506698', '506698', 2019, 3980, 6, [7], [3, 9], 11, 6);

  const customers = [
    ['Иван Петров', 'ivan.petrov@mail.ru', '+79001234567', 'AP-1001', [2023, 2, 10], 5, true],
    ['Мария Сидорова', 'maria.sidorova@gmail.com', '+79007654321', 'AP-1002', [2024, 1, 15], 10, true],
    ['Алексей Козлов', 'akozlov@yandex.ru', '+79111223344', 'AP-1003', [2022, 11, 3], 3, false],
    ['Ольга Новикова', 'olga.novikova@mail.ru', '+79225556677', 'AP-1004', [2024, 6, 20], 7, true],
    ['Дмитрий Орлов', 'd.orlov@outlook.com', '+79031112233', 'AP-1005', [2023, 8, 1], 15, true],
  ];

  customers.forEach(([fullName, email, phone, number, issued, discountPercent, active]) => {
    const customerId = push('customers', { fullName, email, phone });
    push('cards', {
      customerId,
      number,
      issuedAt: iso(...issued),
      discountPercent,
      active,
    });
  });

  push('users', {
    username: 'admin',
    passwordHash: hash('admin123'),
    fullName: 'Администратор',
    email: 'admin@shop.local',
    role: 'admin',
    customerId: null,
  });
  push('users', {
    username: 'manager',
    passwordHash: hash('manager123'),
    fullName: 'Петрова А. С.',
    email: 'petrova@shop.local',
    role: 'manager',
    customerId: null,
  });
  push('users', {
    username: 'buyer',
    passwordHash: hash('buyer123'),
    fullName: 'Иван Петров',
    email: 'ivan.petrov@mail.ru',
    role: 'buyer',
    customerId: 1,
  });
}

function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({ id, ...obj, createdAt: new Date().toISOString(), deletedAt: null });
  return id;
}

function iso(y, m, d) {
  return new Date(Date.UTC(y, m - 1, d)).toISOString();
}

function hash(password) {
  return crypto.createHash('sha256').update(password + SECRET).digest('hex');
}

function slimBrand(id) {
  const item = db.brands.find((x) => x.id === id);
  return item ? { id: item.id, name: item.name } : null;
}

function expandPart(part) {
  return {
    id: part.id,
    name: part.name,
    sku: part.sku,
    year: part.year,
    price: part.price,
    brand: slimBrand(part.brandId),
    brandId: part.brandId,
    categories: (part.categoryIds || [])
      .map((id) => db.categories.find((item) => item.id === id))
      .filter(Boolean)
      .map((item) => ({ id: item.id, name: item.name })),
    categoryIds: part.categoryIds || [],
    carModels: (part.carModelIds || [])
      .map((id) => db.cars.find((item) => item.id === id))
      .filter(Boolean)
      .map((item) => ({ id: item.id, name: item.name, maker: item.maker })),
    carModelIds: part.carModelIds || [],
    stockTotal: part.stockTotal,
    stockAvailable: part.stockAvailable,
    createdAt: part.createdAt,
    deletedAt: part.deletedAt,
  };
}

function expandCustomer(customer) {
  const card = db.cards.find((item) => item.customerId === customer.id && !item.deletedAt);
  return {
    id: customer.id,
    fullName: customer.fullName,
    email: customer.email,
    phone: customer.phone,
    card: card
      ? {
          number: card.number,
          issuedAt: card.issuedAt,
          discountPercent: card.discountPercent,
          active: card.active,
        }
      : null,
    createdAt: customer.createdAt,
    deletedAt: customer.deletedAt,
  };
}

function expandUser(user) {
  return {
    id: user.id,
    username: user.username,
    fullName: user.fullName,
    email: user.email,
    role: user.role,
    customerId: user.customerId,
  };
}

const EXPANDERS = {
  parts: expandPart,
  customers: expandCustomer,
  brands: (item) => item,
  categories: (item) => item,
  cars: (item) => item,
};

function searchableText(collection, item) {
  switch (collection) {
    case 'parts':
      return [item.name, item.sku].join(' ');
    case 'brands':
      return [item.name, item.country].join(' ');
    case 'categories':
      return [item.name, item.description].join(' ');
    case 'cars':
      return [item.name, item.maker].join(' ');
    case 'customers':
      return [item.fullName, item.email, item.phone].join(' ');
    default:
      return '';
  }
}

function applyFilters(collection, rows, q) {
  let result = rows;

  if (q.search) {
    const needle = String(q.search).toLowerCase();
    result = result.filter((item) => searchableText(collection, item).toLowerCase().includes(needle));
  }

  if (collection === 'parts') {
    if (q.categoryId) result = result.filter((item) => item.categoryIds.includes(Number(q.categoryId)));
    if (q.brandId) result = result.filter((item) => item.brandId === Number(q.brandId));
    if (q.carModelId) result = result.filter((item) => item.carModelIds.includes(Number(q.carModelId)));
    if (q.yearFrom) result = result.filter((item) => item.year >= Number(q.yearFrom));
    if (q.yearTo) result = result.filter((item) => item.year <= Number(q.yearTo));
  }

  if (collection === 'brands' && q.country) {
    result = result.filter((item) => item.country === q.country);
  }

  if (collection === 'cars' && q.maker) {
    result = result.filter((item) => item.maker === q.maker);
  }

  return result;
}

function applySort(rows, sort) {
  if (!sort) return rows;
  const [field, dirRaw] = String(sort).split(',');
  const dir = (dirRaw || 'asc').toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const av = a[field];
    const bv = b[field];
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
    return String(av).localeCompare(String(bv), 'ru') * dir;
  });
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  const totalPages = Math.max(1, Math.ceil(total / size));
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages,
  };
}

function validate(collection, body, id = null) {
  const e = {};
  const str = (v) => (typeof v === 'string' ? v.trim() : '');
  const yearNow = new Date().getFullYear();

  if (collection === 'parts') {
    if (!str(body.name)) e.name = 'Укажите название';
    else if (str(body.name).length > 80) e.name = 'Не длиннее 80 символов';

    if (!str(body.sku)) e.sku = 'Укажите артикул';
    else if (str(body.sku).length > 32) e.sku = 'Не длиннее 32 символов';
    else {
      const needle = str(body.sku).toLowerCase();
      const dup = db.parts.find(
        (item) => item.sku.toLowerCase() === needle && item.id !== id && !item.deletedAt
      );
      if (dup) e.sku = 'Артикул уже используется';
    }

    const year = Number(body.year);
    if (!Number.isInteger(year)) e.year = 'Год — целое число';
    else if (year < 1980 || year > yearNow + 1) e.year = `Год от 1980 до ${yearNow + 1}`;

    const price = Number(body.price);
    if (!Number.isInteger(price) || price <= 0) e.price = 'Цена должна быть больше 0';

    const brand = db.brands.find((item) => item.id === Number(body.brandId) && !item.deletedAt);
    if (!brand) e.brandId = 'Бренд не найден';

    const categoryIds = Array.isArray(body.categoryIds) ? body.categoryIds.map(Number) : [];
    if (!categoryIds.length) e.categoryIds = 'Выберите хотя бы одну категорию';
    else if (categoryIds.some((cid) => !db.categories.find((item) => item.id === cid && !item.deletedAt))) {
      e.categoryIds = 'Категория не найдена';
    } else if (brand) {
      const allowed = brandProducedCategories[brand.id];
      if (allowed && categoryIds.some((cid) => !allowed.includes(cid))) {
        e.categoryIds = 'Бренд не выпускает выбранную категорию';
      }
    }

    const carModelIds = Array.isArray(body.carModelIds) ? body.carModelIds.map(Number) : [];
    if (!carModelIds.length) e.carModelIds = 'Выберите хотя бы один автомобиль';
    else if (carModelIds.some((cid) => !db.cars.find((item) => item.id === cid && !item.deletedAt))) {
      e.carModelIds = 'Автомобиль не найден';
    }

    const stockTotal = Number(body.stockTotal);
    if (!Number.isInteger(stockTotal) || stockTotal <= 0) e.stockTotal = 'Всего на складе должно быть больше 0';

    if (body.stockAvailable != null && body.stockAvailable !== '') {
      const stockAvailable = Number(body.stockAvailable);
      if (!Number.isInteger(stockAvailable) || stockAvailable < 0) {
        e.stockAvailable = 'Доступно не может быть отрицательным';
      } else if (Number.isInteger(stockTotal) && stockAvailable > stockTotal) {
        e.stockAvailable = 'Доступно не может быть больше общего количества';
      }
    }
  }

  if (collection === 'brands') {
    if (!str(body.name)) e.name = 'Укажите название';
    if (!str(body.country)) e.country = 'Укажите страну';
    const year = Number(body.foundedYear);
    if (!Number.isInteger(year) || year < 1800 || year > yearNow) e.foundedYear = 'Некорректный год основания';
  }

  if (collection === 'categories') {
    if (!str(body.name)) e.name = 'Укажите название';
    else {
      const dup = db.categories.find(
        (item) => item.name.toLowerCase() === str(body.name).toLowerCase() && item.id !== id && !item.deletedAt
      );
      if (dup) e.name = 'Такая категория уже существует';
    }
  }

  if (collection === 'cars') {
    if (!str(body.name)) e.name = 'Укажите модель';
    if (!str(body.maker)) e.maker = 'Укажите марку';
    const yearFrom = Number(body.yearFrom);
    const yearTo = Number(body.yearTo);
    if (!Number.isInteger(yearFrom) || yearFrom < 1980 || yearFrom > yearNow + 1) {
      e.yearFrom = 'Некорректный год начала';
    }
    if (!Number.isInteger(yearTo) || yearTo < 1980 || yearTo > yearNow + 1) {
      e.yearTo = 'Некорректный год окончания';
    } else if (Number.isInteger(yearFrom) && yearTo < yearFrom) {
      e.yearTo = 'Год по не может быть меньше года с';
    }
  }

  if (collection === 'customers') {
    if (!str(body.fullName)) e.fullName = 'Укажите ФИО';
    if (!str(body.email)) e.email = 'Укажите адрес почты';
    else if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(str(body.email))) e.email = 'Некорректный адрес почты';
    else {
      const dup = db.customers.find(
        (item) => item.email.toLowerCase() === str(body.email).toLowerCase() && item.id !== id && !item.deletedAt
      );
      if (dup) e.email = 'Такой email уже зарегистрирован';
    }
    if (!str(body.phone)) e.phone = 'Укажите телефон';
  }

  return e;
}

function normalize(collection, body) {
  const num = (v) => (v == null || v === '' ? null : Number(v));
  const str = (v) => (v == null ? '' : String(v).trim());
  const ids = (v) => (Array.isArray(v) ? v.map(Number).filter((n) => Number.isInteger(n)) : []);

  switch (collection) {
    case 'parts':
      return {
        name: str(body.name),
        sku: str(body.sku),
        year: num(body.year),
        price: num(body.price),
        brandId: num(body.brandId),
        categoryIds: ids(body.categoryIds),
        carModelIds: ids(body.carModelIds),
        stockTotal: num(body.stockTotal) ?? 0,
        stockAvailable: body.stockAvailable == null || body.stockAvailable === ''
          ? num(body.stockTotal) ?? 0
          : num(body.stockAvailable),
      };
    case 'brands':
      return { name: str(body.name), country: str(body.country), foundedYear: num(body.foundedYear) };
    case 'categories':
      return { name: str(body.name), description: str(body.description) };
    case 'cars':
      return {
        name: str(body.name),
        maker: str(body.maker),
        yearFrom: num(body.yearFrom),
        yearTo: num(body.yearTo),
      };
    case 'customers':
      return { fullName: str(body.fullName), email: str(body.email), phone: str(body.phone) };
    default:
      return { ...body };
  }
}

function conflictOnDelete(collection, id) {
  if (collection === 'brands') {
    const count = db.parts.filter((item) => item.brandId === id).length;
    if (count) return `Бренд нельзя удалить: на него ссылаются ${count} запчастей.`;
  }
  if (collection === 'categories') {
    const count = db.parts.filter((item) => (item.categoryIds || []).includes(id)).length;
    if (count) return `Категорию нельзя удалить: на неё ссылаются ${count} запчастей.`;
  }
  if (collection === 'cars') {
    const count = db.parts.filter((item) => (item.carModelIds || []).includes(id)).length;
    if (count) return `Автомобиль нельзя удалить: на него ссылаются ${count} запчастей.`;
  }
  return null;
}

function upsertCard(customerId, card) {
  const current = db.cards.find((item) => item.customerId === customerId);
  const payload = {
    customerId,
    number: String((card && card.number) || `AP-${1000 + customerId}`),
    issuedAt: (card && card.issuedAt) || new Date().toISOString(),
    discountPercent: Number((card && card.discountPercent) ?? 5),
    active: card && card.active === false ? false : true,
  };
  if (current) {
    Object.assign(current, payload);
  } else {
    push('cards', payload);
  }
}

function allowedOrigin(res) {
  const requestOrigin = res.req && res.req.headers ? res.req.headers.origin : '';
  if (ORIGINS.includes('*')) return '*';
  if (requestOrigin && ORIGINS.includes(requestOrigin)) return requestOrigin;
  return ORIGINS[0];
}

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', allowedOrigin(res));
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function fail(res, status, message) {
  send(res, status, { message });
}

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function currentUser(req) {
  const header = req.headers['authorization'] || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.users.find((user) => user.id === payload.sub && !user.deletedAt) || null;
}

const ROLE_LEVEL = { buyer: 1, manager: 2, admin: 3 };

function requireRole(res, user, minRole) {
  if (!user) {
    fail(res, 401, 'Требуется аутентификация');
    return false;
  }
  if (ROLE_LEVEL[user.role] < ROLE_LEVEL[minRole]) {
    fail(res, 403, `Операция доступна начиная с роли «${minRole}»`);
    return false;
  }
  return true;
}

const COLLECTIONS = ['parts', 'brands', 'categories', 'cars', 'customers'];

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();
  const user = currentUser(req);

  if (q.__fail) {
    return fail(res, Number(q.__fail), 'Ошибка вызвана намеренно параметром __fail');
  }

  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }

  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  if (path === '/api/auth/register' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const errors = {};
    const username = String(body.username || '').trim();
    const password = String(body.password || '');
    if (username.length < 3) errors.username = 'Логин не короче трёх символов';
    else if (db.users.find((item) => item.username === username)) errors.username = 'Такой логин уже занят';
    if (password.length < 8) errors.password = 'Пароль не короче восьми символов';
    else if (!/\d/.test(password)) errors.password = 'Пароль должен содержать цифру';
    if (body.email && !/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(String(body.email))) {
      errors.email = 'Некорректный адрес почты';
    }

    if (Object.keys(errors).length) {
      return send(res, 422, { message: 'Ошибка валидации', errors });
    }

    const id = push('users', {
      username,
      passwordHash: hash(password),
      fullName: String(body.fullName || username),
      email: String(body.email || ''),
      role: 'buyer',
      customerId: null,
    });
    return send(res, 201, expandUser(db.users.find((item) => item.id === id)));
  }

  if (path === '/api/auth/login' && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

    const found = db.users.find(
      (item) => item.username === String(body.username || '').trim() && !item.deletedAt
    );
    if (!found || found.passwordHash !== hash(String(body.password || ''))) {
      return fail(res, 401, 'Неверный логин или пароль');
    }

    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);

    return send(res, 200, {
      accessToken,
      refreshToken,
      expiresIn: ACCESS_TTL,
      user: expandUser(found),
    });
  }

  if (path === '/api/auth/refresh' && method === 'POST') {
    const body = await readBody(req);
    const token = body && body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    const found = db.users.find((item) => item.id === payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');

    db.refreshTokens.delete(token);
    const now = Math.floor(Date.now() / 1000);
    const accessToken = sign({ sub: found.id, role: found.role, type: 'access', exp: now + ACCESS_TTL });
    const refreshToken = sign({ sub: found.id, type: 'refresh', exp: now + REFRESH_TTL });
    db.refreshTokens.add(refreshToken);

    return send(res, 200, { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: expandUser(found) });
  }

  if (path === '/api/auth/me' && method === 'GET') {
    if (!user) return fail(res, 401, 'Требуется аутентификация');
    return send(res, 200, expandUser(user));
  }

  if (path === '/api/auth/logout' && method === 'POST') {
    const body = await readBody(req);
    if (body && body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }

  if (path === '/api/users' && method === 'GET') {
    if (!requireRole(res, user, 'admin')) return;
    const rows = applySort(db.users.filter((item) => !item.deletedAt), q.sort);
    const page = paginate(rows, q);
    return send(res, 200, { ...page, items: page.items.map(expandUser) });
  }

  let m = path.match(/^\/api\/parts\/(\d+)\/sell$/);
  if (m && method === 'POST') {
    if (!requireRole(res, user, 'manager')) return;
    const part = db.parts.find((item) => item.id === Number(m[1]) && !item.deletedAt);
    if (!part) return fail(res, 404, 'Запчасть не найдена');
    const body = await readBody(req);
    const quantity = Number((body && body.quantity) || 1);
    if (!Number.isInteger(quantity) || quantity < 1) {
      return send(res, 422, { message: 'Ошибка валидации', errors: { quantity: 'Количество — целое, не меньше 1' } });
    }
    if (part.stockAvailable < quantity) {
      return fail(res, 409, 'Нет доступного остатка для продажи');
    }
    part.stockAvailable -= quantity;
    return send(res, 200, expandPart(part));
  }

  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);
  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    if (!requireRole(res, user, 'manager')) return;

    const body = await readBody(req);
    const ids = Array.isArray(body && body.ids) ? body.ids.map(Number) : [];
    if (!ids.length) {
      return send(res, 422, { message: 'Ошибка валидации', errors: { ids: 'Передайте непустой список идентификаторов' } });
    }

    for (const id of ids) {
      const conflict = conflictOnDelete(collection, id);
      if (conflict) return fail(res, 409, conflict);
    }

    let deleted = 0;
    for (const row of db[collection]) {
      if (ids.includes(row.id) && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    }
    return send(res, 200, { deleted });
  }

  m = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);
  if (m) {
    const collection = m[1];
    const id = m[2] ? Number(m[2]) : null;
    const action = m[3] || null;

    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    const expand = EXPANDERS[collection];

    if (action === 'restore' && method === 'POST') {
      if (!requireRole(res, user, 'admin')) return;
      const row = db[collection].find((item) => item.id === id);
      if (!row) return fail(res, 404, 'Объект не найден');
      row.deletedAt = null;
      return send(res, 200, expand(row));
    }

    if (id === null && method === 'GET') {
      let rows = db[collection];
      if (q.includeDeleted !== 'true') rows = rows.filter((item) => !item.deletedAt);
      rows = applyFilters(collection, rows, q);
      rows = applySort(rows, q.sort);
      const page = paginate(rows, q);
      return send(res, 200, { ...page, items: page.items.map(expand) });
    }

    if (id !== null && method === 'GET') {
      const row = db[collection].find((item) => item.id === id && (q.includeDeleted === 'true' || !item.deletedAt));
      if (!row) return fail(res, 404, 'Объект не найден');
      return send(res, 200, expand(row));
    }

    if (id === null && method === 'POST') {
      if (!requireRole(res, user, 'manager')) return;
      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const errors = validate(collection, body);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });

      const data = normalize(collection, body);
      const newId = push(collection, data);
      const row = db[collection].find((item) => item.id === newId);
      if (collection === 'parts' && (row.stockAvailable == null || Number.isNaN(row.stockAvailable))) {
        row.stockAvailable = row.stockTotal;
      }
      if (collection === 'customers') upsertCard(newId, body.card);
      return send(res, 201, expand(row));
    }

    if (id !== null && (method === 'PUT' || method === 'PATCH')) {
      if (!requireRole(res, user, 'manager')) return;
      const row = db[collection].find((item) => item.id === id && !item.deletedAt);
      if (!row) return fail(res, 404, 'Объект не найден');

      const body = await readBody(req);
      if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');

      const merged = method === 'PATCH' ? { ...row, ...body } : body;
      const errors = validate(collection, merged, id);
      if (Object.keys(errors).length) return send(res, 422, { message: 'Ошибка валидации', errors });

      Object.assign(row, normalize(collection, merged));
      if (collection === 'customers') upsertCard(id, merged.card);
      return send(res, 200, expand(row));
    }

    if (id !== null && method === 'DELETE') {
      const hard = q.hard === 'true';
      if (!requireRole(res, user, hard ? 'admin' : 'manager')) return;

      const index = db[collection].findIndex((item) => item.id === id);
      if (index === -1) return fail(res, 404, 'Объект не найден');

      const conflict = conflictOnDelete(collection, id);
      if (conflict) return fail(res, 409, conflict);

      if (hard) {
        db[collection].splice(index, 1);
      } else {
        db[collection][index].deletedAt = new Date().toISOString();
      }
      return send(res, 204);
    }
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

seed();

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }

  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((resolve) => setTimeout(resolve, Math.min(delay, 10000)));

  const started = Date.now();
  try {
    await handle(req, res, url);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) fail(res, 500, 'Внутренняя ошибка сервера: ' + err.message);
  }
  console.log(
    `${req.method.padEnd(6)} ${url.pathname}${url.search}  → ${res.statusCode}  ${Date.now() - started} мс`
  );
});

server.listen(PORT, HOST, () => {
  console.log('');
  console.log('  Учебное API «Магазин автозапчастей»');
  console.log(`  Адрес:              http://${HOST}:${PORT}/api`);
  console.log(`  Разрешённые источники: ${ORIGINS.join(', ')}`);
  console.log(`  Срок жизни токена:  ${ACCESS_TTL} с`);
  console.log('');
  console.log('  Учётные записи:  admin/admin123   manager/manager123   buyer/buyer123');
  console.log('  Сброс данных:    POST /api/__reset');
  console.log('  Задержка ответа: любой запрос с ?__delay=1500');
  console.log('  Ошибка по требованию: любой запрос с ?__fail=500');
  console.log('');
});
