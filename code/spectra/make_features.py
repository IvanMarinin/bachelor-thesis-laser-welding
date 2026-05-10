import argparse
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from Parser import load_dataset, save_table
from Spectrum import feature_columns, remove_baseline, savgol_smooth

def parse_args():
    parser = argparse.ArgumentParser(description='Создание таблицы признаков спектров Raw8.')
    parser.add_argument('--data-root', default=None)
    parser.add_argument('--output-dir', default='simple_outputs')
    parser.add_argument('--channel-prefix', default='1712307U3')
    parser.add_argument('--noise-quantile', type=float, default=0.75)
    return parser.parse_args()

def main():
    args = parse_args()
    output_dir = Path(args.output_dir)
    dataset = load_dataset(data_root=args.data_root, channel_prefix=args.channel_prefix, noise_quantile=args.noise_quantile)
    print(f'Папка данных: {dataset.data_root}')
    print(f'Raw8-файлов найдено: {len(dataset.raw_files)}')
    print(f"Сигналов сопоставлено с h_i: {int(dataset.matched_signals['matched_with_defect'].sum())}")
    print(f'После фильтра шума осталось: {len(dataset.spectra)}')
    features = pd.DataFrame([spectrum.features() for spectrum in dataset.spectra])
    features['defect_label'] = np.where(features['h_i'] > 0, 'incomplete_penetration', 'full_penetration')
    sample_features = aggregate_by_sample(features)
    save_table(dataset.defects_by_sample, output_dir, 'defects_by_sample')
    save_table(dataset.matched_signals, output_dir, 'matched_signals')
    save_table(dataset.noise_filter_report, output_dir, 'noise_filter_report')
    save_table(features, output_dir, 'features')
    save_table(sample_features, output_dir, 'sample_features')
    spectrum_processing_plot(dataset.spectra, output_dir / 'spectrum_processing_example.png')
    print(f'Таблица features: {features.shape[0]} x {features.shape[1]}')
    print(f'Таблица sample_features: {sample_features.shape[0]} x {sample_features.shape[1]}')

def aggregate_by_sample(features):
    columns = feature_columns(features)
    rows = []
    for sample_id, group in features.groupby('sample_id', sort=True):
        row = {'sample_id': int(sample_id), 'h_i': float(group['h_i'].iloc[0]), 'defect_label': group['defect_label'].iloc[0], 'spectra_count': int(len(group))}
        for column in columns:
            values = pd.to_numeric(group[column], errors='coerce')
            row[f'{column}_mean_by_sample'] = float(values.mean())
            row[f'{column}_std_by_sample'] = float(values.std(ddof=0))
            row[f'{column}_min_by_sample'] = float(values.min())
            row[f'{column}_max_by_sample'] = float(values.max())
        rows.append(row)
    return pd.DataFrame(rows).replace([np.inf, -np.inf], np.nan).fillna(0)

def spectrum_processing_plot(spectra, output_path):
    spectrum = max(spectra, key=lambda item: item.intensity_sum)
    raw = spectrum.intensities
    smooth = savgol_smooth(raw, 21, 3)
    baseline = savgol_smooth(remove_baseline(raw, 301), 21, 3)
    colors = ['#142421', '#66130F', '#B7743B']
    titles = ['Исходный спектр', 'Сглаженный спектр', 'Сглаженный спектр после удаления baseline']
    values = [raw, smooth, baseline]
    fig, axes = plt.subplots(3, 1, figsize=(10, 8), sharex=True)
    for ax, title, data, color in zip(axes, titles, values, colors):
        ax.plot(spectrum.wavelengths, data, color=color, linewidth=1.5)
        ax.set_title(title)
        ax.set_ylabel('Интенсивность')
        ax.grid(alpha=0.25, color='#142421')
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
    axes[-1].set_xlabel('Длина волны, нм')
    fig.suptitle(f'Пример обработки спектра: образец {spectrum.sample_id}')
    fig.tight_layout()
    fig.savefig(output_path, dpi=300)
    plt.close(fig)
if __name__ == '__main__':
    main()
