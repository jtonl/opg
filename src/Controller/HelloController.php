<?php

namespace App\Controller;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Annotation\Route;

class HelloController
{
    #[Route('/hello', name: 'hello', methods: ['GET'])]
    public function hello(Request $request): JsonResponse
    {
        $name = $request->query->get('name', 'World');
        
        return new JsonResponse([
            'message' => "Hello, {$name}!",
            'timestamp' => date('c'),
            'method' => $request->getMethod(),
            'path' => $request->getPathInfo()
        ]);
    }

    #[Route('/api/status', name: 'status', methods: ['GET'])]
    public function status(): JsonResponse
    {
        return new JsonResponse([
            'status' => 'healthy',
            'service' => 'symfony-opa-api',
            'version' => '1.0.0'
        ]);
    }
}