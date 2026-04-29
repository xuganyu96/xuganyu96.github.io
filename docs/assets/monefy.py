#!/usr/bin/python3
"""Analyze Monefy CSV export"""

import argparse
import pandas as pd


def get_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="monefy", description="Analyze Monefy CSV export"
    )

    parser.add_argument("-f", "--file", help="CSV file", required=True)
    parser.add_argument(
        "--year", default=None, type=int, help="Filter by year if specified"
    )
    parser.add_argument(
        "--month", default=None, type=int, help="Filter by month if specified"
    )
    parser.add_argument("--category", type=str, help="Filter by category if specified")

    return parser


def main():
    pass


if __name__ == "__main__":
    parser = get_parser()
    args = parser.parse_args()

    with open(args.file) as f:
        data = pd.read_csv(f)

    data["date"] = pd.to_datetime(data["date"])
    data["month"] = data["date"].apply(lambda x: x.date().month)
    data["year"] = data["date"].apply(lambda x: x.date().year)

    if args.year:
        data = data.loc[data["year"] == args.year]
    if args.month:
        data = data.loc[data["month"] == args.month]
    if args.category:
        data = data.loc[data["category"] == args.category]

    agg = data.groupby(["year", "month", "category", "description"]).aggregate(
        {"amount": "sum"}
    ).sort_values("amount")

    print(agg)
