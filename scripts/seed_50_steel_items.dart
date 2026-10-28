import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:super_market/objectbox.g.dart';
import 'package:super_market/model/entity_item.dart';
import 'package:super_market/model/entity_item_batch.dart';

class SteelItemDef {
  final String name;
  final String sku;
  final String barcode;
  final String category;
  final String unit;
  final double cost;
  final double sell;
  final String hsn;
  final int qty;

  const SteelItemDef({
    required this.name,
    required this.sku,
    required this.barcode,
    required this.category,
    required this.unit,
    required this.cost,
    required this.sell,
    required this.hsn,
    required this.qty,
  });
}

final List<SteelItemDef> steelData = [
  // ── 1. TMT Rebars (Saria) Fe 550D / Fe 500D (IS 1786) ──
  const SteelItemDef(
    name: 'Tata Tiscon TMT Rebar 8mm Fe 550D',
    sku: 'TMT-8MM-TATA',
    barcode: '890721400101',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 58.50,
    sell: 62.00,
    hsn: '72142090',
    qty: 15000,
  ),
  const SteelItemDef(
    name: 'Tata Tiscon TMT Rebar 10mm Fe 550D',
    sku: 'TMT-10MM-TATA',
    barcode: '890721400102',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 57.50,
    sell: 61.00,
    hsn: '72142090',
    qty: 18000,
  ),
  const SteelItemDef(
    name: 'Tata Tiscon TMT Rebar 12mm Fe 550D',
    sku: 'TMT-12MM-TATA',
    barcode: '890721400103',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 56.50,
    sell: 60.00,
    hsn: '72142090',
    qty: 25000,
  ),
  const SteelItemDef(
    name: 'Tata Tiscon TMT Rebar 16mm Fe 550D',
    sku: 'TMT-16MM-TATA',
    barcode: '890721400104',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 56.50,
    sell: 60.00,
    hsn: '72142090',
    qty: 20000,
  ),
  const SteelItemDef(
    name: 'Tata Tiscon TMT Rebar 20mm Fe 550D',
    sku: 'TMT-20MM-TATA',
    barcode: '890721400105',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 56.50,
    sell: 60.00,
    hsn: '72142090',
    qty: 16000,
  ),
  const SteelItemDef(
    name: 'Tata Tiscon TMT Rebar 25mm Fe 550D',
    sku: 'TMT-25MM-TATA',
    barcode: '890721400106',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 57.00,
    sell: 61.00,
    hsn: '72142090',
    qty: 12000,
  ),
  const SteelItemDef(
    name: 'Tata Tiscon TMT Rebar 32mm Fe 550D',
    sku: 'TMT-32MM-TATA',
    barcode: '890721400107',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 58.00,
    sell: 62.50,
    hsn: '72142090',
    qty: 8500,
  ),
  const SteelItemDef(
    name: 'JSW Neosteel TMT Rebar 8mm Fe 550D',
    sku: 'TMT-8MM-JSW',
    barcode: '890721400108',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 56.50,
    sell: 60.00,
    hsn: '72142090',
    qty: 16000,
  ),
  const SteelItemDef(
    name: 'JSW Neosteel TMT Rebar 10mm Fe 550D',
    sku: 'TMT-10MM-JSW',
    barcode: '890721400109',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 55.50,
    sell: 59.00,
    hsn: '72142090',
    qty: 20000,
  ),
  const SteelItemDef(
    name: 'JSW Neosteel TMT Rebar 12mm Fe 550D',
    sku: 'TMT-12MM-JSW',
    barcode: '890721400110',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 54.50,
    sell: 58.00,
    hsn: '72142090',
    qty: 28000,
  ),
  const SteelItemDef(
    name: 'JSW Neosteel TMT Rebar 16mm Fe 550D',
    sku: 'TMT-16MM-JSW',
    barcode: '890721400111',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 54.50,
    sell: 58.00,
    hsn: '72142090',
    qty: 22000,
  ),
  const SteelItemDef(
    name: 'JSW Neosteel TMT Rebar 20mm Fe 550D',
    sku: 'TMT-20MM-JSW',
    barcode: '890721400112',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 54.50,
    sell: 58.00,
    hsn: '72142090',
    qty: 15000,
  ),
  const SteelItemDef(
    name: 'SAIL TMT Rebar 8mm Fe 500D',
    sku: 'TMT-8MM-SAIL',
    barcode: '890721400113',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 54.00,
    sell: 57.50,
    hsn: '72142090',
    qty: 14000,
  ),
  const SteelItemDef(
    name: 'SAIL TMT Rebar 10mm Fe 500D',
    sku: 'TMT-10MM-SAIL',
    barcode: '890721400114',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 53.00,
    sell: 56.50,
    hsn: '72142090',
    qty: 17000,
  ),
  const SteelItemDef(
    name: 'SAIL TMT Rebar 12mm Fe 500D',
    sku: 'TMT-12MM-SAIL',
    barcode: '890721400115',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 52.00,
    sell: 55.50,
    hsn: '72142090',
    qty: 24000,
  ),
  const SteelItemDef(
    name: 'SAIL TMT Rebar 16mm Fe 500D',
    sku: 'TMT-16MM-SAIL',
    barcode: '890721400116',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 52.00,
    sell: 55.50,
    hsn: '72142090',
    qty: 19000,
  ),
  const SteelItemDef(
    name: 'Jindal Panther TMT 10mm Fe 550D',
    sku: 'TMT-10MM-JINDAL',
    barcode: '890721400117',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 55.00,
    sell: 58.50,
    hsn: '72142090',
    qty: 16500,
  ),
  const SteelItemDef(
    name: 'Jindal Panther TMT 12mm Fe 550D',
    sku: 'TMT-12MM-JINDAL',
    barcode: '890721400118',
    category: 'TMT Rebars (Saria)',
    unit: 'Kg',
    cost: 54.00,
    sell: 57.50,
    hsn: '72142090',
    qty: 21000,
  ),

  // ── 2. MS Angles (L-Profiles IS 2062 E250) ──
  const SteelItemDef(
    name: 'MS Angle 25x25x3 mm (6 Mtrs)',
    sku: 'ANG-25X25X3',
    barcode: '890721400119',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 325.00,
    sell: 365.00,
    hsn: '72162100',
    qty: 550,
  ),
  const SteelItemDef(
    name: 'MS Angle 25x25x5 mm (6 Mtrs)',
    sku: 'ANG-25X25X5',
    barcode: '890721400120',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 510.00,
    sell: 575.00,
    hsn: '72162100',
    qty: 420,
  ),
  const SteelItemDef(
    name: 'MS Angle 35x35x5 mm (6 Mtrs)',
    sku: 'ANG-35X35X5',
    barcode: '890721400121',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 755.00,
    sell: 840.00,
    hsn: '72162100',
    qty: 480,
  ),
  const SteelItemDef(
    name: 'MS Angle 40x40x5 mm (6 Mtrs)',
    sku: 'ANG-40X40X5',
    barcode: '890721400122',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 870.00,
    sell: 970.00,
    hsn: '72162100',
    qty: 620,
  ),
  const SteelItemDef(
    name: 'MS Angle 40x40x6 mm (6 Mtrs)',
    sku: 'ANG-40X40X6',
    barcode: '890721400123',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 1020.00,
    sell: 1140.00,
    hsn: '72162100',
    qty: 360,
  ),
  const SteelItemDef(
    name: 'MS Angle 50x50x5 mm (6 Mtrs)',
    sku: 'ANG-50X50X5',
    barcode: '890721400124',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 1100.00,
    sell: 1225.00,
    hsn: '72162100',
    qty: 540,
  ),
  const SteelItemDef(
    name: 'MS Angle 50x50x6 mm (6 Mtrs)',
    sku: 'ANG-50X50X6',
    barcode: '890721400125',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 1300.00,
    sell: 1450.00,
    hsn: '72162100',
    qty: 680,
  ),
  const SteelItemDef(
    name: 'MS Angle 65x65x6 mm (6 Mtrs)',
    sku: 'ANG-65X65X6',
    barcode: '890721400126',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 1680.00,
    sell: 1880.00,
    hsn: '72162100',
    qty: 410,
  ),
  const SteelItemDef(
    name: 'MS Angle 65x65x8 mm (6 Mtrs)',
    sku: 'ANG-65X65X8',
    barcode: '890721400127',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 2200.00,
    sell: 2450.00,
    hsn: '72162100',
    qty: 290,
  ),
  const SteelItemDef(
    name: 'MS Angle 75x75x6 mm (6 Mtrs)',
    sku: 'ANG-75X75X6',
    barcode: '890721400128',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 1980.00,
    sell: 2200.00,
    hsn: '72162100',
    qty: 380,
  ),
  const SteelItemDef(
    name: 'MS Angle 75x75x8 mm (6 Mtrs)',
    sku: 'ANG-75X75X8',
    barcode: '890721400129',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 2580.00,
    sell: 2880.00,
    hsn: '72162100',
    qty: 270,
  ),
  const SteelItemDef(
    name: 'MS Angle 100x100x8 mm (6 Mtrs)',
    sku: 'ANG-100X100X8',
    barcode: '890721400130',
    category: 'MS Angles',
    unit: 'Pcs',
    cost: 3500.00,
    sell: 3900.00,
    hsn: '72162100',
    qty: 190,
  ),

  // ── 3. MS Channels (ISMC, 6m IS 2062) ──
  const SteelItemDef(
    name: 'MS Channel ISMC 75x40 mm (6 Mtrs)',
    sku: 'CH-ISMC-75',
    barcode: '890721400131',
    category: 'MS Channels (ISMC)',
    unit: 'Pcs',
    cost: 2080.00,
    sell: 2320.00,
    hsn: '72163100',
    qty: 340,
  ),
  const SteelItemDef(
    name: 'MS Channel ISMC 100x50 mm (6 Mtrs)',
    sku: 'CH-ISMC-100',
    barcode: '890721400132',
    category: 'MS Channels (ISMC)',
    unit: 'Pcs',
    cost: 2780.00,
    sell: 3100.00,
    hsn: '72163100',
    qty: 410,
  ),
  const SteelItemDef(
    name: 'MS Channel ISMC 125x65 mm (6 Mtrs)',
    sku: 'CH-ISMC-125',
    barcode: '890721400133',
    category: 'MS Channels (ISMC)',
    unit: 'Pcs',
    cost: 3820.00,
    sell: 4250.00,
    hsn: '72163100',
    qty: 320,
  ),
  const SteelItemDef(
    name: 'MS Channel ISMC 150x75 mm (6 Mtrs)',
    sku: 'CH-ISMC-150',
    barcode: '890721400134',
    category: 'MS Channels (ISMC)',
    unit: 'Pcs',
    cost: 4900.00,
    sell: 5450.00,
    hsn: '72163100',
    qty: 260,
  ),
  const SteelItemDef(
    name: 'MS Channel ISMC 200x75 mm (6 Mtrs)',
    sku: 'CH-ISMC-200',
    barcode: '890721400135',
    category: 'MS Channels (ISMC)',
    unit: 'Pcs',
    cost: 6500.00,
    sell: 7250.00,
    hsn: '72163100',
    qty: 210,
  ),
  const SteelItemDef(
    name: 'MS Channel ISMC 250x80 mm (6 Mtrs)',
    sku: 'CH-ISMC-250',
    barcode: '890721400136',
    category: 'MS Channels (ISMC)',
    unit: 'Pcs',
    cost: 8900.00,
    sell: 9900.00,
    hsn: '72163100',
    qty: 140,
  ),

  // ── 4. MS Beams / Joists (ISMB, 6m IS 2062) ──
  const SteelItemDef(
    name: 'MS I-Beam ISMB 100x50 mm (6 Mtrs)',
    sku: 'BM-ISMB-100',
    barcode: '890721400137',
    category: 'MS Beams / Joists (ISMB)',
    unit: 'Pcs',
    cost: 3350.00,
    sell: 3750.00,
    hsn: '72163200',
    qty: 250,
  ),
  const SteelItemDef(
    name: 'MS I-Beam ISMB 125x70 mm (6 Mtrs)',
    sku: 'BM-ISMB-125',
    barcode: '890721400138',
    category: 'MS Beams / Joists (ISMB)',
    unit: 'Pcs',
    cost: 3880.00,
    sell: 4320.00,
    hsn: '72163200',
    qty: 290,
  ),
  const SteelItemDef(
    name: 'MS I-Beam ISMB 150x75 mm (6 Mtrs)',
    sku: 'BM-ISMB-150',
    barcode: '890721400139',
    category: 'MS Beams / Joists (ISMB)',
    unit: 'Pcs',
    cost: 4380.00,
    sell: 4880.00,
    hsn: '72163200',
    qty: 240,
  ),
  const SteelItemDef(
    name: 'MS I-Beam ISMB 175x85 mm (6 Mtrs)',
    sku: 'BM-ISMB-175',
    barcode: '890721400140',
    category: 'MS Beams / Joists (ISMB)',
    unit: 'Pcs',
    cost: 5650.00,
    sell: 6300.00,
    hsn: '72163200',
    qty: 180,
  ),
  const SteelItemDef(
    name: 'MS I-Beam ISMB 200x100 mm (6 Mtrs)',
    sku: 'BM-ISMB-200',
    barcode: '890721400141',
    category: 'MS Beams / Joists (ISMB)',
    unit: 'Pcs',
    cost: 7400.00,
    sell: 8250.00,
    hsn: '72163200',
    qty: 210,
  ),
  const SteelItemDef(
    name: 'MS I-Beam ISMB 250x125 mm (6 Mtrs)',
    sku: 'BM-ISMB-250',
    barcode: '890721400142',
    category: 'MS Beams / Joists (ISMB)',
    unit: 'Pcs',
    cost: 10800.00,
    sell: 12050.00,
    hsn: '72163200',
    qty: 140,
  ),
  const SteelItemDef(
    name: 'MS I-Beam ISMB 300x140 mm (6 Mtrs)',
    sku: 'BM-ISMB-300',
    barcode: '890721400143',
    category: 'MS Beams / Joists (ISMB)',
    unit: 'Pcs',
    cost: 14200.00,
    sell: 15850.00,
    hsn: '72163200',
    qty: 90,
  ),

  // ── 5. Pipes & Hollow Sections (IS 4923 / IS 1239) ──
  const SteelItemDef(
    name: 'Square Tube 25x25x2 mm (6 Mtrs)',
    sku: 'SHS-25X25X2',
    barcode: '890721400144',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 430.00,
    sell: 485.00,
    hsn: '73066100',
    qty: 620,
  ),
  const SteelItemDef(
    name: 'Square Tube 38x38x2.5 mm (6 Mtrs)',
    sku: 'SHS-38X38X2.5',
    barcode: '890721400145',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 790.00,
    sell: 890.00,
    hsn: '73066100',
    qty: 450,
  ),
  const SteelItemDef(
    name: 'Square Tube 50x50x2.5 mm (6 Mtrs)',
    sku: 'SHS-50X50X2.5',
    barcode: '890721400146',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 1080.00,
    sell: 1210.00,
    hsn: '73066100',
    qty: 390,
  ),
  const SteelItemDef(
    name: 'Square Tube 72x72x3.2 mm (6 Mtrs)',
    sku: 'SHS-72X72X3.2',
    barcode: '890721400147',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 1950.00,
    sell: 2180.00,
    hsn: '73066100',
    qty: 220,
  ),
  const SteelItemDef(
    name: 'Rectangular Tube 50x25x2 mm (6 Mtrs)',
    sku: 'RHS-50X25X2',
    barcode: '890721400148',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 650.00,
    sell: 730.00,
    hsn: '73066100',
    qty: 510,
  ),
  const SteelItemDef(
    name: 'Rectangular Tube 80x40x3 mm (6 Mtrs)',
    sku: 'RHS-80X40X3',
    barcode: '890721400149',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 1540.00,
    sell: 1720.00,
    hsn: '73066100',
    qty: 320,
  ),
  const SteelItemDef(
    name: 'Rectangular Tube 100x50x3.2 mm (6 Mtrs)',
    sku: 'RHS-100X50X3.2',
    barcode: '890721400150',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 2150.00,
    sell: 2400.00,
    hsn: '73066100',
    qty: 240,
  ),
  const SteelItemDef(
    name: 'MS Round Pipe 1" (25 NB Class B, 6m)',
    sku: 'PIPE-ROUND-1INCH',
    barcode: '890721400151',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 720.00,
    sell: 810.00,
    hsn: '73063090',
    qty: 420,
  ),
  const SteelItemDef(
    name: 'MS Round Pipe 1.5" (40 NB Class B, 6m)',
    sku: 'PIPE-ROUND-1.5INCH',
    barcode: '890721400152',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 1040.00,
    sell: 1170.00,
    hsn: '73063090',
    qty: 360,
  ),
  const SteelItemDef(
    name: 'MS Round Pipe 2" (50 NB Class B, 6m)',
    sku: 'PIPE-ROUND-2INCH',
    barcode: '890721400153',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 1470.00,
    sell: 1650.00,
    hsn: '73063090',
    qty: 340,
  ),
  const SteelItemDef(
    name: 'GI Round Pipe 2" (50 NB Galvanized, 6m)',
    sku: 'PIPE-GI-2INCH',
    barcode: '890721400154',
    category: 'Pipes & Hollow Sections',
    unit: 'Pcs',
    cost: 1820.00,
    sell: 2050.00,
    hsn: '73063090',
    qty: 210,
  ),

  // ── 6. HR / CR Plates & Sheets (IS 2062, 8x4 ft) ──
  const SteelItemDef(
    name: 'HR Steel Sheet 1.6 mm (8x4 ft)',
    sku: 'PLT-HR-1.6MM',
    barcode: '890721400155',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 1950.00,
    sell: 2180.00,
    hsn: '72085110',
    qty: 240,
  ),
  const SteelItemDef(
    name: 'HR Steel Sheet 2.0 mm (8x4 ft)',
    sku: 'PLT-HR-2.0MM',
    barcode: '890721400156',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 2440.00,
    sell: 2720.00,
    hsn: '72085110',
    qty: 310,
  ),
  const SteelItemDef(
    name: 'HR Steel Sheet 2.5 mm (8x4 ft)',
    sku: 'PLT-HR-2.5MM',
    barcode: '890721400157',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 3050.00,
    sell: 3410.00,
    hsn: '72085110',
    qty: 280,
  ),
  const SteelItemDef(
    name: 'HR Steel Plate 3.15 mm (8x4 ft)',
    sku: 'PLT-HR-3.15MM',
    barcode: '890721400158',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 3840.00,
    sell: 4290.00,
    hsn: '72085110',
    qty: 230,
  ),
  const SteelItemDef(
    name: 'HR Steel Plate 4.0 mm (8x4 ft)',
    sku: 'PLT-HR-4.0MM',
    barcode: '890721400159',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 4880.00,
    sell: 5450.00,
    hsn: '72085110',
    qty: 195,
  ),
  const SteelItemDef(
    name: 'HR Steel Plate 5.0 mm (8x4 ft)',
    sku: 'PLT-HR-5.0MM',
    barcode: '890721400160',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 6100.00,
    sell: 6800.00,
    hsn: '72085110',
    qty: 160,
  ),
  const SteelItemDef(
    name: 'HR Steel Plate 6.0 mm (8x4 ft)',
    sku: 'PLT-HR-6.0MM',
    barcode: '890721400161',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 7320.00,
    sell: 8180.00,
    hsn: '72085110',
    qty: 145,
  ),
  const SteelItemDef(
    name: 'HR Steel Plate 8.0 mm (8x4 ft)',
    sku: 'PLT-HR-8.0MM',
    barcode: '890721400162',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 9760.00,
    sell: 10900.00,
    hsn: '72085110',
    qty: 110,
  ),
  const SteelItemDef(
    name: 'HR Steel Plate 10.0 mm (8x4 ft)',
    sku: 'PLT-HR-10.0MM',
    barcode: '890721400163',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 12200.00,
    sell: 13600.00,
    hsn: '72085110',
    qty: 90,
  ),
  const SteelItemDef(
    name: 'HR Steel Plate 12.0 mm (8x4 ft)',
    sku: 'PLT-HR-12.0MM',
    barcode: '890721400164',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 14640.00,
    sell: 16300.00,
    hsn: '72085110',
    qty: 75,
  ),
  const SteelItemDef(
    name: 'HR Steel Plate 16.0 mm (8x4 ft)',
    sku: 'PLT-HR-16.0MM',
    barcode: '890721400165',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 19520.00,
    sell: 21800.00,
    hsn: '72085110',
    qty: 55,
  ),
  const SteelItemDef(
    name: 'MS Chequered Plate 3.0 mm (8x4 ft Tear)',
    sku: 'PLT-CHQ-3.0MM',
    barcode: '890721400166',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 4350.00,
    sell: 4850.00,
    hsn: '72085110',
    qty: 140,
  ),
  const SteelItemDef(
    name: 'MS Chequered Plate 4.0 mm (8x4 ft Tear)',
    sku: 'PLT-CHQ-4.0MM',
    barcode: '890721400167',
    category: 'HR / CR Plates & Sheets',
    unit: 'Sheet',
    cost: 5750.00,
    sell: 6420.00,
    hsn: '72085110',
    qty: 115,
  ),

  // ── 7. Binding Wire & Hardware ──
  const SteelItemDef(
    name: 'GI Binding Wire 18 Gauge (25 Kg Bundle)',
    sku: 'WIRE-GI-18G',
    barcode: '890721400168',
    category: 'Binding Wire & Hardware',
    unit: 'Bundle',
    cost: 1720.00,
    sell: 1950.00,
    hsn: '72171010',
    qty: 380,
  ),
  const SteelItemDef(
    name: 'Black Annealed Wire 20 Gauge (25 Kg)',
    sku: 'WIRE-BLK-20G',
    barcode: '890721400169',
    category: 'Binding Wire & Hardware',
    unit: 'Bundle',
    cost: 1600.00,
    sell: 1820.00,
    hsn: '72171010',
    qty: 450,
  ),
];

