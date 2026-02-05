#!/usr/bin/env python3
import argparse
import sys
from collections import defaultdict

import ahocorasick
import pyfastx


def clean_pep(s: str, keep_ambiguous: bool = True) -> str:
    """
    Clean peptide sequence:
    - uppercases
    - removes whitespace
    - keeps standard 20 AAs
    - optionally keeps ambiguous/rare AA letters (X, U, O, B, Z, J)
    """
    s = s.strip().upper()

    std = set("ACDEFGHIKLMNPQRSTVWY")
    amb = set("XUOBJZ")  # common ambiguous/rare letters seen in some databases
    allowed = std.union(amb) if keep_ambiguous else std

    return "".join([c for c in s if c in allowed])


def iter_fasta_records(fasta_path: str, build_index: bool = False):
    """
    Yield (name, seq_str) pairs from a FASTA using pyfastx,
    handling different pyfastx iteration behaviors.
    """
    fa = pyfastx.Fasta(fasta_path, build_index=build_index)

    for rec in fa:
        # Newer pyfastx yields a record object with .name/.seq
        if hasattr(rec, "name") and hasattr(rec, "seq"):
            name = rec.name
            seq = str(rec.seq)
            yield name, seq
        else:
            # Some versions/behaviors can yield tuples; handle safely
            if isinstance(rec, tuple) and len(rec) >= 2:
                yield rec[0], rec[1]
            else:
                # Last resort: treat as sequence only (no header)
                yield "UNKNOWN", str(rec)


def load_epitopes(fasta_path: str, min_len: int, max_len: int, build_index: bool):
    """
    Build an Aho–Corasick automaton from epitope FASTA.

    Returns:
      automaton: Aho automaton where each match returns (peptide, [epitope_ids])
      stats: (n_total_records, n_kept_records, n_unique_peptides)
    """
    A = ahocorasick.Automaton()
    payload = defaultdict(list)

    n_total = 0
    n_kept = 0

    for name, seq in iter_fasta_records(fasta_path, build_index=build_index):
        n_total += 1
        pep = clean_pep(seq, keep_ambiguous=True)
        if not pep:
            continue
        L = len(pep)
        if (min_len and L < min_len) or (max_len and L > max_len):
            continue
        payload[pep].append(name)
        n_kept += 1

    for pep, ids in payload.items():
        A.add_word(pep, (pep, ids))
    A.make_automaton()

    return A, n_total, n_kept, len(payload)


def main():
    ap = argparse.ArgumentParser(description="Exact peptide-in-protein matching using Aho–Corasick.")
    ap.add_argument("--epitopes", required=True, help="Epitope FASTA (peptides)")
    ap.add_argument("--proteins", required=True, help="Protein FASTA (targets)")
    ap.add_argument("--out", required=True, help="Output TSV")
    ap.add_argument("--min-len", type=int, default=0, help="Minimum epitope length to include (0 = no min)")
    ap.add_argument("--max-len", type=int, default=0, help="Maximum epitope length to include (0 = no max)")
    ap.add_argument("--build-index", action="store_true",
                    help="Allow pyfastx to build .fxi index files next to FASTA (off by default)")
    args = ap.parse_args()

    A, n_total, n_kept, n_unique = load_epitopes(
        args.epitopes, args.min_len, args.max_len, build_index=args.build_index
    )
    print(
        f"[acmatch] epitopes: total={n_total} kept={n_kept} unique_peptides={n_unique}",
        file=sys.stderr
    )

    hits = 0
    prots = 0

    # Output columns:
    # protein_id, start_1based, end_1based, peptide, epitope_ids(comma-separated)
    with open(args.out, "w") as out:
        out.write("protein\tstart\tend\tpeptide\tepitope_ids\n")

        for prot_id, prot_seq in iter_fasta_records(args.proteins, build_index=args.build_index):
            prots += 1
            prot_seq = str(prot_seq).upper()

            for end_idx, (pep, ids) in A.iter(prot_seq):
                L = len(pep)
                start0 = end_idx - L + 1
                out.write(
                    f"{prot_id}\t{start0+1}\t{end_idx+1}\t{pep}\t{','.join(ids)}\n"
                )
                hits += 1

    print(f"[acmatch] proteins={prots} hits={hits} wrote={args.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
