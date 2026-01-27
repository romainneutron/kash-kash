<?php

namespace App\Controller;

use App\Entity\RefreshToken;
use App\Entity\User;
use App\Repository\RefreshTokenRepository;
use App\Repository\UserRepository;
use KnpU\OAuth2ClientBundle\Client\ClientRegistry;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/auth')]
class AuthController extends AbstractController
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly RefreshTokenRepository $refreshTokenRepository,
        private readonly JWTTokenManagerInterface $jwtManager,
    ) {}

    #[Route('/google', name: 'connect_google', methods: ['GET'])]
    public function connectGoogle(ClientRegistry $clientRegistry): RedirectResponse
    {
        return $clientRegistry->getClient('google')->redirect(['email', 'profile']);
    }

    #[Route('/google/callback', name: 'connect_google_check', methods: ['GET'])]
    public function connectGoogleCheck(ClientRegistry $clientRegistry): JsonResponse
    {
        $client = $clientRegistry->getClient('google');

        try {
            /** @var \League\OAuth2\Client\Provider\GoogleUser $googleUser */
            $googleUser = $client->fetchUser();
        } catch (\Exception $e) {
            return $this->json(['error' => 'Failed to authenticate with Google'], 400);
        }

        $user = $this->userRepository->findOneByGoogleId($googleUser->getId());

        if (!$user) {
            $user = $this->userRepository->findOneByEmail($googleUser->getEmail());
        }

        if (!$user) {
            $user = new User();
            $user->setEmail($googleUser->getEmail());
            $user->setDisplayName($googleUser->getName() ?? $googleUser->getEmail());
            $user->setAvatarUrl($googleUser->getAvatar());
            $user->setGoogleId($googleUser->getId());
            $this->userRepository->save($user, true);
        } elseif (!$user->getGoogleId()) {
            $user->setGoogleId($googleUser->getId());
            $user->setUpdatedAt(new \DateTimeImmutable());
            $this->userRepository->save($user, true);
        }

        return $this->issueTokens($user);
    }

    #[Route('/token/refresh', name: 'token_refresh', methods: ['POST'])]
    public function refreshToken(Request $request): JsonResponse
    {
        $data = json_decode($request->getContent(), true);
        $refreshTokenValue = $data['refresh_token'] ?? null;

        if (!$refreshTokenValue) {
            return $this->json(['error' => 'Refresh token is required'], 400);
        }

        $refreshToken = $this->refreshTokenRepository->findValidToken($refreshTokenValue);

        if (!$refreshToken) {
            return $this->json(['error' => 'Invalid or expired refresh token'], 401);
        }

        $user = $refreshToken->getUser();

        $this->refreshTokenRepository->getEntityManager()->remove($refreshToken);
        $this->refreshTokenRepository->getEntityManager()->flush();

        return $this->issueTokens($user);
    }

    #[Route('/me', name: 'get_current_user', methods: ['GET'])]
    public function me(): JsonResponse
    {
        /** @var User|null $user */
        $user = $this->getUser();

        if (!$user) {
            return $this->json(['error' => 'Not authenticated'], 401);
        }

        return $this->json($this->serializeUser($user));
    }

    #[Route('/logout', name: 'auth_logout', methods: ['POST'])]
    public function logout(): JsonResponse
    {
        /** @var User|null $user */
        $user = $this->getUser();

        if ($user) {
            $this->refreshTokenRepository->revokeAllForUser($user);
        }

        return $this->json(['message' => 'Logged out successfully']);
    }

    private function issueTokens(User $user): JsonResponse
    {
        $accessToken = $this->jwtManager->create($user);
        $refreshToken = new RefreshToken($user);
        $this->refreshTokenRepository->save($refreshToken, true);

        return $this->json([
            'token' => $accessToken,
            'refresh_token' => $refreshToken->getToken(),
            'user' => $this->serializeUser($user),
        ]);
    }

    private function serializeUser(User $user): array
    {
        return [
            'id' => (string) $user->getId(),
            'email' => $user->getEmail(),
            'displayName' => $user->getDisplayName(),
            'avatarUrl' => $user->getAvatarUrl(),
            'role' => $user->getRoles()[0] ?? 'ROLE_USER',
        ];
    }
}
