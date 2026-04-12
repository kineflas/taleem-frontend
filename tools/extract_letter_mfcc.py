#!/usr/bin/env python3
"""
extract_letter_mfcc.py
──────────────────────
Extrait les signatures MFCC de lettres / syllabes arabes isolées
à partir d'un fichier audio de récitation coranique.

Stratégie :
  1. Charger l'audio (MP3 / WAV)
  2. VAD (Voice Activity Detection) basée sur l'énergie RMS — détecte
     les segments de voix et les sépare par les silences.
  3. Pour chaque segment détecté :
     - Extraire 40 MFCC (coefficients) + delta + delta-delta
     - Sauvegarder le segment WAV + le vecteur MFCC (.npy)
     - Générer un CSV récapitulatif pour labellisation manuelle
  4. Mode "lettre cible" : si une transcription Buckwalter est fournie,
     aligner les segments avec les lettres attendues (forced alignment léger).

Dépendances :
  pip install librosa soundfile numpy pandas pydub tqdm

Usage :
  # Extraction simple (toutes les syllabes détectées)
  python extract_letter_mfcc.py --input al_husary_001.mp3 --output ./dataset/fatiha/

  # Avec texte de référence pour l'alignement
  python extract_letter_mfcc.py \\
    --input al_husary_001.mp3 \\
    --output ./dataset/fatiha/ \\
    --surah 1 \\
    --ayah 1

  # Traitement batch d'un dossier complet
  python extract_letter_mfcc.py --batch ./audios/ --output ./dataset/
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Optional

import librosa
import numpy as np
import pandas as pd
import soundfile as sf
from tqdm import tqdm

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

CFG = {
    # Audio
    "sample_rate": 16_000,          # wav2vec2 attend 16kHz
    "n_mfcc": 40,                   # nombre de coefficients MFCC
    "n_mels": 128,                  # filtres mel pour le spectrogramme
    "hop_length": 160,              # 10ms à 16kHz
    "win_length": 400,              # 25ms à 16kHz
    "fmax": 8_000,                  # fréquence max (suffisant pour la voix)

    # VAD (Voice Activity Detection) basée sur l'énergie
    "vad_top_db": 30,               # seuil de silence (dB sous le max)
    "vad_frame_length": 2048,
    "vad_hop_length": 512,
    "min_segment_ms": 80,           # ignorer les segments < 80ms (artéfacts)
    "max_segment_ms": 2_000,        # ignorer les segments > 2s (trop longs)
    "min_silence_ms": 100,          # silence minimum entre deux segments

    # Padding autour de chaque segment (pour ne pas couper les attaques)
    "pad_ms": 20,

    # MFCC : normalisation
    "normalize_mfcc": True,         # z-score par feature
}

# Alphabet arabe → Buckwalter (pour les labels CSV)
ARABIC_LETTERS = {
    'ا': 'A', 'ب': 'b', 'ت': 't', 'ث': 'v', 'ج': 'j', 'ح': 'H',
    'خ': 'x', 'د': 'd', 'ذ': '*', 'ر': 'r', 'ز': 'z', 'س': 's',
    'ش': '$', 'ص': 'S', 'ض': 'D', 'ط': 'T', 'ظ': 'Z', 'ع': 'E',
    'غ': 'g', 'ف': 'f', 'ق': 'q', 'ك': 'k', 'ل': 'l', 'م': 'm',
    'ن': 'n', 'ه': 'h', 'و': 'w', 'ي': 'y', 'ء': "'", 'آ': '|',
    'أ': '>', 'إ': '<', 'ة': 'p', 'ى': 'Y',
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. Chargement audio
# ─────────────────────────────────────────────────────────────────────────────

def load_audio(path: str) -> tuple[np.ndarray, int]:
    """Charge un fichier audio et resample à 16kHz mono."""
    print(f"[LOAD] {path}")
    audio, sr = librosa.load(path, sr=CFG["sample_rate"], mono=True)
    duration = len(audio) / sr
    print(f"       Durée : {duration:.2f}s | SR : {sr}Hz | Échantillons : {len(audio)}")
    return audio, sr


# ─────────────────────────────────────────────────────────────────────────────
# 2. VAD — Détection des segments de voix
# ─────────────────────────────────────────────────────────────────────────────

def detect_voice_segments(audio: np.ndarray, sr: int) -> list[tuple[float, float]]:
    """
    Retourne une liste de (start_sec, end_sec) pour chaque segment de voix
    détecté via suppression des silences (librosa.effects.split).
    """
    intervals = librosa.effects.split(
        audio,
        top_db=CFG["vad_top_db"],
        frame_length=CFG["vad_frame_length"],
        hop_length=CFG["vad_hop_length"],
    )

    segments = []
    pad_samples = int(CFG["pad_ms"] * sr / 1000)
    min_samples = int(CFG["min_segment_ms"] * sr / 1000)
    max_samples = int(CFG["max_segment_ms"] * sr / 1000)

    for start_idx, end_idx in intervals:
        # Appliquer le padding (sans dépasser les limites)
        start_padded = max(0, start_idx - pad_samples)
        end_padded   = min(len(audio), end_idx + pad_samples)
        length = end_padded - start_padded

        # Filtrer par durée min/max
        if length < min_samples:
            continue
        if length > max_samples:
            # Couper les longs segments en sous-segments de max_segment_ms
            for sub_start in range(start_padded, end_padded, max_samples):
                sub_end = min(sub_start + max_samples, end_padded)
                if sub_end - sub_start >= min_samples:
                    segments.append((sub_start / sr, sub_end / sr))
            continue

        segments.append((start_padded / sr, end_padded / sr))

    print(f"[VAD]  {len(segments)} segments détectés "
          f"(durées : {[f'{(e-s)*1000:.0f}ms' for s,e in segments[:5]]}...)")
    return segments


# ─────────────────────────────────────────────────────────────────────────────
# 3. Extraction MFCC
# ─────────────────────────────────────────────────────────────────────────────

def extract_mfcc(segment: np.ndarray, sr: int) -> np.ndarray:
    """
    Extrait un vecteur de features MFCC pour un segment audio.

    Retourne un array de shape (120,) :
      - 40 MFCC moyennés dans le temps
      - 40 delta-MFCC (vitesse de changement)
      - 40 delta-delta-MFCC (accélération)
    """
    mfcc = librosa.feature.mfcc(
        y=segment,
        sr=sr,
        n_mfcc=CFG["n_mfcc"],
        n_mels=CFG["n_mels"],
        hop_length=CFG["hop_length"],
        win_length=CFG["win_length"],
        fmax=CFG["fmax"],
    )

    # Delta et delta-delta pour capturer la dynamique temporelle
    delta_mfcc  = librosa.feature.delta(mfcc)
    delta2_mfcc = librosa.feature.delta(mfcc, order=2)

    # Agréger dans le temps : moyenne + std → vecteur fixe quelle que soit la durée
    features = np.concatenate([
        np.mean(mfcc, axis=1),
        np.std(mfcc, axis=1),
        np.mean(delta_mfcc, axis=1),
        np.mean(delta2_mfcc, axis=1),
    ])  # shape: (160,)

    # Normalisation z-score
    if CFG["normalize_mfcc"]:
        mean = features.mean()
        std  = features.std()
        features = (features - mean) / (std + 1e-8)

    return features


def extract_mfcc_matrix(segment: np.ndarray, sr: int, fixed_frames: int = 32) -> np.ndarray:
    """
    Extrait un spectrogramme MFCC 2D (pour CNN).
    Retourne shape (40, fixed_frames) — padded/truncated à fixed_frames.
    Utile pour entraîner un CNN de classification de lettres.
    """
    mfcc = librosa.feature.mfcc(
        y=segment,
        sr=sr,
        n_mfcc=CFG["n_mfcc"],
        hop_length=CFG["hop_length"],
        win_length=CFG["win_length"],
    )

    # Normaliser chaque coefficient (Z-score par feature)
    mfcc = (mfcc - mfcc.mean(axis=1, keepdims=True)) / (mfcc.std(axis=1, keepdims=True) + 1e-8)

    # Padding ou troncature à fixed_frames
    if mfcc.shape[1] < fixed_frames:
        pad_width = fixed_frames - mfcc.shape[1]
        mfcc = np.pad(mfcc, ((0, 0), (0, pad_width)), mode='constant')
    else:
        mfcc = mfcc[:, :fixed_frames]

    return mfcc  # shape (40, 32)


# ─────────────────────────────────────────────────────────────────────────────
# 4. Pipeline principal
# ─────────────────────────────────────────────────────────────────────────────

def process_file(
    audio_path: str,
    output_dir: str,
    surah: Optional[int] = None,
    ayah: Optional[int] = None,
    label_prefix: str = "unknown",
) -> pd.DataFrame:
    """
    Traite un fichier audio et extrait tous les segments.

    Retourne un DataFrame avec les métadonnées de chaque segment
    (pour labellisation manuelle dans un tableur).
    """
    output_path = Path(output_dir)
    wav_dir  = output_path / "wavs"
    mfcc_dir = output_path / "mfcc"
    wav_dir.mkdir(parents=True, exist_ok=True)
    mfcc_dir.mkdir(parents=True, exist_ok=True)

    # Charger l'audio
    audio, sr = load_audio(audio_path)

    # Détecter les segments de voix
    segments = detect_voice_segments(audio, sr)

    records = []
    for i, (start_sec, end_sec) in enumerate(tqdm(segments, desc="Extraction MFCC")):
        start_sample = int(start_sec * sr)
        end_sample   = int(end_sec * sr)
        segment_audio = audio[start_sample:end_sample]

        duration_ms = (end_sec - start_sec) * 1000

        # Nom de fichier
        prefix = f"{label_prefix}_s{surah:03d}_a{ayah:03d}" if surah and ayah else label_prefix
        filename = f"{prefix}_{i:04d}"

        # Sauvegarder WAV du segment
        wav_path = wav_dir / f"{filename}.wav"
        sf.write(str(wav_path), segment_audio, sr)

        # Extraire et sauvegarder MFCC vecteur (160,)
        mfcc_vec = extract_mfcc(segment_audio, sr)
        vec_path = mfcc_dir / f"{filename}_vec.npy"
        np.save(str(vec_path), mfcc_vec)

        # Extraire et sauvegarder MFCC matrice (40, 32) pour CNN
        mfcc_mat = extract_mfcc_matrix(segment_audio, sr)
        mat_path = mfcc_dir / f"{filename}_mat.npy"
        np.save(str(mat_path), mfcc_mat)

        records.append({
            "id":           filename,
            "source_file":  os.path.basename(audio_path),
            "start_sec":    round(start_sec, 4),
            "end_sec":      round(end_sec, 4),
            "duration_ms":  round(duration_ms, 1),
            "surah":        surah,
            "ayah":         ayah,
            "segment_idx":  i,
            "wav_path":     str(wav_path.relative_to(output_path)),
            "mfcc_vec_path":str(vec_path.relative_to(output_path)),
            "mfcc_mat_path":str(mat_path.relative_to(output_path)),
            # À remplir manuellement ou via forced alignment :
            "label_arabic": "",    # ex: "بِ"
            "label_buckwalter": "", # ex: "bi"
            "label_type":   "",    # "letter", "syllable", "madd", "tanwin"
            "madd_counts":  "",    # 2 / 4 / 6 si type == "madd"
            "confidence":   "",    # 0.0-1.0 (rempli après validation)
            "verified":     False,
        })

    df = pd.DataFrame(records)

    # Sauvegarder le CSV pour labellisation
    csv_path = output_path / f"{label_prefix}_labels.csv"
    df.to_csv(str(csv_path), index=False, encoding="utf-8-sig")
    print(f"\n[OK]   {len(records)} segments extraits → {csv_path}")
    print(f"       Ouvre le CSV dans un tableur et remplis les colonnes 'label_*'")

    return df


def process_batch(audio_dir: str, output_dir: str) -> None:
    """Traite tous les fichiers MP3/WAV d'un dossier."""
    audio_files = list(Path(audio_dir).glob("**/*.mp3")) + \
                  list(Path(audio_dir).glob("**/*.wav"))

    print(f"[BATCH] {len(audio_files)} fichiers trouvés dans {audio_dir}")

    all_dfs = []
    for audio_path in audio_files:
        df = process_file(
            audio_path=str(audio_path),
            output_dir=output_dir,
            label_prefix=audio_path.stem,
        )
        all_dfs.append(df)

    # CSV global
    if all_dfs:
        combined = pd.concat(all_dfs, ignore_index=True)
        combined_path = Path(output_dir) / "all_segments_labels.csv"
        combined.to_csv(str(combined_path), index=False, encoding="utf-8-sig")
        print(f"\n[BATCH] CSV global : {combined_path}")
        print(f"         Total segments : {len(combined)}")
        _print_duration_stats(combined)


