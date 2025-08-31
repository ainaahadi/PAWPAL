import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/AuthService.dart';
import '../services/FirestoreService.dart';

class AdminEditProfilePage extends StatefulWidget {
  const AdminEditProfilePage({super.key});

  @override
  State<AdminEditProfilePage> createState() => _AdminEditProfilePageState();
}

class _AdminEditProfilePageState extends State<AdminEditProfilePage> {
  final _auth = AuthService();
  final _fs = FirestoreService();

  final _nameCtl = TextEditingController();
  final _avatarCtl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = _auth.currentUser;
    _nameCtl.text = u?.displayName ?? (u?.email?.split('@').first ?? '');
    _avatarCtl.text = u?.photoURL ?? '';
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _avatarCtl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final u = _auth.currentUser!;
    setState(() => _saving = true);
    try {
      // Update Firebase Auth profile
      await _auth.updateDisplayName(_nameCtl.text.trim());
      if (_avatarCtl.text.trim().isNotEmpty) {
        await _auth.updatePhotoUrl(_avatarCtl.text.trim());
      }

      // Mirror to Firestore
      await _fs.updateMyProfile(
        uid: u.uid,
        displayName: _nameCtl.text.trim(),
        avatarUrl: _avatarCtl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = _auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin • Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Text('Email', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 4),
              Text(u?.email ?? '-', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtl,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _avatarCtl,
                decoration: const InputDecoration(
                  labelText: 'Avatar URL (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.save),
                label: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
