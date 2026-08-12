import { useState } from 'react';
import {
  Box,
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
import { useReadingsSearch } from '../hooks/useReadings';

// Read-only page — readings are immutable events ingested via the API (JMeter simulates
// meter submissions against POST /readings), never hand-entered here.
export function ReadingsPage() {
  const [meterId, setMeterId] = useState('');
  const [page, setPage] = useState(0);
  const [size, setSize] = useState(20);

  const { data, isLoading } = useReadingsSearch({
    meterId: meterId || undefined,
    page,
    size,
  });

  return (
    <Box>
      <Box sx={{ display: 'flex', gap: 2, mb: 2, alignItems: 'center' }}>
        <Typography variant="h5" sx={{ flexGrow: 1 }}>
          Readings
        </Typography>
        <TextField
          label="Meter ID"
          size="small"
          value={meterId}
          onChange={(e) => {
            setMeterId(e.target.value);
            setPage(0);
          }}
        />
      </Box>

      <TableContainer component={Paper}>
        <Table>
          <TableHead>
            <TableRow>
              <TableCell>Meter ID</TableCell>
              <TableCell>Reading Timestamp</TableCell>
              <TableCell>Value (kWh)</TableCell>
              <TableCell>Received At</TableCell>
            </TableRow>
          </TableHead>
          <TableBody>
            {!isLoading &&
              data?.content.map((reading) => (
                <TableRow key={reading.id}>
                  <TableCell>{reading.meterId}</TableCell>
                  <TableCell>{new Date(reading.readingTimestamp).toLocaleString()}</TableCell>
                  <TableCell>{reading.value}</TableCell>
                  <TableCell>{new Date(reading.receivedAt).toLocaleString()}</TableCell>
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
    </Box>
  );
}
