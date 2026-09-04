import { execFile } from 'node:child_process';
import path from 'node:path';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

// docker-compose.yml lives at the grid-meter-app repo root, two levels up from
// e2e/tests/ — `docker compose exec` needs to run from there (or be told where it is)
// to find the right project.
const PROJECT_DIR = path.resolve(__dirname, '..', '..');

export async function dockerComposeExec(
  service: string,
  ...command: string[]
): Promise<{ stdout: string; stderr: string }> {
  return execFileAsync('docker', ['compose', 'exec', '-T', service, ...command], {
    cwd: PROJECT_DIR,
  });
}
