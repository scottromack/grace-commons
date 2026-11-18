// Starts Beacon (SPEC.md, Running it): opens every pattern on the store, seeds, and serves.
import { Store } from "./store.ts";
import { Beacon } from "./beacon.ts";
import { buildApp } from "./server.ts";

const env = (k: string): string | undefined => (process.env[k] === "" ? undefined : process.env[k]);

const store = new Store({ host: env("STORE_HOST"), port: env("STORE_PORT") ? Number(env("STORE_PORT")) : undefined });
const beacon = await Beacon.open(store);
await beacon.seed();
const app = buildApp(beacon, { secureCookie: env("SECURE_COOKIE") === "1" });

const server = Bun.serve({ port: Number(env("PORT") ?? 8000), hostname: "0.0.0.0", fetch: app.fetch });
console.log(`beacon: serving on ${server.port}`);