def _print_duration_stats(df: pd.DataFrame) -> None:
    """Affiche des statistiques sur la distribution des durées."""
    d = df["duration_ms"]
    print(f"\n── Statistiques durées ──────────────────────")
    print(f"  Moyenne : {d.mean():.0f}ms")
    print(f"  Médiane : {d.median():.0f}ms")
    print(f"  Min     : {d.min():.0f}ms")
    print(f"  Max     : {d.max():.0f}ms")
    print(f"  < 100ms : {(d < 100).sum()} segments (lettres courtes)")
    print(f"  100-400ms : {((d >= 100) & (d < 400)).sum()} segments (syllabes)")
    print(f"  400-800ms : {((d >= 400) & (d < 800)).sum()} segments (madd tabii)")
    print(f"  800ms+  : {(d >= 800).sum()} segments (madd long)")
    print(f"─────────────────────────────────────────────")


# ─────────────────────────────────────────────────────────────────────────────
# 5. Utilitaires pour le dataset
# ─────────────────────────────────────────────────────────────────────────────

def build_dataset_from_labeled_csv(csv_path: str, output_dir: str) -> None:
    """
    Une fois le CSV labellisé manuellement, génère le dataset structuré
    pour l'entraînement :
      dataset/
        letters/
          ب/  ← une lettre par dossier
            b_0001_vec.npy
            b_0001.wav
        syllables/
          بِ/
            ...
        madd/
          tabii/ munfasil/ lazim/
            ...
    """
    df = pd.read_csv(csv_path, encoding="utf-8-sig")
    df_verified = df[df["verified"] == True]

    print(f"[BUILD DATASET] {len(df_verified)}/{len(df)} segments vérifiés")

    output_path = Path(output_dir)

    for _, row in tqdm(df_verified.iterrows(), total=len(df_verified)):
        label_type   = str(row.get("label_type", "")).strip()
        label_arabic = str(row.get("label_arabic", "")).strip()
        madd_counts  = str(row.get("madd_counts", "")).strip()

        if label_type == "letter" and label_arabic:
            dest_dir = output_path / "letters" / label_arabic
        elif label_type == "syllable" and label_arabic:
            dest_dir = output_path / "syllables" / label_arabic
        elif label_type == "madd" and madd_counts:
            madd_label = {
                "2": "tabii", "4": "munfasil", "6": "lazim"
            }.get(str(int(float(madd_counts))), "unknown")
            dest_dir = output_path / "madd" / madd_label
        else:
            continue

        dest_dir.mkdir(parents=True, exist_ok=True)

        src_wav  = output_path.parent / str(row["wav_path"])
        src_vec  = output_path.parent / str(row["mfcc_vec_path"])
        src_mat  = output_path.parent / str(row["mfcc_mat_path"])

        for src in [src_wav, src_vec, src_mat]:
            if src.exists():
                import shutil
                shutil.copy2(str(src), str(dest_dir / src.name))

    print(f"[OK] Dataset structuré dans {output_dir}")


