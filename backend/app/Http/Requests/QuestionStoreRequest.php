<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;

class QuestionStoreRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'text' => 'required|string|max:1000',
            'options' => 'required|array|min:2|max:10',
            'options.*.text' => 'required|string|max:500',
            'options.*.is_correct' => 'required|boolean',
        ];
    }

    /**
     * Setiap soal harus punya tepat satu kunci jawaban, sehingga skor siswa
     * selalu bisa mencapai 100 (penilaian = benar / total soal).
     */
    public function after(): array
    {
        return [
            function (Validator $validator) {
                if ($validator->errors()->isNotEmpty()) {
                    return;
                }

                $options = $this->input('options');

                if (! is_array($options)) {
                    return;
                }

                $correctCount = collect($options)
                    ->filter(fn ($option) => is_array($option) && (bool) ($option['is_correct'] ?? false))
                    ->count();

                if ($correctCount !== 1) {
                    $validator->errors()->add(
                        'options',
                        'Pilih tepat satu opsi sebagai jawaban benar.'
                    );
                }
            },
        ];
    }

    public function messages(): array
    {
        return [
            'text.required' => 'Soal wajib diisi',
            'text.max' => 'Soal maksimal 1000 karakter',
            'options.required' => 'Opsi jawaban wajib diisi',
            'options.min' => 'Minimal 2 opsi jawaban',
            'options.max' => 'Maksimal 10 opsi jawaban',
            'options.*.text.required' => 'Teks opsi wajib diisi',
            'options.*.text.max' => 'Teks opsi maksimal 500 karakter',
            'options.*.is_correct.required' => 'Pilihan jawaban benar wajib ditentukan',
        ];
    }
}
