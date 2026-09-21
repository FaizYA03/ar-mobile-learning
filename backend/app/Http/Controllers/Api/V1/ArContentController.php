<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\ArMarker;
use App\Models\ArModel;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
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
                'glb_url' => $model->glb_path ? url(Storage::url($model->glb_path)) : null,
                'glb_path' => $model->glb_path,
                'thumbnail_url' => $model->thumbnail_path ? url(Storage::url($model->thumbnail_path)) : null,
                'thumbnail_path' => $model->thumbnail_path,
                'markers' => $model->markers->map(function ($marker) {
                    return [
                        'id' => $marker->id,
                        'marker_id' => $marker->marker_id,
                        'ar_uco_id' => $marker->ar_uco_id,
                        'aruco_dictionary' => $marker->aruco_dictionary,
                        'marker_type' => $marker->marker_type,
                        'image_url' => $marker->image_path ? url(Storage::url($marker->image_path)) : null,
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
                        'image_url' => $hotspot->image_path ? url(Storage::url($hotspot->image_path)) : null,
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

    public function resolve(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'aruco_dictionary' => 'required|string|max:50',
            'aruco_id' => 'required|integer|min:0',
        ]);

        $marker = ArMarker::where('aruco_dictionary', $validated['aruco_dictionary'])
            ->where('ar_uco_id', $validated['aruco_id'])
            ->where('status', 'active')
            ->with([
                'models' => function ($q) {
                    $q->where('is_active', true);
                },
            ])
            ->first();

        if (!$marker) {
            return response()->json([
                'success' => false,
                'message' => 'Marker tidak ditemukan untuk ArUco dictionary dan ID yang diberikan',
                'data' => null,
            ], 404);
        }

        $model = $marker->models->first();

        if (!$model) {
            return response()->json([
                'success' => false,
                'message' => 'Marker ditemukan tetapi tidak ada model 3D yang terhubung',
                'data' => [
                    'marker_id' => $marker->marker_id,
                    'ar_uco_id' => $marker->ar_uco_id,
                    'aruco_dictionary' => $marker->aruco_dictionary,
                ],
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Marker berhasil di-resolve',
            'data' => [
                'marker' => [
                    'id' => $marker->id,
                    'marker_id' => $marker->marker_id,
                    'ar_uco_id' => $marker->ar_uco_id,
                    'aruco_dictionary' => $marker->aruco_dictionary,
                    'marker_type' => $marker->marker_type,
                    'status' => $marker->status,
                ],
                'model' => [
                    'id' => $model->id,
                    'model_name' => $model->model_name,
                    'description' => $model->description,
                    'category' => $model->category,
                    'version' => $model->version,
                    'glb_url' => $model->glb_path ? url(Storage::url($model->glb_path)) : null,
                    'glb_path' => $model->glb_path,
                    'thumbnail_url' => $model->thumbnail_path ? url(Storage::url($model->thumbnail_path)) : null,
                    'thumbnail_path' => $model->thumbnail_path,
                ],
                'hotspots' => $model->hotspots->where('is_active', true)->map(function ($hotspot) {
                    return [
                        'id' => $hotspot->id,
                        'title' => $hotspot->title,
                        'description' => $hotspot->description,
                        'position_x' => $hotspot->position_x ?? 0,
                        'position_y' => $hotspot->position_y ?? 0,
                        'position_z' => $hotspot->position_z ?? 0,
                        'rotation_x' => $hotspot->rotation_x ?? 0,
                        'rotation_y' => $hotspot->rotation_y ?? 0,
                        'rotation_z' => $hotspot->rotation_z ?? 0,
                        'scale' => $hotspot->scale ?? 1.0,
                    ];
                })->values(),
            ],
        ]);
    }

    public function resolveByMarkerId(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'marker_id' => 'required|string|max:100',
        ]);

        $marker = ArMarker::where('marker_id', $validated['marker_id'])
            ->where('status', 'active')
            ->with([
                'models' => function ($q) {
                    $q->where('is_active', true);
                },
            ])
            ->first();

        if (!$marker) {
            return response()->json([
                'success' => false,
                'message' => 'Marker tidak ditemukan',
                'data' => null,
            ], 404);
        }

        $model = $marker->models->first();

        if (!$model) {
            return response()->json([
                'success' => false,
                'message' => 'Marker ditemukan tetapi tidak ada model 3D yang terhubung',
                'data' => [
                    'marker_id' => $marker->marker_id,
                    'ar_uco_id' => $marker->ar_uco_id,
                    'aruco_dictionary' => $marker->aruco_dictionary,
                ],
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Marker berhasil di-resolve',
            'data' => [
                'marker' => [
                    'id' => $marker->id,
                    'marker_id' => $marker->marker_id,
                    'ar_uco_id' => $marker->ar_uco_id,
                    'aruco_dictionary' => $marker->aruco_dictionary,
                    'marker_type' => $marker->marker_type,
                    'status' => $marker->status,
                ],
                'model' => [
                    'id' => $model->id,
                    'model_name' => $model->model_name,
                    'description' => $model->description,
                    'category' => $model->category,
                    'version' => $model->version,
                    'glb_url' => $model->glb_path ? url(Storage::url($model->glb_path)) : null,
                    'glb_path' => $model->glb_path,
                    'thumbnail_url' => $model->thumbnail_path ? url(Storage::url($model->thumbnail_path)) : null,
                    'thumbnail_path' => $model->thumbnail_path,
                ],
                'hotspots' => $model->hotspots->where('is_active', true)->map(function ($hotspot) {
                    return [
                        'id' => $hotspot->id,
                        'title' => $hotspot->title,
                        'description' => $hotspot->description,
                        'position_x' => $hotspot->position_x ?? 0,
                        'position_y' => $hotspot->position_y ?? 0,
                        'position_z' => $hotspot->position_z ?? 0,
                        'rotation_x' => $hotspot->rotation_x ?? 0,
                        'rotation_y' => $hotspot->rotation_y ?? 0,
                        'rotation_z' => $hotspot->rotation_z ?? 0,
                        'scale' => $hotspot->scale ?? 1.0,
                        'sort_order' => $hotspot->sort_order ?? 0,
                    ];
                })->values(),
            ],
        ]);
    }

    public function markers(): JsonResponse
    {
        $markers = ArMarker::where('status', 'active')
            ->with(['models' => function ($q) {
                $q->where('is_active', true);
            }])
            ->orderBy('ar_uco_id')
            ->get()
            ->map(function ($marker) {
                return [
                    'id' => $marker->id,
                    'marker_id' => $marker->marker_id,
                    'ar_uco_id' => $marker->ar_uco_id,
                    'aruco_dictionary' => $marker->aruco_dictionary,
                    'marker_type' => $marker->marker_type,
                    'image_url' => $marker->image_path ? url(Storage::url($marker->image_path)) : null,
                    'image_path' => $marker->image_path,
                    'model_name' => $marker->models->first()?->model_name,
                ];
            });

        return response()->json([
            'success' => true,
            'message' => 'Daftar marker berhasil diambil',
            'data' => $markers,
        ]);
    }
}
