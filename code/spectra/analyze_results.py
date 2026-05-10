import argparse
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.colors import LinearSegmentedColormap
from sklearn.base import clone
from sklearn.ensemble import GradientBoostingClassifier, RandomForestClassifier
from sklearn.feature_selection import SelectKBest, VarianceThreshold, f_classif
from sklearn.impute import SimpleImputer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, balanced_accuracy_score, classification_report, confusion_matrix, f1_score, precision_score, recall_score
from sklearn.model_selection import StratifiedGroupKFold
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC
from Parser import save_table
from Spectrum import feature_columns
LABEL_ORDER = ['full_penetration', 'incomplete_penetration']
RUS_LABELS = ['Полное\nпроплавление', 'Непровар']
MAIN_COLOR = '#66130F'
ACCENT_COLOR = '#B7743B'
DARK_COLOR = '#142421'
BACKGROUND_COLOR = '#DDD8D2'

def parse_args():
    parser = argparse.ArgumentParser(description='Классификация качества сварки по признакам спектров.')
    parser.add_argument('--input-dir', default='simple_outputs')
    parser.add_argument('--output-dir', default='simple_outputs')
    parser.add_argument('--max-cv-splits', type=int, default=5)
    return parser.parse_args()

def main():
    args = parse_args()
    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    sample_features = pd.read_excel(input_dir / 'sample_features.xlsx')
    print(f'Образцов: {sample_features.shape[0]}')
    print('Распределение классов:')
    print(sample_features['defect_label'].value_counts().to_string())
    class_distribution_plot(sample_features, output_dir / 'class_distribution.png')
    metrics, predictions = evaluate_models(sample_features, args.max_cv_splits)
    save_table(metrics, output_dir, 'model_metrics')
    model_comparison_plot(metrics, output_dir / 'model_comparison.png')
    best_model = metrics.iloc[0]['model']
    report = report_table(sample_features['defect_label'], predictions[best_model])
    save_table(report, output_dir, f'classification_report_{best_model}')
    confusion_plot(sample_features['defect_label'], predictions[best_model], output_dir / f'confusion_matrix_{best_model}.png', f'Матрица ошибок: {best_model}')
    sensitive_metrics, sensitive_scores = evaluate_sensitive_models(sample_features, args.max_cv_splits)
    save_table(sensitive_metrics, output_dir, 'sensitive_model_metrics')
    save_table(sensitive_scores, output_dir, 'sensitive_sample_scores')
    sensitive_comparison_plot(sensitive_metrics, output_dir / 'sensitive_model_comparison_top10.png')
    best_sensitive = sensitive_metrics.iloc[0]
    best_predictions = sensitive_predictions(sensitive_scores, best_sensitive)
    save_table(best_predictions, output_dir, 'best_sensitive_sample_predictions')
    save_table(report_table(best_predictions['true_label'], best_predictions['predicted_label']), output_dir, 'best_sensitive_classification_report')
    confusion_plot(best_predictions['true_label'], best_predictions['predicted_label'], output_dir / 'best_sensitive_confusion_matrix.png', 'Чувствительный режим', figsize=(5.6, 4.6))
    model, columns = fit_model(sample_features, str(best_sensitive['base_model']))
    importances = feature_importance(model, columns)
    save_table(importances, output_dir, f"feature_importance_{best_sensitive['base_model']}")
    feature_importance_plot(importances, output_dir / f"feature_importance_{best_sensitive['base_model']}.png")
    print('Лучшая обычная модель:')
    print(metrics.head(1).to_string(index=False))
    print('Лучший чувствительный режим:')
    print(sensitive_metrics.head(1).to_string(index=False))

