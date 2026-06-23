import 'constant.dart';
import 'helper.dart';
import 'types.dart';
import 'type-gen/helpers.dart';
import 'package:swagger_dart_code_generator/src/swagger_models/swagger_root.dart';
// import 'package:swagger_dart_code_generator/src/swagger_models/requests/swagger_request_parameter.dart';

/// Builds a map of base activity type -> highest versioned activity type
/// by scanning all string values in the swagger JSON for ACTIVITY_TYPE_* patterns.
Map<String, String> buildDynamicVersionMap(
    List<Map<String, dynamic>> rawSpecs) {
  final allActivityTypes = <String>{};

  void collect(dynamic value) {
    if (value is String && value.startsWith('ACTIVITY_TYPE_')) {
      allActivityTypes.add(value);
    } else if (value is Map) {
      for (final v in value.values) collect(v);
    } else if (value is List) {
      for (final v in value) collect(v);
    }
  }

  for (final spec in rawSpecs) {
    collect(spec);
  }

  final baseToHighest = <String, (int, String)>{};
  final versionPattern = RegExp(r'^(.+)_V(\d+)$');

  for (final activityType in allActivityTypes) {
    final match = versionPattern.firstMatch(activityType);
    if (match != null) {
      final base = match.group(1)!;
      final version = int.parse(match.group(2)!);
      if (!baseToHighest.containsKey(base) ||
          version > baseToHighest[base]!.$1) {
        baseToHighest[base] = (version, activityType);
      }
    }
  }

  return baseToHighest.map((base, record) => MapEntry(base, record.$2));
}

/// Determines the activity type from operation ID.
/// Checks the static [VERSIONED_ACTIVITY_TYPES] map first (explicit overrides),
/// then falls back to the dynamically-detected highest version from the swagger,
/// and finally falls back to the unversioned base name.
String getActivityTypeFromOperationId(
  String operationId,
  Map<String, String> dynamicVersionMap,
) {
  // Convert operationId to activity type format
  final activityTypeName = 'ACTIVITY_TYPE_${operationId.replaceAllMapped(
        RegExp(r'([A-Z])'),
        (match) => '_${match.group(1)}',
      ).toUpperCase().substring(1)}';

  // 1. Explicit static override wins
  final recordTriple = VERSIONED_ACTIVITY_TYPES[activityTypeName];
  if (recordTriple != null) return recordTriple.$1;

  // 2. Dynamically detected highest version from swagger
  final dynamic = dynamicVersionMap[activityTypeName];
  if (dynamic != null) return dynamic;

  // 3. Fall back to base type
  return activityTypeName;
}

