<?php

use App\Http\Controllers\Admin\AuthController;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\TpAtpController;
use App\Http\Controllers\Admin\MateriController;
use App\Http\Controllers\Admin\QuizController;
use App\Http\Controllers\Admin\QuizAttemptController;
use App\Http\Controllers\Admin\ArModelController;
use App\Http\Controllers\Admin\ArMarkerController;
use App\Http\Controllers\Admin\ArHotspotController;
use App\Http\Controllers\Admin\ArMappingController;
use App\Http\Controllers\Admin\ArHotspotApiController;
use App\Http\Controllers\Admin\ActivityLogController;
use App\Http\Controllers\Admin\SystemController;
use Illuminate\Support\Facades\Route;

Route::get('/login', [AuthController::class, 'showLogin'])->name('admin.login');
Route::post('/login', [AuthController::class, 'login'])->name('admin.login.post');

Route::middleware(['auth', 'role:admin'])->prefix('admin')->name('admin.')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout'])->name('logout');
    Route::get('/dashboard', [DashboardController::class, 'index'])->name('dashboard');

    Route::resource('users', UserController::class)->except('show');
    Route::resource('tp-atp', TpAtpController::class)->except('show');
    Route::resource('materi', MateriController::class)->except('show');
    Route::resource('quiz', QuizController::class)->except('show');
    Route::get('quiz/{quiz}/questions', [QuizController::class, 'questions'])->name('quiz.questions');
    Route::post('quiz/{quiz}/questions', [QuizController::class, 'storeQuestion'])->name('quiz.store-question');
    Route::delete('quiz/questions/{question}', [QuizController::class, 'deleteQuestion'])->name('quiz.delete-question');
    Route::get('quiz-attempts', [QuizAttemptController::class, 'index'])->name('quiz-attempts.index');

    Route::prefix('ar')->name('ar.')->group(function () {
        Route::resource('models', ArModelController::class)->except('show');
        Route::resource('markers', ArMarkerController::class)->except('show');
        Route::resource('hotspots', ArHotspotController::class)->except('show');
        Route::resource('mappings', ArMappingController::class)->except('show');

        Route::prefix('hotspots-api')->name('hotspots-api.')->group(function () {
            Route::get('/', [ArHotspotApiController::class, 'index'])->name('index');
            Route::post('/', [ArHotspotApiController::class, 'store'])->name('store');
            Route::get('/{hotspot}', [ArHotspotApiController::class, 'show'])->name('show');
            Route::put('/{hotspot}', [ArHotspotApiController::class, 'update'])->name('update');
            Route::delete('/{hotspot}', [ArHotspotApiController::class, 'destroy'])->name('destroy');
            Route::post('/reorder', [ArHotspotApiController::class, 'reorder'])->name('reorder');
        });
    });

    Route::get('activity-logs', [ActivityLogController::class, 'index'])->name('activity-logs.index');
    Route::get('system/settings', [SystemController::class, 'settings'])->name('system.settings');
    Route::post('system/settings', [SystemController::class, 'updateSettings'])->name('system.settings.update');
    Route::get('system/content', [SystemController::class, 'content'])->name('system.content');
    Route::post('system/content/branding', [SystemController::class, 'updateBranding'])->name('system.content.branding');
    Route::post('system/content/splash', [SystemController::class, 'updateSplash'])->name('system.content.splash');
    Route::post('system/content/greetings', [SystemController::class, 'updateGreetings'])->name('system.content.greetings');
    Route::post('system/content/announcement', [SystemController::class, 'updateAnnouncement'])->name('system.content.announcement');
    Route::post('system/content/help', [SystemController::class, 'updateHelp'])->name('system.content.help');
    Route::post('system/content/onboarding', [SystemController::class, 'updateOnboarding'])->name('system.content.onboarding');
    Route::get('system/versions', [SystemController::class, 'versions'])->name('system.versions');
    Route::post('system/versions', [SystemController::class, 'storeVersion'])->name('system.versions.store');
    Route::put('system/versions/{appVersion}', [SystemController::class, 'updateVersion'])->name('system.versions.update');
    Route::delete('system/versions/{appVersion}', [SystemController::class, 'destroyVersion'])->name('system.versions.destroy');
});
