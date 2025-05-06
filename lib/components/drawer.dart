import 'package:flutter/material.dart';
import 'package:chatty/pages/settings_page.dart';
import 'package:chatty/services/auth/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  final Function toggleTheme;
  final bool isDarkMode;
  
  const CustomDrawer({
    super.key, 
    required this.toggleTheme, 
    required this.isDarkMode,
  });

  void logout() {
    final auth = AuthService();
    auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      backgroundColor: theme.colorScheme.surface,
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chatty',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.home_rounded, color: theme.colorScheme.primary),
            title: Text(
              'Home',
              style: theme.textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(Icons.settings_rounded, color: theme.colorScheme.primary),
            title: Text(
              'Settings',
              style: theme.textTheme.titleMedium,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => SettingsPage(
                  toggleTheme: toggleTheme,
                  isDarkMode: isDarkMode,
                )),
              );
            },
          ),
          
          // Theme toggle
          ListTile(
            leading: Icon(
              isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: theme.colorScheme.primary,
            ),
            title: Text(
              isDarkMode ? 'Light Mode' : 'Dark Mode',
              style: theme.textTheme.titleMedium,
            ),
            onTap: () {
              toggleTheme();
              Navigator.pop(context);
            },
          ),
          
          const Spacer(),
          
          Divider(color: theme.dividerTheme.color),
          
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red),
            title: Text(
              'Logout',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.red),
            ),
            onTap: logout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}