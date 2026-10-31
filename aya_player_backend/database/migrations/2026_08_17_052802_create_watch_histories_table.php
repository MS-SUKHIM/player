// 2026_08_17_052802_create_watch_histories_table.php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('watch_histories', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('video_identifier');
            $table->string('video_title');
            $table->unsignedInteger('last_position_seconds')->default(0);
            $table->unsignedInteger('total_duration_seconds')->default(0);
            $table->boolean('is_completed')->default(false);
            $table->timestamps();

            $table->unique(['user_id', 'video_identifier']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('watch_histories');
    }
};
