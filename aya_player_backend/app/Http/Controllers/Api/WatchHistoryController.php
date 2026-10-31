// app/Http/Controllers/Api/WatchHistoryController.php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\WatchHistory;
use Illuminate\Http\Request;

class WatchHistoryController extends Controller
{
    public function index(Request $request)
    {
        $histories = $request->user()
            ->watchHistories()
            ->orderBy('updated_at', 'desc')
            ->get();

        return response()->json([
            'status' => true,
            'data'   => $histories,
        ]);
    }

    public function sync(Request $request)
    {
        $validated = $request->validate([
            'video_identifier'       => 'required|string',
            'video_title'            => 'required|string',
            'last_position_seconds'  => 'required|integer|min:0',
            'total_duration_seconds' => 'required|integer|min:0',
        ]);

        $isCompleted = ($validated['total_duration_seconds'] > 0) &&
            (($validated['total_duration_seconds'] - $validated['last_position_seconds']) <= 5);

        $history = WatchHistory::updateOrCreate(
            [
                'user_id'          => $request->user()->id,
                'video_identifier' => $validated['video_identifier'],
            ],
            [
                'video_title'            => $validated['video_title'],
                'last_position_seconds'  => $validated['last_position_seconds'],
                'total_duration_seconds' => $validated['total_duration_seconds'],
                'is_completed'           => $isCompleted,
            ]
        );

        return response()->json([
            'status'  => true,
            'message' => 'تمت مزامنة نقطة التوقف بنجاح',
            'data'    => $history,
        ]);
    }
}
