// Module-level, in-memory token — deliberately not localStorage. localStorage is a
// persistent, globally-enumerable store any XSS payload can sweep well after the payload
// itself executes; an in-memory value dies on tab close/refresh and leaves nothing durable
// to steal. Doesn't eliminate XSS risk entirely (a *live* payload can still read it), but
// meaningfully shrinks the exploit window. Accepted tradeoff: a hard browser refresh loses
// the session and requires re-login.
let currentToken: string | null = null;
const listeners = new Set<(token: string | null) => void>();

export function getToken(): string | null {
  return currentToken;
}

export function setToken(token: string | null): void {
  currentToken = token;
  listeners.forEach((listener) => listener(token));
}

export function subscribeToken(listener: (token: string | null) => void): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}
