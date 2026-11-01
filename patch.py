with open("lib/service/service_item_excel.dart", "r", encoding="utf-8") as f:
    text = f.read()

import_old = """          importedItems.add(EntityItem(
            name:         name,
            sku:          str(1).isEmpty  ? null : str(1),
            barcode:      str(2).isEmpty  ? null : str(2),
            unit:         str(3).isEmpty  ? null : str(3),
            category:     str(4).isEmpty  ? null : str(4),
            costPrice:    dbl(5),
            sellingPrice: dbl(6) ?? 0.0,
            taxName:      str(8).isEmpty  ? null : str(8),
            taxRate:      dbl(9),
            taxType:      str(10).isEmpty ? null : str(10),
            hasExpiry:    str(11).toLowerCase() == 'yes',
            isActive:     str(12).toLowerCase() != 'inactive',
            totalQty:     0,
          ));"""

import_new = """          final sq = dbl(12);
          final parsedQty = (sq != null && sq > 0) ? sq.round() : 0;
          importedItems.add(EntityItem(
            name:         name,
            sku:          str(1).isEmpty  ? null : str(1),
            barcode:      str(2).isEmpty  ? null : str(2),
            unit:         str(3).isEmpty  ? null : str(3),
            category:     str(4).isEmpty  ? null : str(4),
            costPrice:    dbl(5),
            sellingPrice: dbl(6) ?? 0.0,
            taxName:      str(7).isEmpty  ? null : str(7),
            taxRate:      dbl(8),
            taxType:      str(9).isEmpty  ? null : str(9),
            hasExpiry:    str(10).toLowerCase() == 'yes',
            isActive:     str(11).toLowerCase() != 'inactive',
            totalQty:     parsedQty,
          ));"""

text = text.replace(import_old, import_new)

with open("lib/service/service_item_excel.dart", "w", encoding="utf-8") as f:
    f.write(text)
