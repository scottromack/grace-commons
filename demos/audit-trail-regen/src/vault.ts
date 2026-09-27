// The deployment's at-rest keying, which the erasure mechanism shreds. Content is
// stored under a per-record key; destroying the key destroys readability and
// rewrites no stored byte (Term shredding-class; erasure mechanism 3 through 6).
import { createCipheriv, createDecipheriv, randomBytes } from "node:crypto";

export class Vault {
  private keys = new Map<string, Buffer>();
  seal(id: string, plaintext: string): string {
    const key = randomBytes(32), iv = randomBytes(12);
    this.keys.set(id, key);
    const c = createCipheriv("aes-256-gcm", key, iv);
    const body = Buffer.concat([c.update(plaintext, "utf8"), c.final()]);
    return [iv, c.getAuthTag(), body].map((b) => b.toString("base64")).join(".");
  }
  open(id: string, stored: string): string | null {
    const key = this.keys.get(id);
    if (!key) return null;
    const [iv, tag, body] = stored.split(".").map((s) => Buffer.from(s, "base64"));
    const d = createDecipheriv("aes-256-gcm", key, iv);
    d.setAuthTag(tag);
    return Buffer.concat([d.update(body), d.final()]).toString("utf8");
  }
  shred(id: string): boolean { return this.keys.delete(id); }
}
