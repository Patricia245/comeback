import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home/home_screen.dart';
import '../home/islam_home_screen.dart';
import '../home/priest_home_screen.dart';
import '../home/imam_home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedReligion;
  String? _selectedRole;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _religions = ['Christianity', 'Islam'];
  final List<String> _christianRoles = ['Student', 'Priest'];
  final List<String> _islamRoles = ['Student', 'Imam'];

  List<String> get _currentRoles {
    if (_selectedReligion == 'Christianity') return _christianRoles;
    if (_selectedReligion == 'Islam') return _islamRoles;
    return [];
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final religion = _selectedReligion;
    final role = _selectedRole;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        religion == null ||
        role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
        'name': name,
        'email': email,
        'religion': religion,
        'role': role,
        'createdAt': Timestamp.now(),
      });

      if (religion == 'Christianity') {
        if (role == 'Student') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => HomeScreen(studentName: name)));
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => PriestHomeScreen(priestName: name)));
        }
      } else {
        if (role == 'Student') {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => IslamHomeScreen(studentName: name)));
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => ImamHomeScreen(imamName: name)));
        }
      }
    } on FirebaseAuthException catch (e) {
      String msg = 'Registration failed';
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Email already in use.';
          break;
        case 'invalid-email':
          msg = 'Invalid email.';
          break;
        case 'weak-password':
          msg = 'Weak password.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unexpected error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 10,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Join the ComeBack Family',
                    style: theme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.deepPurple),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '“And pray for one another...” – James 5:16',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Religion dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedReligion,
                    decoration: InputDecoration(
                      labelText: 'Select Religion',
                      prefixIcon: const Icon(Icons.self_improvement),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: _religions.map((religion) {
                      return DropdownMenuItem(
                          value: religion, child: Text(religion));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedReligion = value;
                        _selectedRole = null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role dropdown (based on religion)
                  if (_selectedReligion != null)
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Select Role',
                        prefixIcon: const Icon(Icons.emoji_people),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _currentRoles.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedRole = value),
                    ),

                  const SizedBox(height: 24),

                  // Register Button
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _register,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_isLoading ? 'Registering...' : 'Register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    child: const Text('Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
