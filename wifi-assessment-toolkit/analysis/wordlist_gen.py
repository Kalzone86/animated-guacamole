#!/usr/bin/env python3
"""Client-targeted wordlist generator.

Real corporate/home WPA passphrases are usually built from things about the
target: the company name, the town, a founding year, a phone number, a pet.
A generic 14 GB dump rarely hits them; a focused list built from client facts
often does. This builds that focused list.

Use it to test passphrase strength against a network you are AUTHORIZED to test.
The candidates never leave your machine; you feed the list to hashcat/aircrack.

Usage:
    python3 wordlist_gen.py --profile client.yaml -o client_wordlist.txt
    python3 wordlist_gen.py --words acme "Main St" 1998 --out list.txt

client.yaml example:
    seeds: ["Acme", "Acme Corp", "Springfield", "1998", "555-0100"]
    min_len: 8            # WPA passphrases are >= 8 chars; shorter is wasted
    max_len: 32
    years: [2018, 2026]   # append a range of years
"""
import argparse
import itertools
import sys

LEET = str.maketrans({"a": "4", "e": "3", "i": "1", "o": "0", "s": "5", "t": "7"})
SUFFIXES = ["", "!", "1", "12", "123", "1234", "!", "@", "#", "01", "00", "007"]


def base_forms(seed: str):
    s = seed.strip()
    if not s:
        return set()
    forms = {s, s.lower(), s.upper(), s.capitalize(), s.replace(" ", ""),
             s.replace(" ", "").lower(), s.title().replace(" ", "")}
    forms |= {f.translate(LEET) for f in list(forms)}
    return {f for f in forms if f}


def expand(seeds, years, min_len, max_len):
    bases = set()
    for s in seeds:
        bases |= base_forms(s)
    year_suffixes = [str(y) for y in years]
    out = set()
    for b in bases:
        for suf in SUFFIXES + year_suffixes:
            out.add(b + suf)
        # two-seed combos catch "AcmeSpringfield", "Acme2020"
    for a, b in itertools.permutations(list(bases), 2):
        combo = a + b
        if len(combo) <= max_len:
            out.add(combo)
    return {w for w in out if min_len <= len(w) <= max_len}


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--profile", help="YAML profile with seeds/years/lengths")
    ap.add_argument("--words", nargs="*", default=[], help="seed words on CLI")
    ap.add_argument("--min-len", type=int, default=8)
    ap.add_argument("--max-len", type=int, default=32)
    ap.add_argument("--years", nargs="*", type=int, default=[])
    ap.add_argument("-o", "--out", required=True)
    args = ap.parse_args()

    seeds = list(args.words)
    years = list(args.years)
    min_len, max_len = args.min_len, args.max_len

    if args.profile:
        try:
            import yaml
        except ImportError:
            sys.exit("PyYAML needed for --profile: pip install pyyaml")
        with open(args.profile) as fh:
            cfg = yaml.safe_load(fh) or {}
        seeds += cfg.get("seeds", [])
        min_len = cfg.get("min_len", min_len)
        max_len = cfg.get("max_len", max_len)
        yr = cfg.get("years")
        if isinstance(yr, list) and len(yr) == 2:
            years += list(range(yr[0], yr[1] + 1))
        elif isinstance(yr, list):
            years += yr

    if not seeds:
        sys.exit("No seed words. Use --words or --profile.")

    words = sorted(expand(seeds, years, min_len, max_len))
    with open(args.out, "w") as fh:
        fh.write("\n".join(words) + "\n")
    print(f"[+] Wrote {len(words)} candidates -> {args.out}")
    print(f"    Next: ./crack_own_network.sh <hash.hc22000> {args.out}")
    if len(words) > 5_000_000:
        print("[!] Large list; consider trimming seeds. hashcat rules can expand "
              "a small list further at run time.")


if __name__ == "__main__":
    main()
