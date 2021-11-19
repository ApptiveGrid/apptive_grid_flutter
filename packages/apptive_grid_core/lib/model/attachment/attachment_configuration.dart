part of apptive_grid_model;

/// Configuration for ApiEndpoints to support Attachments
///
/// More Info on how to optain these configurations will be provided later
class AttachmentConfiguration {
  /// Creates a new AttachmentConfiguration
  AttachmentConfiguration({
    required this.signedUrlApiEndpoint,
    required this.attachmentApiEndpoint,
  });

  /// Creates a new AttachmentConfiguration from json
  factory AttachmentConfiguration.fromJson(Map<String, dynamic> json) {
    return AttachmentConfiguration(
      signedUrlApiEndpoint: json['signedUrl'],
      attachmentApiEndpoint: json['storageUrl'],
    );
  }

  /// Endpoint used to generate an upload url
  final String signedUrlApiEndpoint;

  /// Endpoint to store data at
  final String attachmentApiEndpoint;

  @override
  String toString() {
    return 'AttachmentConfiguration(signedUrlApiEndpoint: $signedUrlApiEndpoint, attachmentApiEndpoint: $attachmentApiEndpoint)';
  }

  @override
  bool operator ==(Object other) {
    return other is AttachmentConfiguration &&
        signedUrlApiEndpoint == other.signedUrlApiEndpoint &&
        attachmentApiEndpoint == other.attachmentApiEndpoint;
  }

  @override
  int get hashCode => toString().hashCode;
}

/// Converts a [configString] to an actual map of [ApptiveGridEnvironment] and [ApptiveGridConfiguration]
///
/// More Info on how to get a [configString] will follow later
Map<ApptiveGridEnvironment, AttachmentConfiguration?>
    attachmentConfigurationMapFromConfigString(String configString) {
  final json =
      jsonDecode((const Utf8Decoder()).convert(base64Decode(configString)));

  final map = <ApptiveGridEnvironment, AttachmentConfiguration?>{};
  map[ApptiveGridEnvironment.alpha] = json['alpha'] != null
      ? AttachmentConfiguration.fromJson(json['alpha'])
      : null;
  map[ApptiveGridEnvironment.beta] = json['beta'] != null
      ? AttachmentConfiguration.fromJson(json['beta'])
      : null;
  map[ApptiveGridEnvironment.production] = json['production'] != null
      ? AttachmentConfiguration.fromJson(json['production'])
      : null;
  return map;
}
