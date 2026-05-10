import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

from itertools import combinations
from pathlib import Path
from matplotlib.colors import LinearSegmentedColormap
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis
from sklearn.ensemble import GradientBoostingClassifier, GradientBoostingRegressor, RandomForestClassifier, RandomForestRegressor
from sklearn.linear_model import Lasso, LinearRegression, LogisticRegression, Ridge
from sklearn.metrics import ConfusionMatrixDisplay, confusion_matrix, mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import KFold, StratifiedKFold, cross_val_predict, cross_validate
from sklearn.neighbors import KNeighborsClassifier, KNeighborsRegressor
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC, SVR


BASE = Path(__file__).resolve().parent
INPUT_FILE = BASE / "window_features.xlsx"
SERVICE_COLUMNS = ["filename", "power", "h_i", "defect_label", "window_index", "begin", "end"]
COLORS = ["#DDD8D2", "#B7743B", "#66130F", "#142421"]
SCATTER_FEATURES = [
    "visible_mean",
    "visible_std",
    "visible_rms",
    "visible_energy",
    "visible_peak_to_peak",
    "infrared_mean",
    "infrared_std",
    "infrared_rms",
    "infrared_energy",
    "infrared_peak_to_peak",
    "visible_to_infrared_mean_ratio",
    "corr_visible_infrared",
    "visible_fft_high_energy_ratio",
    "visible_fft_spectral_centroid",
    "visible_fft_high_to_low_ratio",
    "infrared_fft_high_energy_ratio",
    "infrared_fft_spectral_centroid",
    "infrared_fft_high_to_low_ratio",
]


def features(data, without_reflected=False):
    cols = [c for c in data.columns if c not in SERVICE_COLUMNS]
    if without_reflected:
        cols = [c for c in cols if not c.startswith("reflected") and "_reflected" not in c]
    X = data[cols].replace([np.inf, -np.inf], np.nan).fillna(0)
    return X


def classifier_models():
    return {
        "LDA": make_pipeline(StandardScaler(), LinearDiscriminantAnalysis()),
        "LogisticRegression": make_pipeline(StandardScaler(), LogisticRegression(max_iter=3000)),
        "SVM_linear": make_pipeline(StandardScaler(), SVC(kernel="linear", C=1)),
        "SVM_RBF": make_pipeline(StandardScaler(), SVC(kernel="rbf", C=1, gamma="scale")),
        "kNN_5": make_pipeline(StandardScaler(), KNeighborsClassifier(n_neighbors=5)),
        "RandomForest": RandomForestClassifier(n_estimators=300, random_state=42),
        "GradientBoosting": GradientBoostingClassifier(random_state=42),
    }


def regressor_models():
    return {
        "LinearRegression": make_pipeline(StandardScaler(), LinearRegression()),
        "Ridge": make_pipeline(StandardScaler(), Ridge(alpha=1.0)),
        "Lasso": make_pipeline(StandardScaler(), Lasso(alpha=0.01, max_iter=10000)),
        "SVR_RBF": make_pipeline(StandardScaler(), SVR(kernel="rbf", C=1.0, gamma="scale")),
        "kNN_5": make_pipeline(StandardScaler(), KNeighborsRegressor(n_neighbors=5)),
        "RandomForest": RandomForestRegressor(n_estimators=300, random_state=42),
        "GradientBoosting": GradientBoostingRegressor(random_state=42),
    }


def compare_models(models, X, y, cv, scoring, main_score, output_xlsx, output_png, ylabel, xlabel, title, ylim=None, smaller_is_better=False):
    rows = []
    for name, model in models.items():
        scores = cross_validate(model, X, y, cv=cv, scoring=scoring)
        row = {"model": name}
        for key in scoring:
            values = scores[f"test_{key}"]
            if key in ["mae", "rmse"]:
                values = -values
            row[f"mean_{key}"] = values.mean()
            row[f"std_{key}"] = values.std()
        for i, value in enumerate(scores[f"test_{main_score}"], 1):
            row[f"fold_{i}"] = -value if main_score in ["mae", "rmse"] else value
        rows.append(row)

    result = pd.DataFrame(rows).sort_values(f"mean_{main_score}", ascending=smaller_is_better).reset_index(drop=True)
    result.to_excel(BASE / output_xlsx, index=False)
    plot_bars(result, f"mean_{main_score}", f"std_{main_score}", BASE / output_png, ylabel, xlabel, title, ylim)
    return result


