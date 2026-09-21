<?php

use App\Http\Controllers\Api\V1\AppConfigController;
use App\Http\Controllers\Api\V1\ArContentController;
use Illuminate\Support\Facades\Route;

Route::get('/app/config', [AppConfigController::class, 'config']);
Route::get('/content/version', [AppConfigController::class, 'contentVersion']);
Route::get('/ar/content', [ArContentController::class, 'index']);
Route::get('/ar/resolve', [ArContentController::class, 'resolve']);
Route::get('/ar/resolve/marker', [ArContentController::class, 'resolveByMarkerId']);
Route::get('/ar/markers', [ArContentController::class, 'markers']);
