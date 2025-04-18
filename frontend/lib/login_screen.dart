import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:frontend/main.dart';
import 'package:frontend/layout.dart';
import 'package:frontend/providers/teacher_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:frontend/utility/geofencing.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

Geofencing geofencing = Geofencing();

Future<void> saveFCMToken(String studentId) async {
  String? token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('students')
        .doc(studentId)
        .update({'fcmToken': token});
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  var _isObscured = true;
  var _userRole = UserRole.student;
  String? _errorText;

  Future<void> _validateAndLogin() async {
    var email = _emailController.text;
    var password = _passwordController.text;

    try {
      //if form not valid then return
      if (!(_formKey.currentState!.validate())) return;

      //check if admin
      if (_userRole == UserRole.admin &&
          _emailController.text == 'admin@gmail.com' &&
          _passwordController.text == 'admin123') {
        await addToSharedPreference({}, _userRole);
        navigateToDashboard(_userRole);
        return;
      }

      //get the user details and validate
      var user = await authenticateUser(email, password, _userRole);
      if (user.isEmpty) return;

      //create geofence
      // await createGeofencesForUser(user, _userRole);

      //add to sharedpreference
      await addToSharedPreference(user, _userRole);

      //update the provider data
      if (_userRole == UserRole.teacher) {
        if (!mounted) return;
        TeacherProvider teacherProvider = Provider.of<TeacherProvider>(
          context,
          listen: false,
        );
        teacherProvider.setTeacher(user);
      }

      //add FCM token if student
      if (_userRole == UserRole.student) {
        await saveFCMToken(user['_id']);
      }

      //go to dashboard
      navigateToDashboard(_userRole);
    } catch (e) {
      print("Error happened: $e");
      print("Stack Trace: $StackTrace");
      setState(() {
        _errorText = "An error occured please try again!";
      });
    }
  }

  void navigateToDashboard(UserRole role) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext ctx) {
          return Layout(currentUser: role);
        },
      ),
    );
  }

  Future<void> addToSharedPreference(
    Map<String, dynamic> user,
    UserRole role,
  ) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString("user_role", role.name);
    await prefs.setString("user_details", jsonEncode(user));
  }

  Future<void> createGeofencesForUser(
    Map<String, dynamic> user,
    UserRole role,
  ) async {
    //remove previous geofences
    geofencing.removeAllGeofences();
    if (role == UserRole.student) {
      print("created geofences for student");
    } else {
      print("created geofences for teachers");
    }
  }

  Future<Map<String, dynamic>> authenticateUser(
    String email,
    String password,
    UserRole role,
  ) async {
    var teacherUrl =
        "https://smart-attendance-app-hackathon.onrender.com/api/auth/login";
    var studentUrl =
        "https://smart-attendance-app-hackathon.onrender.com/api/students/login";
    String reqUrl;

    if (role == UserRole.teacher) {
      reqUrl = teacherUrl;
    } else {
      reqUrl = studentUrl;
    }

    var response = await http.post(
      Uri.parse(reqUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'email': email, 'password': password}),
    );

    var data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      if (role == UserRole.teacher) {
        return data["existingTeacher"];
      } else {
        print(data);
        return data['user'];
      }
    }

    setState(() {
      _errorText = data['message'];
    });

    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Login screen",
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Login",
            style: Theme.of(context).textTheme.headlineLarge!.copyWith(
              color: kcolorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      hintText: "Enter email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter email";
                      if (!RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                      ).hasMatch(value)) {
                        return "Enter a valid email";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    keyboardType: TextInputType.visiblePassword,
                    controller: _passwordController,
                    obscureText: _isObscured,
                    decoration: InputDecoration(
                      labelText: "Password",
                      hintText: "Enter password",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _isObscured = !_isObscured;
                          });
                        },
                        icon:
                            _isObscured
                                ? const Icon(Icons.visibility_off)
                                : const Icon(Icons.visibility),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) return "Please enter password";
                      if (value.length < 6) {
                        return "Password must be at least 6 characters";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    decoration: const InputDecoration(
                      labelText: "Select your role",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    value: _userRole,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _userRole = value;
                      });
                    },
                    items: [
                      for (final item in UserRole.values)
                        DropdownMenuItem(value: item, child: Text(item.name)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_errorText != null)
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  MaterialButton(
                    onPressed: _validateAndLogin,
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Colors.white,
                    minWidth: double.infinity,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                      child: Text("Login", style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
