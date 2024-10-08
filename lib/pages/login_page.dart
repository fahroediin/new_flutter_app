import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:new_flutter_app/auth/auth_page.dart';
import 'forgot_pw_page.dart';
import 'home_page.dart';
import 'register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback showRegisterPage;

  const LoginPage({Key? key, required this.showRegisterPage}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GlobalKey<FormState> _key = GlobalKey<FormState>();
  late ScaffoldMessengerState _scaffoldMessengerState;
  bool _obscurePassword = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scaffoldMessengerState = ScaffoldMessenger.of(context);
      _loadEmailHistory();
    });

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    final snackBar = SnackBar(
      content: Text(message),
      duration: Duration(seconds: 2), // Durasi muncul snackbar selama 2 detik
      behavior: SnackBarBehavior.floating, // Mengatur snackbar menjadi floating
    );
    _scaffoldMessengerState.showSnackBar(snackBar);
  }

  Future<void> _loadEmailHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');
    if (email != null) {
      setState(() {
        _emailController.text = email;
      });
    }
  }

  Future<void> _saveEmailHistory() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _emailController.text);
  }

  Future<void> signIn() async {
    if (_key.currentState!.validate()) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        _saveEmailHistory(); // Simpan histori email

        // Menggunakan Navigator.pushReplacement dengan PageRouteBuilder untuk animasi transisi
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 300),
            pageBuilder: (_, __, ___) => const HomePage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
        _showSnackBar(
            'Login berhasil'); // Menampilkan snackbar "Login berhasil"
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          _showSnackBar('Email tidak terdaftar');
        } else if (e.code == 'wrong-password') {
          _showSnackBar('Password salah');
        } else {
          _showSnackBar('Terjadi kesalahan saat login');
        }
      } catch (e) {
        _showSnackBar('Terjadi kesalahan saat login');
      }
    }
  }

  String? _emailValidator(String? formEmail) {
    if (formEmail == null || formEmail.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    String pattern = r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)*(\.[a-zA-Z]{2,})$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(formEmail)) {
      return 'Format Alamat Email tidak valid.';
    }
    return null;
  }

  String? _passwordValidator(String? formPassword) {
    if (formPassword == null || formPassword.isEmpty) {
      return 'Password tidak boleh kosong.';
    }
    return null;
  }

  Future<void> _showRegisterPage() async {
    _animationController.forward();
    await Future.delayed(Duration(milliseconds: 1000));

    // Menggunakan Navigator.push dengan PageRouteBuilder untuk animasi transisi
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => RegisterPage(
          showLoginPage: () {},
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _key,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),
                  Container(
                    margin: const EdgeInsets.only(left: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selamat Datang,',
                        style: GoogleFonts.roboto(
                          fontSize: 45,
                          color: const Color.fromARGB(255, 20, 20, 19),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 20.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Login untuk melanjutkan.',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          color: const Color.fromARGB(255, 20, 20, 19),
                          fontWeight: FontWeight.w200,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/login.png',
                    width: 250,
                    height: 250,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        hintText: 'Email',
                        fillColor: Color.fromARGB(255, 247, 243, 244),
                        filled: true,
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: _emailValidator,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25.0, vertical: 10),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blueAccent),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        hintText: 'Password',
                        fillColor: Color.fromARGB(255, 247, 243, 244),
                        filled: true,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: _passwordValidator,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
                                  return ForgotPasswordPage();
                                },
                                transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                              ),
                            );
                          },
                          child: Text(
                            'Forgot password',
                            style: TextStyle(
                              color: Color.fromARGB(255, 6, 108, 176),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          await signIn();
                        },
                        child: Text(
                          'LOGIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              Color.fromARGB(255, 6, 108, 176)),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 50),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      'Don`t have an account?',
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 20,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              transitionDuration: Duration(milliseconds: 500),
                              pageBuilder: (_, __, ___) => RegisterPage(
                                showLoginPage: () {},
                              ),
                              transitionsBuilder: (_, animation, __, child) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                            ),
                          );
                        },
                        child: Text(
                          'Register',
                          style: TextStyle(
                            color: Color.fromARGB(255, 6, 108, 176),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
