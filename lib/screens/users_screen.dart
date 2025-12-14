// screens/users_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await UserService.getUsers();
    if (mounted) {
      setState(() {
        _users = users;
        _isLoading = false;
      });
    }
  }

  // -------------------- Floating Notification --------------------
  void showFloatingNotification(String message, Color color) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }

  // -------------------- Add / Edit User Dialog --------------------
  void _showUserDialog({User? user}) {
    final fullNameController = TextEditingController(text: user?.fullName ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');
    String _selectedRole = user?.role ?? "USER";
    bool isValid = false;

    void validate() {
      final fullName = fullNameController.text.trim();
      final email = emailController.text.trim().toLowerCase();
      final emailRegex = RegExp(
        r"^[a-zA-Z0-9]+([._%+-]?[a-zA-Z0-9])*@[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+$",
      );
      isValid = fullName.split(' ').length >= 2 &&
          emailRegex.hasMatch(email) &&
          ["USER", "ADMIN"].contains(_selectedRole);
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(user == null ? "Add User" : "Edit User"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: fullNameController,
                decoration: const InputDecoration(labelText: "Full Name"),
                onChanged: (_) => setState(validate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
                enabled: user == null, // prevent email change on edit
                onChanged: (_) => setState(validate),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: ["USER", "ADMIN"].map((role) {
                  return DropdownMenuItem(
                    value: role,
                    child: Text(role),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    _selectedRole = val;
                    setState(validate);
                  }
                },
                decoration: const InputDecoration(labelText: "Role"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            if (user != null)
              TextButton(
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text("Delete User"),
                      content: const Text("Are you sure you want to delete this user?"),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
                      ],
                    ),
                  );

                  if (confirmed != true) return;

                  final success = await UserService.deleteUser(user.email);
                  if (success) {
                    Navigator.pop(context);
                    _loadUsers();
                    showFloatingNotification(
                      "User deleted: \"${user.fullName}\" (${user.role})",
                      Colors.red,
                    );
                  } else {
                    showFloatingNotification("Failed to delete user", Colors.red);
                  }
                },
                child: const Text("Delete"),
              ),
            ElevatedButton(
              onPressed: isValid
                  ? () async {
                      final fullName = fullNameController.text.trim();
                      final email = emailController.text.trim().toLowerCase();
                      final role = _selectedRole.trim().toUpperCase();

                      if (user == null) {
                        // Add new
                        final existingUser = await UserService.getUserByEmail(email);
                        if (existingUser != null) {
                          showFloatingNotification("This email is already registered", Colors.red);
                          return;
                        }

                        final success = await UserService.addUser(
                          fullName: fullName,
                          email: email,
                          role: role,
                        );

                        if (success) {
                          Navigator.pop(context);
                          _loadUsers();
                          showFloatingNotification("User added successfully", Colors.green);
                        } else {
                          showFloatingNotification("Failed to add user", Colors.red);
                        }
                      } else {
                        // Edit existing
                        final oldName = user.fullName; // capture old name
                        final oldRole = user.role;     // capture old role

                        final success = await UserService.updateUser(
                          fullName: fullName,
                          email: email,
                          role: role,
                        );

                        if (success) {
                          Navigator.pop(context);
                          _loadUsers();
                          showFloatingNotification(
                            "User updated: \"$oldName\" → \"$fullName\" ($role)",
                            Colors.green,
                          );
                        } else {
                          showFloatingNotification("Failed to update user", Colors.red);
                        }
                      }
                    }
                  : null,
              child: Text(user == null ? "Add" : "Save"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (_, index) {
                final user = _users[index];
                return ListTile(
                  title: Text(user.fullName),
                  subtitle: Text("${user.email} • ${user.role}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showUserDialog(user: user),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
