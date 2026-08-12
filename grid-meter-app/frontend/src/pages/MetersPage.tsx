import { useState } from 'react';
import {
  Box,
  Button,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
  MenuItem,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TablePagination,
  TableRow,
  TextField,
  Typography,
} from '@mui/material';
import { useNavigate } from 'react-router';
import { useCreateMeter, useMetersSearch } from '../hooks/useMeters';
import type { MeterStatus } from '../api/metersApi';

const STATUSES: MeterStatus[] = ['ACTIVE', 'INACTIVE', 'MAINTENANCE'];

export function MetersPage() {
  const navigate = useNavigate();
  const [location, setLocation] = useState('');
  const [status, setStatus] = useState<MeterStatus | ''>('');
  const [page, setPage] = useState(0);
  const [size, setSize] = useState(20);
  const [createOpen, setCreateOpen] = useState(false);

  const { data, isLoading } = useMetersSearch({
    location: location || undefined,
    status: status || undefined,
    page,
    size,
  });

  return (
    <Box>
      <Box sx={{ display: 'flex', gap: 2, mb: 2, alignItems: 'center' }}>
        <Typography variant="h5" sx={{ flexGrow: 1 }}>
          Meters
        </Typography>
        <TextField
          label="Location"
          size="small"
          value={location}
          onChange={(e) => {
            setLocation(e.target.value);
            setPage(0);
          }}
        />
        <TextField
          label="Status"
          select
          size="small"
          sx={{ width: 160 }}
          value={status}
          onChange={(e) => {
            setStatus(e.target.value as MeterStatus | '');
            setPage(0);
          }}
        >
          <MenuItem value="">Any</MenuItem>
          {STATUSES.map((s) => (
            <MenuItem key={s} value={s}>
              {s}
            </MenuItem>
          ))}
        </TextField>
        <Button variant="contained" onClick={() => setCreateOpen(true)}>
          New Meter
        </Button>
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Serial Number</TableCell>
              <TableCell>Location</TableCell>
              <TableCell>Status</TableCell>
              <TableCell>Installed</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {!isLoading &&
              data?.content.map((meter) => (
                <TableRow
                  key={meter.id}
                  hover
                  sx={{ cursor: 'pointer' }}
                  onClick={() => navigate(`/meters/${meter.id}`)}
                >
                  <TableCell>{meter.serialNumber}</TableCell>
                  <TableCell>{meter.location}</TableCell>
                  <TableCell>{meter.status}</TableCell>
                  <TableCell>{new Date(meter.installedAt).toLocaleDateString()}</TableCell>
                </TableRow>
              ))}
          </TableBody>
        </Table>
        <TablePagination
          component="div"
          count={data?.totalElements ?? 0}
          page={page}
          onPageChange={(_, newPage) => setPage(newPage)}
          rowsPerPage={size}
          onRowsPerPageChange={(e) => {
            setSize(parseInt(e.target.value, 10));
            setPage(0);
          }}
          rowsPerPageOptions={[10, 20, 50, 100]}
        />
      </TableContainer>

      <CreateMeterDialog open={createOpen} onClose={() => setCreateOpen(false)} />
    </Box>
  );
}

function CreateMeterDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const createMeter = useCreateMeter();
  const [serialNumber, setSerialNumber] = useState('');
  const [meterLocation, setMeterLocation] = useState('');
  const [status, setStatus] = useState<MeterStatus>('ACTIVE');
  const [installedAt, setInstalledAt] = useState('');

  function handleClose() {
    setSerialNumber('');
    setMeterLocation('');
    setStatus('ACTIVE');
    setInstalledAt('');
    onClose();
  }

  async function handleCreate() {
    await createMeter.mutateAsync({
      serialNumber,
      location: meterLocation,
      status,
      installedAt: new Date(installedAt).toISOString(),
    });
    handleClose();
  }

  return (
    <Dialog open={open} onClose={handleClose} fullWidth maxWidth="sm">
      <DialogTitle>New Meter</DialogTitle>
      <DialogContent sx={{ display: 'flex', flexDirection: 'column', gap: 2, pt: 1 }}>
        <TextField
          label="Serial Number"
          value={serialNumber}
          onChange={(e) => setSerialNumber(e.target.value)}
          autoFocus
        />
        <TextField
          label="Location"
          value={meterLocation}
          onChange={(e) => setMeterLocation(e.target.value)}
        />
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
      </DialogContent>
      <DialogActions>
        <Button onClick={handleClose}>Cancel</Button>
        <Button
          variant="contained"
          onClick={handleCreate}
          disabled={!serialNumber || !meterLocation || !installedAt || createMeter.isPending}
        >
          Create
        </Button>
      </DialogActions>
    </Dialog>
  );
}
