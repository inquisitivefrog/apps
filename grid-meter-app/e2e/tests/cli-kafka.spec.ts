import { test, expect } from '@playwright/test';
import { dockerComposeExec } from './cli-helpers';

// Bootstrap port isn't published to the host (see cli-services.ts) — exec into a
// broker container is the only option, not a stylistic choice.
test('Kafka: lists topics via a broker\'s own bootstrap listener', async () => {
  const { stdout } = await dockerComposeExec(
    'kafka-1',
    '/opt/kafka/bin/kafka-topics.sh',
    '--bootstrap-server',
    'kafka-1:9092',
    '--list',
  );
  const topics = stdout.trim().split('\n').filter(Boolean);
  expect(topics).toContain('readings');
});
