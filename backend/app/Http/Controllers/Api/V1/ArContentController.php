<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ArModel;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Storage;

class ArContentController extends Controller
{
    public function index(): JsonResponse
    {
        $mappings = ArModel::where('is_active', true)
            ->with([
                'markers' => function ($q) {
                    $q->where('status', 'active');
                },
                'hotspots' => function ($q) {
                    $q->where('is_active', true);
                },
            ])
            ->withCount(['markers as active_markers_count' => function ($q) {
                $q->where('status', 'active');
            }])
            ->orderBy('model_name')
            ->get();

        $data = $mappings->map(function ($model) {
            return [
                'id' => $model->id,
                'model_name' => $model->model_name,
                'description' => $model->description,
                'category' => $model->category,
                'version' => $model->version,
                'is_active' => $model->is_active,
                'glb_url' => $model->glb_path ? Storage::url($model->glb_path) : null,
                'glb_path' => $model->glb_path,
                'thumbnail_url' => $model->thumbnail_path ? Storage::url($model->thumbnail_path) : null,
                'thumbnail_path' => $model->thumbnail_path,
                'markers' => $model->markers->map(function ($marker) {
                    return [
                        'id' => $marker->id,
                        'marker_id' => $marker->marker_id,
                        'marker_type' => $marker->marker_type,
                        'image_url' => $marker->image_path ? Storage::url($marker->image_path) : null,
                        'image_path' => $marker->image_path,
                        'status' => $marker->status,
                        'updated_at' => $marker->updated_at?->toIso8601String(),
                    ];
                }),
                'hotspots' => $model->hotspots->map(function ($hotspot) {
                    return [
                        'id' => $hotspot->id,
                        'title' => $hotspot->title,
                        'description' => $hotspot->description,
                        'latitude' => $hotspot->latitude,
                        'longitude' => $hotspot->longitude,
                        'position_x' => $hotspot->position_x ?? 0,
                        'position_y' => $hotspot->position_y ?? 0,
                        'position_z' => $hotspot->position_z ?? 0,
                        'rotation_x' => $hotspot->rotation_x ?? 0,
                        'rotation_y' => $hotspot->rotation_y ?? 0,
                        'rotation_z' => $hotspot->rotation_z ?? 0,
                        'scale' => $hotspot->scale ?? 1.0,
                        'sort_order' => $hotspot->sort_order ?? 0,
                        'image_url' => $hotspot->image_path ? Storage::url($hotspot->image_path) : null,
                        'image_path' => $hotspot->image_path,
                    ];
                }),
            ];
        });

        return response()->json([
            'success' => true,
            'message' => 'Konten AR berhasil diambil',
            'data' => $data,
        ]);
    }
}
