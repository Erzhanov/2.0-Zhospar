# ZHOSPAR Mobile App (Flutter)

Жоспарлауға арналған заманауи Flutter мобильді қосымшасы (Google Play Store & Apple App Store релизіне 100% дайын).

---

## 📱 Мүмкіндіктер мен Архитектура

1. **Басты бет (Dashboard):**
   - Апталық орындалу барысы (Progress Hero)
   - Апталық дәйексөз (Weekly Quote) — төменнен ашылатын сәнді редактормен
   - 7 күндік ауыстырғыш (Дүйсенбі — Жексенбі) мен бүгінгі күннің маркері
   - Тапсырмаларды сүзгілеу (Барлығы / Қалған / Дайын)
   - Тапсырмаларды серпу (Swipeable): оңға серпіп орындау, солға серпіп жою
   - Тактильді діріл кері байланысы (Haptic Feedback)
   - Күндік рефлексия (Daily Reflection) блогы

2. **Апталық жоспар (Week Plan):**
   - 2 түрлі режим: Күн бойынша қарау (Day-by-day) немесе 7 күннің толық шолуы (All 7 days grid)
   - Апталарды алға/артқа жылжыту

3. **Талдау және Графиктер (Analytics):**
   - 4 негізгі көрсеткіш: Орындалу пайызы, Streak (үздіксіз күндер), Орындалған, Қалған тапсырмалар
   - Апталық динамика графигі (fl_chart BarChart)
   - Санаттар бойынша үлестірім

4. **Фокус Таймер (Pomodoro Timer & Lo-fi Music):**
   - Помодоро (25 мин), Қысқа үзіліс (5 мин), Ұзақ үзіліс (15 мин)
   - Фондық тыныштандыратын Lo-Fi музыкалар (Deep Focus, Chill Beats, Rain Lofi)
   - Барлық беттерде қолжетімді өзгермелі мини-плеер

5. **AI Көмекші (AI Assistant):**
   - Жоспар құруға арналған арнайы жасанды интеллект чаты (Supabase Edge Function)
   - «Жоспарды қабылдау» — ұсынылған тапсырмаларды бір батырмамен апталық күнтізбеге импорттау

6. **Апталық қорытынды (Weekly Review):**
   - 4 бағыттағы ретроспектива сұрақтары
   - Келесі аптаға арналған 3 басты мақсатты белгілеу

7. **Мұрағат (Archive):**
   - Өткен апталардың тарихын сақтау
   - Орындалмаған тапсырмаларды жаңа аптаға көшіру батырмасы

8. **Баптаулар (Settings):**
   - Жарық және Apple OLED қараңғы режимі (Light & Dark theme)
   - 3 тілді қолдау: Қазақша (kk), Русский (ru), English (en)
   - Onboarding гидін қайта бастау

---

## 🚀 Google Play Store шығарылымы (Release Build)

### 1. Keystore кілтін жасау (бір рет жасалады)
Терминалда мына бұйрықты орындаңыз:
```bash
keytool -genkey -v -keystore android/app/zhospar-upload-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias zhospar
```

### 2. `android/key.properties` файлын толтыру
`android/key.properties.example` файлын көшіріп, `android/key.properties` деп ашып, құпия сөздерді жазыңыз:
```properties
storePassword=құпия_сөзіңіз
keyPassword=кілт_құпия_сөзіңіз
keyAlias=zhospar
storeFile=zhospar-upload-key.jks
```

### 3. Google Play үшін AAB жинау (App Bundle)
```bash
flutter build appbundle --release
```
Дайын файл мына жолда пайда болады:
`build/app/outputs/bundle/release/app-release.aab`  
Осы `.aab` файлын Google Play Console-ға жүктейсіз.

---

## 🍏 Apple App Store шығарылымы (iOS Release)

### 1. Pods орнату (macOS ортасында)
```bash
cd ios
pod install
cd ..
```

### 2. IPA жинау
```bash
flutter build ipa --release
```
Немесе Xcode арқылы:
```bash
open ios/Runner.xcworkspace
```
`Product` -> `Archive` -> `Distribute App` -> `App Store Connect` таңдап жүктейсіз.

> [!NOTE]
> `ios/Runner/PrivacyInfo.xcprivacy` файлы Apple 2024+ талаптарына сай қосылған, сондықтан TestFlight және App Store тексерісінен қатесіз өтеді.

---

## 🛠 Әзірлеу бұйрықтары

- **Талдау (Analyze):** `flutter analyze`
- **Тестілеу (Test):** `flutter test`
- **Іске қосу (Run):** `flutter run`
