import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/daily_notifier.dart';
import '../providers/reset_timer_provider.dart';
import '../widgets/daily_streak_widget.dart';
import '../../domain/entities/daily_mission.dart';
import '../../../game/infrastructure/services/audio_service.dart';
import '../../../auth/presentation/auth_notifier.dart';

/// Kullanıcının günlük görevlerini ve kalan süreyi şık bir tasarım ile gösteren ekran.
class DailyMissionsScreen extends ConsumerWidget {
  const DailyMissionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyState = ref.watch(dailyStateProvider);
    final resetTimeStr = ref.watch(resetTimerProvider).valueOrNull ?? '--:--:--';
    final uid = ref.watch(authProvider).user?.uid;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0C1B), // Çok koyu uzay mavisi/mor
              Color(0xFF151026),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Üst Bar: Geri Dönüş ve Başlık
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'GÜNLÜK MERKEZ',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Başlığı ortalamak için boşluk
                  ],
                ),
              ),

              Expanded(
                child: dailyState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.amber,
                        ),
                      )
                    : dailyState.errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: Colors.redAccent,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    dailyState.errorMessage!,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (uid != null && uid.isNotEmpty) {
                                        ref.read(dailyStateProvider.notifier).init(uid);
                                      }
                                    },
                                    icon: const Icon(Icons.refresh_rounded),
                                    label: const Text('Tekrar Dene'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.amber,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            color: Colors.amber,
                            backgroundColor: const Color(0xFF1E1E38),
                            onRefresh: () async {
                              if (uid != null && uid.isNotEmpty) {
                                await ref.read(dailyStateProvider.notifier).init(uid);
                              }
                            },
                            child: CustomScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                // 1. Giriş Serisi Widget'ı
                                const SliverToBoxAdapter(
                                  child: DailyStreakWidget(),
                                ),

                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 16),
                                ),

                                // 2. Kalan Süre Sayacı (Flat, constraint-safe Row yapısı)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.02),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white10),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.hourglass_bottom_rounded,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                            child: Text(
                                              'Yeni Görevler İçin Kalan Süre',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            resetTimeStr,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.amber,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w900,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 24),
                                ),

                                // 3. Günlük Görevler Başlığı
                                const SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 20),
                                    child: Text(
                                      'GÜNLÜK GÖREVLER',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ),
                                ),

                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 12),
                                ),

                                // 4. Görev Kartları Listesi
                                if (dailyState.missions.isEmpty)
                                  const SliverToBoxAdapter(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(32.0),
                                        child: Text(
                                          'Bugün için görev bulunmuyor.',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(color: Colors.white54),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final mission = dailyState.missions[index];
                                        return _MissionCard(mission: mission);
                                      },
                                      childCount: dailyState.missions.length,
                                    ),
                                  ),

                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 32),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Her bir görevi gösteren, kısıtlamaları güvenli hale getirilmiş, taşma korumalı premium görev kartı bileşeni.
class _MissionCard extends ConsumerWidget {
  final DailyMission mission;

  const _MissionCard({
    required this.mission,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Zorluk (Tier) bazlı renkler
    Color tierColor = Colors.green;
    String tierText = 'KOLAY';
    switch (mission.tier) {
      case MissionTier.easy:
        tierColor = Colors.greenAccent;
        tierText = 'KOLAY';
        break;
      case MissionTier.medium:
        tierColor = Colors.blueAccent;
        tierText = 'ORTA';
        break;
      case MissionTier.hard:
        tierColor = Colors.orangeAccent;
        tierText = 'ZOR';
        break;
      case MissionTier.legendary:
        tierColor = Colors.purpleAccent;
        tierText = 'EFSANEVİ';
        break;
    }

    final double progressPercent = mission.targetProgress > 0
        ? (mission.currentProgress / mission.targetProgress).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C192E), // Kart arka plan rengi
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: mission.isCompleted && !mission.isClaimed
              ? tierColor.withOpacity(0.5)
              : Colors.white.withOpacity(0.05),
          width: mission.isCompleted && !mission.isClaimed ? 1.5 : 1,
        ),
        boxShadow: mission.isCompleted && !mission.isClaimed
            ? [
                BoxShadow(
                  color: tierColor.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst Satır: Nadirlik Etiketi ve XP Ödülü
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tierColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      tierText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tierColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '+${mission.xpReward} XP',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Orta Kısım: Görev Başlığı ve Açıklaması
          Text(
            mission.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            mission.description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
          
          const SizedBox(height: 16),

          // Alt Satır: Progress Bar ve Buton (Constraint-safe, 110px sabit buton genişliği)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // İlerleme Barı ve Metni
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'İlerleme',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${mission.currentProgress}/${mission.targetProgress}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mission.isCompleted ? tierColor : Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          mission.isCompleted ? tierColor : Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // Eylem Butonu (Genişliği tam olarak 110px ile sınırlandırıldı)
              SizedBox(
                width: 110,
                child: _buildActionButton(ref, tierColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(WidgetRef ref, Color tierColor) {
    if (mission.isClaimed) {
      return Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check, color: Colors.greenAccent, size: 14),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                'ALINDI',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (mission.isCompleted) {
      return SizedBox(
        height: 38,
        child: ElevatedButton(
          onPressed: () {
            AudioService.playCorrect(); // Ses efekti
            ref.read(dailyStateProvider.notifier).claimMission(mission.id);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: tierColor,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: tierColor.withOpacity(0.3),
          ),
          child: const Text(
            'ÖDÜLÜ AL',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      );
    }

    // Görev devam ediyorsa buton pasif görünür
    return Container(
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: const Text(
        'DEVAM EDİYOR',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