/// Generates a Dart HTTP client class from a Swagger specification.
///
/// Parameters:
/// - [spec]: The [SwaggerRoot] containing the parsed Swagger specification.
/// - [targetPath]: The [String] file path where the generated client code will be written.
///
/// This function performs the following:
/// - Extracts the namespace from the Swagger tags.
/// - Validates namespace and operation IDs for compliance.
/// - Generates an `HTTP Client` class with methods to interact with API endpoints.
/// - Adds methods for stamping and sending POST requests, as well as generating signed requests.
/// - Organizes and writes the generated code into a Dart file at the specified [targetPath].
///
/// Returns:
/// - A [Future] that resolves when the client generation process is complete.
Future<void> generateClientFromSwagger({
  required List<TFileInfo> fileList,
  required String targetPath,
}) async {
  final importStatementSet = <String>[
    'import "models.dart";',
    'import "../base.dart";',
    'import "../version.dart";',
    'import "dart:convert";',
    'import "dart:async";',
  ];

  final List<String> codeBuffer = [];

  codeBuffer.add('''
      /// HTTP Client for interacting with ZeroXKey API
      class ZeroXKeyClient {
        final THttpConfig config;
        final TStamper stamper;
        final HttpTransport transport;

        ZeroXKeyClient({
          required this.config,
          required this.stamper,
          HttpTransport? transport,
        }) : transport = transport ?? DefaultHttpTransport() {
          if (config.baseUrl.isEmpty) {
            throw Exception('Missing base URL. Please verify environment variables.');
          }
        }

        Future<TResponseType> request<TBodyType, TResponseType>(
          String url,
          TBodyType body,
          TResponseType Function(Map<String, dynamic>) fromJson,

        ) async {
          final fullUrl = '\${config.baseUrl}\$url';
          final stringifiedBody = jsonEncode(body);
          final stamp = await stamper.stamp(stringifiedBody);

          final response = await transport.post(
            url: fullUrl,
            body: stringifiedBody,
            headers: {
              stamp.stampHeaderName: stamp.stampHeaderValue,
              'X-Client-Version': VERSION,
            },
          );

          if (response.statusCode != 200) {
            throw ZeroXKeyRequestError(
              GrpcStatus.fromJson(jsonDecode(response.body)),
            );
          }

          final decodedJson = jsonDecode(response.body) as Map<String, dynamic>;
          return fromJson(decodedJson);
        }

        Future<TResponseType> authProxyRequest<TBodyType, TResponseType>(
          String url,
          TBodyType body,
          TResponseType Function(Map<String, dynamic>) fromJson,

        ) async {
          if (config.authProxyConfigId == null || config.authProxyConfigId!.isEmpty) {
            throw Exception('Missing Auth Proxy config ID. Please verify environment variables.');
          }
          final fullUrl = '\${config.authProxyBaseUrl}\$url';
          final stringifiedBody = jsonEncode(body);

          final response = await transport.post(
            url: fullUrl,
            body: stringifiedBody,
            headers: {
              "X-Auth-Proxy-Config-ID": config.authProxyConfigId!,
              'X-Client-Version': VERSION,
            },
          );

          if (response.statusCode != 200) {
            throw ZeroXKeyRequestError(
              GrpcStatus.fromJson(jsonDecode(response.body)),
            );
          }

          final decodedJson = jsonDecode(response.body) as Map<String, dynamic>;
          return fromJson(decodedJson);
        }

        /// Build the server envelope.
        Map<String, dynamic> makeEnvelope({
          required String type,
          required String organizationId,
          required String timestampMs,
          required Map<String, dynamic> parameters,
        }) {
          return {
            'type': type,
            'organizationId': organizationId,
            'timestampMs': timestampMs,
            'parameters': parameters,
          };
        }

        /// Build `parameters` by taking everything from [src] except the keys in [exclude].
        /// Null values are dropped by default to keep payloads lean.
        Map<String, dynamic> paramsFromBody(
          Map<String, dynamic> src, {
          Iterable<String> exclude = const [],
          bool dropNulls = true,
        }) {
          final out = Map<String, dynamic>.from(src);
          for (final k in exclude) {
            out.remove(k);
          }
          // Optionally drop nulls
          if (dropNulls) {
            out.removeWhere((_, v) => v == null);
          }
          return out;
        }

        /// For command/activityDecision bodies generated by codegen:
        Map<String, dynamic> packActivityBody({
          required Map<String, dynamic> bodyJson,
          required String fallbackOrganizationId,
          required String activityType,
        }) {
          final orgId = (bodyJson['organizationId'] as String?) ?? fallbackOrganizationId;
          final ts = bodyJson['timestampMs'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();

          // Exclude envelope keys (and guard against accidental nesting)
          final params = paramsFromBody(
            bodyJson,
            exclude: const ['organizationId', 'timestampMs'],
          );

          return makeEnvelope(
            type: activityType,
            organizationId: orgId,
            timestampMs: ts,
            parameters: params,
          );
        }

        /// Transforms activity response to flatten specific result from activity.result.{specificResult} to top-level result
        Map<String, dynamic> transformActivityResponse(Map<String, dynamic> json, String operationId) {
          // Convert operationId to the expected result field name (e.g., "StampLogin" -> "stampLoginResult")
          final resultFieldName = '\${operationId[0].toLowerCase()}\${operationId.substring(1)}Result';
          
          final result = <String, dynamic>{
            'activity': json['activity'],
          };

          // Extract specific result from activity.result.{specificResult} and flatten to top level
          if (json['activity'] != null && 
              json['activity']['result'] != null && 
              json['activity']['result'][resultFieldName] != null) {
            result['result'] = json['activity']['result'][resultFieldName];
          }

          return result;
        }
      
    ''');

  final dynamicVersionMap = buildDynamicVersionMap(
    fileList.map((f) => f.parsedData).toList(),
  );

  for (final file in fileList) {
    print('Processing file: ${file.absolutePath}');

    final SwaggerRoot spec = SwaggerRoot.fromJson(file.parsedData);

    final namespace = spec.tags.map((tag) => tag.name).firstWhere(
          (name) => NAMESPACE_TO_DART_PREFIX.containsKey(name),
          orElse: () => file.absolutePath.contains('auth_proxy')
              ? 'AuthProxyService'
              : 'PublicApiService',
        );

    if (namespace.isEmpty) {
      throw Exception(
          'Invalid namespace "$namespace" in spec, cannot generate HTTP client');
    }

    final String prefix = NAMESPACE_TO_DART_PREFIX[namespace] ??
        (throw Exception(
            'No Dart prefix mapping found for namespace "$namespace"'));
    final bool isProxy = prefix == 'Proxy';

    for (final endpointEntry in spec.paths.entries) {
      final String endpointPath = endpointEntry.key;
      final methodMap = endpointEntry.value.requests;
      if (methodMap['post'] == null) {
        // 0xkey Public API includes a small number of GET redirect/query routes
        // that are not used by the mobile SDK client surface.
        continue;
      }

      if (methodMap['post']!.operationId.isEmpty) {
        throw Exception(
          'Invalid operationId in path ${endpointPath}',
        );
      }

      final operation = methodMap['post']!;
      // Remove the MethodId_ prefix if it exists
      final operationId = operation.operationId.indexOf('_') != -1
          ? operation.operationId.split('_')[1]
          : operation.operationId;

      final bool isEndpointDeprecated = operation.deprecated;

      final String methodName =
          operationId[0].toLowerCase() + operationId.substring(1);

      final mType = methodTypeFromMethodName("t$methodName", prefix);

      final inputType = '${prefix}T${operationId}Body';
      final responseType = '${prefix}T${operationId}Response';

      codeBuffer.add(assembleDartDocComment([
        operation.description,
        'Sign the provided `$inputType` with the client\'s `stamp` function and submit the request (POST $endpointPath).',
        'See also: `stamp$operationId`.',
        if (isEndpointDeprecated) '@deprecated',
      ]));

      if (mType == 'activityDecision' || mType == 'command') {
        final activityType =
            getActivityTypeFromOperationId(operationId, dynamicVersionMap);
        codeBuffer.add('''
      Future<$responseType> ${prefix.toLowerCase()}${prefix.isEmpty ? methodName : methodName.capitalize()}({
        required $inputType input,
      }) async {
        final body = packActivityBody(
          bodyJson: input.toJson(),
          fallbackOrganizationId: input.organizationId ?? config.organizationId ?? (throw Exception("Missing organization ID, please pass in a sub-organizationId or instantiate the client with one.")),
          activityType: '$activityType',
        );
        return await request<Map<String, dynamic>, $responseType>(
          "$endpointPath",
          body,
          (json) => $responseType.fromJson(transformActivityResponse(json, '$operationId'))
        );
      }
    ''');
      } else if (mType == 'noop' || mType == 'query') {
        codeBuffer.add('''
      Future<$responseType> ${prefix.toLowerCase()}${prefix.isEmpty ? methodName : methodName.capitalize()}({
        required $inputType input,
      }) async {
        return await request<$inputType, $responseType>(
          "$endpointPath",
          input,
          (json) => $responseType.fromJson(json)
        );
      }
    ''');
      } else if (mType == 'proxy') {
        codeBuffer.add('''
      Future<$responseType> ${prefix.toLowerCase()}${prefix.isEmpty ? methodName : methodName.capitalize()}({
        required $inputType input,
      }) async {
        return await authProxyRequest<$inputType, $responseType>(
          "$endpointPath",
          input,
          (json) => $responseType.fromJson(json)
        );
      }
    ''');
      } else {
        throw Exception('Unknown method type "$mType"');
      }

      codeBuffer.add(assembleDartDocComment([
        'Produce a `SignedRequest` from `$inputType` by using the client\'s `stamp` function.',
        'See also: `$operationId`.',
        if (isEndpointDeprecated) '@deprecated',
        '\n',
      ]));

      if (!isProxy) {
        if (mType == 'activityDecision' || mType == 'command') {
          final activityType =
              getActivityTypeFromOperationId(operationId, dynamicVersionMap);
          codeBuffer.add('''
      Future<TSignedRequest> stamp$operationId({
        required $inputType input,
        }) async {
          final fullUrl = '\${config.baseUrl}$endpointPath';
           final body = packActivityBody(
          bodyJson: input.toJson(),
          fallbackOrganizationId: input.organizationId ?? config.organizationId ?? (throw Exception("Missing organization ID, please pass in a sub-organizationId or instantiate the client with one.")),
          activityType: '$activityType',
        );
        final bodyJson = jsonEncode(body);
        final stamp = await stamper.stamp(bodyJson);

          return TSignedRequest(
            body: bodyJson,
            stamp: stamp,
            url: fullUrl,
          );
        }
    ''');
        } else if (mType == 'noop' || mType == 'query') {
          codeBuffer.add('''
      Future<TSignedRequest> stamp$operationId({
        required $inputType input,
        }) async {
          final fullUrl = '\${config.baseUrl}$endpointPath';
          final body = jsonEncode(input);
          final stamp = await stamper.stamp(body);

          return TSignedRequest(
            body: body,
            stamp: stamp,
            url: fullUrl,
          );
        }
    ''');
        } else {
          throw Exception('Unknown method type "$mType"');
        }
      }
    }
  }

  // End of the ZeroXKeyClient class definition
  codeBuffer.add('}');

  final imports = importStatementSet
      .where((importStatement) => importStatement.isNotEmpty)
      .join("\n");

// Combine the comment header, imports, and code buffer
  final output = [
    COMMENT_HEADER,
    imports,
    ...codeBuffer,
  ].join("\n\n");

  await safeWriteFileAsync("$targetPath/public_api.client.dart", output);
  await formatDocument(targetPath);
}
