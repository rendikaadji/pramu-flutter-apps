import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'app_button.dart';

class OnboardingPage {
  const OnboardingPage({
    required this.illustration,
    required this.title,
    required this.body,
  });

  /// Biasanya salah satu widget di `illustrations/illustrations.dart`.
  final Widget illustration;
  final String title;
  final String body;
}

/// Carousel onboarding 2-3 slide: ilustrasi, judul, isi, indikator titik, tombol
/// Lanjut (slide terakhir: `finishLabel`) dan tautan Lewati. Mengisi tinggi yang
/// tersedia; konten tiap slide menggulir bila skala teks besar.
class OnboardingPager extends StatefulWidget {
  const OnboardingPager({
    super.key,
    required this.pages,
    required this.onFinish,
    this.onSkip,
    this.nextLabel = 'Lanjut',
    this.finishLabel = 'Mulai',
    this.skipLabel = 'Lewati',
  });

  final List<OnboardingPage> pages;
  final VoidCallback onFinish;

  /// Default = `onFinish`.
  final VoidCallback? onSkip;
  final String nextLabel, finishLabel, skipLabel;

  @override
  State<OnboardingPager> createState() => _OnboardingPagerState();
}

class _OnboardingPagerState extends State<OnboardingPager> {
  final _controller = PageController();
  int _index = 0;

  bool get _last => _index == widget.pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) return widget.onFinish();
    _controller.nextPage(
      duration: context.motion(AppMotion.base),
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Opacity(
            opacity: _last ? 0 : 1,
            child: TextButton(
              onPressed: _last ? null : (widget.onSkip ?? widget.onFinish),
              child: Text(widget.skipLabel),
            ),
          ),
        ),
        Expanded(
          child: PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            children: [
              for (final p in widget.pages)
                LayoutBuilder(
                  builder: (context, c) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: c.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          p.illustration,
                          const SizedBox(height: AppSpace.s24),
                          Semantics(
                            header: true,
                            child: Text(
                              p.title,
                              style: context.text.h1,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: AppSpace.s12),
                          Text(
                            p.body,
                            style: context.text.body.copyWith(
                              color: t.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.s16),
        Semantics(
          label: 'Halaman ${_index + 1} dari ${widget.pages.length}',
          child: ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < widget.pages.length; i++)
                  AnimatedContainer(
                    duration: context.motion(AppMotion.base),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? t.primary
                          : t.borderStrong.withValues(alpha: .4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.s24),
        AppButton(
          label: _last ? widget.finishLabel : widget.nextLabel,
          large: true,
          onPressed: _next,
        ),
      ],
    );
  }
}
