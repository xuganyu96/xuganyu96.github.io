#!/usr/bin/env python3

"""Compare rate limits between githubusercontent.com, api.github.com w/o auth,
and api.github.com w/ auth
"""

import os
import pprint
import requests


if __name__ == "__main__":
    ghuc_resp = requests.get(
        "https://raw.githubusercontent.com/usnistgov/ACVP-Server/refs/tags/v1.1.0.42/gen-val/json-files/ML-KEM-encapDecap-FIPS203/internalProjection.json"
    )
    ghuc_resp.raise_for_status()
    pprint.pp(dict(ghuc_resp.headers))

    ghapi_noauth_resp = requests.get(
        "https://api.github.com/repos/usnistgov/ACVP-Server/contents/gen-val/json-files/ML-KEM-encapDecap-FIPS203/internalProjection.json",
        headers={
            "Accept": "application/vnd.github.raw+json",
            "X-GitHub-Api-Version": "2026-03-10",
        },
        params={
            "ref": "v1.1.0.42",
        },
    )
    ghapi_noauth_resp.raise_for_status()
    pprint.pp(dict(ghapi_noauth_resp.headers))

    gh_token = os.getenv("GH_TOKEN")
    if gh_token:
        ghapi_auth_resp = requests.get(
            "https://api.github.com/repos/usnistgov/ACVP-Server/contents/gen-val/json-files/ML-KEM-encapDecap-FIPS203/internalProjection.json",
            headers={
                "Accept": "application/vnd.github.raw+json",
                "X-GitHub-Api-Version": "2026-03-10",
                "Authorization": f"Bearer {gh_token}",
            },
            params={
                "ref": "v1.1.0.42",
            },
        )
        ghapi_auth_resp.raise_for_status()
        pprint.pp(dict(ghapi_auth_resp.headers))
