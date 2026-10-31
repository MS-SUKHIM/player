// 2026_08_17_052810_create_cloud_favorites_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('cloud_favorites', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('video_identifier');
            $table->string('video_title');
            $table->timestamps();

            $table->unique(['user_id', 'video_identifier']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('cloud_favorites');
    }
};
