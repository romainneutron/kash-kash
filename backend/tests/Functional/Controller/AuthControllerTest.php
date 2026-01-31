<?php

namespace App\Tests\Functional\Controller;

use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

/**
 * AuthController functional tests.
 *
 * Note: These tests require a database connection and the full Symfony kernel.
 * Run with: make backend-test (requires Docker)
 *
 * @group functional
 */
class AuthControllerTest extends WebTestCase
{
    public function testGoogleConnectRedirects(): void
    {
        $client = static::createClient();

        $client->request('GET', '/auth/google');

        // Should redirect to Google OAuth
        $this->assertResponseRedirects();
    }

    public function testTokenRefreshReturnsErrorWhenNoToken(): void
    {
        $client = static::createClient();

        $client->request(
            'POST',
            '/auth/token/refresh',
            [],
            [],
            ['CONTENT_TYPE' => 'application/json'],
            json_encode([])
        );

        $this->assertResponseStatusCodeSame(400);

        $response = json_decode($client->getResponse()->getContent(), true);
        $this->assertArrayHasKey('error', $response);
        $this->assertEquals('Refresh token is required', $response['error']);
    }

    public function testTokenRefreshReturnsErrorForInvalidToken(): void
    {
        $client = static::createClient();

        $client->request(
            'POST',
            '/auth/token/refresh',
            [],
            [],
            ['CONTENT_TYPE' => 'application/json'],
            json_encode(['refresh_token' => 'invalid-token'])
        );

        $this->assertResponseStatusCodeSame(401);

        $response = json_decode($client->getResponse()->getContent(), true);
        $this->assertArrayHasKey('error', $response);
        $this->assertEquals('Invalid or expired refresh token', $response['error']);
    }

    public function testMeReturnsUnauthorizedWhenNotAuthenticated(): void
    {
        $client = static::createClient();

        $client->request('GET', '/auth/me');

        // JWT firewall intercepts and returns 401 before reaching controller
        $this->assertResponseStatusCodeSame(401);

        $response = json_decode($client->getResponse()->getContent(), true);
        // JWT bundle returns different error format
        $this->assertArrayHasKey('message', $response);
        $this->assertEquals('JWT Token not found', $response['message']);
    }

    public function testLogoutReturnsUnauthorizedWithoutToken(): void
    {
        $client = static::createClient();

        $client->request('POST', '/auth/logout');

        // JWT firewall intercepts and returns 401 before reaching controller
        $this->assertResponseStatusCodeSame(401);

        $response = json_decode($client->getResponse()->getContent(), true);
        $this->assertArrayHasKey('message', $response);
        $this->assertEquals('JWT Token not found', $response['message']);
    }
}
