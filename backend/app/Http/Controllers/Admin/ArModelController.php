<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ArModel;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ArModelController extends Controller
{
    public function index(Request $request)
    {
        $query = ArModel::withCount('hotspots', 'markers');

        if ($request->filled('search')) {
            $query->where('model_name', 'like', "%{$request->search}%");
        }

        if ($request->filled('status')) {
            $query->where('is_active', $request->status === 'active');
        }

        $models = $query->orderByDesc('created_at')->paginate(15)->withQueryString();
        return view('admin.ar.models', compact('models'));
    }

    public function create()
    {
        return view('admin.ar.create-model');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'model_name' => 'required|string|max:255',
            'glb_path' => 'required|max:102400',
            'thumbnail_path' => 'nullable|image|max:5120',
            'description' => 'nullable|string',
            'category' => 'nullable|string|max:100',
            'is_active' => 'nullable|boolean',
        ]);

        if ($request->hasFile('glb_path')) {
            $glbFile = $request->file('glb_path');
            $stored = $glbFile->storeAs(
                'models',
                Str::uuid() . '.' . $glbFile->getClientOriginalExtension(),
                'public'
            );
            $validated['glb_path'] = $stored ? $stored : '';
        }

        if ($request->hasFile('thumbnail_path')) {
            $thumbFile = $request->file('thumbnail_path');
            $stored = $thumbFile->storeAs(
                'thumbnails',
                Str::uuid() . '.' . $thumbFile->getClientOriginalExtension(),
                'public'
            );
            $validated['thumbnail_path'] = $stored ? $stored : '';
        }

        $validated['is_active'] = $validated['is_active'] ?? true;
        $validated['version'] = 1;

        $model = ArModel::create($validated);

        \App\Services\ActivityLogger::uploaded('ar_model', $model->id, $validated['glb_path'] ?? '', "AR model '{$model->model_name}' uploaded via admin");

        return redirect()->route('admin.ar.models.index')->with('success', 'AR model berhasil ditambahkan.');
    }

    public function edit(ArModel $model)
    {
        return view('admin.ar.edit-model', ['model' => $model]);
    }

    public function update(Request $request, ArModel $model)
    {
        $validated = $request->validate([
            'model_name' => 'sometimes|required|string|max:255',
            'glb_path' => 'sometimes|max:102400',
            'thumbnail_path' => 'sometimes|image|max:5120',
            'description' => 'nullable|string',
            'category' => 'nullable|string|max:100',
            'is_active' => 'nullable|boolean',
        ]);

        if ($request->hasFile('glb_path')) {
            if ($model->glb_path) {
                Storage::disk('public')->delete($model->glb_path);
            }
            $glbFile = $request->file('glb_path');
            $stored = $glbFile->storeAs(
                'models',
                Str::uuid() . '.' . $glbFile->getClientOriginalExtension(),
                'public'
            );
            $validated['glb_path'] = $stored ? $stored : '';
            $validated['version'] = $model->version + 1;
        }

        if ($request->hasFile('thumbnail_path')) {
            if ($model->thumbnail_path) {
                Storage::disk('public')->delete($model->thumbnail_path);
            }
            $thumbFile = $request->file('thumbnail_path');
            $stored = $thumbFile->storeAs(
                'thumbnails',
                Str::uuid() . '.' . $thumbFile->getClientOriginalExtension(),
                'public'
            );
            $validated['thumbnail_path'] = $stored ? $stored : '';
        }

        $model->update($validated);

        \App\Services\ActivityLogger::updated('ar_model', $model->id, "AR model '{$model->model_name}' updated via admin (version: {$model->version})");

        return redirect()->route('admin.ar.models.index')->with('success', 'AR model berhasil diperbarui.');
    }

    public function destroy(ArModel $model)
    {
        if ($model->glb_path) {
            Storage::disk('public')->delete($model->glb_path);
        }
        if ($model->thumbnail_path) {
            Storage::disk('public')->delete($model->thumbnail_path);
        }
        $model->markers()->detach();

        \App\Services\ActivityLogger::deleted('ar_model', $model->id, "AR model '{$model->model_name}' deleted via admin");

        $model->delete();

        return redirect()->route('admin.ar.models.index')->with('success', 'AR model berhasil dihapus.');
    }
}