def generate_dataset_stats(dataset_dir: str) -> None:
    """Affiche les statistiques du dataset final (nombre d'exemples par classe)."""
    dataset_path = Path(dataset_dir)
    print(f"\n── Dataset Stats : {dataset_dir} ──────────────────")

    for category in ["letters", "syllables", "madd"]:
        cat_path = dataset_path / category
        if not cat_path.exists():
            continue
        print(f"\n  📁 {category}/")
        for class_dir in sorted(cat_path.iterdir()):
            if class_dir.is_dir():
                wav_count = len(list(class_dir.glob("*.wav")))
                print(f"     {class_dir.name:12s} : {wav_count} exemples "
                      f"{'✅' if wav_count >= 30 else '⚠️  (besoin de plus)'}")


# ─────────────────────────────────────────────────────────────────────────────
# 6. CLI
# ─────────────────────────────────────────────────────────────────────────────

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extraction MFCC de lettres arabes à partir d'audio coranique",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument("--input",  type=str, help="Fichier audio (MP3/WAV)")
    parser.add_argument("--output", type=str, required=True, help="Dossier de sortie")
    parser.add_argument("--batch",  type=str, help="Dossier contenant plusieurs audios")
    parser.add_argument("--surah",  type=int, help="Numéro de sourate")
    parser.add_argument("--ayah",   type=int, help="Numéro d'ayah")
    parser.add_argument("--prefix", type=str, default="seg", help="Préfixe des fichiers")
    parser.add_argument("--stats",  type=str, help="Afficher stats d'un dataset existant")
    parser.add_argument("--build-from-csv", type=str,
                        help="Construire le dataset structuré depuis un CSV labellisé")

    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if args.stats:
        generate_dataset_stats(args.stats)
        return

    if args.build_from_csv:
        build_dataset_from_labeled_csv(args.build_from_csv, args.output)
        return

    if args.batch:
        process_batch(args.batch, args.output)
        return

    if args.input:
        process_file(
            audio_path=args.input,
            output_dir=args.output,
            surah=args.surah,
            ayah=args.ayah,
            label_prefix=args.prefix,
        )
        return

    print("Erreur : spécifie --input ou --batch. Utilise --help pour plus d'infos.")
    sys.exit(1)


if __name__ == "__main__":
    main()
