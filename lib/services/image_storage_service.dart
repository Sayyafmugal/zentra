/// Abstraction point for turning an image into a durable, publicly-reachable
/// URL to store on a [Product]/[UserProfile] document.
///
/// Firebase Storage was deliberately ruled out for this project (it requires
/// the Blaze billing plan just to enable, which isn't something every
/// deployment of this app can assume) — so today, the app collects an image
/// URL directly from the user (an existing link to an already-hosted image)
/// rather than uploading a file at all. [uploadImage] exists so that if a
/// real external provider (Cloudinary, ImgBB, S3, etc.) is wired in later,
/// every screen that needs "give me a URL for this image" can switch from
/// URL-entry to file-upload without any change beyond swapping the
/// [ImageStorageService] implementation bound in `InitialBinding`.
abstract class ImageStorageService {
  /// Uploads raw image bytes to whatever provider this implementation wraps
  /// and returns a public URL for the stored image.
  Future<String> uploadImage({required List<int> bytes, required String fileName});

  /// Removes a previously uploaded image. A no-op for images this service
  /// never uploaded itself (e.g. a URL the user pasted in from elsewhere).
  Future<void> deleteImage(String url);

  /// Validates that [url] looks like a usable image link (well-formed,
  /// http/https, non-empty) without fetching it. Returns the trimmed URL to
  /// store, or null if it isn't usable.
  String? validateImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.isAbsolute || !(uri.scheme == 'http' || uri.scheme == 'https')) {
      return null;
    }
    return trimmed;
  }
}

/// The only implementation currently wired up: no upload provider is
/// configured, so [uploadImage] fails loudly instead of pretending to
/// succeed. Every screen that needs an image URL today asks the user to
/// paste one directly and calls [validateImageUrl] instead of [uploadImage].
class UnconfiguredImageStorageService extends ImageStorageService {
  @override
  Future<String> uploadImage({required List<int> bytes, required String fileName}) {
    throw UnimplementedError(
      'No image hosting provider is configured for this app. '
      'Paste a direct image URL instead of uploading a file, or bind a real '
      'ImageStorageService implementation (e.g. for Cloudinary/ImgBB/S3) in '
      'InitialBinding.',
    );
  }

  @override
  Future<void> deleteImage(String url) async {
    // Nothing to delete: this service never took ownership of any file —
    // every URL in use was pasted in by a user, not uploaded through here.
  }
}
