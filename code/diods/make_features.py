from pathlib import Path

import pandas as pd

from Parser import Parser


DATA_PATH = Path(__file__).resolve().parents[1] / "data"
OUTPUT_FILE = Path(__file__).with_name("window_features.xlsx")
WINDOW_SIZE = 1500
STEP = 750
FS = 1
PARAMS = [
    (1.5, 3.26),
    (2.0, 1.89),
    (3.5, 0),
    (1.5, 2.97),
    (2.0, 1.78),
    (3.5, 0),
    (1.5, 2.85),
    (2.0, 2.45),
    (3.5, 0.25),
]


def main():
    rows = []
    files = sorted(DATA_PATH.glob("*.txt"))

    for path, (power, h_i) in zip(files, PARAMS):
        signal = Parser(path).parse()
        signal.power = power
        signal.h_i = h_i
        rows.extend(signal.get_window_features(WINDOW_SIZE, STEP, FS))

    pd.DataFrame(rows).to_excel(OUTPUT_FILE, index=False)


main()
