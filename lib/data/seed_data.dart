import '../models/auto_part.dart';
import '../models/brand.dart';
import '../models/car_model.dart';
import '../models/category.dart';
import '../models/customer.dart';

const seedCategories = <Category>[
  Category(id: 1, name: 'Двигатель', description: 'Свечи, ремни, датчики двигателя'),
  Category(id: 2, name: 'Тормозная система', description: 'Колодки, диски, суппорты'),
  Category(id: 3, name: 'Подвеска', description: 'Амортизаторы и стойки'),
  Category(id: 4, name: 'Электрика', description: 'Генераторы, стартеры, датчики'),
  Category(id: 5, name: 'Фильтры', description: 'Масляные, воздушные, салонные'),
  Category(id: 6, name: 'Трансмиссия', description: 'Сцепление и связанные узлы'),
  Category(id: 7, name: 'Охлаждение', description: 'Помпы, термостаты, антифриз'),
  Category(id: 8, name: 'Масла и жидкости', description: 'Моторные масла и техжидкости'),
];

const seedBrands = <Brand>[
  Brand(id: 1, name: 'Bosch', country: 'Германия', foundedYear: 1886),
  Brand(id: 2, name: 'NGK', country: 'Япония', foundedYear: 1936),
  Brand(id: 3, name: 'Mann-Filter', country: 'Германия', foundedYear: 1941),
  Brand(id: 4, name: 'Brembo', country: 'Италия', foundedYear: 1961),
  Brand(id: 5, name: 'Sachs', country: 'Германия', foundedYear: 1895),
  Brand(id: 6, name: 'Valeo', country: 'Франция', foundedYear: 1923),
  Brand(id: 7, name: 'Denso', country: 'Япония', foundedYear: 1949),
  Brand(id: 8, name: 'KYB', country: 'Япония', foundedYear: 1919),
  Brand(id: 9, name: 'Mobil', country: 'США', foundedYear: 1866),
  Brand(id: 10, name: 'Castrol', country: 'Великобритания', foundedYear: 1899),
];


