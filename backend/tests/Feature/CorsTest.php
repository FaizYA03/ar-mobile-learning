<?php

namespace Tests\Feature;

use Tests\TestCase;

class CorsTest extends TestCase
{
    public function test_allowed_origin_is_reflected_with_credentials(): void
    {
        config(['cors.allowed_origins' => ['https://app.example']]);

        $this->call('OPTIONS', '/api/v1/login', server: [
            'HTTP_ORIGIN' => 'https://app.example',
        ])
            ->assertStatus(204)
            ->assertHeader('Access-Control-Allow-Origin', 'https://app.example')
            ->assertHeader('Access-Control-Allow-Credentials', 'true')
            ->assertHeader('Vary', 'Origin');
    }

    public function test_disallowed_origin_does_not_receive_allow_origin_header(): void
    {
        config(['cors.allowed_origins' => ['https://app.example']]);

        $this->call('OPTIONS', '/api/v1/login', server: [
            'HTTP_ORIGIN' => 'https://evil.example',
        ])
            ->assertStatus(204)
            ->assertHeaderMissing('Access-Control-Allow-Origin')
            ->assertHeader('Vary', 'Origin');
    }

    public function test_wildcard_origin_never_uses_credentials(): void
    {
        config(['cors.allowed_origins' => ['*']]);

        $this->call('OPTIONS', '/api/v1/login', server: [
            'HTTP_ORIGIN' => 'https://any.example',
        ])
            ->assertStatus(204)
            ->assertHeader('Access-Control-Allow-Origin', '*')
            ->assertHeaderMissing('Access-Control-Allow-Credentials');
    }
}
