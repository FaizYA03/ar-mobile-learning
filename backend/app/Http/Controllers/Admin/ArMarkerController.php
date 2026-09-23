<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ArMarker;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ArMarkerController extends Controller
{
    public function index(Request $request)
    {
        $query = ArMarker::withCount('models');

        if ($request->filled('search')) {
            $query->where('marker_id', 'like', "%{$request->search}%");
        }

        $markers = $query->orderByDesc('created_at')->paginate(15)->withQueryString();
        return view('admin.ar.markers', compact('markers'));
    }

    public function create()
    {
        return view('admin.ar.create-marker');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'marker_id' => 'required|string|max:100|unique:ar_markers,marker_id',
            'marker_type' => 'required|string|in:pattern,image',
            'image_path' => 'required|image|max:10240',
            'status' => 'nullable|string|in:active,inactive',
        ]);

        if ($request->hasFile('image_path')) {
            $imageFile = $request->file('image_path');
            $stored = $imageFile->storeAs(
                'markers',
                Str::uuid() . '.' . $imageFile->getClientOriginalExtension(),
                'public'
            );
            $validated['image_path'] = $stored ? $stored : '';
        }

        $validated['status'] = $validated['status'] ?? 'active';

        $marker = ArMarker::create($validated);

        \App\Services\ActivityLogger::uploaded('ar_marker', $marker->id, $validated['image_path'] ?? '', "AR marker '{$marker->marker_id}' uploaded via admin");

        return redirect()->route('admin.ar.markers.index')->with('success', 'AR marker berhasil ditambahkan.');
    }

    public function edit(ArMarker $marker)
    {
        return view('admin.ar.edit-marker', ['marker' => $marker]);
    }

    public function update(Request $request, ArMarker $marker)
    {
        $validated = $request->validate([
            'marker_id' => 'sometimes|required|string|max:100|unique:ar_markers,marker_id,' . $marker->id,
            'marker_type' => 'sometimes|required|string|in:pattern,image',
            'image_path' => 'sometimes|max:10240',
            'status' => 'nullable|string|in:active,inactive',
        ]);

        if ($request->hasFile('image_path')) {
            if ($marker->image_path) {
                Storage::disk('public')->delete($marker->image_path);
            }
            $imageFile = $request->file('image_path');
            $stored = $imageFile->storeAs(
                'markers',
                Str::uuid() . '.' . $imageFile->getClientOriginalExtension(),
                'public'
            );
            $validated['image_path'] = $stored ? $stored : '';
        }

        $marker->update($validated);

        \App\Services\ActivityLogger::updated('ar_marker', $marker->id, "AR marker '{$marker->marker_id}' updated via admin");

        return redirect()->route('admin.ar.markers.index')->with('success', 'AR marker berhasil diperbarui.');
    }

    public function destroy(ArMarker $marker)
    {
        if ($marker->image_path) {
            Storage::disk('public')->delete($marker->image_path);
        }
        $marker->models()->detach();

        \App\Services\ActivityLogger::deleted('ar_marker', $marker->id, "AR marker '{$marker->marker_id}' deleted via admin");

        $marker->delete();

        return redirect()->route('admin.ar.markers.index')->with('success', 'AR marker berhasil dihapus.');
    }
}
