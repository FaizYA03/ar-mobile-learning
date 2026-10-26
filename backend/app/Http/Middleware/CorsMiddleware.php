<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CorsMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $allowedOrigins = config('cors.allowed_origins', ['*']);
        $isWildcard = in_array('*', $allowedOrigins, true);
        $origin = $request->headers->get('Origin');

        // Preflight: jawab langsung tanpa meneruskan ke aplikasi.
        if ($request->isMethod('OPTIONS')) {
            $response = response('', 204);
        } else {
            $response = $next($request);
        }

        if ($isWildcard) {
            // Spec CORS: '*' tidak boleh dikombinasikan dengan credentials.
            $response->headers->set('Access-Control-Allow-Origin', '*');
            $response->headers->remove('Access-Control-Allow-Credentials');
        } else {
            // Vary harus selalu ada agar cache tidak menyajikan respons origin lain.
            $response->headers->set('Vary', 'Origin', false);

            if ($origin && in_array($origin, $allowedOrigins, true)) {
                $response->headers->set('Access-Control-Allow-Origin', $origin);
                $response->headers->set('Access-Control-Allow-Credentials', 'true');
            }
        }

        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
        $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept');

        return $response;
    }
}
