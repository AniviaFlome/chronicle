// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Chronicle';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get close => 'Kapat';

  @override
  String get ok => 'Tamam';

  @override
  String get copy => 'Kopyala';

  @override
  String get errorAddSlot => 'Ders saati eklenemedi';

  @override
  String get errorUpdateSlot => 'Ders saati güncellenemedi';

  @override
  String get errorSaveClass => 'Ders kaydedilemedi';

  @override
  String get errorDeleteClass => 'Ders silinemedi';

  @override
  String get errorDeleteSlot => 'Ders saati silinemedi';

  @override
  String get navToday => 'Bugün';

  @override
  String get navCalendar => 'Takvim';

  @override
  String get navClasses => 'Dersler';

  @override
  String get navTasks => 'Görevler';

  @override
  String get navAbsences => 'Devamsızlık';

  @override
  String get navMenu => 'Menü';

  @override
  String get navSettings => 'Ayarlar';

  @override
  String get campusLabel => 'Yerleşke';

  @override
  String get mealBreakfast => 'Kahvaltı';

  @override
  String get mealLunch => 'Öğle';

  @override
  String get mealDinner => 'Akşam';

  @override
  String get mealVegan => 'Vegan';

  @override
  String menuKcal(Object n) {
    return '$n kcal';
  }

  @override
  String get menuEmpty => 'Bu gün için yayımlanmış menü yok';

  @override
  String get menuStale => 'Önbellekteki menü · yenilemek için çekin';

  @override
  String get menuError => 'Menü yüklenemedi';

  @override
  String get menuRetry => 'Tekrar dene';

  @override
  String get menuChooseSource => 'Ayarlar\'dan bir menü kaynağı seçin';

  @override
  String get menuSourceTitle => 'Yemek menüsü';

  @override
  String get menuSourceLabel => 'Menü kaynağı';

  @override
  String get menuSourceNone => 'Yok';

  @override
  String get allergensTitle => 'Alerjenler';

  @override
  String get classFallback => 'Ders';

  @override
  String get absentBadge => 'Devamsız';

  @override
  String couldNotLoadYears(Object error) {
    return 'Yıllar yüklenemedi: $error';
  }

  @override
  String get allYears => 'Tüm yıllar';

  @override
  String get noYearOption => 'Yıl yok';

  @override
  String get addAcademicYear => 'Akademik yıl ekle';

  @override
  String get editYear => 'Yılı düzenle';

  @override
  String get nameLabel => 'Ad';

  @override
  String get startsLabel => 'Başlangıç';

  @override
  String get endsLabel => 'Bitiş';

  @override
  String get dayRotationLabel => 'Gün rotasyonu';

  @override
  String get dayRotationHint => 'Dönen gün etiketleri (örn. Gün 1-6)';

  @override
  String get offLabel => 'Kapalı';

  @override
  String daysCount(Object n) {
    return '$n gün';
  }

  @override
  String get pickStartEnd => 'Başlangıç ve bitiş tarihi seçin';

  @override
  String get endBeforeStart => 'Bitiş tarihi başlangıçtan önce olamaz';

  @override
  String couldNotSaveYear(Object error) {
    return 'Yıl kaydedilemedi: $error';
  }

  @override
  String get pickPlaceholder => 'Seç';

  @override
  String get noYearsYet => 'Henüz akademik yıl yok.';

  @override
  String get filteringAllYears => 'Filtre: tüm yıllar';

  @override
  String get filteringOneYear => 'Filtre: tek yıl';

  @override
  String get yearActions => 'Yıl işlemleri';

  @override
  String get editAction => 'Düzenle';

  @override
  String get deleteYearTitle => 'Yıl silinsin mi?';

  @override
  String deleteYearBody(Object name) {
    return '\"$name\" silinsin mi? Dersler yıl olmadan çalışmaya devam eder.';
  }

  @override
  String couldNotDelete(Object error) {
    return 'Silinemedi: $error';
  }

  @override
  String todayWithDate(Object date) {
    return 'Bugün · $date';
  }

  @override
  String couldNotLoadTasks(Object error) {
    return 'Görevler yüklenemedi: $error';
  }

  @override
  String couldNotLoadSchedule(Object error) {
    return 'Program yüklenemedi: $error';
  }

  @override
  String get nothingDueWeek => 'Önümüzdeki 7 günde vadesi gelen yok.';

  @override
  String get absenceWarnings => 'Devamsızlık uyarıları';

  @override
  String get todaysClasses => 'Bugünkü dersler';

  @override
  String get noClassesToday => 'Bugün ders yok.';

  @override
  String get tomorrowSection => 'Yarın';

  @override
  String get noClassesTomorrow => 'Yarın ders yok.';

  @override
  String get upcomingSection => 'Yaklaşanlar';

  @override
  String quotaOver(Object unexcused, Object limit) {
    return '$unexcused mazeretsiz devamsızlık — $limit sınırının üzerinde';
  }

  @override
  String quotaOneLeft(Object unexcused, Object limit) {
    return '$unexcused mazeretsiz devamsızlık — $limit sınırına bir kaldı';
  }

  @override
  String get examLabel => 'Sınav';

  @override
  String get overduePrefix => 'Gecikmiş · ';

  @override
  String dueOn(Object date) {
    return 'Vade $date';
  }

  @override
  String get dayStreak => 'günlük seri';

  @override
  String get doneThisWeek => 'bu hafta tamamlanan';

  @override
  String get focusedThisWeek => 'bu hafta odaklanılan';

  @override
  String get classesTitle => 'Dersler';

  @override
  String get addClass => 'Ders ekle';

  @override
  String couldNotLoadClasses(Object error) {
    return 'Dersler yüklenemedi: $error';
  }

  @override
  String get showingYear => 'Gösterilen yıl';

  @override
  String absenceLimit(Object limit) {
    return 'Devamsızlık sınırı: $limit';
  }

  @override
  String get noClassesYet => 'Henüz ders yok';

  @override
  String get addFirstClass => 'Programını oluşturmak için ilk dersini ekle.';

  @override
  String get tasksTitle => 'Görevler';

  @override
  String get gradesTooltip => 'Notlar';

  @override
  String get focusTooltip => 'Odaklan zamanlayıcısı';

  @override
  String get addTask => 'Görev ekle';

  @override
  String get allFilter => 'Tümü';

  @override
  String get typeHomework => 'Ödev';

  @override
  String get typeEssay => 'Kompozisyon';

  @override
  String get typeProject => 'Grup projesi';

  @override
  String get typeReading => 'Okuma';

  @override
  String get typeRevision => 'Tekrar';

  @override
  String get typeReminder => 'Hatırlatıcı';

  @override
  String get hideDone => 'Bitenleri gizle';

  @override
  String get examCountdown => 'Sınav geri sayımı';

  @override
  String get sectionOverdue => 'Gecikmiş';

  @override
  String get sectionUpcoming => 'Yaklaşan';

  @override
  String get sectionNoDate => 'Vadesiz';

  @override
  String get sectionDone => 'Biten';

  @override
  String get noDateLabel => 'Vade yok';

  @override
  String daysOverdue(Object n) {
    return '${n}g gecikmiş';
  }

  @override
  String get tomorrowWord => 'Yarın';

  @override
  String inDays(Object n) {
    return '$n gün içinde';
  }

  @override
  String get noTasksHere => 'Burada görev yok';

  @override
  String get addTasksHint =>
      'Takip etmek için ödev, sınav ve hatırlatıcı ekle.';

  @override
  String dueOnTime(Object date, Object time) {
    return 'Vade $date$time';
  }

  @override
  String stepsCount(Object done, Object total) {
    return '$done/$total adım';
  }

  @override
  String get repeatsLabel => 'Tekrarlar';

  @override
  String get remindDueTime => 'Vade zamanı';

  @override
  String remindMins(Object n) {
    return '$n dk önce';
  }

  @override
  String remindHours(num n) {
    return '$n saat önce';
  }

  @override
  String remindDays(num n) {
    return '$n gün önce';
  }

  @override
  String remindWeeks(num n) {
    return '$n hafta önce';
  }

  @override
  String get repeatNever => 'Asla';

  @override
  String get repeatDaily => 'Günlük';

  @override
  String get repeatWeekly => 'Haftalık';

  @override
  String get repeatMonthly => 'Aylık';

  @override
  String get priorityLow => 'Düşük';

  @override
  String get priorityNormal => 'Normal';

  @override
  String get priorityHigh => 'Yüksek';

  @override
  String get remindersNeedDue =>
      'Hatırlatıcılar için vade tarihi gerekli — bir tarih seç ya da kaldır';

  @override
  String get deleteTaskTitle => 'Görev silinsin mi?';

  @override
  String deleteTaskBody(Object title) {
    return '\"$title\" alt görevleri ve hatırlatıcılarıyla silinsin mi?';
  }

  @override
  String get deleteTaskTooltip => 'Görevi sil';

  @override
  String get editTask => 'Görevi düzenle';

  @override
  String get titleLabel => 'Başlık';

  @override
  String get titleRequired => 'Başlık gerekli';

  @override
  String get typeLabel => 'Tür';

  @override
  String get priorityLabel => 'Öncelik';

  @override
  String get classLabel => 'Ders';

  @override
  String get noClass => 'Ders yok';

  @override
  String get dueDateLabel => 'Vade tarihi';

  @override
  String get dueTimeLabel => 'Vade saati';

  @override
  String get notSet => 'Ayarlanmadı';

  @override
  String get allDay => 'Tüm gün';

  @override
  String get notesLabel => 'Notlar';

  @override
  String get trackProgress => 'İlerlemeyi % ile takip et';

  @override
  String get trackProgressHint =>
      'Sadece bitirme yerine kısmi ilerlemeyi kaydet';

  @override
  String get resultSection => 'Sonuç';

  @override
  String get stepsSection => 'Adımlar';

  @override
  String get remindersSection => 'Hatırlatıcılar';

  @override
  String get saveTask => 'Görevi kaydet';

  @override
  String couldNotSaveTask(Object error) {
    return 'Görev kaydedilemedi: $error';
  }

  @override
  String get newStep => 'Yeni adım';

  @override
  String get addStep => 'Adım ekle';

  @override
  String couldNotLoadSteps(Object error) {
    return 'Adımlar yüklenemedi: $error';
  }

  @override
  String couldNotLoadReminders(Object error) {
    return 'Hatırlatıcılar yüklenemedi: $error';
  }

  @override
  String couldNotLoadExams(Object error) {
    return 'Sınavlar yüklenemedi: $error';
  }

  @override
  String get preparesForExam => 'Hazırlandığı sınav';

  @override
  String get noExam => 'Sınav yok';

  @override
  String get noRemindersHint =>
      'Hatırlatıcı yok. Çalışması için vade tarihi gerekli.';

  @override
  String get enterValidScore => 'Geçerli bir puan ve üst sınır girin';

  @override
  String couldNotSaveGrade(Object error) {
    return 'Not kaydedilemedi: $error';
  }

  @override
  String couldNotLoadGrade(Object error) {
    return 'Not yüklenemedi: $error';
  }

  @override
  String get scoreLabel => 'Puan';

  @override
  String get outOfLabel => 'Üzerinden';

  @override
  String get deleteGradeTooltip => 'Notu sil';

  @override
  String resultScore(Object score, Object max) {
    return 'Sonuç: $score / $max';
  }

  @override
  String get listViewTooltip => 'Liste görünümü';

  @override
  String get gridViewTooltip => 'Haftalık ızgara görünümü';

  @override
  String couldNotLoad(Object error) {
    return 'Yüklenemedi: $error';
  }

  @override
  String get quotasTitle => 'Kotalar';

  @override
  String get noAbsencesRecorded => 'Kayıtlı devamsızlık yok.';

  @override
  String get excusedBadge => 'Mazeretli';

  @override
  String get unexcusedBadge => 'Mazeretsiz';

  @override
  String get allClasses => 'Tüm dersler';

  @override
  String get noClassesToShow => 'Gösterilecek ders yok.';

  @override
  String get weekPrefix => 'H';

  @override
  String quotaCount(Object unexcused, Object limit) {
    return '$unexcused / $limit mazeretsiz';
  }

  @override
  String get deleteAbsenceTooltip => 'Devamsızlık kaydını sil';

  @override
  String get timeGridTooltip => 'Zaman ızgarası görünümü';

  @override
  String get addEvent => 'Etkinlik ekle';

  @override
  String get prevWeek => 'Önceki hafta';

  @override
  String get nextWeek => 'Sonraki hafta';

  @override
  String get prevDay => 'Önceki gün';

  @override
  String get nextDay => 'Sonraki gün';

  @override
  String couldNotLoadWeek(Object error) {
    return 'Hafta yüklenemedi: $error';
  }

  @override
  String couldNotLoadEvents(Object error) {
    return 'Etkinlikler yüklenemedi: $error';
  }

  @override
  String couldNotMoveClass(Object error) {
    return 'Ders taşınamadı: $error';
  }

  @override
  String couldNotMoveEvent(Object error) {
    return 'Etkinlik taşınamadı: $error';
  }

  @override
  String adjustTitle(Object title) {
    return '$title ayarla';
  }

  @override
  String get gradesTitle => 'Notlar';

  @override
  String couldNotLoadGrades(Object error) {
    return 'Notlar yüklenemedi: $error';
  }

  @override
  String get noGradesYet => 'Henüz not yok';

  @override
  String get recordExamsHint => 'GNO takibi için sınav sonuçlarını kaydet.';

  @override
  String gpaSummary(num n) {
    return 'GNO · $n notlu sınav';
  }

  @override
  String examsAverage(num n, Object avg) {
    return '$n sınav · %$avg ortalama';
  }

  @override
  String get focusTitle => 'Odaklan';

  @override
  String get focusWorkLabel => 'Çalışma süresi';

  @override
  String get focusBreakLabel => 'Mola süresi';

  @override
  String get customMinutesLabel => 'Özel dakika';

  @override
  String minutesShort(Object n) {
    return '$n dk';
  }

  @override
  String get lockPortraitTitle => 'Dikey kilit';

  @override
  String get lockPortraitHint => 'Uygulamayı telefonda dikey tut';

  @override
  String get startFocus => 'Odaklanma oturumu başlat';

  @override
  String get giveUp => 'Vazgeç';

  @override
  String get skipBreak => 'Molayı atla';

  @override
  String get todayChip => 'bugün';

  @override
  String get phaseReady => 'Hazır';

  @override
  String get phaseFocus => 'Odaklan';

  @override
  String get phaseBreak => 'Mola';

  @override
  String get endAfterStart => 'Bitiş saati başlangıçtan sonra olmalı';

  @override
  String couldNotSaveEvent(Object error) {
    return 'Etkinlik kaydedilemedi: $error';
  }

  @override
  String get deleteEventTitle => 'Etkinlik silinsin mi?';

  @override
  String deleteEventBody(Object title) {
    return '\"$title\" silinsin mi?';
  }

  @override
  String get editEvent => 'Etkinliği düzenle';

  @override
  String get eventTitleHint => 'Başlık (spor, randevu, kulüp…)';

  @override
  String get dateLabel => 'Tarih';

  @override
  String get locationLabel => 'Konum';

  @override
  String get allDayLabel => 'Tüm gün';

  @override
  String couldNotLoadClass(Object error) {
    return 'Ders yüklenemedi: $error';
  }

  @override
  String couldNotLoadAttendance(Object error) {
    return 'Yoklama yüklenemedi: $error';
  }

  @override
  String get markAbsent => 'Devamsız yaz';

  @override
  String get editClass => 'Dersi düzenle';

  @override
  String couldNotMarkAbsent(Object error) {
    return 'Devamsızlık işlenemedi: $error';
  }

  @override
  String get couldNotOpenLink => 'Bağlantı açılamadı';

  @override
  String get markPresent => 'Katıldı olarak işaretle';

  @override
  String get reasonOptional => 'Mazeret (isteğe bağlı)';

  @override
  String get selectCycleWeek => 'En az bir döngü haftası seçin';

  @override
  String get selectRotationDay => 'En az bir rotasyon günü seçin';

  @override
  String get editSlot => 'Ders saatini düzenle';

  @override
  String get addSlot => 'Ders saati ekle';

  @override
  String get dayLabel => 'Gün';

  @override
  String get startTimeLabel => 'Başlangıç';

  @override
  String get endTimeLabel => 'Bitiş';

  @override
  String get roomOverrideHint =>
      'Oda (isteğe bağlı, ders odasını geçersiz kılar)';

  @override
  String get everyWeek => 'Her hafta';

  @override
  String get weekAbRotation => 'A / B haftası rotasyonu';

  @override
  String get customCycle => 'Özel döngü';

  @override
  String get weekA => 'A Haftası';

  @override
  String get weekB => 'B Haftası';

  @override
  String weekABLabel(Object letter) {
    return '$letter Haftası';
  }

  @override
  String get cycleLengthLabel => 'Döngü uzunluğu (hafta)';

  @override
  String weeksCount(Object n) {
    return '$n hafta';
  }

  @override
  String get classesOnWeeks => 'Ders olan haftalar:';

  @override
  String get meetsOnRotationDays => 'Rotasyon günlerinde ders:';

  @override
  String customCycleSummary(Object length, Object weeks) {
    return 'Döngü $length: $weeks. haftalar';
  }

  @override
  String rotationDaysSummary(Object days) {
    return 'Rotasyon günleri $days';
  }

  @override
  String get selectWeekday => 'En az bir hafta günü seçin';

  @override
  String get selectTimes => 'Başlangıç ve bitiş saati seçin';

  @override
  String get deleteClassTitle => 'Ders silinsin mi?';

  @override
  String deleteClassBody(Object name) {
    return '$name programı ve devamsızlık kayıtlarıyla silinsin mi? Görevler ders olmadan saklanır.';
  }

  @override
  String get deleteClassTooltip => 'Dersi sil';

  @override
  String get classNameLabel => 'Ders adı';

  @override
  String get colorLabel => 'Renk';

  @override
  String get meetsOn => 'Ders günleri';

  @override
  String get startsAtLabel => 'Başlangıç';

  @override
  String get endsAtLabel => 'Bitiş';

  @override
  String get meetingHint =>
      'Haftalık ders saatleri. Kaydettikten sonra güne, A/B haftasına veya özel döngüye göre ayarlayın.';

  @override
  String get teacherLabel => 'Öğretmen';

  @override
  String get teacherEmailLabel => 'Öğretmen e-postası';

  @override
  String get roomLabel => 'Oda';

  @override
  String get buildingLabel => 'Bina';

  @override
  String get moduleLabel => 'Modül';

  @override
  String get onlineLinkLabel => 'Çevrimiçi bağlantı';

  @override
  String get onlineLinkHint =>
      'Görüntülü görüşme veya ders sayfası bağlantısı (isteğe bağlı)';

  @override
  String get absenceLimitLabel => 'Devamsızlık sınırı';

  @override
  String get theoryLabel => 'Teorik';

  @override
  String get practicalLabel => 'Uygulama';

  @override
  String get sessionKindLabel => 'Ders türü';

  @override
  String get classReminderLabel => 'Ders hatırlatıcısı (dakika önce)';

  @override
  String get classReminderHint => 'Boş = varsayılan ayarı kullan';

  @override
  String get notesFieldLabel => 'Notlar';

  @override
  String get activeLabel => 'Aktif';

  @override
  String get saveClass => 'Dersi kaydet';

  @override
  String get meetingTimes => 'Ders saatleri';

  @override
  String get addSlotTooltip => 'Ders saati ekle';

  @override
  String couldNotLoadSlots(Object error) {
    return 'Ders saatleri yüklenemedi: $error';
  }

  @override
  String get noSlotsYet => 'Henüz ders saati yok.';

  @override
  String get weeklyHoursHint =>
      'Bu dersin haftalık saatleri. Düzenlemek için bir saate dokun.';

  @override
  String get deleteSlotTooltip => 'Ders saatini sil';

  @override
  String get absencesSection => 'Devamsızlık';

  @override
  String couldNotLoadAbsences(Object error) {
    return 'Devamsızlıklar yüklenemedi: $error';
  }

  @override
  String get nameRequired => 'Ad gerekli';

  @override
  String couldNotLoadSettings(Object error) {
    return 'Ayarlar yüklenemedi: $error';
  }

  @override
  String couldNotSaveSetting(Object error) {
    return 'Ayar kaydedilemedi: $error';
  }

  @override
  String get defaultDurationTitle => 'Varsayılan süre (dakika)';

  @override
  String get defaultReminderTitle => 'Varsayılan ders hatırlatıcısı';

  @override
  String get minutesBeforeClass => 'Dersten dakika önce';

  @override
  String get emptyMeansOff => 'Boş = kapalı';

  @override
  String get enterNonNegative => 'Negatif olmayan bir tam sayı girin';

  @override
  String get defaultLimitSaved => 'Varsayılan devamsızlık sınırı kaydedildi';

  @override
  String get appearanceHeader => 'Görünüm';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get themeLabel => 'Tema';

  @override
  String couldNotSaveTheme(Object error) {
    return 'Tema kaydedilemedi: $error';
  }

  @override
  String couldNotSaveAccent(Object error) {
    return 'Vurgu rengi kaydedilemedi: $error';
  }

  @override
  String get accentLabel => 'Vurgu';

  @override
  String get generalHeader => 'Genel';

  @override
  String get languagesHeader => 'Diller';

  @override
  String get languageLabel => 'Dil';

  @override
  String get languageSystem => 'Sistem varsayılanı';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get defaultAbsenceLimit => 'Varsayılan devamsızlık sınırı';

  @override
  String get prefilledHint => 'Yeni derslere önceden doldurulur. Boş = yok.';

  @override
  String get academicYearsHeader => 'Akademik yıllar';

  @override
  String get dataHeader => 'Veri';

  @override
  String get exportCalendar => 'Takvimi dışa aktar (.ics)';

  @override
  String get exportCalendarHint =>
      'Dersler, görevler ve etkinlikler, gelecek 90 gün';

  @override
  String get importCalendar => 'Takvimi içe aktar (.ics)';

  @override
  String get importCalendarHint => 'Etkinlikleri ekstra kayıt olarak ekler';

  @override
  String get scheduleHeader => 'Program';

  @override
  String get defaultClassStart => 'Varsayılan ders başlangıcı';

  @override
  String prefilledStartHint(Object start) {
    return 'Yeni ders ve saatlere önceden doldurulur: $start';
  }

  @override
  String get defaultClassDuration => 'Varsayılan ders süresi';

  @override
  String prefilledDurationHint(Object minutes) {
    return 'Önceden doldurulan ders süresi: $minutes dk';
  }

  @override
  String get autoEndTitle => 'Bitiş saatini otomatik ayarla';

  @override
  String get autoEndHint =>
      'Başlangıç değişince bitiş = başlangıç + varsayılan süre olur';

  @override
  String get reminderOffHint => 'Kapalı — derslerden önce hatırlatıcı yok';

  @override
  String remindsBeforeHint(Object minutes) {
    return 'Her dersten $minutes dk önce hatırlatır';
  }

  @override
  String get dayStartsLabel => 'Gün başlangıcı';

  @override
  String get dayEndsLabel => 'Gün bitişi';

  @override
  String couldNotSave(Object error) {
    return 'Kaydedilemedi: $error';
  }

  @override
  String get gridRhythmSaved => 'Izgara ritmi kaydedildi';

  @override
  String get gridValidation => 'Pozitif ders ve mola süreleri girin';

  @override
  String get gridTimeLabels => 'Izgara zaman etiketleri';

  @override
  String get modeClassTimes => 'Ders saatleri';

  @override
  String get modeFixed => 'Sabit saat';

  @override
  String get lessonMinLabel => 'Ders (dk)';

  @override
  String get breakMinLabel => 'Mola (dk)';

  @override
  String get loadingEllipsis => 'Yükleniyor…';

  @override
  String savedTo(Object uri) {
    return '$uri konumuna kaydedildi';
  }

  @override
  String couldNotExport(Object error) {
    return 'Dışa aktarılamadı: $error';
  }

  @override
  String couldNotExportCalendar(Object error) {
    return 'Takvim dışa aktarılamadı: $error';
  }

  @override
  String couldNotImportCalendar(Object error) {
    return 'Takvim içe aktarılamadı: $error';
  }

  @override
  String importedEvents(num n) {
    return '$n etkinlik içe aktarıldı';
  }

  @override
  String get notifChannel => 'Görev hatırlatıcıları';

  @override
  String get openAction => 'Aç';

  @override
  String overdueTitle(Object title) {
    return 'Gecikmiş: $title';
  }

  @override
  String wasDue(Object date) {
    return 'Vadesi $date idi';
  }

  @override
  String startsAt(Object time) {
    return '$time başlıyor';
  }

  @override
  String get repeatUntilLabel => 'Tekrar bitişi';

  @override
  String get foreverLabel => 'Süresiz';

  @override
  String get pickTime => 'Saat seç';

  @override
  String absenceSummaryPlain(Object unexcused, Object excused) {
    return '$unexcused mazeretsiz ($excused mazeretli)';
  }

  @override
  String absenceSummaryQuota(Object unexcused, Object limit, Object excused) {
    return '$unexcused / $limit mazeretsiz ($excused mazeretli)';
  }

  @override
  String get excusedAbsenceTitle => 'Mazeretli devamsızlık';

  @override
  String get unexcusedAbsenceTitle => 'Mazeretsiz devamsızlık';

  @override
  String get customColorTitle => 'Özel renk';

  @override
  String get fixedTimeHint => 'Gün başlangıcından gün bitişine tekrarlanır';

  @override
  String get dataFolderTitle => 'Veri klasörü';

  @override
  String get dataFolderUnset =>
      'Ayarlanmadı — veri dosyaları için bir klasör seçin';

  @override
  String get dataFolderNeedsFolder => 'Önce bir veri klasörü seçin';

  @override
  String get exportDataAction => 'Verileri dışa aktar';

  @override
  String get importDataAction => 'Verileri içe aktar';

  @override
  String dataExportDone(Object rows) {
    return '$rows satır dışa aktarıldı';
  }

  @override
  String dataImportDone(Object upserted, Object deleted) {
    return '$upserted birleştirildi · $deleted silindi';
  }

  @override
  String couldNotExportData(Object error) {
    return 'Veriler dışa aktarılamadı: $error';
  }

  @override
  String couldNotImportData(Object error) {
    return 'Veriler içe aktarılamadı: $error';
  }

  @override
  String dataLastExport(Object date) {
    return 'Son dışa aktarma: $date';
  }

  @override
  String dataLastImport(Object date) {
    return 'Son içe aktarma: $date';
  }

  @override
  String get autoSyncTitle => 'Otomatik eşitleme';

  @override
  String get autoSyncHint =>
      'Değişiklikleri dışa, güncellemeleri içe otomatik aktar';

  @override
  String get classFilesSection => 'Dosyalar';

  @override
  String get addFiles => 'Dosya ekle';

  @override
  String get noFilesYet => 'Henüz dosya yok.';

  @override
  String couldNotLoadFiles(Object error) {
    return 'Dosyalar yüklenemedi: $error';
  }

  @override
  String couldNotPickFiles(Object error) {
    return 'Dosyalar eklenemedi: $error';
  }

  @override
  String couldNotOpenFile(Object error) {
    return 'Dosya açılamadı: $error';
  }

  @override
  String get deleteFileTitle => 'Dosya silinsin mi?';

  @override
  String deleteFileBody(Object name) {
    return '\"$name\" silinsin mi?';
  }

  @override
  String get openFileTooltip => 'Dosyayı aç';

  @override
  String get deleteFileTooltip => 'Dosyayı sil';

  @override
  String get couldNotAccessFile =>
      'Seçilen dosya okunamadı. Sistem dosya seçici erişimi reddetti — tekrar deneyin.';

  @override
  String get importErrorFolderMissing =>
      'Veri klasörü bulunamadı. Ayarlar\'dan yeniden seçin.';

  @override
  String get importErrorManifestMissing =>
      'Bu klasörde henüz Chronicle dışa aktarımı yok. Önce diğer cihazınızdan dışa aktarın.';

  @override
  String get importErrorManifestUnreadable =>
      'manifest.json bulundu ancak okunamadı. Chronicle\'a dosya erişimi verin ve klasörü yeniden seçin.';

  @override
  String get importErrorInvalid =>
      'Bu klasör bir Chronicle veri klasörü değil.';
}
