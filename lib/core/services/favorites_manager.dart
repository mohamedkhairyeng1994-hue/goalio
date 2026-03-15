import 'package:shared_preferences/shared_preferences.dart';

class FavoritesManager {
  static const String _favoritesKey = 'favorite_teams';

  // Get list of favorite team names
  static Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // Add a team to favorites
  static Future<void> addFavorite(String teamName) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    if (!favorites.contains(teamName)) {
      favorites.add(teamName);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // Remove a team from favorites
  static Future<void> removeFavorite(String teamName) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    if (favorites.contains(teamName)) {
      favorites.remove(teamName);
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // Toggle favorite status
  static Future<bool> toggleFavorite(String teamName) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    bool isAdded = false;

    if (favorites.contains(teamName)) {
      favorites.remove(teamName);
      isAdded = false;
    } else {
      favorites.add(teamName);
      isAdded = true;
    }

    await prefs.setStringList(_favoritesKey, favorites);
    return isAdded;
  }

  // Check if a team is favorite
  static Future<bool> isFavorite(String teamName) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoritesKey) ?? [];
    return favorites.contains(teamName);
  }
}
