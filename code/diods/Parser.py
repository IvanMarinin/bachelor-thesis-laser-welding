import json
from pathlib import Path

import numpy as np

from Signal import Signal


class Parser:
    def __init__(self, path, threshold_factor=100, begin_offset=2500, end_offset=1000):
        self.path = Path(path)
        self.threshold_factor = threshold_factor
        self.begin_offset = begin_offset
        self.end_offset = end_offset

    def parse(self):
        with self.path.open("rb") as f:
            header_size = int.from_bytes(f.read(4), "little")
            header = json.loads(f.read(header_size).decode("utf-8"))
            raw = np.frombuffer(f.read(), dtype="<i2")

        n = header["BasicInfo"]["length"]
        channels = len(header["ChannelList"])
        data = raw.reshape(channels, n).T

        reflected = data[:, 2]
        background = np.mean(np.r_[reflected[:1000], reflected[-2000:]])
        active = np.where(reflected > self.threshold_factor * background)[0]
        begin = max(0, active[0] + self.begin_offset)
        end = min(n, active[-1] - self.end_offset)

        return Signal(
            filename=self.path.name,
            header=header,
            time=np.arange(end - begin),
            unknown=data[begin:end, 0],
            visible=data[begin:end, 1],
            reflected=data[begin:end, 2],
            infrared=data[begin:end, 3],
        )
