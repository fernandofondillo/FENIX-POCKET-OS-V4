// test/services/skills_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fenix_pocket_os/services/skills_service.dart';

void main() {
  group('SkillsService Unit Tests', () {
    test('Instanciación correcta con baseUrl', () {
      final svc = SkillsService(baseUrl: 'https://example.com');
      expect(svc.baseUrl, 'https://example.com');
    });

    test('Instanciación con default (config)', () {
      final svc = SkillsService();
      expect(svc.baseUrl.isNotEmpty, true);
    });
  });
}
