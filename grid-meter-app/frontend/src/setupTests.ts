import { afterEach } from 'vitest';
import { cleanup } from '@testing-library/react';
import '@testing-library/jest-dom/vitest';

// globals: false in vite.config.ts means RTL can't auto-detect a global afterEach
// to hook its automatic unmount-between-tests cleanup, so it's wired explicitly here.
afterEach(cleanup);
