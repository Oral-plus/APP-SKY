import 'package:url_launcher/url_launcher.dart';

class SimpleWompiService {
  static const String wompiPublicKey = 'pub_prod_vq6SWvyOjQMav2mrcWlKOye4BBueaS7Q';
  static const String wompiBaseUrl = 'https://checkout.wompi.co/p/';

  static Future<bool> openPaymentInBrowser({
    required String reference,
    required int amountInCents,
    required String currency,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String description,
  }) async {
    try {
      final params = {
        'public-key': wompiPublicKey,
        'currency': currency,
        'amount-in-cents': amountInCents.toString(),
        'reference': reference,
        'customer-data:email': customerEmail,
        'customer-data:full-name': customerName,
        'customer-data:phone-number': customerPhone,
        'description': description,
      };

      final uri = Uri.parse(wompiBaseUrl).replace(
        queryParameters: params,
      );

      print('🌐 URL Wompi: $uri');

      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        print('❌ No se puede abrir la URL de Wompi');
        return false;
      }
    } catch (e) {
      print('❌ Error abriendo Wompi: $e');
      return false;
    }
  }
}
