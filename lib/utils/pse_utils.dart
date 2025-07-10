class PSEBank {
  final String code;
  final String name;
  final String logoUrl;

  PSEBank({
    required this.code,
    required this.name,
    this.logoUrl = '',
  });
}

class PSEUtils {
  // Lista de bancos disponibles para PSE
  static List<PSEBank> getBanks() {
    return [
      PSEBank(
        code: '1022',
        name: 'Bancolombia',
        logoUrl: 'assets/images/banks/bancolombia.png',
      ),
      PSEBank(
        code: '1013',
        name: 'Banco de Bogotá',
        logoUrl: 'assets/images/banks/bogota.png',
      ),
      PSEBank(
        code: '1051',
        name: 'Davivienda',
        logoUrl: 'assets/images/banks/davivienda.png',
      ),
      PSEBank(
        code: '1032',
        name: 'BBVA Colombia',
        logoUrl: 'assets/images/banks/bbva.png',
      ),
      PSEBank(
        code: '1023',
        name: 'Banco de Occidente',
        logoUrl: 'assets/images/banks/occidente.png',
      ),
      PSEBank(
        code: '1002',
        name: 'Banco Popular',
        logoUrl: 'assets/images/banks/popular.png',
      ),
      PSEBank(
        code: '1052',
        name: 'Banco AV Villas',
        logoUrl: 'assets/images/banks/avvillas.png',
      ),
      PSEBank(
        code: '1019',
        name: 'Banco Caja Social',
        logoUrl: 'assets/images/banks/cajasocial.png',
      ),
    ];
  }

  // Tipos de documento aceptados por PSE
  static Map<String, String> getDocumentTypes() {
    return {
      'CC': 'Cédula de Ciudadanía',
      'CE': 'Cédula de Extranjería',
      'TI': 'Tarjeta de Identidad',
      'NIT': 'NIT',
      'PP': 'Pasaporte',
    };
  }

  // Validar transacción PSE
  static Future<Map<String, dynamic>> validatePSETransaction({
    required String bankCode,
    required String idType,
    required String idNumber,
    required String email,
  }) async {
    // Aquí iría la lógica para validar la transacción con el servicio PSE
    // Por ahora, simulamos una respuesta exitosa
    await Future.delayed(const Duration(seconds: 2));
    
    return {
      'success': true,
      'transactionId': 'PSE-${DateTime.now().millisecondsSinceEpoch}',
      'bankUrl': 'https://secure.pse.com.co/redirect',
    };
  }
}
