<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ArHotspot;
use App\Models\ArModel;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ArHotspotController extends Controller
{
    public function index(Request $request)
    {
        $query = ArHotspot::with('arModel:id,model_name');

        if ($request->filled('search')) {
            $query->where('title', 'like', "%{$request->search}%");
        }

        $hotspots = $query->orderByDesc('created_at')->paginate(15)->withQueryString();
        return view('admin.ar.hotspots', compact('hotspots'));
    }

    public function create()
    {
        $models = ArModel::orderBy('model_name')->get();
        return view('admin.ar.create-hotspot', compact('models'));
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'ar_model_id' => 'required|exists:ar_models,id',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'image_path' => 'nullable|image|max:5120',
            'is_active' => 'nullable|boolean',
        ]);

        if ($request->hasFile('image_path')) {
            $imageFile = $request->file('image_path');
            $stored = $imageFile->storeAs(
                'hotspots',
                Str::uuid() . '.' . $imageFile->getClientOriginalExtension(),
                'public'
            );
            $validated['image_path'] = $stored ? $stored : '';
        }

        $validated['is_active'] = $validated['is_active'] ?? true;

        $hotspot = ArHotspot::create($validated);

        \App\Services\ActivityLogger::created('ar_hotspot', $hotspot->id, "AR hotspot '{$hotspot->title}' created via admin");

        return redirect()->route('admin.ar.hotspots.index')->with('success', 'AR hotspot berhasil ditambahkan.');
    }

    public function edit(ArHotspot $hotspot)
    {
        $models = ArModel::orderBy('model_name')->get();
        return view('admin.ar.edit-hotspot', ['hotspot' => $hotspot, 'models' => $models]);
    }

    public function update(Request $request, ArHotspot $hotspot)
    {
        $validated = $request->validate([
            'ar_model_id' => 'sometimes|required|exists:ar_models,id',
            'title' => 'sometimes|required|string|max:255',
            'description' => 'nullable|string',
            'latitude' => 'nullable|numeric',
            'longitude' => 'nullable|numeric',
            'image_path' => 'sometimes|image|mimes:jpg,jpeg,png,webp|max:5120',
            'is_active' => 'nullable|boolean',
        ]);

        if ($request->hasFile('image_path')) {
            if ($hotspot->image_path) {
                Storage::disk('public')->delete($hotspot->image_path);
            }
            $imageFile = $request->file('image_path');
            $stored = $imageFile->storeAs(
                'hotspots',
                Str::uuid() . '.' . $imageFile->getClientOriginalExtension(),
                'public'
            );
            $validated['image_path'] = $stored ? $stored : '';
        }

        $hotspot->update($validated);

        \App\Services\ActivityLogger::updated('ar_hotspot', $hotspot->id, "AR hotspot '{$hotspot->title}' updated via admin");

        return redirect()->route('admin.ar.hotspots.index')->with('success', 'AR hotspot berhasil diperbarui.');
    }

    public function destroy(ArHotspot $hotspot)
    {
        if ($hotspot->image_path) {
            Storage::disk('public')->delete($hotspot->image_path);
        }

        \App\Services\ActivityLogger::deleted('ar_hotspot', $hotspot->id, "AR hotspot '{$hotspot->title}' deleted via admin");

        $hotspot->delete();

        return redirect()->route('admin.ar.hotspots.index')->with('success', 'AR hotspot berhasil dihapus.');
    }
}
