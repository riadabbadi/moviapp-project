import 'package:flutter/material.dart';

void main() {
  runApp(const MovieApp());
}

// ==================== APPLICATION PRINCIPALE ====================
class MovieApp extends StatelessWidget {
  const MovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CinéApp Pro',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

// ==================== SIMULATION BASE DE DONNÉES ====================
class Database {
  static final Database _instance = Database._internal();
  factory Database() => _instance;
  Database._internal();

  final List<Map<String, dynamic>> _users = [];
  final Map<String, List<int>> _userFavorites = {};

  void addUser(String username, String email, String password) {
    _users.add({
      'username': username,
      'email': email,
      'password': password,
    });
  }

  Map<String, dynamic>? getUser(String username) {
    try {
      return _users.firstWhere((user) => user['username'] == username);
    } catch (e) {
      return null;
    }
  }

  bool validateUser(String username, String password) {
    final user = getUser(username);
    return user != null && user['password'] == password;
  }

  void updateUser(String oldUsername, String newUsername, String newEmail, String newPassword) {
    final user = getUser(oldUsername);
    if (user != null) {
      // Transférer les favoris
      if (oldUsername != newUsername) {
        final favorites = getFavorites(oldUsername);
        saveFavorites(newUsername, favorites);
        removeFavorites(oldUsername);
      }
      
      user['username'] = newUsername;
      user['email'] = newEmail;
      user['password'] = newPassword;
      
      // Mettre à jour dans la liste
      final index = _users.indexWhere((u) => u['username'] == oldUsername);
      if (index != -1) {
        _users[index] = user;
      }
    }
  }

  // FAVORIS - FONCTIONNEL
  void saveFavorites(String username, List<int> favorites) {
    _userFavorites[username] = favorites;
  }

  List<int> getFavorites(String username) {
    return _userFavorites[username] ?? [];
  }

  void addFavorite(String username, int movieId) {
    _userFavorites.putIfAbsent(username, () => []);
    if (!_userFavorites[username]!.contains(movieId)) {
      _userFavorites[username]!.add(movieId);
    }
  }

  void removeFavorite(String username, int movieId) {
    _userFavorites[username]?.remove(movieId);
  }

  void removeFavorites(String username) {
    _userFavorites.remove(username);
  }

