import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../data/models/product_model.dart';

class VisualMatchResult {
  final ProductModel product;
  final double score; // 0.0 to 1.0 (1.0 = exact match)

  VisualMatchResult({required this.product, required this.score});

  int get percentage => (score * 100).round();
}

class ImageSimilarityService {
  static final ImageSimilarityService instance = ImageSimilarityService._();
  ImageSimilarityService._();

  // In-memory cache for precomputed product fingerprints
  final Map<String, _AdvancedImageFingerprint> _cache = {};

  // Decode Image bytes from Base64 or Data URI
  img.Image? _decodeImage(String base64OrDataUri) {
    try {
      String trimmed = base64OrDataUri.trim();
      if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
        try {
          final List<dynamic> list = jsonDecode(trimmed);
          if (list.isNotEmpty) trimmed = list.first.toString().trim();
        } catch (_) {}
      } else if (trimmed.contains('|')) {
        final parts = trimmed.split('|');
        if (parts.isNotEmpty) trimmed = parts.first.trim();
      }

      final commaIdx = trimmed.indexOf(',');
      final rawBase64 = commaIdx != -1 ? trimmed.substring(commaIdx + 1) : trimmed;
      final Uint8List bytes = base64Decode(rawBase64);
      return img.decodeImage(bytes);
    } catch (_) {
      return null;
    }
  }

  // Convert RGB to HSV
  static List<double> _rgbToHsv(int r, int g, int b) {
    final double rf = r / 255.0;
    final double gf = g / 255.0;
    final double bf = b / 255.0;

    final double maxVal = max(rf, max(gf, bf));
    final double minVal = min(rf, min(gf, bf));
    final double delta = maxVal - minVal;

    double h = 0.0;
    if (delta != 0.0) {
      if (maxVal == rf) {
        h = 60.0 * (((gf - bf) / delta) % 6.0);
      } else if (maxVal == gf) {
        h = 60.0 * (((bf - rf) / delta) + 2.0);
      } else {
        h = 60.0 * (((rf - gf) / delta) + 4.0);
      }
      if (h < 0.0) h += 360.0;
    }

    final double s = maxVal == 0.0 ? 0.0 : delta / maxVal;
    final double v = maxVal;

    return [h, s, v];
  }

  // 1. Spatial 3x3 Grid HSV Color Descriptor (Center-Weighted)
  List<_CellHsv> _extractSpatialHsvGrid(img.Image image) {
    final small = img.copyResize(image, width: 48, height: 48);
    final int cellW = (small.width / 3).floor();
    final int cellH = (small.height / 3).floor();

    final List<_CellHsv> grid = [];

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        double sumH = 0.0;
        double sumS = 0.0;
        double sumV = 0.0;
        int count = 0;

        for (int y = row * cellH; y < (row + 1) * cellH; y++) {
          for (int x = col * cellW; x < (col + 1) * cellW; x++) {
            final p = small.getPixel(x, y);
            final hsv = _rgbToHsv(p.r.toInt(), p.g.toInt(), p.b.toInt());
            sumH += hsv[0];
            sumS += hsv[1];
            sumV += hsv[2];
            count++;
          }
        }

        if (count > 0) {
          grid.add(_CellHsv(
            h: sumH / count,
            s: sumS / count,
            v: sumV / count,
            // Weight center region 1.8x more than background edges
            weight: (row == 1 && col == 1) ? 1.8 : ((row == 1 || col == 1) ? 1.2 : 0.8),
          ));
        }
      }
    }
    return grid;
  }

  // 2. Discrete Cosine Transform (DCT) 64-bit pHash
  int _computeDctPHash(img.Image image) {
    final gray = img.grayscale(image);
    final resized = img.copyResize(gray, width: 32, height: 32);

    final List<List<double>> matrix = List.generate(
      32,
      (y) => List.generate(32, (x) => resized.getPixel(x, y).r.toDouble()),
    );

    // 2D DCT calculation for top 8x8 low-frequency components
    final List<List<double>> dct = List.generate(8, (_) => List.filled(8, 0.0));
    final double piFactor = pi / 32.0;

    for (int u = 0; u < 8; u++) {
      for (int v = 0; v < 8; v++) {
        double sum = 0.0;
        for (int x = 0; x < 32; x++) {
          for (int y = 0; y < 32; y++) {
            sum += matrix[y][x] * cos((2 * x + 1) * u * piFactor) * cos((2 * y + 1) * v * piFactor);
          }
        }
        final double cu = u == 0 ? 1.0 / sqrt(2.0) : 1.0;
        final double cv = v == 0 ? 1.0 / sqrt(2.0) : 1.0;
        dct[u][v] = 0.25 * cu * cv * sum;
      }
    }

    // Compute median of the 64 coefficients (excluding DC term [0,0])
    final List<double> values = [];
    for (int u = 0; u < 8; u++) {
      for (int v = 0; v < 8; v++) {
        if (u == 0 && v == 0) continue;
        values.add(dct[u][v]);
      }
    }
    values.sort();
    final double median = values[values.length ~/ 2];

    // Build 64-bit hash
    int hash = 0;
    int bit = 0;
    for (int u = 0; u < 8; u++) {
      for (int v = 0; v < 8; v++) {
        if (dct[u][v] > median) {
          hash |= (1 << bit);
        }
        bit++;
      }
    }
    return hash;
  }

  // 3. Sobel Edge & Texture Complexity Density
  double _computeTextureDensity(img.Image image) {
    final gray = img.grayscale(image);
    final small = img.copyResize(gray, width: 32, height: 32);

    double totalGradient = 0.0;
    int pixelCount = 0;

    for (int y = 1; y < 31; y++) {
      for (int x = 1; x < 31; x++) {
        // Horizontal Sobel
        final double gx = (-1.0 * small.getPixel(x - 1, y - 1).r) +
            (1.0 * small.getPixel(x + 1, y - 1).r) +
            (-2.0 * small.getPixel(x - 1, y).r) +
            (2.0 * small.getPixel(x + 1, y).r) +
            (-1.0 * small.getPixel(x - 1, y + 1).r) +
            (1.0 * small.getPixel(x + 1, y + 1).r);

        // Vertical Sobel
        final double gy = (-1.0 * small.getPixel(x - 1, y - 1).r) +
            (-2.0 * small.getPixel(x, y - 1).r) +
            (-1.0 * small.getPixel(x + 1, y - 1).r) +
            (1.0 * small.getPixel(x - 1, y + 1).r) +
            (2.0 * small.getPixel(x, y + 1).r) +
            (1.0 * small.getPixel(x + 1, y + 1).r);

        final double mag = sqrt((gx * gx) + (gy * gy));
        totalGradient += mag;
        pixelCount++;
      }
    }

    // Normalize texture complexity density (0.0 = plain fabric, 1.0 = heavy pattern/floral)
    final double avgGradient = pixelCount > 0 ? (totalGradient / pixelCount) : 0.0;
    return (avgGradient / 180.0).clamp(0.0, 1.0);
  }

  // Compute Full Multi-Feature Fingerprint
  _AdvancedImageFingerprint? _computeFingerprint(String base64OrDataUri) {
    if (_cache.containsKey(base64OrDataUri)) {
      return _cache[base64OrDataUri];
    }

    final decoded = _decodeImage(base64OrDataUri);
    if (decoded == null) return null;

    final spatialHsv = _extractSpatialHsvGrid(decoded);
    final pHash = _computeDctPHash(decoded);
    final textureDensity = _computeTextureDensity(decoded);

    final fp = _AdvancedImageFingerprint(
      spatialHsv: spatialHsv,
      pHash: pHash,
      textureDensity: textureDensity,
    );

    _cache[base64OrDataUri] = fp;
    return fp;
  }

  // Calculate High-Precision Similarity Score (0.0 to 1.0)
  double _calculateSimilarity(_AdvancedImageFingerprint fp1, _AdvancedImageFingerprint fp2) {
    // 1. Spatial HSV Color Similarity (45% Weight)
    double totalColorSim = 0.0;
    double totalWeight = 0.0;

    final minCells = min(fp1.spatialHsv.length, fp2.spatialHsv.length);
    for (int i = 0; i < minCells; i++) {
      final c1 = fp1.spatialHsv[i];
      final c2 = fp2.spatialHsv[i];

      // Circular Hue distance (0 to 180 deg)
      double hDiff = (c1.h - c2.h).abs();
      if (hDiff > 180.0) hDiff = 360.0 - hDiff;
      final double hScore = (1.0 - (hDiff / 180.0)).clamp(0.0, 1.0);

      // Saturation & Value distance
      final double sScore = (1.0 - (c1.s - c2.s).abs()).clamp(0.0, 1.0);
      final double vScore = (1.0 - (c1.v - c2.v).abs()).clamp(0.0, 1.0);

      // Perceptual color physics: When saturated, Hue is the primary determinant
      final double avgSat = (c1.s + c2.s) / 2.0;
      double cellSim;
      if (avgSat > 0.15) {
        // Vibrant color: Hue dominates (80% weight) with exponential penalty for hue divergence
        final double hNonLinear = pow(hScore, 2.5).toDouble();
        cellSim = (hNonLinear * 0.80) + (sScore * 0.10) + (vScore * 0.10);
      } else {
        // Monochromatic (black, white, gray): Value/Brightness dominates
        cellSim = (vScore * 0.70) + (sScore * 0.30);
      }

      final double w = (c1.weight + c2.weight) / 2.0;
      totalColorSim += cellSim * w;
      totalWeight += w;
    }
    final double colorScore = totalWeight > 0 ? (totalColorSim / totalWeight).clamp(0.0, 1.0) : 0.0;

    // 2. DCT pHash Structural Cut & Shape Match (30% Weight)
    int xor = fp1.pHash ^ fp2.pHash;
    int distance = 0;
    while (xor != 0) {
      distance += xor & 1;
      xor >>= 1;
    }
    final double pHashScore = ((64 - distance) / 64.0).clamp(0.0, 1.0);

    // 3. Texture & Pattern Density Similarity (25% Weight)
    final double textureDiff = (fp1.textureDensity - fp2.textureDensity).abs();
    final double textureScore = (1.0 - textureDiff).clamp(0.0, 1.0);

    // Color gate: If color tone is completely opposite (e.g. Red vs Blue), sharply penalize the overall score
    final double colorGate = colorScore < 0.5 ? pow(colorScore / 0.5, 1.5).toDouble() : 1.0;

    // Weighted High-Precision Composite Score
    final double composite = ((colorScore * 0.50) + (pHashScore * 0.25) + (textureScore * 0.25)) * colorGate;
    return composite.clamp(0.0, 1.0);
  }

  // Rank products by visual match
  List<VisualMatchResult> rankProducts(
    String queryBase64,
    List<ProductModel> products, {
    double minThreshold = 0.35,
  }) {
    final queryFp = _computeFingerprint(queryBase64);
    if (queryFp == null) return [];

    final List<VisualMatchResult> results = [];

    for (final product in products) {
      if (product.imageUrl == null || product.imageUrl!.trim().isEmpty) continue;

      final targetFp = _computeFingerprint(product.imageUrl!);
      if (targetFp == null) continue;

      final score = _calculateSimilarity(queryFp, targetFp);
      if (score >= minThreshold) {
        results.add(VisualMatchResult(product: product, score: score));
      }
    }

    // Sort descending by highest match percentage
    results.sort((a, b) => b.score.compareTo(a.score));
    return results;
  }
}

class _CellHsv {
  final double h;
  final double s;
  final double v;
  final double weight;

  _CellHsv({required this.h, required this.s, required this.v, required this.weight});
}

class _AdvancedImageFingerprint {
  final List<_CellHsv> spatialHsv;
  final int pHash;
  final double textureDensity;

  _AdvancedImageFingerprint({
    required this.spatialHsv,
    required this.pHash,
    required this.textureDensity,
  });
}