void main() {
  test('seed steel items', () async {
  print('Starting Steel Catalog Seeder for 69 items...');

  // 1. Export Excel File
  final excel = Excel.createExcel();
  final sheet = excel['Sheet1'];
  excel.setDefaultSheet('Sheet1');

  final headers = [
    'Name', 'SKU', 'Barcode', 'Unit', 'Category',
    'Cost Price', 'Selling Price', 'Tax Name',
    'Tax Rate (%)', 'Tax Type', 'Has Expiry', 'Stock'
  ];
  sheet.appendRow(headers);

  final csvLines = <String>[];
  csvLines.add(headers.join(','));

  for (final it in steelData) {
    sheet.appendRow([
      it.name,
      it.sku,
      it.barcode,
      it.unit,
      it.category,
      it.cost,
      it.sell,
      'GST',
      18.0,
      'inclusive',
      'No',
      it.qty,
    ]);

    csvLines.add('"${it.name}","${it.sku}","${it.barcode}","${it.unit}","${it.category}",${it.cost},${it.sell},"GST",18.0,"inclusive","No",${it.qty}');
  }

  final excelBytes = excel.save();
  if (excelBytes != null) {
    File('sample_50_steel_items.xlsx').writeAsBytesSync(excelBytes);
    print('Created sample_50_steel_items.xlsx with ${steelData.length} items');
  }
  File('sample_50_steel_items.csv').writeAsStringSync(csvLines.join('\n'));
  print('Created sample_50_steel_items.csv with ${steelData.length} items');

  // 2. Direct-seed into ObjectBox active databases
  final dbDirs = Directory('.').listSync()
      .whereType<Directory>()
      .where((d) => d.path.contains('market_brand_') || d.path.endsWith('market'))
      .toList();

  final now = DateTime.now().toUtc().millisecondsSinceEpoch;

  for (final dir in dbDirs) {
    print('Checking database directory: ${dir.path}');
    try {
      final store = Store(getObjectBoxModel(), directory: dir.path);
      final itemBox = store.box<EntityItem>();
      final batchBox = store.box<EntityItemBatch>();

      int addedCount = 0;
      int updatedCount = 0;

      for (final it in steelData) {
        // Query by barcode or SKU
        EntityItem? item = itemBox.query(EntityItem_.barcode.equals(it.barcode)).build().findFirst();
        item ??= itemBox.query(EntityItem_.sku.equals(it.sku)).build().findFirst();

        final taxAmount = (it.sell * 18.0) / 118.0;
        final basePrice = it.sell - taxAmount;

        if (item == null) {
          item = EntityItem(
            name: it.name,
            sku: it.sku,
            barcode: it.barcode,
            unit: it.unit,
            category: it.category,
            costPrice: it.cost,
            sellingPrice: it.sell,
            taxName: 'GST',
            taxRate: 18.0,
            taxType: 'inclusive',
            taxAmount: taxAmount,
            priceBeforeTax: basePrice,
            priceAfterTax: it.sell,
            hsnCode: it.hsn,
            totalQty: it.qty,
            hasExpiry: false,
            isActive: true,
            createdAtUtcMs: now,
            updatedAtUtcMs: now,
          );
          final id = itemBox.put(item);

          // Add initial Batch
          batchBox.put(EntityItemBatch(
            itemId: id,
            batchNo: 'BATCH-STEEL-${it.sku}',
            barcode: it.barcode,
            costPrice: it.cost,
            salePrice: it.sell,
            mrp: it.sell,
            quantity: it.qty,
            receivedAtUtcMs: now,
          ));
          addedCount++;
        } else {
          // Update stocks and details
          item.name = it.name;
          item.unit = it.unit;
          item.category = it.category;
          item.costPrice = it.cost;
          item.sellingPrice = it.sell;
          item.taxRate = 18.0;
          item.taxName = 'GST';
          item.taxType = 'inclusive';
          item.taxAmount = taxAmount;
          item.priceBeforeTax = basePrice;
          item.priceAfterTax = it.sell;
          item.hsnCode = it.hsn;
          item.totalQty = it.qty;
          item.isActive = true;
          item.updatedAtUtcMs = now;
          itemBox.put(item);

          // Ensure batch exists
          final existingBatch = batchBox.query(EntityItemBatch_.itemId.equals(item.id!)).build().findFirst();
          if (existingBatch != null) {
            existingBatch.quantity = it.qty;
            existingBatch.costPrice = it.cost;
            existingBatch.salePrice = it.sell;
            batchBox.put(existingBatch);
          } else {
            batchBox.put(EntityItemBatch(
              itemId: item.id!,
              batchNo: 'BATCH-STEEL-${it.sku}',
              barcode: it.barcode,
              costPrice: it.cost,
              salePrice: it.sell,
              mrp: it.sell,
              quantity: it.qty,
              receivedAtUtcMs: now,
            ));
          }
          updatedCount++;
        }
      }

      print('-> ${dir.path}: Added $addedCount new items, Updated $updatedCount items. Total in DB: ${itemBox.count()}');
      store.close();
    } catch (e) {
      print('Could not seed ${dir.path} (may be locked by running app): $e');
    }
  }

  print('Done seeding steel items!');
  });
}

