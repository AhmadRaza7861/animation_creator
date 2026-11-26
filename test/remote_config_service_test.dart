import 'package:dummy/core/services/remote_config_service.dart';
import 'package:dummy/services/addHelper/ad_maniget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    RemoteConfigService.instance.resetTestValues();
    AdManager.resetApplyBrushClickCount();
  });

  group('RemoteConfigService open app ad gating', () {
    test('uses exact Firebase Remote Config parameter keys', () {
      expect(RemoteConfigService.keyIsShowAds, 'Is_show_ads');
      expect(RemoteConfigService.keyIsShowOpenAppAd, 'is_show_open_app_ad');
      expect(RemoteConfigService.keyIsShowTutorialAd, 'is_show_tutorial_ad');
      expect(
        RemoteConfigService.keyIsShowCreateProjectBtn,
        'is_show_create_project_btn',
      );
      expect(RemoteConfigService.keyIsShowHistoryAd, 'is_show_history_ad');
      expect(RemoteConfigService.keyIsShowExportAd, 'is_show_export_ad');
      expect(RemoteConfigService.keyProjectSttingAd, 'project_stting_ad');
      expect(RemoteConfigService.keyIsShowAdOnImport, 'is_show_ad_on_import');
      expect(
        RemoteConfigService.keyIsShowAplyBrushAd,
        'is_show_aply_brush_ad',
      );
    });

    test('shouldShowOpenAppAd is true only when both flags are true', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowOpenAppAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowOpenAppAd, isTrue);
    });

    test('shouldShowOpenAppAd is false when Is_show_ads is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowOpenAppAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowOpenAppAd, isFalse);
    });

    test('shouldShowOpenAppAd is false when is_show_open_app_ad is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowOpenAppAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowOpenAppAd, isFalse);
    });

    test('shouldShowOpenAppAd is false when both flags are false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowOpenAppAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowOpenAppAd, isFalse);
    });
  });

  group('RemoteConfigService tutorial ad gating', () {
    test('shouldShowTutorialAd is true only when both flags are true', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowTutorialAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowTutorialAd, isTrue);
    });

    test('shouldShowTutorialAd is false when Is_show_ads is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowTutorialAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowTutorialAd, isFalse);
    });

    test('shouldShowTutorialAd is false when is_show_tutorial_ad is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowTutorialAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowTutorialAd, isFalse);
    });

    test('shouldShowTutorialAd is false when both flags are false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowTutorialAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowTutorialAd, isFalse);
    });
  });

  group('RemoteConfigService create project button ad gating', () {
    test('shouldShowCreateProjectBtnAd is true only when both flags are true', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowCreateProjectBtn: true,
      );
      expect(RemoteConfigService.instance.shouldShowCreateProjectBtnAd, isTrue);
    });

    test('shouldShowCreateProjectBtnAd is false when Is_show_ads is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowCreateProjectBtn: true,
      );
      expect(
        RemoteConfigService.instance.shouldShowCreateProjectBtnAd,
        isFalse,
      );
    });

    test(
      'shouldShowCreateProjectBtnAd is false when is_show_create_project_btn is false',
      () {
        RemoteConfigService.instance.setTestValues(
          isShowAds: true,
          isShowCreateProjectBtn: false,
        );
        expect(
          RemoteConfigService.instance.shouldShowCreateProjectBtnAd,
          isFalse,
        );
      },
    );

    test('shouldShowCreateProjectBtnAd is false when both flags are false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowCreateProjectBtn: false,
      );
      expect(
        RemoteConfigService.instance.shouldShowCreateProjectBtnAd,
        isFalse,
      );
    });
  });

  group('RemoteConfigService history ad gating', () {
    test('shouldShowHistoryAd is true only when both flags are true', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowHistoryAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowHistoryAd, isTrue);
    });

    test('shouldShowHistoryAd is false when Is_show_ads is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowHistoryAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowHistoryAd, isFalse);
    });

    test('shouldShowHistoryAd is false when is_show_history_ad is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowHistoryAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowHistoryAd, isFalse);
    });

    test('shouldShowHistoryAd is false when both flags are false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowHistoryAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowHistoryAd, isFalse);
    });
  });

  group('RemoteConfigService export ad gating', () {
    test('shouldShowExportAd is true only when both flags are true', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowExportAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowExportAd, isTrue);
    });

    test('shouldShowExportAd is false when Is_show_ads is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowExportAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowExportAd, isFalse);
    });

    test('shouldShowExportAd is false when is_show_export_ad is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowExportAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowExportAd, isFalse);
    });

    test('shouldShowExportAd is false when both flags are false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowExportAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowExportAd, isFalse);
    });
  });

  group('RemoteConfigService project settings ad gating', () {
    test('shouldShowProjectSettingAd is true only when both flags are true', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        projectSttingAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowProjectSettingAd, isTrue);
    });

    test('shouldShowProjectSettingAd is false when Is_show_ads is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        projectSttingAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowProjectSettingAd, isFalse);
    });

    test(
      'shouldShowProjectSettingAd is false when project_stting_ad is false',
      () {
        RemoteConfigService.instance.setTestValues(
          isShowAds: true,
          projectSttingAd: false,
        );
        expect(
          RemoteConfigService.instance.shouldShowProjectSettingAd,
          isFalse,
        );
      },
    );

    test('shouldShowProjectSettingAd is false when both flags are false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        projectSttingAd: false,
      );
      expect(RemoteConfigService.instance.shouldShowProjectSettingAd, isFalse);
    });
  });

  group('RemoteConfigService import ad gating', () {
    test('shouldShowAdOnImport is true only when both flags are true', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowAdOnImport: true,
      );
      expect(RemoteConfigService.instance.shouldShowAdOnImport, isTrue);
    });

    test('shouldShowAdOnImport is false when Is_show_ads is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowAdOnImport: true,
      );
      expect(RemoteConfigService.instance.shouldShowAdOnImport, isFalse);
    });

    test('shouldShowAdOnImport is false when is_show_ad_on_import is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowAdOnImport: false,
      );
      expect(RemoteConfigService.instance.shouldShowAdOnImport, isFalse);
    });

    test('shouldShowAdOnImport is false when both flags are false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowAdOnImport: false,
      );
      expect(RemoteConfigService.instance.shouldShowAdOnImport, isFalse);
    });
  });

  group('RemoteConfigService apply brush ad gating and 4th-click cadence', () {
    test('shouldShowApplyBrushAd is true only when both flags are true', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowAplyBrushAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowApplyBrushAd, isTrue);
    });

    test('shouldShowApplyBrushAd is false when Is_show_ads is false', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isShowAplyBrushAd: true,
      );
      expect(RemoteConfigService.instance.shouldShowApplyBrushAd, isFalse);
    });

    test(
      'shouldShowApplyBrushAd is false when is_show_aply_brush_ad is false',
      () {
        RemoteConfigService.instance.setTestValues(
          isShowAds: true,
          isShowAplyBrushAd: false,
        );
        expect(RemoteConfigService.instance.shouldShowApplyBrushAd, isFalse);
      },
    );

    test('shows on every 4th click (1-3 skip, 4th show, 5-7 skip, 8th show)', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowAplyBrushAd: true,
      );

      expect(AdManager.shouldShowApplyBrushAdOnClick(), isFalse); // 1st
      expect(AdManager.shouldShowApplyBrushAdOnClick(), isFalse); // 2nd
      expect(AdManager.shouldShowApplyBrushAdOnClick(), isFalse); // 3rd
      expect(AdManager.shouldShowApplyBrushAdOnClick(), isTrue);  // 4th
      expect(AdManager.shouldShowApplyBrushAdOnClick(), isFalse); // 5th
      expect(AdManager.shouldShowApplyBrushAdOnClick(), isFalse); // 6th
      expect(AdManager.shouldShowApplyBrushAdOnClick(), isFalse); // 7th
      expect(AdManager.shouldShowApplyBrushAdOnClick(), isTrue);  // 8th
    });

    test('never shows or advances when disabled', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowAplyBrushAd: false,
      );
      for (int i = 0; i < 8; i++) {
        expect(AdManager.shouldShowApplyBrushAdOnClick(), isFalse);
      }
    });
  });

  group('is_russian (Yandex vs AdMob)', () {
    test('uses the exact Firebase parameter name', () {
      expect(RemoteConfigService.keyIsRussian, 'is_russian');
    });

    test('defaults to false (AdMob) when Remote Config is unavailable', () {
      expect(RemoteConfigService.instance.isRussian, isFalse);
    });

    test('can be switched on', () {
      RemoteConfigService.instance.setTestValues(isRussian: true);
      expect(RemoteConfigService.instance.isRussian, isTrue);
    });

    test('Is_show_ads=false still blocks ads for Russian users', () {
      RemoteConfigService.instance.setTestValues(
        isShowAds: false,
        isRussian: true,
      );
      bool continued = false;
      AdManager.showInterstitialAd(onAdDismissed: () => continued = true);
      expect(continued, isTrue, reason: 'app must continue without an ad');
    });

    test('is_show_open_app_ad=false skips the Yandex open ad too', () async {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowOpenAppAd: false,
        isRussian: true,
      );
      bool continued = false;
      AdManager.loadOpenAppAd(onAdDismissed: () => continued = true);
      await Future<void>.delayed(Duration.zero);
      expect(continued, isTrue);
    });

    test('per-screen flag off skips the interstitial for Russian users', () async {
      RemoteConfigService.instance.setTestValues(
        isShowAds: true,
        isShowExportAd: false,
        isRussian: true,
      );
      await AdManager.showExportInterstitialIfEnabled(); // completes, no ad
    });
  });
}
