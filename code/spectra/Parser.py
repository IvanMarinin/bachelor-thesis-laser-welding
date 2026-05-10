from pathlib import Path
from types import SimpleNamespace
import numpy as np
import pandas as pd
from Spectrum import Spectrum
EXPERIMENT_DIR_NAME = '2023-0101 Spectroscopy'
DEFECTS_FILE_NAME = '2023-0101 Procedure test.xlsx'
CHANNEL_PREFIX = '1712307U3'

def find_data_root(path=None):
    if path:
        root = Path(path).expanduser().resolve()
        if not root.exists():
            raise FileNotFoundError(root)
        return root
    roots = [Path.cwd(), Path.cwd().parent, Path.home() / 'Desktop']
    for root in roots:
        direct = root / EXPERIMENT_DIR_NAME
        if (direct / DEFECTS_FILE_NAME).exists():
            return direct
    for root in roots:
        if root.exists():
            for candidate in root.rglob(EXPERIMENT_DIR_NAME):
                if (candidate / DEFECTS_FILE_NAME).exists():
                    return candidate
    raise FileNotFoundError(f'Не найдена папка {EXPERIMENT_DIR_NAME}')

def read_defects(defects_file, sheet_name='M1'):
    raw = pd.read_excel(defects_file, sheet_name=sheet_name, header=None)
    header_row, end_row = (None, len(raw))
    for i, row in raw.iterrows():
        values = [str(value).strip() for value in row.values if pd.notna(value)]
        if header_row is None and {'Sample ID', 'Litera', 'hi'}.issubset(values):
            header_row = i
        if 'Quality limits' in values:
            end_row = i
            break
    if header_row is None:
        raise ValueError('В Excel не найдены столбцы Sample ID, Litera, hi')
    headers = [str(value).strip() if pd.notna(value) else f'column_{i}' for i, value in enumerate(raw.iloc[header_row].tolist())]
    defects = raw.iloc[header_row + 2:end_row].copy()
    defects.columns = headers
    defects['Sample ID'] = defects['Sample ID'].ffill()
    defects = defects[defects['Litera'].isin(['a', 'b', 'c', 'd'])].copy()
    for column in ['Sample ID', 'V', 'PL', 'Fz', 'hi']:
        if column in defects.columns:
            defects[column] = pd.to_numeric(defects[column], errors='coerce')
    defects = defects.dropna(subset=['Sample ID', 'hi']).copy()
    defects['sample_id'] = defects['Sample ID'].astype(int)
    defects['h_i'] = defects['hi'].astype(float)
    rows = []
    for sample_id, group in defects.groupby('sample_id', sort=True):
        first = group.iloc[0]
        rows.append({'sample_id': int(sample_id), 'h_i': float(group['h_i'].max()), 'h_i_mean': float(group['h_i'].mean()), 'h_i_min': float(group['h_i'].min()), 'h_i_max': float(group['h_i'].max()), 'macrosection_count': int(len(group)), 'V': first.get('V', np.nan), 'PL': first.get('PL', np.nan), 'Fz': first.get('Fz', np.nan)})
    return (defects, pd.DataFrame(rows))

def scan_raw8_files(data_root, channel_prefix=CHANNEL_PREFIX):
    rows = []
    folders = sorted([folder for folder in data_root.iterdir() if folder.is_dir() and folder.name.isdigit()], key=lambda folder: int(folder.name))
    for folder in folders:
        for file_path in sorted(folder.glob(f'{channel_prefix}_*.Raw8')):
            rows.append({'sample_id': int(folder.name), 'channel': file_path.name.split('_', 1)[0], 'filename': file_path.name, 'file_path': str(file_path), 'file_size_bytes': file_path.stat().st_size})
    return pd.DataFrame(rows)

