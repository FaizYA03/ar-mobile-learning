<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class CorsMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        $allowedOrigins = array_map('trim', explode(',', env('CORS_ALLOWED_ORIGINS', '*')));

        $origin = $request->headers->get('Origin', '*');
        $allowedOrigin = in_array($origin, $allowedOrigins) || in_array('*', $allowedOrigins)
            ? $origin
            : ($allowedOrigins[0] ?? '*');

        $response->headers->set('Access-Control-Allow-Origin', $allowedOrigin);
        $response->headers->set('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
        $response->headers->set('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept');
        $response->headers->set('Access-Control-Allow-Credentials', 'true');

        if ($request->isMethod('OPTIONS')) {
            $response->setStatusCode(200);
        }

        return $response;
    }
}