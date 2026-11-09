import '../models/auto_part.dart';
import '../models/brand.dart';
import '../models/category.dart';

const seedCategories = <Category>[
  Category(id: 1, name: 'Двигатель'),
  Category(id: 2, name: 'Тормозная система'),
  Category(id: 3, name: 'Подвеска'),
  Category(id: 4, name: 'Электрика'),
  Category(id: 5, name: 'Фильтры'),
  Category(id: 6, name: 'Трансмиссия'),
  Category(id: 7, name: 'Охлаждение'),
  Category(id: 8, name: 'Масла и жидкости'),
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

const seedParts = <AutoPart>[
  AutoPart(id: 1, name: 'Свеча зажигания Bosch Super Plus', sku: 'FR7DC+', year: 2022, price: 390, brandId: 1, categoryId: 1),
  AutoPart(id: 2, name: 'Свеча зажигания NGK Laser Iridium', sku: 'ILZKR7B-11S', year: 2023, price: 1450, brandId: 2, categoryId: 1),
  AutoPart(id: 3, name: 'Масляный фильтр Mann W 712/95', sku: 'W71295', year: 2021, price: 620, brandId: 3, categoryId: 5),
  AutoPart(id: 4, name: 'Воздушный фильтр Mann C 27 192', sku: 'C27192', year: 2020, price: 980, brandId: 3, categoryId: 5),
  AutoPart(id: 5, name: 'Салонный фильтр Mann CU 2939', sku: 'CU2939', year: 2022, price: 870, brandId: 3, categoryId: 5),
  AutoPart(id: 6, name: 'Тормозные колодки Brembo P 85 125', sku: 'P85125', year: 2023, price: 4890, brandId: 4, categoryId: 2),
  AutoPart(id: 7, name: 'Тормозной диск Brembo 09.9772.11', sku: '09977211', year: 2022, price: 6720, brandId: 4, categoryId: 2),
  AutoPart(id: 8, name: 'Амортизатор KYB Excel-G 334238', sku: '334238', year: 2021, price: 5340, brandId: 8, categoryId: 3),
  AutoPart(id: 9, name: 'Амортизатор Sachs 317 572', sku: '317572', year: 2020, price: 4980, brandId: 5, categoryId: 3),
  AutoPart(id: 10, name: 'Комплект сцепления Sachs 3000 951 011', sku: '3000951011', year: 2019, price: 12490, brandId: 5, categoryId: 6),
  AutoPart(id: 11, name: 'Комплект сцепления Valeo 826494', sku: '826494', year: 2021, price: 11200, brandId: 6, categoryId: 6),
  AutoPart(id: 12, name: 'Щётки стеклоочистителя Valeo 574307', sku: '574307', year: 2024, price: 1890, brandId: 6, categoryId: 4),
  AutoPart(id: 13, name: 'Генератор Denso DAN1055', sku: 'DAN1055', year: 2018, price: 18750, brandId: 7, categoryId: 4),
  AutoPart(id: 14, name: 'Стартер Denso DSN940', sku: 'DSN940', year: 2019, price: 15400, brandId: 7, categoryId: 4),
  AutoPart(id: 15, name: 'Моторное масло Mobil 1 5W-30 4л', sku: 'MOB5W30-4', year: 2024, price: 4590, brandId: 9, categoryId: 8),
  AutoPart(id: 16, name: 'Моторное масло Castrol EDGE 5W-40 4л', sku: 'CST5W40-4', year: 2023, price: 4320, brandId: 10, categoryId: 8),
  AutoPart(id: 17, name: 'Антифриз Castrol Radicool 5л', sku: 'CSTRAD-5', year: 2022, price: 2180, brandId: 10, categoryId: 7),
  AutoPart(id: 18, name: 'Термостат Bosch 1 987 724 001', sku: '1987724001', year: 2020, price: 1760, brandId: 1, categoryId: 7),
  AutoPart(id: 19, name: 'Ремень ГРМ Bosch 1 987 949 565', sku: '1987949565', year: 2021, price: 2890, brandId: 1, categoryId: 1),
  AutoPart(id: 20, name: 'Кислородный датчик NGK 95801', sku: 'NGK95801', year: 2022, price: 7650, brandId: 2, categoryId: 4),
  AutoPart(id: 21, name: 'Тормозные колодки Bosch 0 986 494 136', sku: '0986494136', year: 2023, price: 3120, brandId: 1, categoryId: 2),
  AutoPart(id: 22, name: 'Стойка стабилизатора KYB KS1094', sku: 'KS1094', year: 2020, price: 1540, brandId: 8, categoryId: 3),
  AutoPart(id: 23, name: 'Масляный фильтр Bosch 0 451 103 316', sku: '0451103316', year: 2024, price: 540, brandId: 1, categoryId: 5),
  AutoPart(id: 24, name: 'Помпа охлаждения Valeo 506698', sku: '506698', year: 2019, price: 3980, brandId: 6, categoryId: 7),
];

Category? categoryById(int id) {
  for (final item in seedCategories) {
    if (item.id == id) return item;
  }
  return null;
}

Brand? brandById(int id) {
  for (final item in seedBrands) {
    if (item.id == id) return item;
  }
  return null;
}

List<String> get seedCountries {
  final values = seedBrands.map((b) => b.country).toSet().toList()..sort();
  return values;
}
