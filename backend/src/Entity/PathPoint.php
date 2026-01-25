<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Uid\Uuid;

#[ORM\Entity]
#[ORM\Table(name: 'path_points')]
class PathPoint
{
    #[ORM\Id]
    #[ORM\Column(type: 'uuid', unique: true)]
    private Uuid $id;

    #[ORM\ManyToOne(targetEntity: QuestAttempt::class, inversedBy: 'pathPoints')]
    #[ORM\JoinColumn(nullable: false)]
    private QuestAttempt $attempt;

    #[ORM\Column(type: Types::FLOAT)]
    private float $latitude;

    #[ORM\Column(type: Types::FLOAT)]
    private float $longitude;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    private \DateTimeImmutable $timestamp;

    #[ORM\Column(type: Types::FLOAT)]
    private float $accuracy;

    #[ORM\Column(type: Types::FLOAT)]
    private float $speed;

    public function __construct()
    {
        $this->id = Uuid::v4();
        $this->timestamp = new \DateTimeImmutable();
    }

    public function getId(): Uuid
    {
        return $this->id;
    }

    public function getAttempt(): QuestAttempt
    {
        return $this->attempt;
    }

    public function setAttempt(QuestAttempt $attempt): static
    {
        $this->attempt = $attempt;
        return $this;
    }

    public function getLatitude(): float
    {
        return $this->latitude;
    }

    public function setLatitude(float $latitude): static
    {
        $this->latitude = $latitude;
        return $this;
    }

    public function getLongitude(): float
    {
        return $this->longitude;
    }

    public function setLongitude(float $longitude): static
    {
        $this->longitude = $longitude;
        return $this;
    }

    public function getTimestamp(): \DateTimeImmutable
    {
        return $this->timestamp;
    }

    public function setTimestamp(\DateTimeImmutable $timestamp): static
    {
        $this->timestamp = $timestamp;
        return $this;
    }

    public function getAccuracy(): float
    {
        return $this->accuracy;
    }

    public function setAccuracy(float $accuracy): static
    {
        $this->accuracy = $accuracy;
        return $this;
    }

    public function getSpeed(): float
    {
        return $this->speed;
    }

    public function setSpeed(float $speed): static
    {
        $this->speed = $speed;
        return $this;
    }
}
