<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ArMarker;
use App\Services\ArMarkerGenerator;
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

    /**
     * Form generate marker ArUco otomatis (tanpa upload file).
     */
    public function showGenerate()
    {
        $dictionaries = ArMarkerGenerator::DICTIONARIES;
        $usedIds = ArMarker::whereNotNull('aruco_dictionary')
            ->whereNotNull('ar_uco_id')
            ->get(['aruco_dictionary', 'ar_uco_id'])
            ->groupBy('aruco_dictionary')
            ->map(fn ($rows) => $rows->pluck('ar_uco_id')->all())
            ->all();
        $available = ArMarkerGenerator::isAvailable();

        return view('admin.ar.generate-marker', compact('dictionaries', 'usedIds', 'available'));
    }

    /**
     * Generate PNG via OpenCV lalu buat record marker.
     */
    public function generate(Request $request)
    {
        $validated = $request->validate([
            'marker_id' => 'required|string|max:100|unique:ar_markers,marker_id',
            'aruco_dictionary' => 'required|string|in:' . implode(',', array_keys(ArMarkerGenerator::DICTIONARIES)),
            'ar_uco_id' => 'required|integer|min:0',
            'status' => 'nullable|string|in:active,inactive',
        ]);

        $max = ArMarkerGenerator::maxId($validated['aruco_dictionary']);
        if ($validated['ar_uco_id'] > $max) {
            return back()->withErrors(['ar_uco_id' => "ID maksimal untuk {$validated['aruco_dictionary']} adalah {$max}."])->withInput();
        }

        if (ArMarkerGenerator::comboExists($validated['aruco_dictionary'], (int) $validated['ar_uco_id'])) {
            return back()->withErrors(['ar_uco_id' => "ID {$validated['ar_uco_id']} pada {$validated['aruco_dictionary']} sudah dipakai marker lain."])->withInput();
        }

        try {
            $path = ArMarkerGenerator::generate(
                $validated['aruco_dictionary'],
                (int) $validated['ar_uco_id']
            );
        } catch (\RuntimeException $e) {
            return back()->withErrors(['ar_uco_id' => $e->getMessage()])->withInput();
        }

        $marker = ArMarker::create([
            'marker_id' => $validated['marker_id'],
            'marker_type' => 'pattern',
            'image_path' => $path,
            'aruco_dictionary' => $validated['aruco_dictionary'],
            'ar_uco_id' => $validated['ar_uco_id'],
            'status' => $validated['status'] ?? 'active',
        ]);

        \App\Services\ActivityLogger::uploaded('ar_marker', $marker->id, $path, "AR marker '{$marker->marker_id}' digenerate via admin");

        return redirect()->route('admin.ar.markers.index')->with('success', "Marker {$marker->marker_id} berhasil digenerate.");
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'marker_id' => 'required|string|max:100|unique:ar_markers,marker_id',
            'marker_type' => 'required|string|in:pattern,image',
            'image_path' => 'required|image|max:10240',
            'aruco_dictionary' => 'nullable|string|in:' . implode(',', array_keys(ArMarkerGenerator::DICTIONARIES)),
            'ar_uco_id' => 'nullable|integer|min:0',
            'status' => 'nullable|string|in:active,inactive',
        ]);

        if ($error = ArMarkerGenerator::pairError($validated['aruco_dictionary'] ?? null, $validated['ar_uco_id'] ?? null)) {
            return back()->withErrors(['ar_uco_id' => $error])->withInput();
        }
        if (!empty($validated['aruco_dictionary']) && ArMarkerGenerator::comboExists($validated['aruco_dictionary'], (int) $validated['ar_uco_id'])) {
            return back()->withErrors(['ar_uco_id' => "ID {$validated['ar_uco_id']} pada {$validated['aruco_dictionary']} sudah dipakai marker lain."])->withInput();
        }

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
            'image_path' => 'sometimes|image|mimes:jpg,jpeg,png,webp|max:10240',
            'aruco_dictionary' => 'nullable|string|in:' . implode(',', array_keys(ArMarkerGenerator::DICTIONARIES)),
            'ar_uco_id' => 'nullable|integer|min:0',
            'status' => 'nullable|string|in:active,inactive',
        ]);

        $dictionary = array_key_exists('aruco_dictionary', $validated) ? $validated['aruco_dictionary'] : $marker->aruco_dictionary;
        $arucoId = array_key_exists('ar_uco_id', $validated) ? $validated['ar_uco_id'] : $marker->ar_uco_id;
        if ($error = ArMarkerGenerator::pairError($dictionary, $arucoId)) {
            return back()->withErrors(['ar_uco_id' => $error])->withInput();
        }
        if (!empty($dictionary) && ArMarkerGenerator::comboExists($dictionary, (int) $arucoId, $marker->id)) {
            return back()->withErrors(['ar_uco_id' => "ID {$arucoId} pada {$dictionary} sudah dipakai marker lain."])->withInput();
        }
        $validated['aruco_dictionary'] = $dictionary;
        $validated['ar_uco_id'] = $arucoId;

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
