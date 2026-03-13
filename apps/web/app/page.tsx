"use client";

import { useEffect, useState } from "react";

type HealthState =
  | { phase: "loading" }
  | { phase: "ready"; status: string; service: string }
  | { phase: "error"; message: string };

const apiBaseUrl =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

export default function HomePage() {
  const [health, setHealth] = useState<HealthState>({ phase: "loading" });

  useEffect(() => {
    const controller = new AbortController();

    async function loadHealth() {
      try {
        const response = await fetch(`${apiBaseUrl}/health`, {
          signal: controller.signal,
        });

        if (!response.ok) {
          throw new Error(`API returned ${response.status}`);
        }

        const payload = (await response.json()) as {
          service: string;
          status: string;
        };

        setHealth({
          phase: "ready",
          service: payload.service,
          status: payload.status,
        });
      } catch (error) {
        if (controller.signal.aborted) {
          return;
        }

        const message =
          error instanceof Error ? error.message : "Unknown request error";
        setHealth({ phase: "error", message });
      }
    }

    void loadHealth();

    return () => {
      controller.abort();
    };
  }, []);

  return (
    <main
      style={{
        display: "grid",
        placeItems: "center",
        padding: "2rem",
      }}
    >
      <section
        style={{
          width: "min(100%, 52rem)",
          padding: "2rem",
          borderRadius: "1.5rem",
          backgroundColor: "rgba(255, 253, 247, 0.88)",
          border: "1px solid rgba(22, 33, 31, 0.1)",
          boxShadow: "0 24px 80px rgba(22, 33, 31, 0.12)",
        }}
      >
        <p
          style={{
            margin: 0,
            textTransform: "uppercase",
            letterSpacing: "0.18em",
            fontSize: "0.75rem",
            color: "#6f5c30",
          }}
        >
          Ralph Monorepo Template
        </p>
        <h1
          style={{
            marginTop: "1rem",
            marginBottom: "0.75rem",
            fontSize: "clamp(2.4rem, 8vw, 4.8rem)",
            lineHeight: 0.95,
          }}
        >
          Next.js on the front.
          <br />
          FastAPI at the edge.
        </h1>
        <p
          style={{
            marginTop: 0,
            marginBottom: "2rem",
            maxWidth: "38rem",
            fontSize: "1.05rem",
            lineHeight: 1.6,
            color: "#30413d",
          }}
        >
          This starter keeps the web app and API separate, but wires them
          together through a minimal health contract so the repo is immediately
          runnable.
        </p>

        <div
          style={{
            display: "grid",
            gap: "1rem",
            gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
          }}
        >
          <InfoCard
            label="Web stack"
            value="Next.js App Router"
            detail="TypeScript, bun, turbo"
          />
          <InfoCard
            label="API stack"
            value="FastAPI"
            detail="uv, pytest, ruff, mypy"
          />
          <StatusCard health={health} />
        </div>
      </section>
    </main>
  );
}

function InfoCard({
  detail,
  label,
  value,
}: {
  detail: string;
  label: string;
  value: string;
}) {
  return (
    <article
      style={{
        padding: "1rem 1.1rem",
        borderRadius: "1rem",
        backgroundColor: "#f8f6ef",
        border: "1px solid rgba(22, 33, 31, 0.08)",
      }}
    >
      <p
        style={{
          margin: 0,
          fontSize: "0.8rem",
          textTransform: "uppercase",
          letterSpacing: "0.12em",
          color: "#6a7b76",
        }}
      >
        {label}
      </p>
      <p
        style={{
          marginTop: "0.6rem",
          marginBottom: "0.3rem",
          fontSize: "1.3rem",
          fontWeight: 600,
        }}
      >
        {value}
      </p>
      <p
        style={{
          margin: 0,
          color: "#3b4c48",
        }}
      >
        {detail}
      </p>
    </article>
  );
}

function StatusCard({ health }: { health: HealthState }) {
  let label = "Checking API";
  let detail = `GET ${apiBaseUrl}/health`;
  let accent = "#d7b978";

  if (health.phase === "ready") {
    label = `${health.service} is ${health.status}`;
    detail = "Frontend and backend are talking to each other.";
    accent = "#4c8b68";
  } else if (health.phase === "error") {
    label = "API unavailable";
    detail = health.message;
    accent = "#b65447";
  }

  return (
    <article
      style={{
        padding: "1rem 1.1rem",
        borderRadius: "1rem",
        backgroundColor: "#16211f",
        color: "#f9f6ee",
        borderTop: `4px solid ${accent}`,
      }}
    >
      <p
        style={{
          margin: 0,
          fontSize: "0.8rem",
          textTransform: "uppercase",
          letterSpacing: "0.12em",
          color: "#b8c4be",
        }}
      >
        API health
      </p>
      <p
        style={{
          marginTop: "0.6rem",
          marginBottom: "0.35rem",
          fontSize: "1.3rem",
          fontWeight: 600,
        }}
      >
        {label}
      </p>
      <p
        style={{
          margin: 0,
          color: "#d9e0dc",
        }}
      >
        {detail}
      </p>
    </article>
  );
}