const brandProducedCategories = <int, List<int>>{
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

const seedCarModels = <CarModel>[
  CarModel(id: 1, name: 'Camry', maker: 'Toyota', yearFrom: 2018, yearTo: 2024),
  CarModel(id: 2, name: 'RAV4', maker: 'Toyota', yearFrom: 2019, yearTo: 2024),
  CarModel(id: 3, name: 'Polo', maker: 'Volkswagen', yearFrom: 2015, yearTo: 2022),
  CarModel(id: 4, name: 'Tiguan', maker: 'Volkswagen', yearFrom: 2017, yearTo: 2024),
  CarModel(id: 5, name: '3 Series', maker: 'BMW', yearFrom: 2019, yearTo: 2024),
  CarModel(id: 6, name: 'Solaris', maker: 'Hyundai', yearFrom: 2017, yearTo: 2024),
  CarModel(id: 7, name: 'Rio', maker: 'Kia', yearFrom: 2017, yearTo: 2023),
  CarModel(id: 8, name: 'Vesta', maker: 'Lada', yearFrom: 2015, yearTo: 2024),
  CarModel(id: 9, name: 'Octavia', maker: 'Skoda', yearFrom: 2017, yearTo: 2024),
  CarModel(id: 10, name: 'Focus', maker: 'Ford', yearFrom: 2015, yearTo: 2022),
];

final seedCustomers = <Customer>[
  Customer(
    id: 1,
    fullName: 'Иван Петров',
    email: 'ivan.petrov@mail.ru',
    phone: '+79001234567',
    card: LoyaltyCard(number: 'AP-1001', issuedAt: DateTime(2023, 2, 10), discountPercent: 5, active: true),
  ),
  Customer(
    id: 2,
    fullName: 'Мария Сидорова',
    email: 'maria.sidorova@gmail.com',
    phone: '+79007654321',
    card: LoyaltyCard(number: 'AP-1002', issuedAt: DateTime(2024, 1, 15), discountPercent: 10, active: true),
  ),
  Customer(
    id: 3,
    fullName: 'Алексей Козлов',
    email: 'akozlov@yandex.ru',
    phone: '+79111223344',
    card: LoyaltyCard(number: 'AP-1003', issuedAt: DateTime(2022, 11, 3), discountPercent: 3, active: false),
  ),
  Customer(
    id: 4,
    fullName: 'Ольга Новикова',
    email: 'olga.novikova@mail.ru',
    phone: '+79225556677',
    card: LoyaltyCard(number: 'AP-1004', issuedAt: DateTime(2024, 6, 20), discountPercent: 7, active: true),
  ),
  Customer(
    id: 5,
    fullName: 'Дмитрий Орлов',
    email: 'd.orlov@outlook.com',
    phone: '+79031112233',
    card: LoyaltyCard(number: 'AP-1005', issuedAt: DateTime(2023, 8, 1), discountPercent: 15, active: true),
  ),
];

const seedParts = <AutoPart>[
  AutoPart(id: 1, name: 'Свеча зажигания Bosch Super Plus', sku: 'FR7DC+', year: 2022, price: 390, brandId: 1, categoryIds: [1], carModelIds: [6, 7, 8], stockTotal: 40, stockAvailable: 28),
  AutoPart(id: 2, name: 'Свеча зажигания NGK Laser Iridium', sku: 'ILZKR7B-11S', year: 2023, price: 1450, brandId: 2, categoryIds: [1], carModelIds: [1, 2], stockTotal: 24, stockAvailable: 18),
  AutoPart(id: 3, name: 'Масляный фильтр Mann W 712/95', sku: 'W71295', year: 2021, price: 620, brandId: 3, categoryIds: [5], carModelIds: [3, 9, 10], stockTotal: 30, stockAvailable: 21),
  AutoPart(id: 4, name: 'Воздушный фильтр Mann C 27 192', sku: 'C27192', year: 2020, price: 980, brandId: 3, categoryIds: [5], carModelIds: [4, 9], stockTotal: 18, stockAvailable: 12),
  AutoPart(id: 5, name: 'Салонный фильтр Mann CU 2939', sku: 'CU2939', year: 2022, price: 870, brandId: 3, categoryIds: [5], carModelIds: [3, 4, 9], stockTotal: 22, stockAvailable: 16),
  AutoPart(id: 6, name: 'Тормозные колодки Brembo P 85 125', sku: 'P85125', year: 2023, price: 4890, brandId: 4, categoryIds: [2], carModelIds: [5], stockTotal: 12, stockAvailable: 7),
  AutoPart(id: 7, name: 'Тормозной диск Brembo 09.9772.11', sku: '09977211', year: 2022, price: 6720, brandId: 4, categoryIds: [2], carModelIds: [5], stockTotal: 10, stockAvailable: 6),
  AutoPart(id: 8, name: 'Амортизатор KYB Excel-G 334238', sku: '334238', year: 2021, price: 5340, brandId: 8, categoryIds: [3], carModelIds: [1, 2], stockTotal: 14, stockAvailable: 9),
  AutoPart(id: 9, name: 'Амортизатор Sachs 317 572', sku: '317572', year: 2020, price: 4980, brandId: 5, categoryIds: [3], carModelIds: [3, 10], stockTotal: 16, stockAvailable: 11),
  AutoPart(id: 10, name: 'Комплект сцепления Sachs 3000 951 011', sku: '3000951011', year: 2019, price: 12490, brandId: 5, categoryIds: [6], carModelIds: [6, 7], stockTotal: 8, stockAvailable: 4),
  AutoPart(id: 11, name: 'Комплект сцепления Valeo 826494', sku: '826494', year: 2021, price: 11200, brandId: 6, categoryIds: [6], carModelIds: [3, 9], stockTotal: 7, stockAvailable: 3),
  AutoPart(id: 12, name: 'Щётки стеклоочистителя Valeo 574307', sku: '574307', year: 2024, price: 1890, brandId: 6, categoryIds: [4], carModelIds: [4, 9], stockTotal: 20, stockAvailable: 15),
  AutoPart(id: 13, name: 'Генератор Denso DAN1055', sku: 'DAN1055', year: 2018, price: 18750, brandId: 7, categoryIds: [4], carModelIds: [1, 2], stockTotal: 5, stockAvailable: 2),
  AutoPart(id: 14, name: 'Стартер Denso DSN940', sku: 'DSN940', year: 2019, price: 15400, brandId: 7, categoryIds: [4], carModelIds: [1, 5], stockTotal: 6, stockAvailable: 3),
  AutoPart(id: 15, name: 'Моторное масло Mobil 1 5W-30 4л', sku: 'MOB5W30-4', year: 2024, price: 4590, brandId: 9, categoryIds: [8], carModelIds: [1, 2, 5], stockTotal: 25, stockAvailable: 19),
  AutoPart(id: 16, name: 'Моторное масло Castrol EDGE 5W-40 4л', sku: 'CST5W40-4', year: 2023, price: 4320, brandId: 10, categoryIds: [8], carModelIds: [3, 6, 8], stockTotal: 26, stockAvailable: 20),
  AutoPart(id: 17, name: 'Антифриз Castrol Radicool 5л', sku: 'CSTRAD-5', year: 2022, price: 2180, brandId: 10, categoryIds: [7, 8], carModelIds: [6, 7, 8], stockTotal: 18, stockAvailable: 13),
  AutoPart(id: 18, name: 'Термостат Bosch 1 987 724 001', sku: '1987724001', year: 2020, price: 1760, brandId: 1, categoryIds: [7], carModelIds: [6, 7], stockTotal: 15, stockAvailable: 10),
  AutoPart(id: 19, name: 'Ремень ГРМ Bosch 1 987 949 565', sku: '1987949565', year: 2021, price: 2890, brandId: 1, categoryIds: [1], carModelIds: [3, 9, 10], stockTotal: 12, stockAvailable: 8),
  AutoPart(id: 20, name: 'Кислородный датчик NGK 95801', sku: 'NGK95801', year: 2022, price: 7650, brandId: 2, categoryIds: [1, 4], carModelIds: [1, 5], stockTotal: 9, stockAvailable: 5),
  AutoPart(id: 21, name: 'Тормозные колодки Bosch 0 986 494 136', sku: '0986494136', year: 2023, price: 3120, brandId: 1, categoryIds: [2], carModelIds: [6, 7, 8], stockTotal: 20, stockAvailable: 14),
  AutoPart(id: 22, name: 'Стойка стабилизатора KYB KS1094', sku: 'KS1094', year: 2020, price: 1540, brandId: 8, categoryIds: [3], carModelIds: [6, 8], stockTotal: 17, stockAvailable: 12),
  AutoPart(id: 23, name: 'Масляный фильтр Bosch 0 451 103 316', sku: '0451103316', year: 2024, price: 540, brandId: 1, categoryIds: [5], carModelIds: [6, 7, 10], stockTotal: 35, stockAvailable: 27),
  AutoPart(id: 24, name: 'Помпа охлаждения Valeo 506698', sku: '506698', year: 2019, price: 3980, brandId: 6, categoryIds: [7], carModelIds: [3, 9], stockTotal: 11, stockAvailable: 6),
];

T? byId<T>(List<T> items, int id, int Function(T item) idOf) {
  for (final item in items) {
    if (idOf(item) == id) return item;
  }
  return null;
}

List<String> uniqueSorted(Iterable<String> values) {
  final result = values.toSet().toList()..sort();
  return result;
}
