part of 'auth_hive_model.dart';


class AuthHiveModelAdapter extends TypeAdapter<AuthHiveModel> {
  @override
  final int typeId = 0;

  @override
  AuthHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i=0; i<numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuthHiveModel(
      fullName: fields[0] as String,
      email: fields[1] as String,
      password: fields[2] as String,
      phone: fields[3] as String,
      education: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuthHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.phone)
      ..writeByte(4)
      ..write(obj.education);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is AuthHiveModelAdapter &&
              runtimeType == other.runtimeType &&
              typeId == other.typeId;
}