def models(n_samples):
    k_neighbors = min(5, max(1, n_samples // 10))
    return {'LogisticRegression': Pipeline([('imputer', SimpleImputer(strategy='median')), ('variance', VarianceThreshold()), ('select', SelectKBest(f_classif, k='all')), ('scaler', StandardScaler()), ('model', LogisticRegression(max_iter=3000, class_weight='balanced', random_state=42))]), 'RandomForest': Pipeline([('imputer', SimpleImputer(strategy='median')), ('variance', VarianceThreshold()), ('select', SelectKBest(f_classif, k='all')), ('model', RandomForestClassifier(n_estimators=400, class_weight='balanced', random_state=42, n_jobs=-1))]), 'GradientBoosting': Pipeline([('imputer', SimpleImputer(strategy='median')), ('variance', VarianceThreshold()), ('select', SelectKBest(f_classif, k='all')), ('model', GradientBoostingClassifier(random_state=42))]), 'SVM_RBF': Pipeline([('imputer', SimpleImputer(strategy='median')), ('variance', VarianceThreshold()), ('select', SelectKBest(f_classif, k='all')), ('scaler', StandardScaler()), ('model', SVC(kernel='rbf', class_weight='balanced', random_state=42))]), 'kNN': Pipeline([('imputer', SimpleImputer(strategy='median')), ('variance', VarianceThreshold()), ('select', SelectKBest(f_classif, k='all')), ('scaler', StandardScaler()), ('model', KNeighborsClassifier(n_neighbors=k_neighbors))])}

def cv_splitter(y, groups, max_splits):
    group_labels = pd.DataFrame({'y': y, 'group': groups}).drop_duplicates('group')
    n_splits = min(max_splits, group_labels.groupby('y')['group'].nunique().min())
    return StratifiedGroupKFold(n_splits=int(n_splits), shuffle=True, random_state=42)

def evaluate_models(features, max_splits):
    columns = feature_columns(features)
    X = features[columns].replace([np.inf, -np.inf], np.nan)
    y = features['defect_label'].astype(str)
    groups = features['sample_id']
    cv = cv_splitter(y, groups, max_splits)
    rows, predictions = ([], {})
    for name, model in models(len(features)).items():
        pred = pd.Series(index=y.index, dtype=object)
        fold_balanced_accuracy, fold_f1 = ([], [])
        for train, test in cv.split(X, y, groups):
            current = clone(model)
            current.fit(X.iloc[train], y.iloc[train])
            fold_pred = current.predict(X.iloc[test])
            pred.iloc[test] = fold_pred
            fold_balanced_accuracy.append(balanced_accuracy_score(y.iloc[test], fold_pred))
            fold_f1.append(f1_score(y.iloc[test], fold_pred, labels=['incomplete_penetration'], average='macro', zero_division=0))
        pred = pred.to_numpy()
        predictions[name] = pred
        row = metric_row(y, pred)
        row.update({'model': name, 'n_splits': cv.n_splits, 'std_balanced_accuracy': float(np.std(fold_balanced_accuracy, ddof=1)), 'std_f1_defect': float(np.std(fold_f1, ddof=1))})
        for i, value in enumerate(fold_balanced_accuracy, 1):
            row[f'fold_{i}_balanced_accuracy'] = value
        rows.append(row)
    return (pd.DataFrame(rows).sort_values(['f1_defect', 'balanced_accuracy'], ascending=False), predictions)

def evaluate_sensitive_models(features, max_splits):
    columns = feature_columns(features)
    X = features[columns].replace([np.inf, -np.inf], np.nan)
    y = features['defect_label'].astype(str)
    groups = features['sample_id']
    cv = cv_splitter(y, groups, max_splits)
    thresholds = [round(value, 2) for value in np.arange(0.1, 0.91, 0.05)]
    rows, score_tables = ([], [])
    for name, model in models(len(features)).items():
        scores = []
        for fold, (train, test) in enumerate(cv.split(X, y, groups), 1):
            current = clone(model)
            current.fit(X.iloc[train], y.iloc[train])
            for row_index, score in zip(test, defect_scores(current, X.iloc[test])):
                scores.append({'model': name, 'fold': fold, 'sample_id': int(features.iloc[row_index]['sample_id']), 'h_i': float(features.iloc[row_index]['h_i']), 'true_label': y.iloc[row_index], 'defect_score': float(score)})
        scores = pd.DataFrame(scores)
        score_tables.append(scores)
        for threshold in thresholds:
            pred = np.where(scores['defect_score'] >= threshold, 'incomplete_penetration', 'full_penetration')
            row = metric_row(scores['true_label'], pred)
            row.update({'model': f'{name} | score >= {threshold:g}', 'base_model': name, 'threshold': threshold, 'n_splits': cv.n_splits})
            row['meets_working_specificity'] = row['specificity_full'] >= 0.5
            for fold, group in scores.groupby('fold'):
                fold_pred = np.where(group['defect_score'] >= threshold, 'incomplete_penetration', 'full_penetration')
                row[f'fold_{fold}_recall_defect'] = recall_score(group['true_label'], fold_pred, labels=['incomplete_penetration'], average='macro', zero_division=0)
            rows.append(row)
    metrics = pd.DataFrame(rows).sort_values(['meets_working_specificity', 'recall_defect', 'balanced_accuracy', 'f1_defect', 'precision_defect'], ascending=False)
    return (metrics, pd.concat(score_tables, ignore_index=True))

def metric_row(y_true, y_pred):
    tn, fp, fn, tp = confusion_matrix(y_true, y_pred, labels=LABEL_ORDER).ravel()
    return {'accuracy': accuracy_score(y_true, y_pred), 'balanced_accuracy': balanced_accuracy_score(y_true, y_pred), 'precision_macro': precision_score(y_true, y_pred, average='macro', zero_division=0), 'recall_macro': recall_score(y_true, y_pred, average='macro', zero_division=0), 'f1_macro': f1_score(y_true, y_pred, average='macro', zero_division=0), 'precision_defect': precision_score(y_true, y_pred, labels=['incomplete_penetration'], average='macro', zero_division=0), 'recall_defect': recall_score(y_true, y_pred, labels=['incomplete_penetration'], average='macro', zero_division=0), 'f1_defect': f1_score(y_true, y_pred, labels=['incomplete_penetration'], average='macro', zero_division=0), 'true_negative': int(tn), 'false_positive': int(fp), 'false_negative': int(fn), 'true_positive': int(tp), 'specificity_full': tn / (tn + fp) if tn + fp else 0.0}

def defect_scores(model, X):
    if hasattr(model, 'predict_proba'):
        probabilities = model.predict_proba(X)
        return probabilities[:, list(model.classes_).index('incomplete_penetration')]
    if hasattr(model, 'decision_function'):
        score = 1 / (1 + np.exp(-model.decision_function(X)))
        return score if list(model.classes_)[-1] == 'incomplete_penetration' else 1 - score
    return (model.predict(X) == 'incomplete_penetration').astype(float)

def sensitive_predictions(scores, best):
    result = scores[scores['model'] == best['base_model']].copy()
    result['predicted_label'] = np.where(result['defect_score'] >= best['threshold'], 'incomplete_penetration', 'full_penetration')
    result['is_correct'] = result['true_label'] == result['predicted_label']
    return result.sort_values(['fold', 'sample_id'])

def report_table(y_true, y_pred):
    return pd.DataFrame(classification_report(y_true, y_pred, labels=LABEL_ORDER, output_dict=True, zero_division=0)).transpose().reset_index(names='label')

def fit_model(features, model_name):
    columns = feature_columns(features)
    X = features[columns].replace([np.inf, -np.inf], np.nan)
    y = features['defect_label'].astype(str)
    model = models(len(features))[model_name]
    model.fit(X, y)
    return (model, columns)

def feature_importance(model, columns):
    estimator = model.named_steps['model']
    selected = np.array(columns, dtype=object)
    selected = selected[model.named_steps['variance'].get_support()]
    selected = selected[model.named_steps['select'].get_support()]
    if hasattr(estimator, 'coef_'):
        values = np.ravel(np.abs(estimator.coef_))
    elif hasattr(estimator, 'feature_importances_'):
        values = estimator.feature_importances_
    else:
        return pd.DataFrame(columns=['feature', 'importance'])
    return pd.DataFrame({'feature': selected, 'importance': values}).sort_values('importance', ascending=False)

def style():
    plt.rcParams.update({'font.size': 10, 'axes.edgecolor': DARK_COLOR, 'axes.labelcolor': DARK_COLOR, 'xtick.color': DARK_COLOR, 'ytick.color': DARK_COLOR, 'text.color': DARK_COLOR})

def clean_axes():
    ax = plt.gca()
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)

def class_distribution_plot(features, path):
    style()
    counts = features['defect_label'].value_counts().reindex(LABEL_ORDER, fill_value=0)
    plt.figure(figsize=(7, 4.5))
    plt.bar(range(2), counts.values, color=[DARK_COLOR, MAIN_COLOR], edgecolor=DARK_COLOR, alpha=0.88)
    plt.xticks(range(2), RUS_LABELS)
    plt.ylabel('Количество образцов')
    plt.xlabel('Класс качества')
    plt.title('Распределение классов по образцам')
    plt.grid(axis='y', alpha=0.25, color=DARK_COLOR)
    clean_axes()
    plt.tight_layout()
    plt.savefig(path, dpi=300)
    plt.close()

def model_comparison_plot(metrics, path):
    style()
    ordered = metrics.sort_values('balanced_accuracy', ascending=False)
    plt.figure(figsize=(10, 5))
    plt.bar(ordered['model'], ordered['balanced_accuracy'], color=MAIN_COLOR, edgecolor=DARK_COLOR, alpha=0.85)
    for i, row in enumerate(ordered.itertuples()):
        fold_values = [getattr(row, c) for c in ordered.columns if c.startswith('fold_') and c.endswith('_balanced_accuracy')]
        plt.scatter([i] * len(fold_values), fold_values, color=ACCENT_COLOR, edgecolors=DARK_COLOR, zorder=3)
    plt.ylim(0, 1)
    plt.ylabel('Сбалансированная точность')
    plt.xlabel('Классификатор')
    plt.title('Сравнение классификаторов по образцам')
    plt.grid(axis='y', alpha=0.25, color=DARK_COLOR)
    clean_axes()
    plt.tight_layout()
    plt.savefig(path, dpi=300)
    plt.close()

def sensitive_comparison_plot(metrics, path):
    style()
    ordered = metrics.sort_values(['meets_working_specificity', 'recall_defect', 'balanced_accuracy'], ascending=False)
    ordered = ordered.groupby('base_model', as_index=False, sort=False).head(1).sort_values('recall_defect', ascending=False)
    x = np.arange(len(ordered))
    labels = [f'{row.base_model}\nпорог = {row.threshold:g}' for row in ordered.itertuples()]
    plt.figure(figsize=(9.2, 5.2))
    plt.bar(x, ordered['recall_defect'], color=MAIN_COLOR, edgecolor=DARK_COLOR, alpha=0.85, label='Полнота обнаружения непровара')
    fold_columns = [c for c in ordered.columns if c.startswith('fold_') and c.endswith('_recall_defect')]
    for i, row in ordered.reset_index(drop=True).iterrows():
        values = [row[c] for c in fold_columns if pd.notna(row[c])]
        offsets = np.linspace(-0.12, 0.12, len(values))
        plt.scatter([x[i] + offset for offset in offsets], values, color=ACCENT_COLOR, edgecolors=DARK_COLOR, zorder=3, label='Значения разбиений' if i == 0 else None)
        plt.text(x[i], max(0.08, row['recall_defect'] / 2), f"{row['recall_defect']:.2f}", ha='center', va='center', color='white')
    plt.xticks(x, labels)
    plt.ylim(0, 1.08)
    plt.ylabel('Полнота обнаружения непровара')
    plt.xlabel('Классификатор')
    plt.title('Сравнение чувствительных классификаторов')
    plt.grid(axis='y', alpha=0.25, color=DARK_COLOR)
    plt.legend(loc='upper center', bbox_to_anchor=(0.5, -0.18), ncol=2)
    clean_axes()
    plt.tight_layout()
    plt.savefig(path, dpi=220)
    plt.close()

def confusion_plot(y_true, y_pred, path, title, figsize=(6.2, 5.0)):
    style()
    cm = confusion_matrix(y_true, y_pred, labels=LABEL_ORDER)
    normalized = confusion_matrix(y_true, y_pred, labels=LABEL_ORDER, normalize='true')
    cmap = LinearSegmentedColormap.from_list('quality_cmap', [BACKGROUND_COLOR, ACCENT_COLOR, MAIN_COLOR])
    plt.figure(figsize=figsize)
    plt.imshow(normalized, cmap=cmap, vmin=0, vmax=1)
    plt.xticks(range(2), RUS_LABELS)
    plt.yticks(range(2), RUS_LABELS)
    plt.xlabel('Предсказанный класс')
    plt.ylabel('Истинный класс')
    plt.title(title)
    for i in range(2):
        for j in range(2):
            plt.text(j, i, f'{normalized[i, j]:.2f}\n({cm[i, j]})', ha='center', va='center', color=DARK_COLOR)
    plt.colorbar(fraction=0.046, pad=0.04)
    plt.tight_layout(pad=1.1)
    plt.savefig(path, dpi=220)
    plt.close()

def feature_importance_plot(importances, path, top_n=25):
    if importances.empty:
        return
    style()
    top = importances.head(top_n).sort_values('importance')
    plt.figure(figsize=(8, 7))
    plt.barh(top['feature'], top['importance'], color=MAIN_COLOR, edgecolor=DARK_COLOR, alpha=0.85)
    plt.xlabel('Важность признака')
    plt.ylabel('Признак')
    plt.title('Наиболее важные признаки')
    plt.grid(axis='x', alpha=0.25, color=DARK_COLOR)
    clean_axes()
    plt.tight_layout()
    plt.savefig(path, dpi=300)
    plt.close()
if __name__ == '__main__':
    main()
