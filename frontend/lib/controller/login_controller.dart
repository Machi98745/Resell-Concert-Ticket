class LoginController {
  final Map<String, Map<String, String>> _users = {
    'admin': {
      'password': '1111',
      'email': 'admin@gmail.com',
      'phone': '0812345678',
    },
    'cocomint': {
      'password': '2222',
      'email': 'cocomint@gmail.com',
      'phone': '0898765432',
    },
  };

  /// Returns an error message when credentials are invalid, otherwise null.
  String? validateCredentials(String username, String password) {
    final normalizedUsername = username.trim();
    final normalizedPassword = password.trim();

    if (normalizedUsername.isEmpty || normalizedPassword.isEmpty) {
      return 'Please enter username and password';
    }

    if (_users[normalizedUsername]?['password'] != normalizedPassword) {
      return 'Invalid username or password';
    }

    return null;
  }

  bool isAdmin(String username) => username.trim() == 'admin';

  String? findUsernameByEmailAndPhone(String email, String phone) {
    final normalizedEmail = email.trim();
    final normalizedPhone = phone.trim();

    for (final entry in _users.entries) {
      if (entry.value['email'] == normalizedEmail &&
          entry.value['phone'] == normalizedPhone) {
        return entry.key;
      }
    }

    return null;
  }

  bool updatePassword(String username, String newPassword) {
    final user = _users[username];
    if (user == null) return false;

    user['password'] = newPassword;
    return true;
  }
}