def plot_bars(result, mean_col, std_col, output_png, ylabel, xlabel, title, ylim=None):
    x = range(len(result))
    plt.figure(figsize=(10, 5))
    plt.bar(
        x,
        result[mean_col],
        yerr=result[std_col],
        capsize=10,
        color=COLORS[2],
        edgecolor=COLORS[3],
        linewidth=0.8,
        alpha=0.85,
        error_kw={"ecolor": COLORS[3], "elinewidth": 2.5, "capthick": 2.5},
    )
    folds = [c for c in result.columns if c.startswith("fold_")]
    for i, row in result.iterrows():
        plt.scatter([i] * len(folds), [row[c] for c in folds], color=COLORS[1], edgecolors=COLORS[3], linewidths=0.5, s=35, zorder=3)
    plt.xticks(ticks=x, labels=result["model"], rotation=30, ha="right")
    if ylim:
        plt.ylim(*ylim)
    plt.ylabel(ylabel)
    plt.xlabel(xlabel)
    plt.title(title)
    plt.grid(axis="y", alpha=0.25, color=COLORS[3])
    ax = plt.gca()
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(COLORS[3])
    ax.spines["bottom"].set_color(COLORS[3])
    plt.tight_layout()
    plt.savefig(output_png, dpi=600)
    plt.close()


def plot_confusion(X, y):
    cv = StratifiedKFold(n_splits=5, shuffle=True, random_state=42)
    pred = cross_val_predict(classifier_models()["LDA"], X, y, cv=cv)
    labels = ["full_penetration", "incomplete_penetration"]
    cm = confusion_matrix(y, pred, labels=labels, normalize="true")
    cmap = LinearSegmentedColormap.from_list("cmap", COLORS[:3])
    ConfusionMatrixDisplay(cm, display_labels=["Полное\nпроплавление", "Непровар"]).plot(values_format=".2f", cmap=cmap, colorbar=True)
    plt.title("Матрица ошибок: LDA")
    plt.xlabel("Предсказанный класс")
    plt.ylabel("Истинный класс")
    plt.tight_layout()
    plt.savefig(BASE / "defect_confusion_matrix.png", dpi=600)
    plt.close()


