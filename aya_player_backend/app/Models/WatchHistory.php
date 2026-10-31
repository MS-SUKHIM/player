// app/Models/WatchHistory.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WatchHistory extends Model
{
    protected $fillable = [
        'user_id',
        'video_identifier',
        'video_title',
        'last_position_seconds',
        'total_duration_seconds',
        'is_completed',
    ];

    protected $casts = [
        'is_completed' => 'boolean',
        'last_position_seconds' => 'integer',
        'total_duration_seconds' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
