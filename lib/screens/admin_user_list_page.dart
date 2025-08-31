import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/FirestoreService.dart';
import '../services/AuthService.dart';

class AdminUserListPage extends StatelessWidget {
  const AdminUserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fs = FirestoreService();
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: fs.streamAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final d = docs[i];
              final data = d.data();
              final email = data['email'] as String? ?? '-';
              final name = data['displayName'] as String? ?? email.split('@').first;
              final role = data['role'] as String? ?? 'user';
              final avatar = data['avatarUrl'] as String? ?? '';
              final isMe = d.id == auth.currentUser?.uid;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (avatar.isNotEmpty) ? NetworkImage(avatar) : null,
                    child: (avatar.isEmpty) ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?') : null,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('$email • $role'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'reset') {
                        try {
                          await auth.sendPasswordResetEmail(email);
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Reset email sent to $email')),
                          );
                        } catch (e) {
                          // ignore: use_build_context_synchronously
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'reset',
                        child: ListTile(
                          leading: Icon(Icons.mail),
                          title: Text('Send password reset email'),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {}, // future: open user detail
                ),
              );
            },
          );
        },
      ),
    );
  }
}