  bool isFavorite(String username, int movieId) {
    return _userFavorites[username]?.contains(movieId) ?? false;
  }
}

// ==================== GESTIONNAIRE D'AUTHENTIFICATION ====================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final Database _db = Database();
  String? _currentUsername;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Ajouter un utilisateur de test
    _db.addUser('test', 'test@test.com', '123456');
    _db.addUser('admin', 'admin@admin.com', 'admin123');
  }

  void _register(String username, String email, String password) {
    _db.addUser(username, email, password);
    _login(username, password);
  }

  void _login(String username, String password) {
    if (_db.validateUser(username, password)) {
      setState(() {
        _currentUsername = username;
        _isLoggedIn = true;
      });
    }
  }

  void _logout() {
    setState(() {
      _currentUsername = null;
      _isLoggedIn = false;
    });
  }

  void _updateProfile(String oldUsername, String newUsername, String newEmail, String newPassword) {
    _db.updateUser(oldUsername, newUsername, newEmail, newPassword);
    if (oldUsername != newUsername) {
      setState(() {
        _currentUsername = newUsername;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn || _currentUsername == null) {
      return RegisterScreen(
        onRegister: _register,
        onLogin: _login,
        db: _db,
      );
    } else {
      return HomeScreen(
        username: _currentUsername!,
        db: _db,
        onLogout: _logout,
        onUpdateProfile: _updateProfile,
      );
    }
  }
}

// ==================== ÉCRAN D'INSCRIPTION/CONNEXION (TEXTE BLANC) ====================
class RegisterScreen extends StatefulWidget {
  final Function(String, String, String) onRegister;
  final Function(String, String) onLogin;
  final Database db;

  const RegisterScreen({
    super.key,
    required this.onRegister,
    required this.onLogin,
    required this.db,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLogin = true;
  bool _showError = false;
  String _errorMessage = '';
  
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  void _submit() {
    setState(() => _showError = false);

    if (_isLogin) {
      // CONNEXION
      if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
        setState(() {
          _showError = true;
          _errorMessage = 'Veuillez remplir tous les champs';
        });
        return;
      }
      
      if (widget.db.validateUser(_usernameController.text, _passwordController.text)) {
        widget.onLogin(_usernameController.text, _passwordController.text);
      } else {
        setState(() {
          _showError = true;
          _errorMessage = 'Nom d\'utilisateur ou mot de passe incorrect';
        });
      }
    } else {
      // INSCRIPTION
      if (_usernameController.text.isEmpty ||
          _emailController.text.isEmpty ||
          _passwordController.text.isEmpty ||
          _confirmPasswordController.text.isEmpty) {
        setState(() {
          _showError = true;
          _errorMessage = 'Veuillez remplir tous les champs';
        });
        return;
      }
      
      if (widget.db.getUser(_usernameController.text) != null) {
        setState(() {
          _showError = true;
          _errorMessage = 'Ce nom d\'utilisateur existe déjà';
        });
        return;
      }
      
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _showError = true;
          _errorMessage = 'Les mots de passe ne correspondent pas';
        });
        return;
      }
      
      if (_passwordController.text.length < 6) {
        setState(() {
          _showError = true;
          _errorMessage = 'Le mot de passe doit faire au moins 6 caractères';
        });
        return;
      }
      
      widget.onRegister(
        _usernameController.text,
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F0F1A),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.movie_filter_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // Titre en BLANC
                Text(
                  _isLogin ? 'Content de vous revoir !' : 'Rejoignez CinéApp',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _isLogin
                      ? 'Connectez-vous à votre compte'
                      : 'Créez votre compte gratuitement',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 40),

                // Message d'erreur
                if (_showError)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_showError) const SizedBox(height: 20),

                // Formulaire
                Card(
                  color: Colors.white.withOpacity(0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Email (inscription seulement)
                        if (!_isLogin) ...[
                          TextField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.email, color: Colors.white70),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],

                        // Nom d'utilisateur
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Nom d\'utilisateur',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.person, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Mot de passe
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: const TextStyle(color: Colors.white70),
                            prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // Confirmation mot de passe (inscription seulement)
                        if (!_isLogin) ...[
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Confirmer le mot de passe',
                              labelStyle: const TextStyle(color: Colors.white70),
                              prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],

                        // Bouton
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepPurple,
                            ),
                            child: Text(
                              _isLogin ? 'Se connecter' : 'S\'inscrire',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Lien
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _showError = false;
                              _usernameController.clear();
                              _emailController.clear();
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Pas de compte ? S\'inscrire'
                                : 'Déjà un compte ? Se connecter',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== ÉCRAN PRINCIPAL ====================
class HomeScreen extends StatefulWidget {
  final String username;
  final Database db;
  final VoidCallback onLogout;
  final Function(String, String, String, String) onUpdateProfile;

  const HomeScreen({
    super.key,
    required this.username,
    required this.db,
    required this.onLogout,
    required this.onUpdateProfile,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<int> _favoriteMovies;

  @override
  void initState() {
    super.initState();
    _favoriteMovies = widget.db.getFavorites(widget.username);
  }

  void _toggleFavorite(int movieId) {
    setState(() {
      if (_favoriteMovies.contains(movieId)) {
        widget.db.removeFavorite(widget.username, movieId);
        _favoriteMovies.remove(movieId);
      } else {
        widget.db.addFavorite(widget.username, movieId);
        _favoriteMovies.add(movieId);
      }
    });
  }

  void _showFavorites() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎬 Mes Films Favoris'),
        content: _favoriteMovies.isEmpty
            ? const Text('Aucun film favori pour le moment')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _favoriteMovies.length,
                  itemBuilder: (context, index) {
                    final movieId = _favoriteMovies[index];
                    final movie = Movie.movies[movieId];
                    return ListTile(
                      leading: const Icon(Icons.movie, color: Colors.deepPurple),
                      title: Text(movie.title),
                      subtitle: Text('${movie.year} • ${movie.genre}'),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.db.getUser(widget.username);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0
              ? '🎬 Films du moment'
              : _selectedIndex == 1
                  ? '❓ Quiz Cinéma'
                  : '👤 Mon Profil',
        ),
        leading: IconButton(
          icon: const Icon(Icons.favorite),
          onPressed: _showFavorites,
          tooltip: 'Voir mes favoris',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: MovieSearchDelegate(),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.username),
              accountEmail: Text(user?['email'] ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.deepPurple[100],
                child: Text(
                  widget.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 24, color: Colors.deepPurple),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.deepPurple),
              title: const Text('Accueil'),
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.red),
              title: const Text('Mes Favoris'),
              onTap: () {
                _showFavorites();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz, color: Colors.green),
              title: const Text('Quiz'),
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Mon Profil'),
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Déconnexion'),
              onTap: () {
                widget.onLogout();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          MoviesScreen(
            username: widget.username,
            db: widget.db,
            favoriteMovies: _favoriteMovies,
            onToggleFavorite: _toggleFavorite,
          ),
          const QuizScreen(),
          ProfileScreen(
            username: widget.username,
            db: widget.db,
            onLogout: widget.onLogout,
            onUpdateProfile: widget.onUpdateProfile,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.movie_outlined),
            selectedIcon: Icon(Icons.movie),
            label: 'Films',
          ),
          NavigationDestination(
            icon: Icon(Icons.quiz_outlined),
            selectedIcon: Icon(Icons.quiz),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

// ==================== RECHERCHE DE FILMS ====================
class MovieSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = Movie.movies
        .where((movie) =>
            movie.title.toLowerCase().contains(query.toLowerCase()) ||
            movie.genre.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final movie = results[index];
        return ListTile(
          leading: const Icon(Icons.movie, color: Colors.deepPurple),
          title: Text(movie.title),
          subtitle: Text('${movie.year} • ${movie.genre}'),
          onTap: () {
            close(context, null);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('🎬 ${movie.title} sélectionné')),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const Center(
      child: Text('Recherchez un film ou un genre...'),
    );
  }
}

// ==================== ÉCRAN FILMS ====================
class MoviesScreen extends StatelessWidget {
  final String username;
  final Database db;
  final List<int> favoriteMovies;
  final Function(int) onToggleFavorite;

  const MoviesScreen({
    super.key,
    required this.username,
    required this.db,
    required this.favoriteMovies,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Tous', 'Action', 'Science-Fiction', 'Drame', 'Animation', 'Comédie']
                  .map((genre) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(genre),
                          selected: genre == 'Tous',
                          onSelected: (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Filtre: $genre')),
                            );
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
        // Liste des films
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: Movie.movies.length,
            itemBuilder: (context, index) {
              final movie = Movie.movies[index];
              final isFavorite = db.isFavorite(username, index);
              
              return MovieCard(
                movie: movie,
                isFavorite: isFavorite,
                onToggleFavorite: () => onToggleFavorite(index),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==================== MODÈLE FILM ====================
class Movie {
  final String title;
  final int year;
  final double rating;
  final String genre;
  final String description;
  final String duration;
  final String director;

  Movie({
    required this.title,
    required this.year,
    required this.rating,
    required this.genre,
    required this.description,
    required this.duration,
    required this.director,
  });

  static final List<Movie> movies = [
    Movie(
      title: 'Dune : Deuxième partie',
      year: 2024,
      rating: 4.8,
      genre: 'Science-Fiction',
      description: 'Paul Atreides s\'unit avec Chani et les Fremen pour se venger.',
      duration: '2h 46m',
      director: 'Denis Villeneuve',
    ),
    Movie(
      title: 'Oppenheimer',
      year: 2023,
      rating: 4.7,
      genre: 'Biographie',
      description: 'L\'histoire du père de la bombe atomique.',
      duration: '3h',
      director: 'Christopher Nolan',
    ),
    Movie(
      title: 'Spider-Man: Across the Spider-Verse',
      year: 2023,
      rating: 4.9,
      genre: 'Animation',
      description: 'Miles Morales explore le multivers.',
      duration: '2h 20m',
      director: 'Joaquim Dos Santos',
    ),
    Movie(
      title: 'The Batman',
      year: 2022,
      rating: 4.5,
      genre: 'Action',
      description: 'Batman enquête sur la corruption à Gotham.',
      duration: '2h 56m',
      director: 'Matt Reeves',
    ),
    Movie(
      title: 'Top Gun: Maverick',
      year: 2022,
      rating: 4.6,
      genre: 'Action',
      description: 'Pete Mitchell forme les meilleurs pilotes.',
      duration: '2h 10m',
      director: 'Joseph Kosinski',
    ),
  ];
}

// ==================== CARTE FILM ====================
class MovieCard extends StatefulWidget {
  final Movie movie;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  const MovieCard({
    super.key,
    required this.movie,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  double userRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final List<String> comments = [];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Container(
                  width: 60,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.movie, size: 40, color: Colors.deepPurple),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.movie.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${widget.movie.year} • ${widget.movie.genre}'),
                      Text('⏱️ ${widget.movie.duration}'),
                      Text('🎬 ${widget.movie.director}'),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: widget.isFavorite ? Colors.red : Colors.grey,
                  ),
                  onPressed: widget.onToggleFavorite,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Note moyenne
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${widget.movie.rating}/5',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const Text('(Note moyenne)'),
              ],
            ),
            const SizedBox(height: 8),

            // Votre note
            const Text('Votre note:'),
            Row(
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < userRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: () {
                    setState(() => userRating = (index + 1).toDouble());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('⭐ Vous avez donné ${index + 1} étoile(s)')),
                    );
                  },
                );
              }),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              widget.movie.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Commentaires
            const Text('💬 Commentaires:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...comments.map((comment) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('• $comment'),
                )),
            if (comments.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Aucun commentaire pour le moment', style: TextStyle(color: Colors.grey)),
              ),
            const SizedBox(height: 16),

            // Ajouter un commentaire
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      setState(() {
                        comments.add(_commentController.text);
                        _commentController.clear();
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('💬 Commentaire ajouté!')),
                      );
                    }
                  },
                  child: const Text('Envoyer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ÉCRAN QUIZ ====================
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuiz = 0;
  int currentQuestion = 0;
  int score = 0;

  final List<List<Map<String, dynamic>>> allQuizzes = [
    [
      {
        'question': 'Quel film a remporté l\'Oscar 2024?',
        'answers': ['Oppenheimer', 'Barbie', 'Poor Things', 'Dune'],
        'correct': 0,
      },
      {
        'question': 'Qui a réalisé "Inception"?',
        'answers': ['Christopher Nolan', 'Steven Spielberg', 'James Cameron', 'Quentin Tarantino'],
        'correct': 0,
      },
      {
        'question': 'Quel acteur joue Iron Man?',
        'answers': ['Chris Evans', 'Robert Downey Jr.', 'Chris Hemsworth', 'Mark Ruffalo'],
        'correct': 1,
      },
      {
        'question': 'Quelle franchise a le plus gros box-office?',
        'answers': ['Harry Potter', 'James Bond', 'Marvel Cinematic Universe', 'Star Wars'],
        'correct': 2,
      },
      {
        'question': 'Qui a réalisé "Pulp Fiction"?',
        'answers': ['Martin Scorsese', 'Quentin Tarantino', 'David Fincher', 'Stanley Kubrick'],
        'correct': 1,
      },
    ],
  ];

  final List<String> quizTitles = [
    '🎬 Quiz Général',
  ];

  void answerQuestion(int selectedIndex) {
    if (selectedIndex == allQuizzes[currentQuiz][currentQuestion]['correct']) {
      score++;
    }

    setState(() {
      if (currentQuestion < allQuizzes[currentQuiz].length - 1) {
        currentQuestion++;
      } else {
        _showResults();
      }
    });
  }

  void _showResults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('🏆 ${quizTitles[currentQuiz]} Terminé!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Score: $score/${allQuizzes[currentQuiz].length}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              score == allQuizzes[currentQuiz].length
                  ? '🎉 Parfait! Vous êtes un vrai cinéphile!'
                  : score >= allQuizzes[currentQuiz].length / 2
                      ? '👍 Excellent score! Continue comme ça!'
                      : '💪 Pas mal! Vous pouvez faire mieux!',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentQuestion = 0;
                score = 0;
              });
            },
            child: const Text('Recommencer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Sélection du quiz
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(quizTitles.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(quizTitles[index]),
                    selected: currentQuiz == index,
                    onSelected: (_) {
                      setState(() {
                        currentQuiz = index;
                        currentQuestion = 0;
                        score = 0;
                      });
                    },
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),

          // Progression
          LinearProgressIndicator(
            value: (currentQuestion + 1) / allQuizzes[currentQuiz].length,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestion + 1}/${allQuizzes[currentQuiz].length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Score: $score',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Question
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    allQuizzes[currentQuiz][currentQuestion]['question'],
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Réponses
                  ...List.generate(
                    allQuizzes[currentQuiz][currentQuestion]['answers'].length,
                    (index) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ElevatedButton(
                        onPressed: () => answerQuestion(index),
                        child: Text(allQuizzes[currentQuiz][currentQuestion]['answers'][index]),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
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

// ==================== ÉCRAN PROFIL ====================
class ProfileScreen extends StatefulWidget {
  final String username;
  final Database db;
  final VoidCallback onLogout;
  final Function(String, String, String, String) onUpdateProfile;

  const ProfileScreen({
    super.key,
    required this.username,
    required this.db,
    required this.onLogout,
    required this.onUpdateProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = widget.db.getUser(widget.username);
    _usernameController = TextEditingController(text: widget.username);
    _emailController = TextEditingController(text: user?['email'] ?? '');
    _passwordController = TextEditingController(text: user?['password'] ?? '');
  }

  void _saveProfile() {
    widget.onUpdateProfile(
      widget.username,
      _usernameController.text,
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Profil mis à jour avec succès')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.db.getUser(widget.username);
    final favorites = widget.db.getFavorites(widget.username);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Photo de profil
          Stack(
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.deepPurple[100],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.deepPurple, width: 3),
                ),
                child: Center(
                  child: Text(
                    widget.username.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Formulaire d'édition
          if (_isEditing) ...[
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Nom d\'utilisateur',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Enregistrer'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _isEditing = false),
                    child: const Text('Annuler'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],

          // Infos profil
          if (!_isEditing) ...[
            Text(
              widget.username,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(user?['email'] ?? '', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
          ],

          // Statistiques
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStat('${Movie.movies.length}', 'Films'),
                  _buildStat('${favorites.length}', 'Favoris'),
                  _buildStat('5', 'Questions'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),

          // Options
          Column(
            children: [
              _buildOption(Icons.favorite, 'Mes Favoris (${favorites.length})'),
              _buildOption(Icons.history, 'Historique'),
              _buildOption(Icons.settings, 'Paramètres'),
              _buildOption(Icons.help, 'Centre d\'aide'),
              _buildOption(Icons.logout, 'Déconnexion', isLogout: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildOption(IconData icon, String label, {bool isLogout = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, color: isLogout ? Colors.red : Colors.deepPurple),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (isLogout) {
            widget.onLogout();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('📱 $label')),
            );
          }
        },
      ),
    );
  }
}