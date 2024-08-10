import 'package:flutter/material.dart';
import 'package:new_flutter_app/pages/login_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../pages/register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class Auth with ChangeNotifier {
  void signIn(String email, String password) async {
    Uri url = Uri.parse(
        "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=AIzaSyCZNiQt72OoHO4MCj0clCdaxIGmJ5-3Ohk");
    var response = await http.post(
      url,
      body: json.encode({
        "email": email,
        "password": password,
        "returnSecureToken": true,
      }),
    );
    // ignore: avoid_print
    print(json.decode(response.body));
  }
}

class _AuthPageState extends State<AuthPage> {
  //inisiasi login page
  bool showLoginPage = true;

  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(showRegisterPage: toggleScreens);
    } else {
      return RegisterPage(showLoginPage: toggleScreens);
    }
  }
}
