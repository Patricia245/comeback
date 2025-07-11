import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  User? _user;
  DocumentSnapshot? _profileData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    _user = _auth.currentUser;
    if (_user != null) {
      final snapshot =
          await _firestore.collection('users').doc(_user!.uid).get();
      setState(() {
        _profileData = snapshot;
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _editProfile() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Edit'),
        content: const Text(
          'Are you sure you want to edit your profile? You may need to verify your identity.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfileScreen(
            userId: _user!.uid,
            initialData: _profileData!,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = _profileData?.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] ?? 'No name';
    final age = data['age'] ?? 'Unknown';
    final religion = data['religion'] ?? 'Unknown';
    final photoUrl = data['photoUrl'];
    final prayerRequests = data['prayerRequests'] as List<dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : const AssetImage('assets/images/placeholder_avatar.png')
                      as ImageProvider,
            ),
            const SizedBox(height: 16),
            Text(name, style: theme.headlineSmall),
            Text('Age: $age'),
            Text('Religion: $religion'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _editProfile,
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
            ),
            const SizedBox(height: 32),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Prayer Requests',
                style: theme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            if (prayerRequests != null && prayerRequests.isNotEmpty)
              ...prayerRequests.map(
                (p) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.favorite),
                    title: Text(p['request'] ?? 'No details'),
                    subtitle:
                        Text('Scheduled on: ${p['scheduledDay'] ?? 'TBD'}'),
                  ),
                ),
              )
            else
              const Text('No prayer requests yet.'),
          ],
        ),
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  final String userId;
  final DocumentSnapshot initialData;

  const EditProfileScreen({
    super.key,
    required this.userId,
    required this.initialData,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData.data() as Map<String, dynamic>? ?? {};
    _nameController = TextEditingController(text: data['name'] ?? '');
    _ageController =
        TextEditingController(text: (data['age'] ?? '').toString());
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Failed to save profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    setState(() => saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: saving
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Name required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age'),
                      validator: (value) {
                        final age = int.tryParse(value!);
                        if (age == null || age <= 0) {
                          return 'Enter valid age';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
