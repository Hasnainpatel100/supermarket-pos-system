/// Indian Standard (IS) Steel Specifications and Sections.
/// Compliant with IS 1786 (TMT Rebars), IS 2062 (Structural Steel),
/// IS 1161 / IS 4923 (Pipes & Tubes), and IS 2062 (Plates & Sheets).
enum SteelCategory {
  tmtRebars('TMT Rebars (Saria)', '72142090'),
  msAngles('MS Angles', '72162100'),
  msChannels('MS Channels (ISMC)', '72163100'),
  msBeams('MS Beams / Joists (ISMB)', '72163200'),
  pipesAndTubes('Pipes & Hollow Sections', '73066100'),
  platesAndSheets('HR / CR Plates & Sheets', '72085110'),
  wireAndMesh('Binding Wire & Meshes', '72171010');

  final String displayName;
  final String defaultHsn;
  const SteelCategory(this.displayName, this.defaultHsn);
}

class SteelSectionSpec {
  final String id;
  final String name;
  final SteelCategory category;
  final String size;
  final String grade;
  final double unitWeightKgPerMtr;
  final double standardLengthMtrs;
  final int bundleCount;
  final String hsnCode;

  const SteelSectionSpec({
    required this.id,
    required this.name,
    required this.category,
    required this.size,
    required this.grade,
    required this.unitWeightKgPerMtr,
    this.standardLengthMtrs = 12.0,
    this.bundleCount = 1,
    required this.hsnCode,
  });

  /// Standard calculated weight of a single full-length piece/bar in kilograms.
  double get weightPerPieceKg => unitWeightKgPerMtr * standardLengthMtrs;

  /// Calculate total weight in kilograms given a quantity of pieces and custom length.
  double calculateWeightKg({required int pieces, double? lengthMtrs}) {
    final effectiveLength = lengthMtrs ?? standardLengthMtrs;
    return pieces * effectiveLength * unitWeightKgPerMtr;
  }

  /// Calculate weight in Metric Tons (MT) given a quantity of pieces.
  double calculateWeightMetricTons({required int pieces, double? lengthMtrs}) {
    return calculateWeightKg(pieces: pieces, lengthMtrs: lengthMtrs) / 1000.0;
  }
}

