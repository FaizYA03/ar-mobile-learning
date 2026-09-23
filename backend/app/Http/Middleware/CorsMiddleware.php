<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CorsMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $allowedOrigins = array_map('trim', explode(',', env('CORS_ALLOWED_ORIGINS', '*')));
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
            $allowedOrigin = ($origin && in_array($origin, $allowedOrigins, true))
                ? $origin
                : ($allowedOrigins[0] ?? '');
            if ($allowedOrigin !== '') {
                $response->headers->set('Access-Control-Allow-Origin', $allowedOrigin);
                $response->headers->set('Access-Control-Allow-Credentials', 'true');
                $response->headers->set('Vary', 'Origin');
            }
        }

        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
        $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept');

        return $response;
    }
}