<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\WatchHistoryCon    
use App\Http\Controllers\Api\CloudFavoriteController;

Route::prefix('v1/auth')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware('auth:sanctum')->prefix('v1')->group(function () {
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::get('/auth/me', [AuthController::class, 'me']);

    Route::get('/history', [WatchHistoryController::class, 'index']);
    Route::post('/history/sync', [WatchHistoryController::class, 'sync']);

    Route::get('/favorites', [CloudFavoriteController::class, 'index']);
    Route::post('/favorites/toggle', [CloudFavoriteController::class, 'toggle']);
});