/// Curated master catalog of Indian Standard steel sections
class SteelCatalogData {
  static const List<SteelSectionSpec> standardCatalog = [
    // ── TMT Rebars (IS 1786: Fe 500D / Fe 550D, 12m Standard Length) ──
    SteelSectionSpec(
      id: 'tmt-8mm',
      name: 'TMT Rebar 8mm Fe 550D',
      category: SteelCategory.tmtRebars,
      size: '8 mm',
      grade: 'Fe 550D',
      unitWeightKgPerMtr: 0.395,
      standardLengthMtrs: 12.0,
      bundleCount: 10,
      hsnCode: '72142090',
    ),
    SteelSectionSpec(
      id: 'tmt-10mm',
      name: 'TMT Rebar 10mm Fe 550D',
      category: SteelCategory.tmtRebars,
      size: '10 mm',
      grade: 'Fe 550D',
      unitWeightKgPerMtr: 0.617,
      standardLengthMtrs: 12.0,
      bundleCount: 7,
      hsnCode: '72142090',
    ),
    SteelSectionSpec(
      id: 'tmt-12mm',
      name: 'TMT Rebar 12mm Fe 550D',
      category: SteelCategory.tmtRebars,
      size: '12 mm',
      grade: 'Fe 550D',
      unitWeightKgPerMtr: 0.888,
      standardLengthMtrs: 12.0,
      bundleCount: 5,
      hsnCode: '72142090',
    ),
    SteelSectionSpec(
      id: 'tmt-16mm',
      name: 'TMT Rebar 16mm Fe 550D',
      category: SteelCategory.tmtRebars,
      size: '16 mm',
      grade: 'Fe 550D',
      unitWeightKgPerMtr: 1.580,
      standardLengthMtrs: 12.0,
      bundleCount: 3,
      hsnCode: '72142090',
    ),
    SteelSectionSpec(
      id: 'tmt-20mm',
      name: 'TMT Rebar 20mm Fe 550D',
      category: SteelCategory.tmtRebars,
      size: '20 mm',
      grade: 'Fe 550D',
      unitWeightKgPerMtr: 2.470,
      standardLengthMtrs: 12.0,
      bundleCount: 2,
      hsnCode: '72142090',
    ),
    SteelSectionSpec(
      id: 'tmt-25mm',
      name: 'TMT Rebar 25mm Fe 550D',
      category: SteelCategory.tmtRebars,
      size: '25 mm',
      grade: 'Fe 550D',
      unitWeightKgPerMtr: 3.850,
      standardLengthMtrs: 12.0,
      bundleCount: 1,
      hsnCode: '72142090',
    ),
    SteelSectionSpec(
      id: 'tmt-32mm',
      name: 'TMT Rebar 32mm Fe 550D',
      category: SteelCategory.tmtRebars,
      size: '32 mm',
      grade: 'Fe 550D',
      unitWeightKgPerMtr: 6.310,
      standardLengthMtrs: 12.0,
      bundleCount: 1,
      hsnCode: '72142090',
    ),

    // ── MS Angles (IS 2062: E250 / Grade A, 6m Standard Length) ──
    SteelSectionSpec(
      id: 'ang-25x25x3',
      name: 'MS Angle 25x25x3 mm',
      category: SteelCategory.msAngles,
      size: '25 x 25 x 3 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 1.12,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72162100',
    ),
    SteelSectionSpec(
      id: 'ang-35x35x5',
      name: 'MS Angle 35x35x5 mm',
      category: SteelCategory.msAngles,
      size: '35 x 35 x 5 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 2.60,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72162100',
    ),
    SteelSectionSpec(
      id: 'ang-40x40x5',
      name: 'MS Angle 40x40x5 mm',
      category: SteelCategory.msAngles,
      size: '40 x 40 x 5 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 3.00,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72162100',
    ),
    SteelSectionSpec(
      id: 'ang-50x50x6',
      name: 'MS Angle 50x50x6 mm',
      category: SteelCategory.msAngles,
      size: '50 x 50 x 6 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 4.50,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72162100',
    ),
    SteelSectionSpec(
      id: 'ang-65x65x6',
      name: 'MS Angle 65x65x6 mm',
      category: SteelCategory.msAngles,
      size: '65 x 65 x 6 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 5.80,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72162100',
    ),
    SteelSectionSpec(
      id: 'ang-75x75x6',
      name: 'MS Angle 75x75x6 mm',
      category: SteelCategory.msAngles,
      size: '75 x 75 x 6 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 6.80,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72162100',
    ),

    // ── MS Channels (ISMC, 6m Standard Length) ──
    SteelSectionSpec(
      id: 'ch-ismc-75',
      name: 'MS Channel ISMC 75x40',
      category: SteelCategory.msChannels,
      size: '75 x 40 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 7.14,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163100',
    ),
    SteelSectionSpec(
      id: 'ch-ismc-100',
      name: 'MS Channel ISMC 100x50',
      category: SteelCategory.msChannels,
      size: '100 x 50 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 9.56,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163100',
    ),
    SteelSectionSpec(
      id: 'ch-ismc-125',
      name: 'MS Channel ISMC 125x65',
      category: SteelCategory.msChannels,
      size: '125 x 65 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 13.10,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163100',
    ),
    SteelSectionSpec(
      id: 'ch-ismc-150',
      name: 'MS Channel ISMC 150x75',
      category: SteelCategory.msChannels,
      size: '150 x 75 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 16.80,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163100',
    ),
    SteelSectionSpec(
      id: 'ch-ismc-200',
      name: 'MS Channel ISMC 200x75',
      category: SteelCategory.msChannels,
      size: '200 x 75 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 22.30,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163100',
    ),

    // ── MS Beams / Joists (ISMB, 6m Standard Length) ──
    SteelSectionSpec(
      id: 'bm-ismb-100',
      name: 'MS I-Beam ISMB 100',
      category: SteelCategory.msBeams,
      size: '100 x 50 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 11.50,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163200',
    ),
    SteelSectionSpec(
      id: 'bm-ismb-125',
      name: 'MS I-Beam ISMB 125',
      category: SteelCategory.msBeams,
      size: '125 x 70 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 13.30,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163200',
    ),
    SteelSectionSpec(
      id: 'bm-ismb-150',
      name: 'MS I-Beam ISMB 150',
      category: SteelCategory.msBeams,
      size: '150 x 75 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 15.00,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163200',
    ),
    SteelSectionSpec(
      id: 'bm-ismb-200',
      name: 'MS I-Beam ISMB 200',
      category: SteelCategory.msBeams,
      size: '200 x 100 mm',
      grade: 'IS 2062 E250',
      unitWeightKgPerMtr: 25.40,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '72163200',
    ),

    // ── Pipes & Hollow Sections (IS 4923 / IS 1161, 6m Standard Length) ──
    SteelSectionSpec(
      id: 'pipe-shs-25x25x2',
      name: 'Square Hollow Tube 25x25x2 mm',
      category: SteelCategory.pipesAndTubes,
      size: '25 x 25 x 2 mm',
      grade: 'IS 4923 YSt-210',
      unitWeightKgPerMtr: 1.44,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '73066100',
    ),
    SteelSectionSpec(
      id: 'pipe-shs-50x50x2.5',
      name: 'Square Hollow Tube 50x50x2.5 mm',
      category: SteelCategory.pipesAndTubes,
      size: '50 x 50 x 2.5 mm',
      grade: 'IS 4923 YSt-210',
      unitWeightKgPerMtr: 3.70,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '73066100',
    ),
    SteelSectionSpec(
      id: 'pipe-round-2inch-med',
      name: 'MS Round Pipe 2" (50 NB Class B)',
      category: SteelCategory.pipesAndTubes,
      size: '50 NB (Medium)',
      grade: 'IS 1239 Class B',
      unitWeightKgPerMtr: 5.03,
      standardLengthMtrs: 6.0,
      bundleCount: 1,
      hsnCode: '73063090',
    ),

    // ── Plates & Sheets (Density 7.85 kg/m²/mm, 8ft x 4ft = 2.438m x 1.219m = 2.972 m²) ──
    SteelSectionSpec(
      id: 'plate-hr-2mm',
      name: 'HR Steel Sheet 2.0 mm (8x4 ft)',
      category: SteelCategory.platesAndSheets,
      size: '8x4 ft x 2.0 mm',
      grade: 'IS 2062 Grade A',
      unitWeightKgPerMtr: 7.85 * 2.0 * 2.972, // per sheet
      standardLengthMtrs: 1.0,
      bundleCount: 1,
      hsnCode: '72085110',
    ),
    SteelSectionSpec(
      id: 'plate-hr-5mm',
      name: 'HR Steel Plate 5.0 mm (8x4 ft)',
      category: SteelCategory.platesAndSheets,
      size: '8x4 ft x 5.0 mm',
      grade: 'IS 2062 Grade A',
      unitWeightKgPerMtr: 7.85 * 5.0 * 2.972, // per sheet
      standardLengthMtrs: 1.0,
      bundleCount: 1,
      hsnCode: '72085110',
    ),
    SteelSectionSpec(
      id: 'plate-hr-10mm',
      name: 'HR Steel Plate 10.0 mm (8x4 ft)',
      category: SteelCategory.platesAndSheets,
      size: '8x4 ft x 10.0 mm',
      grade: 'IS 2062 Grade A',
      unitWeightKgPerMtr: 7.85 * 10.0 * 2.972, // per sheet
      standardLengthMtrs: 1.0,
      bundleCount: 1,
      hsnCode: '72085110',
    ),

    // ── Wire & Meshes ──
    SteelSectionSpec(
      id: 'wire-binding-18g',
      name: 'MS Annealed Binding Wire 18 Gauge',
      category: SteelCategory.wireAndMesh,
      size: '18 Gauge (1.2 mm)',
      grade: 'Soft Annealed',
      unitWeightKgPerMtr: 25.0, // Sold in 25kg bundles
      standardLengthMtrs: 1.0,
      bundleCount: 1,
      hsnCode: '72171010',
    ),
  ];
}

