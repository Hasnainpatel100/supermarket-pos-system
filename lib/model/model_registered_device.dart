class ModelRegisteredDevice {
  final String deviceId;
  final String deviceName;
  final String registeredAt;
  final String? ipAddress;

  const ModelRegisteredDevice({
    required this.deviceId,
    required this.deviceName,
    required this.registeredAt,
    this.ipAddress,
  });

  factory ModelRegisteredDevice.fromJson(Map<String, dynamic> json) {
    return ModelRegisteredDevice(
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? 'Unknown Device',
      registeredAt: json['registeredAt']?.toString() ?? '',
      ipAddress: json['ipAddress']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'registeredAt': registeredAt,
      if (ipAddress != null) 'ipAddress': ipAddress,
    };
  }

  ModelRegisteredDevice copyWith({
    String? deviceId,
    String? deviceName,
    String? registeredAt,
    String? ipAddress,
  }) {
    return ModelRegisteredDevice(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      registeredAt: registeredAt ?? this.registeredAt,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ModelRegisteredDevice &&
          runtimeType == other.runtimeType &&
          deviceId == other.deviceId;

  @override
  int get hashCode => deviceId.hashCode;
}
