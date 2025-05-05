import 'package:chatty/components/user_tile.dart';
import 'package:flutter/material.dart';
import 'package:chatty/components/drawer.dart';
import 'package:chatty/services/chat/chat_service.dart';
import 'package:chatty/pages/chat_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  final Function toggleTheme;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // Clear search when switching tabs
      if (_isSearching) {
        setState(() {
          _searchController.clear();
          _searchQuery = '';
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      } else {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        _tabController.index == 0
                            ? 'Search conversations'
                            : 'Find people by email',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  style: theme.textTheme.bodyLarge,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                  autofocus: true,
                )
                : Text(
                  'Chatty',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                  ),
                ),
        leading:
            _isSearching
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _toggleSearch,
                  tooltip: 'Back',
                )
                : null,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Clear search' : 'Search',
          ),
        ],
        bottom:
            _isSearching
                ? null
                : TabBar(
                  controller: _tabController,
                  tabs: const [Tab(text: 'Chats'), Tab(text: 'Find People')],
                  labelStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Montserrat',
                  ),
                  unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Montserrat',
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                ),
        elevation: 0,
      ),
      drawer: CustomDrawer(
        toggleTheme: widget.toggleTheme,
        isDarkMode: widget.isDarkMode,
      ),
      body: Container(
        color:
            theme.brightness == Brightness.light
                ? Colors.grey.shade50
                : theme.colorScheme.background,
        child:
            _isSearching
                ? (_tabController.index == 0
                    ? _buildContactsSearch(_auth.currentUser!.email!)
                    : _buildAllUsersSearch(_auth.currentUser!.email!))
                : TabBarView(
                  controller: _tabController,
                  children: [_buildUserList(), _buildNewUsersTab()],
                ),
      ),
    );
  }

  Widget _buildNewUsersTab() {
    final currentUserEmail = _auth.currentUser?.email;
    final searchController = TextEditingController();
    final ValueNotifier<String> searchQuery = ValueNotifier<String>('');
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Simple instructions
          Text(
            'Find someone by email address',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Enter email address...',
              prefixIcon: Icon(
                Icons.search,
                color: theme.colorScheme.primary.withOpacity(0.7),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              suffixIcon: ValueListenableBuilder<String>(
                valueListenable: searchQuery,
                builder: (context, value, child) {
                  return value.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                      : const SizedBox.shrink();
                },
              ),
              hintStyle: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.5),
                fontFamily: 'Montserrat',
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: theme.colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontFamily: 'Montserrat',
            ),
            onChanged: (value) {
              searchQuery.value = value.toLowerCase();
            },
          ),

          const SizedBox(height: 24),

          // Results area
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: searchQuery,
              builder: (context, query, child) {
                if (query.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search,
                          size: 80,
                          color: theme.colorScheme.onBackground.withOpacity(
                            0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Enter an email address to find someone',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.7,
                            ),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return StreamBuilder(
                  stream: _chatService.getUserStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _buildErrorState('Could not search users');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No users found',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onBackground.withOpacity(
                              0.7,
                            ),
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      );
                    }

                    // Filter users by search query and exclude current user
                    final filteredUsers =
                        snapshot.data!
                            .where(
                              (userData) =>
                                  userData['email'] != null &&
                                  userData['email'] != currentUserEmail &&
                                  userData['email']
                                      .toString()
                                      .toLowerCase()
                                      .contains(query),
                            )
                            .toList();

                    if (filteredUsers.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_off,
                              size: 60,
                              color: theme.colorScheme.onBackground.withOpacity(
                                0.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No user found with email containing "$query"',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onBackground
                                    .withOpacity(0.7),
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredUsers.length,
                      padding: const EdgeInsets.only(top: 8),
                      itemBuilder: (context, index) {
                        final userData = filteredUsers[index];
                        final String email = userData['email'] ?? 'No email';

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: UserTile(
                            text: email,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ChatPage(
                                        recieverEmail: email,
                                        isDarkMode: widget.isDarkMode,
                                        toggleTheme: widget.toggleTheme,
                                      ),
                                ),
                              );
                            },
                            isNewContact: true,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsSearch(String currentUserEmail) {
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: _chatService.getChatUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Could not search contacts');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No conversations yet',
            'Tap "Find People" to start a new chat',
            actionButton: TextButton.icon(
              onPressed: () {
                _tabController.animateTo(1);
                setState(() {
                  _isSearching = false;
                });
              },
              icon: Icon(Icons.people, color: theme.colorScheme.primary),
              label: Text(
                'Find People',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }

        // Filter chat users by search query
        final filteredUsers =
            snapshot.data!.where((chatUser) {
              final email =
                  currentUserEmail == chatUser.senderEmail
                      ? chatUser.receiverEmail
                      : chatUser.senderEmail;

              return email.toLowerCase().contains(_searchQuery);
            }).toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(
            'No matching contacts',
            'Try a different search term or find new people',
            actionButton: TextButton.icon(
              onPressed: () {
                _tabController.animateTo(1);
                setState(() {
                  _isSearching = true;
                });
              },
              icon: Icon(Icons.people, color: theme.colorScheme.primary),
              label: Text(
                'Find People Instead',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemBuilder: (context, index) {
            final chatUser = filteredUsers[index];
            final String email =
                currentUserEmail == chatUser.senderEmail
                    ? chatUser.receiverEmail
                    : chatUser.senderEmail;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UserTile(
                text: email,
                subtitle:
                    chatUser.lastMessage.isNotEmpty
                        ? chatUser.lastMessage
                        : 'Start a conversation',
                onTap: () {
                  setState(() {
                    _isSearching = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatPage(
                            recieverEmail: email,
                            isDarkMode: widget.isDarkMode,
                            toggleTheme: widget.toggleTheme,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAllUsersSearch(String currentUserEmail) {
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: _chatService.getUserStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Could not search users');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No users found',
            'Be the first to invite friends!',
          );
        }

        // Filter users by search query and exclude current user
        final filteredUsers =
            snapshot.data!
                .where(
                  (userData) =>
                      userData['email'] != null &&
                      userData['email'] != currentUserEmail &&
                      userData['email'].toString().toLowerCase().contains(
                        _searchQuery,
                      ),
                )
                .toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(
            'No users found matching "$_searchQuery"',
            'Try a different search term',
          );
        }

        return ListView.builder(
          itemCount: filteredUsers.length,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemBuilder: (context, index) {
            final userData = filteredUsers[index];
            final String email = userData['email'] ?? 'No email';

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UserTile(
                text: email,
                onTap: () {
                  setState(() {
                    _isSearching = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatPage(
                            recieverEmail: email,
                            isDarkMode: widget.isDarkMode,
                            toggleTheme: widget.toggleTheme,
                          ),
                    ),
                  );
                },
                isNewContact: true,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserList() {
    final currentUserEmail = _auth.currentUser?.email;
    final theme = Theme.of(context);

    return StreamBuilder(
      stream: _chatService.getChatUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Could not load conversations');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            'No conversations yet',
            'Start a new chat to connect with people',
            actionButton: TextButton.icon(
              onPressed: () => _tabController.animateTo(1),
              icon: Icon(
                Icons.chat_bubble_outline,
                color: theme.colorScheme.primary,
              ),
              label: Text(
                'Start a New Chat',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          itemBuilder: (context, index) {
            final chatUser = snapshot.data![index];
            final String email =
                currentUserEmail == chatUser.senderEmail
                    ? chatUser.receiverEmail
                    : chatUser.senderEmail;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: UserTile(
                text: email,
                subtitle:
                    chatUser.lastMessage.isNotEmpty
                        ? chatUser.lastMessage
                        : 'Start a conversation',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChatPage(
                            recieverEmail: email,
                            isDarkMode: widget.isDarkMode,
                            toggleTheme: widget.toggleTheme,
                          ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(
    String title,
    String message, {
    Widget? actionButton,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _tabController.index == 0
                  ? Icons.chat_bubble_outline
                  : Icons.people_outline,
              size: 70,
              color: theme.colorScheme.onBackground.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            if (actionButton != null) ...[
              const SizedBox(height: 24),
              actionButton,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 70, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
                color: theme.colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => setState(() {}),
              icon: Icon(Icons.refresh, color: theme.colorScheme.primary),
              label: Text(
                'Try Again',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
