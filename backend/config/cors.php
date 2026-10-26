<?php

$origins = array_filter(array_map(
    'trim',
    explode(',', (string) env('CORS_ALLOWED_ORIGINS', '*'))
));

return [
    'allowed_origins' => $origins === [] ? ['*'] : array_values($origins),
];
