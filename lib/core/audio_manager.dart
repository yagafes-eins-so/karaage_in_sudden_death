import 'package:flame_audio/flame_audio.dart';

/// BGM/SEの再生を一元管理するシングルトン。
/// 各コンポーネント/ViewModelはこのクラス経由でのみ音を鳴らし、
/// flame_audio への直接依存を持たないようにする(差し替え容易性のため)。
class AudioManager {
  AudioManager._internal();
  static final AudioManager instance = AudioManager._internal();

  bool _muted = false;
  bool get muted => _muted;

  static const _bgm = 'bunkasai_ingame_loop_20s.mp3';
  static const _sfxClick = 'sfx_click.mp3';
  static const _sfxCharge = 'sfx_charge.mp3';
  static const _sfxThrow = 'sfx_throw.mp3';
  static const _sfxSuccess = 'sfx_success.mp3';
  static const _sfxMiss = 'sfx_miss.mp3';
  static const _sfxPerfect = 'sfx_perfect.mp3';

  bool _assetsAvailable = false;

  Future<void> preload() async {
    // 重要: アセット未配置(開発初期)でもゲーム初期化を止めないよう、
    // 1ファイルずつ読み込み、失敗しても例外を外に投げない。
    // loadAll() は途中の1ファイルが無いだけで残り全てを巻き込んで失敗するため使わない。
    FlameAudio.audioCache.prefix = 'assets/audio/';

    final files = [
      _bgm,
      _sfxClick,
      _sfxCharge,
      _sfxThrow,
      _sfxSuccess,
      _sfxMiss,
      _sfxPerfect,
    ];
    var successCount = 0;
    for (final file in files) {
      final loaded = await FlameAudio.audioCache.load(file).then((_) => true).catchError((_) => false);
      if (loaded) {
        successCount++;
      }
    }
    _assetsAvailable = successCount == files.length;
  }

  void playBgm() {
    if (_muted || !_assetsAvailable) return;
    () async {
      try {
        await FlameAudio.bgm.play(_bgm, volume: 0.5);
        // 前回セッションで上げた再生速度が残らないよう、再生開始時に必ず等倍へ戻す。
        await FlameAudio.bgm.audioPlayer.setPlaybackRate(1.0);
      } catch (_) {}
    }();
  }

  void stopBgm() => FlameAudio.bgm.stop();

  /// 紙コップの速度上昇(サドンデスの倍率)に合わせてBGMの再生速度を変える。
  /// [rate] は1.0が等倍。
  void setBgmSpeed(double rate) {
    if (!_assetsAvailable) return;
    () async {
      try {
        await FlameAudio.bgm.audioPlayer.setPlaybackRate(rate);
      } catch (_) {}
    }();
  }

  void playClick() => _play(_sfxClick);
  void playCharge() => _play(_sfxCharge);
  void playThrow() => _play(_sfxThrow);
  void playSuccess() => _play(_sfxSuccess);
  void playMiss() => _play(_sfxMiss);
  void playPerfect() => _play(_sfxPerfect);

  void toggleMute() {
    _muted = !_muted;
    if (_muted) {
      FlameAudio.bgm.pause();
    } else {
      FlameAudio.bgm.resume();
    }
  }

  void _play(String file) {
    if (_muted || !_assetsAvailable) return;
    () async {
      try {
        await FlameAudio.play(file, volume: 0.8);
      } catch (_) {}
    }();
  }
}
