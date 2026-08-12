import { useEffect, useState } from 'react';
import { Box, Button, MenuItem, Paper, TextField, Typography } from '@mui/material';
import { useNavigate, useParams } from 'react-router';
import { useMeter, useUpdateMeter } from '../hooks/useMeters';
import type { MeterStatus } from '../api/metersApi';

const STATUSES: MeterStatus[] = ['ACTIVE', 'INACTIVE', 'MAINTENANCE'];

export function MeterDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { data: meter, isLoading } = useMeter(id);
  const updateMeter = useUpdateMeter(id as string);

  const [serialNumber, setSerialNumber] = useState('');
  const [location, setLocation] = useState('');
  const [status, setStatus] = useState<MeterStatus>('ACTIVE');
  const [installedAt, setInstalledAt] = useState('');

  useEffect(() => {
    if (meter) {
      setSerialNumber(meter.serialNumber);
      setLocation(meter.location);
      setStatus(meter.status);
      setInstalledAt(meter.installedAt.slice(0, 10));
    }
  }, [meter]);

  if (isLoading || !meter) {
    return <Typography>Loading…</Typography>;
  }

  async function handleSave() {
    await updateMeter.mutateAsync({
      serialNumber,
      location,
      status,
      installedAt: new Date(installedAt).toISOString(),
    });
    navigate('/meters');
  }

  return (
    <Box sx={{ maxWidth: 480 }}>
      <Typography variant="h5" sx={{ mb: 2 }}>
        Meter {meter.serialNumber}
      </Typography>
      <Paper sx={{ p: 3, display: 'flex', flexDirection: 'column', gap: 2 }}>
        <TextField
          label="Serial Number"
          value={serialNumber}
          onChange={(e) => setSerialNumber(e.target.value)}
        />
        <TextField label="Location" value={location} onChange={(e) => setLocation(e.target.value)} />
        <TextField label="Status" select value={status} onChange={(e) => setStatus(e.target.value as MeterStatus)}>
          {STATUSES.map((s) => (
            <MenuItem key={s} value={s}>
              {s}
            </MenuItem>
          ))}
        </TextField>
        <TextField
          label="Installed At"
          type="date"
          slotProps={{ inputLabel: { shrink: true } }}
          value={installedAt}
          onChange={(e) => setInstalledAt(e.target.value)}
        />
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button variant="contained" onClick={handleSave} disabled={updateMeter.isPending}>
            Save
          </Button>
          <Button onClick={() => navigate('/meters')}>Cancel</Button>
        </Box>
      </Paper>
    </Box>
  );
}
