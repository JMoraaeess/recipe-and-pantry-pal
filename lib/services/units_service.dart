import 'dart:math';

class NormalizedQuantity {
  final double value;
  final String unit;

  NormalizedQuantity(this.value, this.unit);
}

class UnitsService {
  // Tabela de densidades simplificada (g por 100ml)
  static const Map<String, double> _densities = {
    'farinha': 60.0,      // 1 xícara (200ml) = 120g
    'açúcar': 100.0,      // 1 xícara (200ml) = 200g
    'leite': 103.0,       // 100ml = 103g
    'água': 100.0,        // 100ml = 100g
    'óleo': 92.0,         // 100ml = 92g
    'manteiga': 95.0,     // 100ml = 95g
    'arroz': 85.0,        // 1 xícara (200ml) = 170g
    'feijão': 80.0,
    'sal': 120.0,
  };

  // Unidades de volume para ML (base: 1 xícara = 200ml)
  static const Map<String, double> _volumeToMl = {
    'l': 1000.0,
    'litro': 1000.0,
    'litros': 1000.0,
    'ml': 1.0,
    'mililitro': 1.0,
    'mililitros': 1.0,
    'xícara': 200.0,
    'xicaras': 200.0,
    'copo': 200.0,
    'copos': 200.0,
    'colher de sopa': 15.0,
    'colheres de sopa': 15.0,
    'colher de chá': 5.0,
    'colheres de chá': 5.0,
    'pitada': 0.5,
  };

  // Unidades de peso para G
  static const Map<String, double> _weightToG = {
    'kg': 1000.0,
    'quilo': 1000.0,
    'quilos': 1000.0,
    'g': 1.0,
    'grama': 1.0,
    'gramas': 1.0,
    'mg': 0.001,
  };

  double parseFraction(String fraction) {
    fraction = fraction.toLowerCase().trim();
    
    // Termos textuais simples
    if (fraction == 'meio' || fraction == 'meia') return 0.5;
    if (fraction == 'um' || fraction == 'uma') return 1.0;

    // Suporte a caracteres unicode (se a string for apenas o caractere ou começar com ele)
    final unicodeFractions = {
      '½': 0.5, '¼': 0.25, '¾': 0.75, '⅓': 0.33, '⅔': 0.66, '⅛': 0.125
    };
    
    for (var entry in unicodeFractions.entries) {
      if (fraction.startsWith(entry.key)) {
        // Se houver mais texto após o unicode, pode ser um "1½"
        String rest = fraction.substring(entry.key.length).trim();
        if (rest.isEmpty) return entry.value;
      }
    }
    
    // Caso especial: ½ já dentro da string formatada pelo regex
    if (unicodeFractions.containsKey(fraction)) return unicodeFractions[fraction]!;

    if (fraction.contains('/')) {
      final parts = fraction.split('/');
      if (parts.length == 2) {
        final denStr = parts[1].trim();
        final den = double.tryParse(denStr) ?? 1.0;
        
        String numPart = parts[0].trim();
        if (numPart.contains(' ')) {
          final subParts = numPart.split(' ');
          final whole = double.tryParse(subParts[0]) ?? 0.0;
          final part = double.tryParse(subParts[1]) ?? 0.0;
          return whole + (part / den);
        }
        
        return (double.tryParse(numPart) ?? 0.0) / den;
      }
    }
    
    return double.tryParse(fraction.replaceAll(',', '.')) ?? 0.0;
  }

  String _removeAccents(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÖØòóôõöøÈÉÊËèéêëÇçÌÍÎÏìíîïÙÚÛÜùúûüÿÑñ';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOooooooEEEEeeeeCcIIIIiiiiUUUUuuuuyNn';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  NormalizedQuantity normalize(String quantityStr, String itemName) {
    if (quantityStr.isEmpty) return NormalizedQuantity(1.0, 'unidade');
    
    final lowerStr = quantityStr.toLowerCase().trim();
    final itemLower = itemName.toLowerCase();

    // Regex melhorada: tenta capturar o número/fração no início
    final regex = RegExp(r'^([\d\/\s\.,½¼¾⅓⅔⅛umao]+)?\s*(.*)$');
    final match = regex.firstMatch(lowerStr);

    String valPart = '1';
    String unitPart = lowerStr;

    if (match != null) {
      valPart = (match.group(1) ?? '1').trim();
      unitPart = (match.group(2) ?? '').trim();
      
      if (valPart.isEmpty) {
        valPart = '1';
        unitPart = lowerStr;
      }
    }

    double value = parseFraction(valPart);
    if (value == 0) value = 1.0;

    if (unitPart.isEmpty) unitPart = 'unidade';

    // Normaliza a unidade removendo acentos para comparação
    final normalizedUnitPart = _removeAccents(unitPart);

    // Verifica se é peso
    for (var entry in _weightToG.entries) {
      final normKey = _removeAccents(entry.key);
      if (normalizedUnitPart == normKey || normalizedUnitPart.startsWith("$normKey ") || normalizedUnitPart.startsWith("${normKey}s")) {
        return NormalizedQuantity(value * entry.value, 'g');
      }
    }

    // Verifica se é volume
    for (var entry in _volumeToMl.entries) {
      final normKey = _removeAccents(entry.key);
      if (normalizedUnitPart == normKey || normalizedUnitPart.startsWith("$normKey ") || normalizedUnitPart.startsWith("${normKey}s")) {
        double mlValue = value * entry.value;
        
        for (var densityEntry in _densities.entries) {
          if (itemLower.contains(densityEntry.key)) {
            return NormalizedQuantity(mlValue * (densityEntry.value / 100.0), 'g');
          }
        }
        
        return NormalizedQuantity(mlValue, 'ml');
      }
    }

    return NormalizedQuantity(value, 'unidade');
  }
  String formatQuantity(double value, String unit) {
    if (value <= 0) return "0 $unit";
    
    // Para unidades de peso e volume, tenta simplificar (ex: 2000g -> 2kg)
    if (unit == 'g' && value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}kg";
    }
    if (unit == 'ml' && value >= 1000) {
      return "${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}l";
    }

    return "${value.toStringAsFixed(1).replaceAll('.0', '')}$unit";
  }
}
