class TagGenerator {
  /// Generates a deterministic, 4-character uppercase alphanumeric tag (Discord/Riot-style)
  /// from a given Firebase UID using the FNV-1a 32-bit hash algorithm.
  static String generateDeterministicTag(String uid) {
    int hash = 2166136261;
    for (int i = 0; i < uid.length; i++) {
      hash = hash ^ uid.codeUnitAt(i);
      // Enforce 32-bit unsigned integer multiplication
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    
    // We want a 4-character base36 string.
    // 36^4 = 1,679,616. Modulo constraints the hash value to 0..1679615.
    final int value = hash.abs() % 1679616;
    
    // Convert to base 36 (digits + uppercase letters) and pad to 4 characters
    return value.toRadixString(36).toUpperCase().padLeft(4, '0');
  }
}
