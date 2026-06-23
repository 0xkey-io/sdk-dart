import 'dart:convert';

import 'package:test/test.dart';
import 'package:zeroxkey_crypto/src/zeroxkey.dart';

const _legacyEnclavePublicKey =
    '04cf288fe433cc4e1aa0ce1632feac4ea26bf2f5a09dcfe5a42c398e06898710330f0572882f4dbdf0f5304b8fc8703acd69adca9a4bbf7f5d00d20a5e364b2569';

void main() {
  group('decryptCredentialBundle Tests', () {
    test('throws for invalid bundle input', () {
      expect(
        () => decryptCredentialBundle(
          credentialBundle: 'invalidBase58CheckData',
          embeddedKey:
              '20fa65df11f24833790ae283fc9a0c215eecbbc589549767977994dc69d05a56',
        ),
        throwsException,
      );
    });
  });

  group('encryptWalletToBundle Tests', () {
    test('encrypts import bundles signed by legacy enclave fixtures', () async {
      const mnemonic =
          'leaf lady until indicate praise final route toast cake minimum insect unknown';
      const importBundle = '''
        {
          "version":"v1.0.0",
          "data":"7b227461726765745075626c6963223a2230343937363965366266636162333235303534356666633537353361396138393061663431653833366432613933333633353461303165623737346135616265616563393465656430663734396665303366393966646566663839643033386630643534366538636539323164383732373562376437396161383730656133393061222c226f7267616e697a6174696f6e4964223a2266396133316336342d643630342d343265342d396265662d613737333039366166616437222c22757365724964223a2237643461383835642d343636382d343063342d386633352d333333303165313165376435227d",
          "dataSignature":"3045022100fefc56c6bf4142ff54ce085b8103e79c7ac571dad16a145e9c99ec6d081b97ff0220203bd0d0f6048cd139aa3eb79ccace5425c2f1347401b2c18c66b728f540f17e",
          "enclaveQuorumPublic":"$_legacyEnclavePublicKey"
        }
      ''';

      final encrypted = await encryptWalletToBundle(
        mnemonic: mnemonic,
        importBundle: importBundle,
        userId: '7d4a885d-4668-40c4-8f35-33301e11e7d5',
        organizationId: 'f9a31c64-d604-42e4-9bef-a773096afad7',
        dangerouslyOverrideSignerPublicKey: _legacyEnclavePublicKey,
      );

      final parsed = jsonDecode(encrypted) as Map<String, dynamic>;
      expect(parsed['encappedPublic'], isNotEmpty);
      expect(parsed['ciphertext'], isNotEmpty);
    });
  });

  group('encryptPrivateKeyToBundle Tests', () {
    test('encrypts private key import bundles with legacy fixtures', () async {
      const privateKey =
          '6fd4d81de4820d2f8f7b2df8aa63ebb4b042af5854313e1f3abae6b55eb1cf83';
      const importBundle =
          '{"version":"v1.0.0","data":"7b227461726765745075626c6963223a2230343133613663626239646434643763653561303562363031313631643437643565353861303732386237353162613063363838333364356335383164623931616339303061633431626433616530383830636636306233353636306261353839373066356663393162353263373135636438313734386364633431333363656263222c226f7267616e697a6174696f6e4964223a2266396133316336342d643630342d343265342d396265662d613737333039366166616437222c22757365724964223a2237643461383835642d343636382d343063342d386633352d333333303165313165376435227d","dataSignature":"30440220424e74b9b75ee7e0ea83ff71c5c33dfa113c6321447fb65322bfe154b06f97f6022030d98ab126ece21eb60bd19d4dd6670a802d5cc84e626949746a797b4ee23163","enclaveQuorumPublic":"$_legacyEnclavePublicKey"}';

      final encrypted = await encryptPrivateKeyToBundle(
        privateKey: privateKey,
        keyFormat: 'HEXADECIMAL',
        importBundle: importBundle,
        userId: '7d4a885d-4668-40c4-8f35-33301e11e7d5',
        organizationId: 'f9a31c64-d604-42e4-9bef-a773096afad7',
        dangerouslyOverrideSignerPublicKey: _legacyEnclavePublicKey,
      );

      final parsed = jsonDecode(encrypted) as Map<String, dynamic>;
      expect(parsed['encappedPublic'], isNotEmpty);
      expect(parsed['ciphertext'], isNotEmpty);
    });
  });
}
