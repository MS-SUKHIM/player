// app/Models/CloudFavorite.php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class CloudFavorite extends Model
{
    protected $fillable = [
        'user_id',
        'video_identifier',
        'video_title',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
