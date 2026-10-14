"""Rebuild the three organic cues from the private shared Sonniss library."""

import argparse
import hashlib
from pathlib import Path
import struct
import subprocess


ROOT = Path(__file__).resolve().parents[1]
SOURCES = (
    ("tap", "Epic Stock Media - Board Game - Sound Set Kit for Tabletop and Digital Games/GAMEBoard_Game Play Piece Action Organic Connect Dots Fall Bounce 04_ESM_BG.wav", "e834e6c3fcd8bf7fa69ad076d37cfbee36abea5a053263eb2186e6415dde5a5e", -10),
    ("next", "Cinematic Sound Design - Paper Foley/Encyclopedia Glossy Page Turn Muted.wav", "0746668350526caa62127530fa43dead246ab423a0996f4cc87774d1fed3f61d", -10),
    ("success", "CB_Sounddesign - Applicable Sounds - Organic UI and Building Games SFX/UIMisc_Kalimba 3 Up_CB Sounddesign_APPlicable Sounds.wav", "0298f3405836720e064d1ff486f58fa032b03009d6f9e55e668b84e759dca360", -9),
)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--library", type=Path, default=ROOT.parents[1] / "Assets/sfx-library/sonniss-gdc-2026/library")
    args = parser.parse_args()
    for name, relative, digest, peak_db in SOURCES:
        source = args.library / relative
        if hashlib.sha256(source.read_bytes()).hexdigest() != digest:
            raise RuntimeError(f"Source checksum mismatch: {source}")
        pcm = subprocess.check_output([
            "ffmpeg", "-v", "error", "-i", str(source), "-ar", "22050", "-ac", "1",
            "-f", "f32le", "-c:a", "pcm_f32le", "-",
        ])
        peak = max(abs(sample[0]) for sample in struct.iter_unpack("<f", pcm))
        gain = 10 ** (peak_db / 20) / peak
        duration = len(pcm) / 4 / 22050
        output = ROOT / "assets/sfx" / f"{name}.wav"
        subprocess.run([
            "ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", "22050", "-ac", "1",
            "-i", "-", "-af", f"volume={gain:.10f},afade=t=out:st={max(0, duration - 0.02):.6f}:d=0.02",
            "-map_metadata", "-1", "-fflags", "+bitexact", "-c:a", "pcm_s16le", str(output),
        ], input=pcm, check=True)
        print(f"{output}: {duration:.3f}s, peak ceiling {peak_db} dBFS, sha256 {hashlib.sha256(output.read_bytes()).hexdigest()}")


if __name__ == "__main__":
    main()
