// app/Http/Controllers/Api/CloudFavoriteController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CloudFavorite;
use Illuminate\Http\Request;

class CloudFavoriteController extends Controller
{
    public function index(Request $request)
    {
        $favorites = $request->user()
            ->cloudFavorites()
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => true,
            'data'   => $favorites,
        ]);
    }

    public function toggle(Request $request)
    {
        $validated = $request->validate([
            'video_identifier' => 'required|string',
            'video_title'      => 'required|string',
        ]);

        $userId = $request->user()->id;
        $favorite = CloudFavorite::where('user_id', $userId)
            ->where('video_identifier', $validated['video_identifier'])
            ->first();

        if ($favorite) {
            $favorite->delete();
            return response()->json([
                'status'       => true,
                'is_favorited' => false,
                'message'      => 'تم الحذف من المفضلة السحابية',
            ]);
        }

        $newFavorite = CloudFavorite::create([
            'user_id'          => $userId,
            'video_identifier' => $validated['video_identifier'],
            'video_title'      => $validated['video_title'],
        ]);

        return response()->json([
            'status'       => true,
            'is_favorited' => true,
            'message'      => 'تمت الإضافة إلى المفضلة السحابية',
            'data'         => $newFavorite,
        ]);
    }
}
