<?php

namespace App\Entity;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use ApiPlatform\Metadata\Put;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'quest_attempts')]
#[ApiResource(
    operations: [
        new Get(security: "is_granted('ROLE_USER') and object.getUser() == user"),
        new GetCollection(security: "is_granted('ROLE_USER')"),
        new Post(security: "is_granted('ROLE_USER')"),
        new Put(security: "is_granted('ROLE_USER') and object.getUser() == user"),
    ]
)]
class QuestAttempt
{
    public const STATUS_IN_PROGRESS = 'in_progress';
    public const STATUS_COMPLETED = 'completed';
    public const STATUS_ABANDONED = 'abandoned';

    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne(targetEntity: Quest::class, inversedBy: 'attempts')]
    #[ORM\JoinColumn(nullable: false)]
    private Quest $quest;

    #[ORM\ManyToOne(targetEntity: User::class, inversedBy: 'attempts')]
    #[ORM\JoinColumn(nullable: false)]
    private User $user;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    private \DateTimeImmutable $startedAt;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE, nullable: true)]
    private ?\DateTimeImmutable $completedAt = null;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE, nullable: true)]
    private ?\DateTimeImmutable $abandonedAt = null;

    #[ORM\Column(length: 20)]
    private string $status = self::STATUS_IN_PROGRESS;

    #[ORM\Column(type: Types::INTEGER, nullable: true)]
    private ?int $durationSeconds = null;

    #[ORM\Column(type: Types::FLOAT, nullable: true)]
    private ?float $distanceWalked = null;

    #[ORM\OneToMany(targetEntity: PathPoint::class, mappedBy: 'attempt', cascade: ['persist', 'remove'])]
    private Collection $pathPoints;

    public function __construct()
    {
        $this->id = Uuid::v4();
        $this->startedAt = new \DateTimeImmutable();
        $this->pathPoints = new ArrayCollection();
    }

    public function getId(): Uuid
    {
        return $this->id;
    }

    public function getQuest(): Quest
    {
        return $this->quest;
    }

    public function setQuest(Quest $quest): static
    {
        $this->quest = $quest;
        return $this;
    }

    public function getUser(): User
    {
        return $this->user;
    }

    public function setUser(User $user): static
    {
        $this->user = $user;
        return $this;
    }

    public function getStartedAt(): \DateTimeImmutable
    {
        return $this->startedAt;
    }

    public function getCompletedAt(): ?\DateTimeImmutable
    {
        return $this->completedAt;
    }

    public function setCompletedAt(?\DateTimeImmutable $completedAt): static
    {
        $this->completedAt = $completedAt;
        return $this;
    }

    public function getAbandonedAt(): ?\DateTimeImmutable
    {
        return $this->abandonedAt;
    }

    public function setAbandonedAt(?\DateTimeImmutable $abandonedAt): static
    {
        $this->abandonedAt = $abandonedAt;
        return $this;
    }

    public function getStatus(): string
    {
        return $this->status;
    }

    public function setStatus(string $status): static
    {
        $this->status = $status;
        return $this;
    }

    public function getDurationSeconds(): ?int
    {
        return $this->durationSeconds;
    }

    public function setDurationSeconds(?int $durationSeconds): static
    {
        $this->durationSeconds = $durationSeconds;
        return $this;
    }

    public function getDistanceWalked(): ?float
    {
        return $this->distanceWalked;
    }

    public function setDistanceWalked(?float $distanceWalked): static
    {
        $this->distanceWalked = $distanceWalked;
        return $this;
    }

    public function getPathPoints(): Collection
    {
        return $this->pathPoints;
    }

    public function addPathPoint(PathPoint $pathPoint): static
    {
        if (!$this->pathPoints->contains($pathPoint)) {
            $this->pathPoints->add($pathPoint);
            $pathPoint->setAttempt($this);
        }
        return $this;
    }

    public function complete(): void
    {
        $this->status = self::STATUS_COMPLETED;
        $this->completedAt = new \DateTimeImmutable();
        $this->durationSeconds = $this->completedAt->getTimestamp() - $this->startedAt->getTimestamp();
    }

    public function abandon(): void
    {
        $this->status = self::STATUS_ABANDONED;
        $this->abandonedAt = new \DateTimeImmutable();
        $this->durationSeconds = $this->abandonedAt->getTimestamp() - $this->startedAt->getTimestamp();
    }
}
