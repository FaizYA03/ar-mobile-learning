class AppUser {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? avatar;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatar,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'siswa',
      avatar: json['avatar'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'avatar': avatar,
      };

  bool get isAdmin => role == 'admin';
  bool get isGuru => role == 'guru';
  bool get isSiswa => role == 'siswa';
}

class LoginResponse {
  final AppUser user;
  final String token;

  LoginResponse({required this.user, required this.token});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: AppUser.fromJson(json['user']),
      token: json['token'],
    );
  }
}

class OnboardingSlideData {
  final String title;
  final String description;

  const OnboardingSlideData({required this.title, required this.description});

  factory OnboardingSlideData.fromJson(Map<String, dynamic> json) {
    return OnboardingSlideData(
      title: '${json['title'] ?? ''}',
      description: '${json['description'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {'title': title, 'description': description};
}

class AppConfigData {
  final bool maintenanceMode;
  final bool arcoreEnabled;
  final String? latestVersion;
  final String? minimumSupportedVersion;
  final String? buildNumber;
  final String? releaseNotes;
  final String? downloadUrl;
  final int contentVersion;

  // Batch 1: konten CMS (branding + teks + onboarding).
  final int uiContentVersion;
  final String appName;
  final String appTagline;
  final String? logoPath;
  final String? logoUrl;
  final String splashTitle;
  final String splashSubtitle;
  final String greetingSiswa;
  final String greetingGuru;
  final String greetingAdmin;
  final List<OnboardingSlideData> onboardingSlides;

  // Batch 2: pengumuman + bantuan/tentang + kontak.
  final String announcementText;
  final bool announcementActive;
  final String helpContent;
  final String aboutContent;
  final String contactEmail;
  final String contactWa;

  static const List<OnboardingSlideData> defaultSlides = [
    OnboardingSlideData(
        title: 'Belajar Informatika\nLebih Menarik',
        description:
            'Pelajari konsep Informatika melalui materi yang terstruktur dan mudah dipahami.'),
    OnboardingSlideData(
        title: 'Temukan\nDunia 3D',
        description:
            'Scan marker dan lihat objek pembelajaran dalam bentuk 3D secara interaktif.'),
    OnboardingSlideData(
        title: 'Uji\nPemahamanmu',
        description: 'Uji pemahaman setelah belajar dan lihat hasilnya.'),
  ];

  AppConfigData({
    required this.maintenanceMode,
    this.arcoreEnabled = true,
    this.latestVersion,
    this.minimumSupportedVersion,
    this.buildNumber,
    this.releaseNotes,
    this.downloadUrl,
    required this.contentVersion,
    this.uiContentVersion = 1,
    this.appName = 'AR Mobile Learning',
    this.appTagline = 'Informatika dengan Augmented Reality',
    this.logoPath,
    this.logoUrl,
    this.splashTitle = 'AR Mobile Learning',
    this.splashSubtitle = 'Informatika dengan Augmented Reality',
    this.greetingSiswa = 'Mari lanjutkan belajar',
    this.greetingGuru = 'Kelola pembelajaran Anda',
    this.greetingAdmin = 'Kelola sistem pembelajaran',
    this.onboardingSlides = defaultSlides,
    this.announcementText = '',
    this.announcementActive = false,
    this.helpContent = '',
    this.aboutContent = '',
    this.contactEmail = '',
    this.contactWa = '',
  });

  factory AppConfigData.fromJson(Map<String, dynamic> json) {
    final branding = json['branding'] as Map<String, dynamic>?;
    final texts = json['texts'] as Map<String, dynamic>?;
    final announcement = json['announcement'] as Map<String, dynamic>?;
    final contact = json['contact'] as Map<String, dynamic>?;
    final rawSlides = json['onboarding_slides'] as List?;
    final slides = (rawSlides ?? [])
        .whereType<Map>()
        .map((s) => OnboardingSlideData.fromJson(Map<String, dynamic>.from(s)))
        .where((s) => s.title.isNotEmpty)
        .toList();
    return AppConfigData(
      maintenanceMode: json['maintenance_mode'] ?? false,
      arcoreEnabled: json['arcore_enabled'] ?? true,
      latestVersion: json['latest_version'],
      minimumSupportedVersion: json['minimum_supported_version'],
      buildNumber: json['build_number'],
      releaseNotes: json['release_notes'],
      downloadUrl: json['download_url'],
      contentVersion: json['content_version'] ?? 0,
      uiContentVersion: json['ui_content_version'] ?? 1,
      appName: branding?['app_name'] ?? 'AR Mobile Learning',
      appTagline: branding?['app_tagline'] ?? '',
      logoPath: branding?['logo_path'],
      logoUrl: branding?['logo_url'],
      splashTitle: texts?['splash_title'] ?? 'AR Mobile Learning',
      splashSubtitle: texts?['splash_subtitle'] ?? '',
      greetingSiswa: texts?['greeting_siswa'] ?? 'Mari lanjutkan belajar',
      greetingGuru: texts?['greeting_guru'] ?? 'Kelola pembelajaran Anda',
      greetingAdmin: texts?['greeting_admin'] ?? 'Kelola sistem pembelajaran',
      onboardingSlides: slides.isEmpty ? defaultSlides : slides,
      announcementText: '${announcement?['text'] ?? ''}',
      announcementActive: announcement?['active'] ?? false,
      helpContent: '${json['help_content'] ?? ''}',
      aboutContent: '${json['about_content'] ?? ''}',
      contactEmail: '${contact?['email'] ?? ''}',
      contactWa: '${contact?['wa'] ?? ''}',
    );
  }

  Map<String, dynamic> toJson() => {
        'maintenance_mode': maintenanceMode,
        'arcore_enabled': arcoreEnabled,
        'latest_version': latestVersion,
        'minimum_supported_version': minimumSupportedVersion,
        'build_number': buildNumber,
        'release_notes': releaseNotes,
        'download_url': downloadUrl,
        'content_version': contentVersion,
        'ui_content_version': uiContentVersion,
        'branding': {
          'app_name': appName,
          'app_tagline': appTagline,
          'logo_path': logoPath,
          'logo_url': logoUrl,
        },
        'texts': {
          'splash_title': splashTitle,
          'splash_subtitle': splashSubtitle,
          'greeting_siswa': greetingSiswa,
          'greeting_guru': greetingGuru,
          'greeting_admin': greetingAdmin,
        },
        'onboarding_slides': onboardingSlides.map((s) => s.toJson()).toList(),
        'announcement': {
          'text': announcementText,
          'active': announcementActive
        },
        'help_content': helpContent,
        'about_content': aboutContent,
        'contact': {'email': contactEmail, 'wa': contactWa},
      };
}

class ContentVersionData {
  final int contentVersion;
  final String updatedAt;

  ContentVersionData({required this.contentVersion, required this.updatedAt});

  factory ContentVersionData.fromJson(Map<String, dynamic> json) {
    return ContentVersionData(
      contentVersion: json['content_version'] ?? 0,
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class ArContentItem {
  final int id;
  final String modelName;
  final String? description;
  final String? category;
  final int version;
  final bool isActive;
  final String? glbUrl;
  final String? glbPath;
  final String? thumbnailUrl;
  final String? thumbnailPath;
  final List<ArMarkerData> markers;
  final List<ArHotspotData> hotspots;

  ArContentItem({
    required this.id,
    required this.modelName,
    this.description,
    this.category,
    required this.version,
    required this.isActive,
    this.glbUrl,
    this.glbPath,
    this.thumbnailUrl,
    this.thumbnailPath,
    required this.markers,
    required this.hotspots,
  });

  factory ArContentItem.fromJson(Map<String, dynamic> json) {
    return ArContentItem(
      id: json['id'] ?? 0,
      modelName: json['model_name'] ?? '',
      description: json['description'],
      category: json['category'],
      version: json['version'] ?? 1,
      isActive: json['is_active'] ?? true,
      glbUrl: json['glb_url'],
      glbPath: json['glb_path'],
      thumbnailUrl: json['thumbnail_url'],
      thumbnailPath: json['thumbnail_path'],
      markers: (json['markers'] as List<dynamic>?)
              ?.map((m) => ArMarkerData.fromJson(m))
              .toList() ??
          [],
      hotspots: (json['hotspots'] as List<dynamic>?)
              ?.map((h) => ArHotspotData.fromJson(h))
              .toList() ??
          [],
    );
  }
}

class ArMarkerData {
  final int id;
  final String markerId;
  final int? arUcoId;
  final String? arucoDictionary;
  final String markerType;
  final String? imageUrl;
  final String? imagePath;
  final String status;
  final String? updatedAt;

  ArMarkerData({
    required this.id,
    required this.markerId,
    this.arUcoId,
    this.arucoDictionary,
    required this.markerType,
    this.imageUrl,
    this.imagePath,
    required this.status,
    this.updatedAt,
  });

  factory ArMarkerData.fromJson(Map<String, dynamic> json) {
    return ArMarkerData(
      id: json['id'] ?? 0,
      markerId: json['marker_id'] ?? '',
      arUcoId: json['ar_uco_id'],
      arucoDictionary: json['aruco_dictionary'],
      markerType: json['marker_type'] ?? 'image',
      imageUrl: json['image_url'],
      imagePath: json['image_path'],
      status: json['status'] ?? 'active',
      updatedAt: json['updated_at'],
    );
  }
}

class ArHotspotData {
  final int id;
  final String title;
  final String? description;
  final double? latitude;
  final double? longitude;
  final double positionX;
  final double positionY;
  final double positionZ;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final double hotspotScale;
  final int sortOrder;
  final String? imageUrl;
  final String? imagePath;

  ArHotspotData({
    required this.id,
    required this.title,
    this.description,
    this.latitude,
    this.longitude,
    this.positionX = 0,
    this.positionY = 0,
    this.positionZ = 0,
    this.rotationX = 0,
    this.rotationY = 0,
    this.rotationZ = 0,
    this.hotspotScale = 1.0,
    this.sortOrder = 0,
    this.imageUrl,
    this.imagePath,
  });

  factory ArHotspotData.fromJson(Map<String, dynamic> json) {
    return ArHotspotData(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      positionX: (json['position_x'] as num?)?.toDouble() ?? 0,
      positionY: (json['position_y'] as num?)?.toDouble() ?? 0,
      positionZ: (json['position_z'] as num?)?.toDouble() ?? 0,
      rotationX: (json['rotation_x'] as num?)?.toDouble() ?? 0,
      rotationY: (json['rotation_y'] as num?)?.toDouble() ?? 0,
      rotationZ: (json['rotation_z'] as num?)?.toDouble() ?? 0,
      hotspotScale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      sortOrder: json['sort_order'] ?? 0,
      imageUrl: json['image_url'],
      imagePath: json['image_path'],
    );
  }
}

class QuizItem {
  final int id;
  final String title;
  final String? description;
  final int? timeLimit;
  final int passingScore;
  final int questionsCount;
  final List<QuizQuestion>? questions;

  QuizItem({
    required this.id,
    required this.title,
    this.description,
    this.timeLimit,
    this.passingScore = 70,
    this.questionsCount = 0,
    this.questions,
  });

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    return QuizItem(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      timeLimit: json['time_limit'],
      passingScore: json['passing_score'] ?? 70,
      questionsCount: json['questions_count'] ?? 0,
      questions: (json['questions'] as List<dynamic>?)
          ?.map((q) => QuizQuestion.fromJson(q))
          .toList(),
    );
  }
}

class QuizQuestion {
  final int id;
  final int quizId;
  final String text;
  final int order;
  final List<QuizOption> options;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.text,
    this.order = 0,
    this.options = const [],
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] ?? 0,
      quizId: json['quiz_id'] ?? 0,
      text: json['text'] ?? '',
      order: json['order'] ?? 0,
      options: (json['options'] as List<dynamic>?)
              ?.map((o) => QuizOption.fromJson(o))
              .toList() ??
          [],
    );
  }
}

class QuizOption {
  final int id;
  final int questionId;
  final String text;
  final int order;
  final bool? isCorrect;

