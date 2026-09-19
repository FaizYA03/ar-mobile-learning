<?php

require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->handle(new \Symfony\Component\Console\Input\ArgvInput());

use Illuminate\Support\Facades\DB;

echo "=== Fixing AR Model paths ===\n";

// Fix glb_path
$count = DB::table('ar_models')->where('glb_path', 'LIKE', 'storage/%')->count();
echo "Models with storage/ prefix in glb_path: $count\n";

DB::table('ar_models')
    ->where('glb_path', 'LIKE', 'storage/%')
    ->update(['glb_path' => DB::raw("REPLACE(glb_path, 'storage/', '')")]);

DB::table('ar_models')
    ->where('thumbnail_path', 'LIKE', 'storage/%')
    ->update(['thumbnail_path' => DB::raw("REPLACE(thumbnail_path, 'storage/', '')")]);

DB::table('ar_markers')
    ->where('image_path', 'LIKE', 'storage/%')
    ->update(['image_path' => DB::raw("REPLACE(image_path, 'storage/', '')")]);

DB::table('ar_hotspots')
    ->where('image_path', 'LIKE', 'storage/%')
    ->update(['image_path' => DB::raw("REPLACE(image_path, 'storage/', '')")]);

echo "\n=== Verification ===\n";

echo "\nModels:\n";
$models = DB::table('ar_models')->get();
foreach ($models as $m) {
    echo "  {$m->id}: glb={$m->glb_path}, thumb={$m->thumbnail_path}\n";
}

echo "\nMarkers:\n";
$markers = DB::table('ar_markers')->get();
foreach ($markers as $m) {
    echo "  {$m->id}: img={$m->image_path}\n";
}

echo "\nDone!\n";
