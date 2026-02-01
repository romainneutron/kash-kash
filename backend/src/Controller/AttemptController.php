<?php

namespace App\Controller;

use App\Entity\PathPoint;
use App\Entity\QuestAttempt;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;
use Symfony\Component\Uid\Uuid;

#[Route('/api/attempts')]
#[IsGranted('ROLE_USER')]
class AttemptController extends AbstractController
{
    public function __construct(
        private readonly EntityManagerInterface $entityManager,
    ) {}

    #[Route('/{id}/path', name: 'attempt_add_path_points', methods: ['POST'])]
    public function addPathPoints(string $id, Request $request): JsonResponse
    {
        $attempt = $this->entityManager->find(QuestAttempt::class, Uuid::fromString($id));

        if (!$attempt) {
            return $this->json(['error' => 'Attempt not found'], 404);
        }

        // Verify the attempt belongs to the current user
        if ($attempt->getUser() !== $this->getUser()) {
            return $this->json(['error' => 'Access denied'], 403);
        }

        $data = json_decode($request->getContent(), true);
        $points = $data['points'] ?? [];

        if (empty($points)) {
            return $this->json(['error' => 'No points provided'], 400);
        }

        $added = 0;
        $errors = [];

        foreach ($points as $index => $pointData) {
            try {
                $point = new PathPoint();
                $point->setAttempt($attempt);
                $point->setLatitude((float) $pointData['latitude']);
                $point->setLongitude((float) $pointData['longitude']);
                $point->setAccuracy((float) ($pointData['accuracy'] ?? 0));
                $point->setSpeed((float) ($pointData['speed'] ?? 0));

                if (isset($pointData['timestamp'])) {
                    $point->setTimestamp(new \DateTimeImmutable($pointData['timestamp']));
                }

                $this->entityManager->persist($point);
                $added++;
            } catch (\Exception $e) {
                $errors[] = [
                    'index' => $index,
                    'error' => $e->getMessage(),
                ];
            }
        }

        $this->entityManager->flush();

        return $this->json([
            'added' => $added,
            'errors' => $errors,
        ]);
    }

    #[Route('/{id}/complete', name: 'attempt_complete', methods: ['POST'])]
    public function complete(string $id, Request $request): JsonResponse
    {
        $attempt = $this->entityManager->find(QuestAttempt::class, Uuid::fromString($id));

        if (!$attempt) {
            return $this->json(['error' => 'Attempt not found'], 404);
        }

        if ($attempt->getUser() !== $this->getUser()) {
            return $this->json(['error' => 'Access denied'], 403);
        }

        if ($attempt->getStatus() !== QuestAttempt::STATUS_IN_PROGRESS) {
            return $this->json(['error' => 'Attempt is not in progress'], 400);
        }

        $data = json_decode($request->getContent(), true);

        $attempt->complete();

        if (isset($data['distance_walked'])) {
            $attempt->setDistanceWalked((float) $data['distance_walked']);
        }

        $this->entityManager->flush();

        return $this->json([
            'id' => (string) $attempt->getId(),
            'status' => $attempt->getStatus(),
            'completed_at' => $attempt->getCompletedAt()?->format('c'),
            'duration_seconds' => $attempt->getDurationSeconds(),
            'distance_walked' => $attempt->getDistanceWalked(),
        ]);
    }

    #[Route('/{id}/abandon', name: 'attempt_abandon', methods: ['POST'])]
    public function abandon(string $id): JsonResponse
    {
        $attempt = $this->entityManager->find(QuestAttempt::class, Uuid::fromString($id));

        if (!$attempt) {
            return $this->json(['error' => 'Attempt not found'], 404);
        }

        if ($attempt->getUser() !== $this->getUser()) {
            return $this->json(['error' => 'Access denied'], 403);
        }

        if ($attempt->getStatus() !== QuestAttempt::STATUS_IN_PROGRESS) {
            return $this->json(['error' => 'Attempt is not in progress'], 400);
        }

        $attempt->abandon();
        $this->entityManager->flush();

        return $this->json([
            'id' => (string) $attempt->getId(),
            'status' => $attempt->getStatus(),
            'abandoned_at' => $attempt->getAbandonedAt()?->format('c'),
            'duration_seconds' => $attempt->getDurationSeconds(),
        ]);
    }
}
