<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ArMarker;
use App\Models\ArMarker3dMapping;
use App\Models\ArModel;
use Illuminate\Http\Request;

class ArMappingController extends Controller
{
    public function index(Request $request)
    {
        $query = ArMarker3dMapping::with(['arMarker:id,marker_id', 'arModel:id,model_name']);

        if ($request->filled('search')) {
            $query->whereHas('arMarker', function ($q) use ($request) {
                $q->where('marker_id', 'like', "%{$request->search}%");
            })->orWhereHas('arModel', function ($q) use ($request) {
                $q->where('model_name', 'like', "%{$request->search}%");
            });
        }

        $mappings = $query->orderByDesc('created_at')->paginate(15)->withQueryString();
        return view('admin.ar.mappings', compact('mappings'));
    }

    public function create()
    {
        $markers = ArMarker::orderBy('marker_id')->get();
        $models = ArModel::where('is_active', true)->orderBy('model_name')->get();
        return view('admin.ar.create-mapping', compact('markers', 'models'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'ar_marker_id' => 'required|exists:ar_markers,id',
            'ar_model_id' => 'required|exists:ar_models,id',
            'mapping_method' => 'required|string|in:image_tracking,marker_id',
            'mapping_status' => 'required|string|in:pending,mapped,failed',
            'mapping_notes' => 'nullable|string',
        ]);

        $exists = ArMarker3dMapping::where('ar_marker_id', $validated['ar_marker_id'])
            ->where('ar_model_id', $validated['ar_model_id'])
            ->exists();

        if ($exists) {
            return back()->withErrors(['ar_model_id' => 'Mapping ini sudah ada.'])->withInput();
        }

        $mapping = ArMarker3dMapping::create($validated);

        \App\Services\ActivityLogger::created('ar_mapping', $mapping->id, "AR mapping created via admin");

        return redirect()->route('admin.ar.mappings.index')->with('success', 'Mapping berhasil dibuat.');
    }

    public function edit(ArMarker3dMapping $mapping)
    {
        $markers = ArMarker::orderBy('marker_id')->get();
        $models = ArModel::where('is_active', true)->orderBy('model_name')->get();
        return view('admin.ar.edit-mapping', ['mapping' => $mapping, 'markers' => $markers, 'models' => $models]);
    }

    public function update(Request $request, ArMarker3dMapping $mapping)
    {
        $validated = $request->validate([
            'mapping_method' => 'sometimes|required|string|in:image_tracking,marker_id',
            'mapping_status' => 'sometimes|required|string|in:pending,mapped,failed',
            'mapping_notes' => 'nullable|string',
        ]);

        $mapping->update($validated);

        \App\Services\ActivityLogger::updated('ar_mapping', $mapping->id, "AR mapping updated via admin");

        return redirect()->route('admin.ar.mappings.index')->with('success', 'Mapping berhasil diperbarui.');
    }

    public function destroy(ArMarker3dMapping $mapping)
    {
        \App\Services\ActivityLogger::deleted('ar_mapping', $mapping->id, "AR mapping deleted via admin");
        $mapping->delete();

        return redirect()->route('admin.ar.mappings.index')->with('success', 'Mapping berhasil dihapus.');
    }
}