def read_raw8(file_path, header_size=328, n_points=2048):
    data = np.fromfile(file_path, dtype=np.float32, offset=header_size)
    if len(data) < 2 * n_points:
        raise ValueError(f'Слишком короткий Raw8-файл: {file_path}')
    return (data[:n_points].astype(float), data[n_points:2 * n_points].astype(float))

def read_and_match(raw_files, defects_by_sample):
    h_i_by_sample = defects_by_sample.set_index('sample_id')['h_i'].to_dict()
    rows, spectra = ([], [])
    for i, row in raw_files.reset_index(drop=True).iterrows():
        if i == 0 or (i + 1) % 500 == 0 or i + 1 == len(raw_files):
            print(f'Чтение Raw8: {i + 1}/{len(raw_files)}')
        record = row.to_dict()
        record['h_i'] = h_i_by_sample.get(int(row['sample_id']), np.nan)
        record['matched_with_defect'] = pd.notna(record['h_i'])
        try:
            wavelengths, intensities = read_raw8(row['file_path'])
            record.update(signal_statistics(wavelengths, intensities))
            record['read_status'] = 'ok'
            if record['matched_with_defect']:
                spectra.append(Spectrum.from_row(record, wavelengths, intensities))
        except Exception as exc:
            record['read_status'] = 'error'
            record['read_error'] = str(exc)
        rows.append(record)
    return (pd.DataFrame(rows), spectra)

def filter_noise(spectra, quantile=0.75):
    filtered, rows = ([], [])
    for sample_id in sorted({spectrum.sample_id for spectrum in spectra}):
        group = [spectrum for spectrum in spectra if spectrum.sample_id == sample_id]
        mean_limit = np.quantile([s.intensity_mean for s in group], quantile)
        sum_limit = np.quantile([s.intensity_sum for s in group], quantile)
        peak_limit = np.quantile([s.peak_ratio for s in group], quantile)
        for spectrum in group:
            keep = spectrum.intensity_mean >= mean_limit and spectrum.intensity_sum >= sum_limit and (spectrum.peak_ratio >= peak_limit)
            rows.append({**spectrum.metadata_row(), 'noise_filter_keep': bool(keep), 'mean_threshold': float(mean_limit), 'integral_threshold': float(sum_limit), 'peak_ratio_threshold': float(peak_limit)})
            if keep:
                filtered.append(spectrum)
    return (filtered, pd.DataFrame(rows))

def load_dataset(data_root=None, channel_prefix=CHANNEL_PREFIX, noise_quantile=0.75):
    root = find_data_root(data_root)
    defect_rows, defects_by_sample = read_defects(root / DEFECTS_FILE_NAME)
    raw_files = scan_raw8_files(root, channel_prefix)
    matched_signals, spectra = read_and_match(raw_files, defects_by_sample)
    spectra, noise_report = filter_noise(spectra, noise_quantile)
    return SimpleNamespace(data_root=root, defect_rows=defect_rows, defects_by_sample=defects_by_sample, raw_files=raw_files, matched_signals=matched_signals, noise_filter_report=noise_report, spectra=spectra)

def signal_statistics(wavelengths, intensities):
    mean = float(np.mean(intensities))
    maximum = float(np.max(intensities))
    return {'n_points': int(len(intensities)), 'wavelength_min': float(np.min(wavelengths)), 'wavelength_max': float(np.max(wavelengths)), 'intensity_mean': mean, 'intensity_std': float(np.std(intensities)), 'intensity_min': float(np.min(intensities)), 'intensity_max': maximum, 'intensity_integral': float(np.trapezoid(intensities, wavelengths)), 'intensity_sum': float(np.sum(intensities)), 'peak_ratio': maximum / mean if mean else 0.0}

def save_table(df, output_dir, name):
    output_dir.mkdir(parents=True, exist_ok=True)
    df.to_csv(output_dir / f'{name}.csv', index=False, encoding='utf-8-sig')
    df.to_excel(output_dir / f'{name}.xlsx', index=False)
