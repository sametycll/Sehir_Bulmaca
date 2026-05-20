import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/sources/city_data.dart';
import '../../infrastructure/data_sources/geojson_map_loader.dart';
import '../../infrastructure/data_sources/region_data.dart';
import '../providers/game_notifier.dart';
import '../../domain/entities/city_entity.dart';
import '../../../leaderboard/domain/entities/game_mode.dart';

// Harita Durumu İçin Riverpod Sağlayıcıları (Providers)
final mapDataProvider = FutureProvider<ParsedMapData>((ref) async {
  return GeoJsonMapLoader.loadAndParse();
});

final selectedProvinceProvider = StateProvider.autoDispose<int?>((ref) => null);

class TurkiyeMapWidget extends ConsumerStatefulWidget {
  const TurkiyeMapWidget({super.key});

  @override
  ConsumerState<TurkiyeMapWidget> createState() => _TurkiyeMapWidgetState();
}

class _TurkiyeMapWidgetState extends ConsumerState<TurkiyeMapWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapDataAsync = ref.watch(mapDataProvider);
    final gameState = ref.watch(gameProvider);
    final selectedPlate = ref.watch(selectedProvinceProvider);
    final gameMode = gameState.gameMode;

    final Set<int>? regionPlates = gameMode.isRegional
        ? RegionData.platesForMode(gameMode.id)
        : null;

    final foundCityPlates = gameState.foundCities.map((c) => c.plateCode).toSet();

    ref.listen<int>(gameProvider.select((s) => s.foundCities.length), (previous, next) {
      if (next > (previous ?? 0)) {
        _animationController.forward(from: 0.0);
      }
    });

    return mapDataAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SpinKitThreeBounce(
              color: AppColors.primary,
              size: 40.0,
            ),
            const SizedBox(height: 16),
            Text(
              'Türkiye Haritası Yükleniyor...',
              style: TextStyle(
                color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text(
              'Harita yüklenirken hata oluştu!',
              style: TextStyle(
                color: AppColors.error.withValues(alpha: 0.9),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
            ),
          ],
        ),
      ),
      data: (parsedData) {
        return LayoutBuilder(
          builder: (context, constraints) {
            // Bölge modunda sadece o bölgenin illerini filtrele
            final List<ProvinceMapData> visibleProvinces = regionPlates != null
                ? parsedData.provinces
                    .where((p) => regionPlates.contains(p.plateCode))
                    .toList()
                : parsedData.provinces;

            // Görünen illerin bounding box'ını hesapla (bölge auto-centering)
            final Rect activeBounds = _computeBounds(visibleProvinces) ??
                parsedData.boundingBox;

            final minX = activeBounds.left;
            final maxX = activeBounds.right;
            final minY = activeBounds.top;
            final maxY = activeBounds.bottom;

            final width = maxX - minX;
            final height = maxY - minY;
            final mapCenter = Offset(minX + width / 2, minY + height / 2);

            // Bölge modunda %10 padding bırakarak sığdır
            final double paddingFactor = regionPlates != null ? 0.85 : 1.0;
            final scaleX = constraints.maxWidth / width * paddingFactor;
            final scaleY = constraints.maxHeight / height * paddingFactor;
            final scale = math.min(scaleX, scaleY);

            // Odaklanma / Zoom hesaplamaları
            double focusAmount = 0.0;
            Offset focusPoint = mapCenter;

            if (_animationController.isAnimating && gameState.foundCities.isNotEmpty) {
              final lastFound = gameState.foundCities.last;
              focusAmount = math.sin(_animationController.value * math.pi) * 0.16;

              final lastProv = parsedData.provinces.firstWhere(
                (p) => p.plateCode == lastFound.plateCode,
                orElse: () => parsedData.provinces.first,
              );
              focusPoint = lastProv.bounds.center;
            } else if (selectedPlate != null) {
              focusAmount = 0.08;
              final selProv = parsedData.provinces.firstWhere(
                (p) => p.plateCode == selectedPlate,
                orElse: () => parsedData.provinces.first,
              );
              focusPoint = selProv.bounds.center;
            }

            final lerpedCenter = Offset.lerp(mapCenter, focusPoint, focusAmount)!;
            final lerpedScale = scale * (1.0 + focusAmount * 0.20);

            final double projectedCenterX = constraints.maxWidth / 2;
            final double projectedCenterY = constraints.maxHeight / 2;

            return Stack(
              children: [
                Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22.5),
                    child: GestureDetector(
                      onTapUp: (details) {
                        final localPoint = details.localPosition;

                        final double projectedX =
                            (localPoint.dx - projectedCenterX) / lerpedScale +
                                lerpedCenter.dx;
                        final double projectedY =
                            (localPoint.dy - projectedCenterY) / lerpedScale +
                                lerpedCenter.dy;
                        final Offset projectedPoint = Offset(projectedX, projectedY);

                        ProvinceMapData? tappedProvince;
                        for (final province in visibleProvinces) {
                          if (province.originalPath.contains(projectedPoint)) {
                            tappedProvince = province;
                            break;
                          }
                        }

                        if (tappedProvince != null) {
                          Feedback.forTap(context);
                          final int clickedPlate = tappedProvince.plateCode;
                          if (selectedPlate == clickedPlate) {
                            ref.read(selectedProvinceProvider.notifier).state = null;
                          } else {
                            ref.read(selectedProvinceProvider.notifier).state = clickedPlate;
                          }
                        } else {
                          ref.read(selectedProvinceProvider.notifier).state = null;
                        }
                      },
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return CustomPaint(
                              size: Size(constraints.maxWidth, constraints.maxHeight),
                              painter: MapPainter(
                                parsedData: parsedData,
                                visibleProvinces: visibleProvinces,
                                activeBounds: activeBounds,
                                foundCities: gameState.foundCities,
                                selectedCityId: selectedPlate,
                                animationValue: _animationController.value,
                                paddingFactor: paddingFactor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),

                // Üst Yardım Mesajı
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: selectedPlate == null ? 0.7 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        alignment: Alignment.center,
                        child: Text(
                          'Detayları görmek için şehirlere tıklayabilirsiniz.',
                          style: TextStyle(
                            color: AppColors.textSecondaryDark.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Cam Efektli Bilgi Kartı
                _buildFloatingCard(context, ref, selectedPlate, foundCityPlates, gameState),
              ],
            );
          },
        );
      },
    );
  }

  /// Verilen il listesinin genel sınır kutusunu hesaplar
  Rect? _computeBounds(List<ProvinceMapData> provinces) {
    if (provinces.isEmpty) return null;
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;
    for (final p in provinces) {
      if (p.bounds.left < minX) minX = p.bounds.left;
      if (p.bounds.right > maxX) maxX = p.bounds.right;
      if (p.bounds.top < minY) minY = p.bounds.top;
      if (p.bounds.bottom > maxY) maxY = p.bounds.bottom;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  Widget _buildFloatingCard(
    BuildContext context,
    WidgetRef ref,
    int? selectedPlate,
    Set<int> foundCityPlates,
    dynamic gameState,
  ) {
    if (selectedPlate == null) return const SizedBox.shrink();

    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final rawCity = CityRawData.cities.firstWhere(
      (c) => c['plateCode'] == selectedPlate,
      orElse: () => <String, dynamic>{},
    );
    final String cityName = rawCity['name'] as String? ?? 'Bilinmeyen Şehir';
    final String region = rawCity['region'] as String? ?? 'Belirtilmemiş Bölge';
    final bool isFound = foundCityPlates.contains(selectedPlate);

    return Positioned(
      bottom: isKeyboardOpen ? null : 16,
      top: isKeyboardOpen ? 8 : null,
      left: 16,
      right: 16,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: Container(
              width: math.min(380.0, MediaQuery.of(context).size.width - 32),
              padding: EdgeInsets.all(isKeyboardOpen ? 10 : 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isFound
                      ? const Color(0xFF10B981).withValues(alpha: 0.25)
                      : AppColors.primary.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isFound ? const Color(0xFF10B981) : AppColors.primary)
                        .withValues(alpha: 0.15),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isKeyboardOpen ? 8 : 10,
                              vertical: isKeyboardOpen ? 2 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: isFound
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: isFound
                                      ? const Color(0xFF10B981)
                                      : AppColors.primary,
                                  width: 1),
                            ),
                            child: Text(
                              selectedPlate.toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: isKeyboardOpen ? 13 : 16,
                                fontWeight: FontWeight.bold,
                                color: isFound
                                    ? const Color(0xFF10B981)
                                    : AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(width: isKeyboardOpen ? 8 : 12),
                          Text(
                            cityName,
                            style: TextStyle(
                              fontSize: isKeyboardOpen ? 15 : 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondaryDark,
                          size: isKeyboardOpen ? 18 : 20,
                        ),
                        onPressed: () {
                          ref.read(selectedProvinceProvider.notifier).state = null;
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: isKeyboardOpen ? 6 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BÖLGE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            region,
                            style: TextStyle(
                              fontSize: isKeyboardOpen ? 12 : 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'DURUM',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                              color: AppColors.textSecondaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                isFound
                                    ? Icons.check_circle_rounded
                                    : Icons.lock_outline_rounded,
                                color: isFound
                                    ? const Color(0xFF10B981)
                                    : AppColors.warning,
                                size: isKeyboardOpen ? 14 : 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isFound ? 'Bulundu' : 'Keşfedilmedi',
                                style: TextStyle(
                                  fontSize: isKeyboardOpen ? 12 : 14,
                                  fontWeight: FontWeight.bold,
                                  color: isFound
                                      ? const Color(0xFF10B981)
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isFound && !isKeyboardOpen) ...[
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    const SizedBox(height: 8),
                    Text(
                      'İpucu: Bu şehir $region bölgesinde yer alıyor. İsmini aşağıdaki kutucuğa yazarak bulabilirsiniz!',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryDark.withValues(alpha: 0.9),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// MapPainter — bölge farkında harita çizici
// ──────────────────────────────────────────────
class MapPainter extends CustomPainter {
  final ParsedMapData parsedData;
  final List<ProvinceMapData> visibleProvinces;
  final Rect activeBounds;
  final List<CityEntity> foundCities;
  final int? selectedCityId;
  final double animationValue;
  final double paddingFactor;

  MapPainter({
    required this.parsedData,
    required this.visibleProvinces,
    required this.activeBounds,
    required this.foundCities,
    required this.selectedCityId,
    required this.animationValue,
    this.paddingFactor = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (parsedData.provinces.isEmpty) return;

    final minX = activeBounds.left;
    final maxX = activeBounds.right;
    final minY = activeBounds.top;
    final maxY = activeBounds.bottom;

    final width = maxX - minX;
    final height = maxY - minY;
    final mapCenter = Offset(minX + width / 2, minY + height / 2);

    final scaleX = size.width / width * paddingFactor;
    final scaleY = size.height / height * paddingFactor;
    final scale = math.min(scaleX, scaleY);

    double focusAmount = 0.0;
    Offset focusPoint = mapCenter;

    if (animationValue > 0.0 && animationValue < 1.0 && foundCities.isNotEmpty) {
      focusAmount = math.sin(animationValue * math.pi) * 0.16;
      final lastFound = foundCities.last;
      final lastProv = parsedData.provinces.firstWhere(
        (p) => p.plateCode == lastFound.plateCode,
        orElse: () => parsedData.provinces.first,
      );
      focusPoint = lastProv.bounds.center;
    } else if (selectedCityId != null) {
      focusAmount = 0.08;
      final selProv = parsedData.provinces.firstWhere(
        (p) => p.plateCode == selectedCityId,
        orElse: () => parsedData.provinces.first,
      );
      focusPoint = selProv.bounds.center;
    }

    final lerpedCenter = Offset.lerp(mapCenter, focusPoint, focusAmount)!;
    final lerpedScale = scale * (1.0 + focusAmount * 0.20);

    // 1. Deniz arka planı
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final seaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4A7D9D),
          Color(0xFF1B2E47),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, seaPaint);

    // 2. Gölge — sadece görünen iller için
    final shadowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2 + 4.0);
    canvas.scale(lerpedScale);
    canvas.translate(-lerpedCenter.dx, -lerpedCenter.dy);

    // Sadece görünen iller için birleşik gölge yolu
    final visibleShadowPath = Path();
    for (final p in visibleProvinces) {
      visibleShadowPath.addPath(p.originalPath, Offset.zero);
    }
    canvas.drawPath(visibleShadowPath, shadowPaint);
    canvas.restore();

    // Boya fırçaları
    final unfoundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF7F8C8D);

    final foundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF10B981);

    // Bölge modunda gizli iller için soluk renk
    final hiddenPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF2A3340); // Çok koyu, neredeyse arka planla aynı

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 0.8 / lerpedScale;

    final hiddenBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 0.4 / lerpedScale;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(lerpedScale);
    canvas.translate(-lerpedCenter.dx, -lerpedCenter.dy);

    final foundCityIds = foundCities.map((c) => c.plateCode).toSet();
    final int? lastFoundPlate = foundCities.isNotEmpty ? foundCities.last.plateCode : null;
    final visiblePlateCodes = visibleProvinces.map((p) => p.plateCode).toSet();

    // 3. Tüm illeri çiz (görünenler renkli, gizlenler karanlık)
    for (final province in parsedData.provinces) {
      final int plate = province.plateCode;
      if (selectedCityId == plate) continue;

      final bool isVisible = visiblePlateCodes.contains(plate);

      if (!isVisible) {
        // Bölge modunda diğer iller çok soluk çizilir
        canvas.drawPath(province.originalPath, hiddenPaint);
        canvas.drawPath(province.originalPath, hiddenBorderPaint);
        continue;
      }

      final bool isFound = foundCityIds.contains(plate);

      if (isFound) {
        if (lastFoundPlate == plate && animationValue > 0.0 && animationValue < 1.0) {
          final scaleFactor = 1.0 + 0.08 * math.sin(animationValue * math.pi);
          final color = Color.lerp(
            const Color(0xFF7F8C8D),
            const Color(0xFF10B981),
            animationValue,
          )!;
          final glowPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = const Color(0xFF10B981).withValues(alpha: 0.45 * (1.0 - animationValue));

          canvas.save();
          final center = province.bounds.center;
          canvas.translate(center.dx, center.dy);
          canvas.scale(scaleFactor);
          canvas.translate(-center.dx, -center.dy);

          canvas.drawPath(province.originalPath, glowPaint);
          final animFoundPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = color;
          canvas.drawPath(province.originalPath, animFoundPaint);
          canvas.drawPath(province.originalPath, borderPaint);
          canvas.restore();
        } else {
          canvas.drawPath(province.originalPath, foundPaint);
          canvas.drawPath(province.originalPath, borderPaint);
        }
      } else {
        canvas.drawPath(province.originalPath, unfoundPaint);
        canvas.drawPath(province.originalPath, borderPaint);
      }
    }

    // 4. Seçili ili en üstte neon sınırla çiz
    if (selectedCityId != null) {
      final selectedProv = parsedData.provinces.firstWhere(
        (p) => p.plateCode == selectedCityId,
        orElse: () => parsedData.provinces.first,
      );
      final bool isFound = foundCityIds.contains(selectedCityId);

      final selectedGlowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.neonBlue.withValues(alpha: 0.5)
        ..strokeWidth = 5.0 / lerpedScale
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      final selectedBorderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = AppColors.neonBlue
        ..strokeWidth = 2.0 / lerpedScale;

      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = isFound
            ? const Color(0xFF10B981).withValues(alpha: 0.9)
            : AppColors.primary.withValues(alpha: 0.65);

      canvas.drawPath(selectedProv.originalPath, fillPaint);
      canvas.drawPath(selectedProv.originalPath, selectedGlowPaint);
      canvas.drawPath(selectedProv.originalPath, selectedBorderPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.foundCities.length != foundCities.length ||
        oldDelegate.selectedCityId != selectedCityId ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.parsedData != parsedData ||
        oldDelegate.visibleProvinces.length != visibleProvinces.length ||
        oldDelegate.activeBounds != activeBounds;
  }
}
