import numpy as np
from scipy.signal import savgol_filter
SERVICE_COLUMNS = {'sample_id', 'channel', 'filename', 'file_path', 'file_size_bytes', 'h_i', 'defect_label', 'spectra_count'}

class Spectrum:

    def __init__(self, sample_id, channel, filename, file_path, file_size_bytes, h_i, wavelengths, intensities):
        self.sample_id = int(sample_id)
        self.channel = str(channel)
        self.filename = str(filename)
        self.file_path = str(file_path)
        self.file_size_bytes = int(file_size_bytes)
        self.h_i = float(h_i)
        self.wavelengths = np.asarray(wavelengths, dtype=float)
        self.intensities = np.asarray(intensities, dtype=float)

    @classmethod
    def from_row(cls, row, wavelengths, intensities):
        return cls(sample_id=int(row['sample_id']), channel=str(row['channel']), filename=str(row['filename']), file_path=str(row['file_path']), file_size_bytes=int(row['file_size_bytes']), h_i=float(row['h_i']), wavelengths=np.asarray(wavelengths, dtype=float), intensities=np.asarray(intensities, dtype=float))

    @property
    def intensity_mean(self):
        return float(np.mean(self.intensities))

    @property
    def intensity_max(self):
        return float(np.max(self.intensities))

    @property
    def intensity_sum(self):
        return float(np.sum(self.intensities))

    @property
    def peak_ratio(self):
        return self.intensity_max / self.intensity_mean if self.intensity_mean else 0.0

    def metadata_row(self):
        return {'sample_id': self.sample_id, 'channel': self.channel, 'filename': self.filename, 'file_path': self.file_path, 'file_size_bytes': self.file_size_bytes, 'h_i': self.h_i}

    def features(self):
        rows = self.metadata_row()
        signal_versions = {'raw': self.intensities, 'smooth': moving_average(self.intensities, 7), 'savgol': savgol_smooth(self.intensities, 21, 3), 'baseline': remove_baseline(self.intensities, 301)}
        signal_versions['baseline_savgol'] = savgol_smooth(signal_versions['baseline'], 21, 3)
        for prefix, values in signal_versions.items():
            rows.update(features_for_series(self.wavelengths, values, prefix))
        return rows

def moving_average(values, window):
    if window <= 1:
        return values.astype(float)
    if window % 2 == 0:
        window += 1
    kernel = np.ones(window) / window
    padded = np.pad(values.astype(float), window // 2, mode='edge')
    return np.convolve(padded, kernel, mode='valid')

def savgol_smooth(values, window, polyorder):
    window = valid_window(window, len(values), polyorder + 2)
    if window <= polyorder:
        return values.astype(float)
    return savgol_filter(values.astype(float), window, polyorder, mode='interp')

def remove_baseline(values, window):
    baseline = savgol_smooth(values, window, 2)
    return values.astype(float) - baseline

def valid_window(window, signal_length, minimum):
    window = max(int(window), int(minimum))
    if window % 2 == 0:
        window += 1
    if window > signal_length:
        window = signal_length if signal_length % 2 else signal_length - 1
    return max(window, 3)

def features_for_series(wavelengths, values, prefix):
    values = np.asarray(values, dtype=float)
    wavelengths = np.asarray(wavelengths, dtype=float)
    result = {}
    result.update(basic_features(values, prefix))
    result.update(band_features(wavelengths, values, prefix))
    result.update(fft_features(wavelengths, values, prefix))
    return result

def basic_features(values, prefix):
    minimum, maximum = (float(np.min(values)), float(np.max(values)))
    mean, std = (float(np.mean(values)), float(np.std(values)))
    centered = values - mean
    variance = float(np.mean(centered ** 2))
    quantiles = np.quantile(values, [0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95])
    skewness = float(np.mean(centered ** 3) / variance ** 1.5) if variance else 0.0
    kurtosis = float(np.mean(centered ** 4) / variance ** 2 - 3.0) if variance else 0.0
    shifted = values - minimum
    probabilities = shifted / np.sum(shifted) if np.sum(shifted) else np.array([])
    probabilities = probabilities[probabilities > 0]
    entropy = float(-np.sum(probabilities * np.log(probabilities))) if len(probabilities) else 0.0
    names = ['q05', 'q10', 'q25', 'q50', 'q75', 'q90', 'q95']
    result = {f'{prefix}_mean': mean, f'{prefix}_std': std, f'{prefix}_min': minimum, f'{prefix}_max': maximum, f'{prefix}_amplitude': maximum - minimum, f'{prefix}_energy': float(np.sum(values ** 2)), f'{prefix}_rms': float(np.sqrt(np.mean(values ** 2))), f'{prefix}_skewness': skewness, f'{prefix}_kurtosis': kurtosis, f'{prefix}_entropy': entropy}
    result.update({f'{prefix}_{name}': float(value) for name, value in zip(names, quantiles)})
    return result

def band_features(wavelengths, values, prefix):
    bands = [(450, 500), (500, 550), (550, 600), (600, 650), (650, 700), (700, 750)]
    total = float(np.trapezoid(values, wavelengths))
    peak = int(np.argmax(values))
    result = {f'{prefix}_peak_wavelength': float(wavelengths[peak]), f'{prefix}_peak_intensity': float(values[peak])}
    for left, right in bands:
        mask = (wavelengths >= left) & (wavelengths < right)
        name = f'{prefix}_band_{left}_{right}'
        if np.any(mask):
            integral = float(np.trapezoid(values[mask], wavelengths[mask]))
            result[f'{name}_integral'] = integral
            result[f'{name}_mean'] = float(np.mean(values[mask]))
            result[f'{name}_max'] = float(np.max(values[mask]))
            result[f'{name}_relative'] = integral / total if total else 0.0
        else:
            result.update({f'{name}_integral': 0.0, f'{name}_mean': 0.0, f'{name}_max': 0.0, f'{name}_relative': 0.0})
    return result

def fft_features(wavelengths, values, prefix):
    step = float(np.mean(np.diff(wavelengths)))
    freq = np.fft.rfftfreq(len(values), d=step)[1:]
    mag = np.abs(np.fft.rfft(values - np.mean(values)))[1:]
    if len(mag) == 0:
        return {f'{prefix}_fft_{name}': 0.0 for name in ['dominant_frequency', 'dominant_magnitude', 'total_energy']}
    energy = mag ** 2
    total = float(np.sum(energy))
    max_freq = float(np.max(freq))
    masks = {'low': freq <= 0.15 * max_freq, 'mid': (freq > 0.15 * max_freq) & (freq <= 0.5 * max_freq), 'high': freq > 0.5 * max_freq}
    dominant = int(np.argmax(mag))
    result = {f'{prefix}_fft_dominant_frequency': float(freq[dominant]), f'{prefix}_fft_dominant_magnitude': float(mag[dominant]), f'{prefix}_fft_total_energy': total}
    for name, mask in masks.items():
        value = float(np.sum(energy[mask]))
        result[f'{prefix}_fft_{name}_energy'] = value
        result[f'{prefix}_fft_{name}_relative_energy'] = value / total if total else 0.0
    return result

def feature_columns(df):
    numeric = df.select_dtypes(include=[np.number]).columns.tolist()
    return [column for column in numeric if column not in SERVICE_COLUMNS]
