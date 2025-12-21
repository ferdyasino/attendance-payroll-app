// screens/users_screen.dart
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  bool _showInactive = true;

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

  Future<bool> _toggleStatus(String email, bool activate) async {
    if (email.isEmpty) return false;
    final user = _users.firstWhere((u) => u.email == email);

    final success = user.status !=
            (activate ? "ACTIVE" : "INACTIVE")
        ? await UserService.updateUser(
            fullName: user.fullName,
            email: user.email,
            role: user.role,
            status: activate ? "ACTIVE" : "INACTIVE",
          )
        : false;

    if (success) await _loadUsers();

    return success;
  }

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
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 2), entry.remove);
  }

  void _showUserDialog({User? user}) {
    final fullNameController =
        TextEditingController(text: user?.fullName ?? '');
    final emailController =
        TextEditingController(text: user?.email ?? '');
    String selectedRole = user?.role ?? "USER";
    bool isValid = false;

    void validate() {
      final fullName = fullNameController.text.trim();
      final email = emailController.text.trim().toLowerCase();
      final emailRegex = RegExp(
        r"^[a-zA-Z0-9]+([._%+-]?[a-zA-Z0-9])*@[a-zA-Z0-9-]+(\.[a-zA-Z]{2,})+$",
      );
      isValid = fullName.split(' ').length >= 2 &&
          emailRegex.hasMatch(email) &&
          ["USER", "ADMIN"].contains(selectedRole);
    }

    final bool isActive = user?.status == "ACTIVE";

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
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                onChanged: (_) => setState(validate),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
                enabled: user == null,
                onChanged: (_) => setState(validate),
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
                  if (isActive) {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Delete User"),
                        content: const Text(
                          "Are you sure you want to delete this user?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              "Delete",
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    final success = await UserService.deleteUser(user.email);

                    if (success) {
                      Navigator.pop(context);
                      _loadUsers();
                      showFloatingNotification(
                        "User deleted: ${user.fullName}",
                        AppColors.error,
                      );
                    }
                  } else {
                    final success = await _toggleStatus(user.email, true);

                    if (success) {
                      Navigator.pop(context);
                      showFloatingNotification(
                        "User activated: ${user.fullName}",
                        AppColors.success,
                      );
                    }
                  }
                },
                child: Text(
                  isActive ? "Delete" : "Activate",
                  style: TextStyle(
                    color: isActive ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
            ElevatedButton(
              onPressed: isValid
                  ? () async {
                      final fullName = fullNameController.text.trim();
                      final email = emailController.text.trim().toLowerCase();

                      if (user == null) {
                        final exists = await UserService.getUserByEmail(email);
                        if (exists != null) {
                          showFloatingNotification(
                            "Email already exists",
                            AppColors.error,
                          );
                          return;
                        }

                        final success = await UserService.addUser(
                          fullName: fullName,
                          email: email,
                          role: selectedRole,
                        );

                        if (success) {
                          Navigator.pop(context);
                          _loadUsers();
                          showFloatingNotification(
                            "User added successfully",
                            AppColors.success,
                          );
                        }
                      } else {
                        final success = await UserService.updateUser(
                          fullName: fullName,
                          email: email,
                          role: selectedRole,
                          status: user.status,
                        );

                        if (success) {
                          Navigator.pop(context);
                          _loadUsers();
                          showFloatingNotification(
                            "User updated successfully",
                            AppColors.success,
                          );
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

  List<User> get _filteredUsers {
    if (_showInactive) return _users;
    return _users.where((u) => u.status != "INACTIVE").toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text("Users"),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Text("Show Inactive"),
                    const Spacer(),
                    Switch(
                      value: _showInactive,
                      onChanged: (v) {
                        setState(() => _showInactive = v);
                        Navigator.pop(context);
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredUsers.isEmpty
              ? Center(
                  child: Text(
                    "No users found.",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  itemCount: _filteredUsers.length,
                  itemBuilder: (_, index) {
                    final user = _filteredUsers[index];
                    final inactive = user.status == "INACTIVE";

                    return Card(
                      color: inactive ? AppColors.error.withOpacity(0.3) : null,
                      child: ListTile(
                        title: Text(user.fullName),
                        subtitle: Text(
                          "${user.email} • ${user.role} • ${user.status}",
                        ),
                        onTap: () => _showUserDialog(user: user),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showUserDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