def plot_predictions(X, y):
    cv = KFold(n_splits=5, shuffle=True, random_state=42)
    pred = cross_val_predict(regressor_models()["GradientBoosting"], X, y, cv=cv)
    true_values = np.sort(np.unique(y))
    grouped = [pred[y == value] for value in true_values]
    lo = min(y.min(), pred.min())
    hi = max(y.max(), pred.max())
    pad = 0.08 * (hi - lo) or 0.1
    plot_min = lo - pad
    plot_max = hi + pad
    box_width = 0.35 * np.min(np.diff(true_values)) if len(true_values) > 1 else 0.2

    plt.figure(figsize=(8, 6))
    box = plt.boxplot(grouped, positions=true_values, widths=box_width, patch_artist=True, showfliers=True, manage_ticks=False)
    for patch in box["boxes"]:
        patch.set_facecolor(COLORS[2])
        patch.set_alpha(0.75)
        patch.set_edgecolor(COLORS[3])
        patch.set_linewidth(1.0)
    for part in ["whiskers", "caps"]:
        for item in box[part]:
            item.set_color(COLORS[3])
            item.set_linewidth(1.4)
    for median in box["medians"]:
        median.set_color("white")
        median.set_linewidth(1.6)
    for flier in box["fliers"]:
        flier.set_marker("o")
        flier.set_markerfacecolor(COLORS[1])
        flier.set_markeredgecolor(COLORS[3])
        flier.set_alpha(0.45)
        flier.set_markersize(3)
    plt.plot([plot_min, plot_max], [plot_min, plot_max], color=COLORS[3], linewidth=1.5, linestyle="--", label="Идеальное соответствие $y=x$", zorder=2)
    plt.scatter(true_values, true_values, color=COLORS[1], edgecolors=COLORS[3], linewidths=0.7, s=55, zorder=4, label="Фактическое значение $h_i$")
    plt.text(
        0.03,
        0.97,
        f"MAE = {mean_absolute_error(y, pred):.3f} мм\nRMSE = {np.sqrt(mean_squared_error(y, pred)):.3f} мм\n$R^2$ = {r2_score(y, pred):.3f}",
        transform=plt.gca().transAxes,
        verticalalignment="top",
        bbox={"boxstyle": "round", "facecolor": COLORS[0], "edgecolor": COLORS[1], "alpha": 0.9},
    )
    plt.xlim(plot_min, plot_max)
    plt.ylim(plot_min, plot_max)
    plt.xlabel("Фактическое значение $h_i$, мм")
    plt.ylabel("Предсказанное значение $h_i$, мм")
    plt.title("Распределение предсказаний $h_i$ по окнам: GradientBoosting")
    plt.grid(True, alpha=0.25, color=COLORS[3])
    plt.legend()
    ax = plt.gca()
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color(COLORS[3])
    ax.spines["bottom"].set_color(COLORS[3])
    plt.tight_layout()
    plt.savefig(BASE / "hi_true_vs_predicted.png", dpi=600)
    plt.close()


def plot_scatters(data):
    out = BASE / "defect_scatter_plots"
    out.mkdir(exist_ok=True)
    styles = {
        "full_penetration": ("Полное проплавление", COLORS[3]),
        "incomplete_penetration": ("Неполное проплавление", COLORS[2]),
    }

    for x, y in combinations(SCATTER_FEATURES, 2):
        plt.figure(figsize=(7, 5))
        for label, (title, color) in styles.items():
            part = data[data["defect_label"] == label]
            plt.scatter(part[x], part[y], label=title, color=color, alpha=0.75, s=28, edgecolors="white", linewidths=0.3)
        plt.xlabel(x)
        plt.ylabel(y)
        plt.title(f"{x} vs {y}")
        plt.grid(True, alpha=0.25)
        plt.legend(title="Класс")
        plt.tight_layout()
        plt.savefig(out / f"scatter_{x}_vs_{y}.png", dpi=600)
        plt.close()


def main():
    data = pd.read_excel(INPUT_FILE)

    Xc = features(data)
    yc = data["defect_label"].astype(str)
    compare_models(
        classifier_models(),
        Xc,
        yc,
        StratifiedKFold(n_splits=5, shuffle=True, random_state=42),
        {"accuracy": "accuracy", "balanced_accuracy": "balanced_accuracy", "f1": "f1_macro"},
        "balanced_accuracy",
        "defect_classifier_comparison.xlsx",
        "defect_classifier_comparison.png",
        "Balanced accuracy",
        "Классификатор",
        "Сравнение классификаторов для обнаружения неполного проплавления",
        ylim=(0, 1),
    )
    plot_confusion(Xc, yc)
    plot_scatters(data)

    Xr = features(data, without_reflected=False)
    yr = data["h_i"].astype(float)
    compare_models(
        regressor_models(),
        Xr,
        yr,
        KFold(n_splits=5, shuffle=True, random_state=42),
        {"mae": "neg_mean_absolute_error", "rmse": "neg_root_mean_squared_error", "r2": "r2"},
        "mae",
        "hi_regression_comparison.xlsx",
        "hi_regression_comparison.png",
        "MAE по $h_i$, мм",
        "Регрессионная модель",
        "Сравнение моделей регрессии для оценки $h_i$",
        smaller_is_better=True,
    )
    plot_predictions(Xr, yr)


main()
