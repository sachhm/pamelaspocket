import '../domain/enums.dart';

/// How a role reads in the interface, e.g. "Support worker".
String roleLabel(Role role) {
  return switch (role) {
    Role.owner => 'Main carer',
    Role.staff => 'Support worker',
    Role.family => 'Family',
  };
}
