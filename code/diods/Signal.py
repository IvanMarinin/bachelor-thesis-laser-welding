import numpy as np
from scipy.signal import butter, filtfilt, medfilt, savgol_filter
from scipy.stats import entropy, kurtosis, skew


class Signal:
    def __init__(self, filename, header, time, unknown, visible, reflected, infrared, power=None, h_i=None):
        self.filename = filename
        self.header = header
        self.time = np.asarray(time, dtype=float)
        self.unknown = np.asarray(unknown, dtype=float)
        self.visible = np.asarray(visible, dtype=float)
        self.reflected = np.asarray(reflected, dtype=float)
        self.infrared = np.asarray(infrared, dtype=float)
        self.power = power
        self.h_i = h_i

    def label(self):
        return "full_penetration" if np.isclose(self.h_i, 0) else "incomplete_penetration"

    def div(self, a, b):
        return np.nan if b == 0 else a / b

    def corr(self, a, b):
        return np.nan if np.std(a) == 0 or np.std(b) == 0 else np.corrcoef(a, b)[0, 1]

    def time_features(self, x, name):
        hist, _ = np.histogram(x, bins=512, density=True)
        hist = hist[hist > 0]
        rms = np.sqrt(np.mean(x ** 2))
        std = np.std(x)
        return {
            f"{name}_mean": np.mean(x),
            f"{name}_std": std,
            f"{name}_rms": rms,
            f"{name}_min": np.min(x),
            f"{name}_max": np.max(x),
            f"{name}_peak_to_peak": np.ptp(x),
            f"{name}_energy": np.sum(x ** 2),
            f"{name}_skewness": skew(x),
            f"{name}_kurtosis": kurtosis(x),
            f"{name}_iqr": np.percentile(x, 75) - np.percentile(x, 25),
            f"{name}_snr": self.div(rms, std),
            f"{name}_entropy": entropy(hist),
            f"{name}_spike_count": np.sum(x > np.mean(x) + 5 * std),
        }

    def fft_features(self, x, name, fs=1):
        x = np.asarray(x, dtype=float)
        x = x - np.mean(x)
        if np.std(x) != 0:
            x = x / np.std(x)

        freq = np.fft.rfftfreq(len(x), d=1 / fs)
        mag = np.abs(np.fft.rfft(x))
        p = mag ** 2
        total = np.sum(p)
        i = np.argmax(p[1:]) + 1 if len(p) > 1 else 0
        m1 = freq <= 0.2 * freq.max()
        m2 = (freq > 0.2 * freq.max()) & (freq <= 0.6 * freq.max())
        m3 = freq > 0.6 * freq.max()
        e1, e2, e3 = np.sum(p[m1]), np.sum(p[m2]), np.sum(p[m3])

        return {
            f"{name}_fft_total_energy": total,
            f"{name}_fft_low_energy": e1,
            f"{name}_fft_mid_energy": e2,
            f"{name}_fft_high_energy": e3,
            f"{name}_fft_high_to_low_ratio": self.div(e3, e1),
            f"{name}_fft_dominant_frequency": freq[i],
            f"{name}_fft_spectral_centroid": self.div(np.sum(freq * p), total),
            f"{name}_fft_peak_magnitude": mag[i],
            f"{name}_fft_low_energy_ratio": self.div(e1, total),
            f"{name}_fft_mid_energy_ratio": self.div(e2, total),
            f"{name}_fft_high_energy_ratio": self.div(e3, total),
        }

    def get_window_features(self, window_size=1500, step=750, fs=1):
        rows = []
        channels = {"visible": self.visible, "reflected": self.reflected, "infrared": self.infrared}

        for window_index, begin in enumerate(range(0, len(self.visible) - window_size + 1, step)):
            end = begin + window_size
            w = {name: values[begin:end] for name, values in channels.items()}
            row = {
                "filename": self.filename,
                "power": self.power,
                "h_i": self.h_i,
                "defect_label": self.label(),
                "window_index": window_index,
                "begin": begin,
                "end": end,
            }

            for name, x in w.items():
                row.update(self.time_features(x, name))
                row.update(self.fft_features(x, name, fs))

            means = {name: np.mean(x) for name, x in w.items()}
            energy = {name: np.sum(x ** 2) for name, x in w.items()}
            pairs = [("visible", "infrared"), ("visible", "reflected"), ("infrared", "reflected")]

            for a, b in pairs:
                row[f"{a}_to_{b}_mean_ratio"] = self.div(means[a], means[b])
                row[f"{a}_to_{b}_energy_ratio"] = self.div(energy[a], energy[b])

            row["corr_visible_reflected"] = self.corr(w["visible"], w["reflected"])
            row["corr_visible_infrared"] = self.corr(w["visible"], w["infrared"])
            row["corr_reflected_infrared"] = self.corr(w["reflected"], w["infrared"])
            rows.append(row)

        return rows

    def median_filter(self, kernel_size=5):
        self.visible = medfilt(self.visible, kernel_size)
        self.infrared = medfilt(self.infrared, kernel_size)

    def savgol_filter(self, window_length=31, polyorder=3):
        self.visible = savgol_filter(self.visible, window_length, polyorder)
        self.infrared = savgol_filter(self.infrared, window_length, polyorder)

    def butter_lowpass_filter(self, normal_cutoff=0.1, order=4):
        b, a = butter(order, normal_cutoff, btype="low")
        self.visible = filtfilt(b, a, self.visible)
        self.infrared = filtfilt(b, a, self.infrared)