  QuizOption({
    required this.id,
    required this.questionId,
    required this.text,
    this.order = 0,
    this.isCorrect,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'] ?? 0,
      questionId: json['question_id'] ?? 0,
      text: json['text'] ?? '',
      order: json['order'] ?? 0,
      isCorrect: json['is_correct'],
    );
  }
}

class QuizAttemptResult {
  final int attemptId;
  final int score;
  final int correct;
  final int total;
  final bool passed;

  QuizAttemptResult({
    required this.attemptId,
    required this.score,
    required this.correct,
    required this.total,
    required this.passed,
  });

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) {
    return QuizAttemptResult(
      attemptId: json['attempt_id'] ?? 0,
      score: json['score'] ?? 0,
      correct: json['correct'] ?? 0,
      total: json['total'] ?? 0,
      passed: json['passed'] ?? false,
    );
  }
}

class ArUcoResult {
  final int markerId;
  final String arucoDictionary;
  final List<List<double>> corners;
  final String markerType;
  final DateTime detectedAt;

  ArUcoResult({
    required this.markerId,
    this.arucoDictionary = 'DICT_4X4_50',
    required this.corners,
    this.markerType = 'aruco',
    DateTime? detectedAt,
  }) : detectedAt = detectedAt ?? DateTime.now();

