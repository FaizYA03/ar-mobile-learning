<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\QuizController;
use App\Http\Controllers\DashboardController;
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
        Route::get('/users', [DashboardController::class, 'adminUsers']);
    });
});
