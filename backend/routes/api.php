<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\AdminController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/quizzes', [QuizController::class, 'index']);
    Route::get('/quizzes/{quiz}', [QuizController::class, 'show']);
    Route::post('/quizzes/{quiz}/submit', [QuizController::class, 'submit']);

    Route::middleware('role:admin')->prefix('admin')->group(function () {
        Route::get('/users', [AdminController::class, 'users']);
        Route::post('/users', [AdminController::class, 'storeUser']);
        Route::put('/users/{user}', [AdminController::class, 'updateUser']);
        Route::delete('/users/{user}', [AdminController::class, 'deleteUser']);
    });

    Route::middleware('role:guru,admin')->group(function () {
        Route::get('/guru/quizzes', [QuizController::class, 'guruIndex']);
        Route::post('/guru/quizzes', [QuizController::class, 'guruStore']);
        Route::put('/guru/quizzes/{quiz}', [QuizController::class, 'guruUpdate']);
        Route::delete('/guru/quizzes/{quiz}', [QuizController::class, 'guruDestroy']);
        Route::post('/guru/quizzes/{quiz}/questions', [QuizController::class, 'addQuestion']);
        Route::delete('/guru/questions/{question}', [QuizController::class, 'deleteQuestion']);
    });
});