  factory ArUcoResult.fromJson(Map<String, dynamic> json) {
    return ArUcoResult(
      markerId: json['marker_id'] ?? 0,
      arucoDictionary: json['aruco_dictionary'] ?? 'DICT_4X4_50',
      corners: List<List<double>>.from(
        (json['corners'] as List<dynamic>?)
                ?.map((c) => List<double>.from(c.map((v) => v.toDouble())))
                .toList() ??
            [],
      ),
      markerType: json['marker_type'] ?? 'aruco',
      detectedAt: json['detected_at'] != null
          ? DateTime.parse(json['detected_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'marker_id': markerId,
        'aruco_dictionary': arucoDictionary,
        'corners': corners,
        'marker_type': markerType,
        'detected_at': detectedAt.toIso8601String(),
      };
}

class ArResolveResult {
  final ArResolveMarker marker;
  final ArResolveModel model;
  final List<ArHotspotData> hotspots;

  ArResolveResult({
    required this.marker,
    required this.model,
    required this.hotspots,
  });

  factory ArResolveResult.fromJson(Map<String, dynamic> json) {
    return ArResolveResult(
      marker: ArResolveMarker.fromJson(json['marker'] ?? {}),
      model: ArResolveModel.fromJson(json['model'] ?? {}),
      hotspots: (json['hotspots'] as List<dynamic>?)
              ?.map((h) => ArHotspotData.fromJson(h))
              .toList() ??
          [],
    );
  }
}

class ArResolveMarker {
  final int id;
  final String markerId;
  final int? arUcoId;
  final String? arucoDictionary;
  final String markerType;
  final String status;

  ArResolveMarker({
    required this.id,
    required this.markerId,
    this.arUcoId,
    this.arucoDictionary,
    required this.markerType,
    required this.status,
  });

  factory ArResolveMarker.fromJson(Map<String, dynamic> json) {
    return ArResolveMarker(
      id: json['id'] ?? 0,
      markerId: json['marker_id'] ?? '',
      arUcoId: json['ar_uco_id'],
      arucoDictionary: json['aruco_dictionary'],
      markerType: json['marker_type'] ?? 'pattern',
      status: json['status'] ?? 'active',
    );
  }
}

class ArResolveModel {
  final int id;
  final String modelName;
  final String? description;
  final String? category;
  final int version;
  final String? glbUrl;
  final String? glbPath;
  final String? thumbnailUrl;
  final String? thumbnailPath;

  ArResolveModel({
    required this.id,
    required this.modelName,
    this.description,
    this.category,
    required this.version,
    this.glbUrl,
    this.glbPath,
    this.thumbnailUrl,
    this.thumbnailPath,
  });

  factory ArResolveModel.fromJson(Map<String, dynamic> json) {
    return ArResolveModel(
      id: json['id'] ?? 0,
      modelName: json['model_name'] ?? '',
      description: json['description'],
      category: json['category'],
      version: json['version'] ?? 1,
      glbUrl: json['glb_url'],
      glbPath: json['glb_path'],
      thumbnailUrl: json['thumbnail_url'],
      thumbnailPath: json['thumbnail_path'],
    );
  }
}

class MateriItem {
  final int id;
  final int? tpAtpId;
  final int? arModelId;
  final int? quizId;
  final String judul;
  final String? slug;
  final String? ringkasan;
  final String? konten;
  final String? gambarCover;
  final String? gambarCoverUrl;
  final int estimasiMenit;
  final int order;
  final bool isPublished;
  final Map<String, dynamic>? tpAtp;
  final Map<String, dynamic>? arModel;
  final MateriQuiz? quiz;

  MateriItem({
    required this.id,
    this.tpAtpId,
    this.arModelId,
    this.quizId,
    required this.judul,
    this.slug,
    this.ringkasan,
    this.konten,
    this.gambarCover,
    this.gambarCoverUrl,
    this.estimasiMenit = 15,
    this.order = 1,
    this.isPublished = true,
    this.tpAtp,
    this.arModel,
    this.quiz,
  });

  factory MateriItem.fromJson(Map<String, dynamic> json) {
    return MateriItem(
      id: json['id'] ?? 0,
      tpAtpId: json['tp_atp_id'],
      arModelId: json['ar_model_id'],
      quizId: json['quiz_id'],
      judul: json['judul'] ?? '',
      slug: json['slug'],
      ringkasan: json['ringkasan'],
      konten: json['konten'],
      gambarCover: json['gambar_cover'],
      gambarCoverUrl: json['gambar_cover_url'],
      estimasiMenit: json['estimasi_menit'] ?? 15,
      order: json['order'] ?? 1,
      isPublished: json['is_published'] ?? true,
      tpAtp: json['tp_atp'],
      arModel: json['ar_model'],
      quiz: json['quiz'] != null ? MateriQuiz.fromJson(json['quiz']) : null,
    );
  }
}

class MateriQuiz {
  final int id;
  final String title;
  final String? description;
  final int? timeLimit;
  final int passingScore;
  final int questionsCount;

  MateriQuiz({
    required this.id,
    required this.title,
    this.description,
    this.timeLimit,
    this.passingScore = 70,
    this.questionsCount = 0,
  });

  factory MateriQuiz.fromJson(Map<String, dynamic> json) {
    return MateriQuiz(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'],
      timeLimit: json['time_limit'],
      passingScore: json['passing_score'] ?? 70,
      questionsCount: json['questions_count'] ?? 0,
    );
  }
}

class QuizAttemptHistory {
  final int quizId;
  final String quizTitle;
  final int totalAttempts;
  final int? bestScore;
  final bool passed;
  final List<QuizAttemptItem> attempts;

  QuizAttemptHistory({
    required this.quizId,
    required this.quizTitle,
    required this.totalAttempts,
    this.bestScore,
    required this.passed,
    required this.attempts,
  });

  factory QuizAttemptHistory.fromJson(Map<String, dynamic> json) {
    return QuizAttemptHistory(
      quizId: json['quiz_id'] ?? 0,
      quizTitle: json['quiz_title'] ?? '',
      totalAttempts: json['total_attempts'] ?? 0,
      bestScore: json['best_score'],
      passed: json['passed'] ?? false,
      attempts: (json['attempts'] as List<dynamic>?)
              ?.map((a) => QuizAttemptItem.fromJson(a))
              .toList() ??
          [],
    );
  }
}

class QuizAttemptItem {
  final int id;
  final int score;
  final bool passed;
  final String? createdAt;

  QuizAttemptItem({
    required this.id,
    required this.score,
    required this.passed,
    this.createdAt,
  });

  factory QuizAttemptItem.fromJson(Map<String, dynamic> json) {
    return QuizAttemptItem(
      id: json['id'] ?? 0,
      score: json['score'] ?? 0,
      passed: json['passed'] ?? false,
      createdAt: json['created_at'],
    );
  }
}
