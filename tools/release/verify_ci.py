"""Reject signing unless both existing GitHub CI runs passed the requested SHA."""
import argparse
import json
import os
import re
import urllib.request

REPOSITORY = 'xiaoxiaoming676-pixel/study-app'


def validate(run: dict, sha: str, workflow: str) -> None:
    if run.get('repository', {}).get('full_name') != REPOSITORY:
        raise ValueError('CI repository does not match Study')
    if run.get('head_sha') != sha or run.get('path') != workflow:
        raise ValueError('CI did not test this commit with the required workflow')
    if run.get('status') != 'completed' or run.get('conclusion') != 'success':
        raise ValueError('CI is not completed and green; signing is blocked')


def fetch(run_id: str) -> dict:
    if not re.fullmatch(r'[0-9]+', run_id):
        raise ValueError('Run ID must be numeric')
    headers = {'Accept': 'application/vnd.github+json',
               'User-Agent': 'study-release-preflight'}
    # Optional read-only token avoids shared runner public API rate limits.
    # Never print it or embed it in an URL.
    if os.environ.get('STUDY_GITHUB_READ_TOKEN'):
        headers['Authorization'] = f'Bearer {os.environ["STUDY_GITHUB_READ_TOKEN"]}'
    request = urllib.request.Request(
        f'https://api.github.com/repos/{REPOSITORY}/actions/runs/{run_id}',
        headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.load(response)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--sha', required=True)
    parser.add_argument('--ios-run', required=True)
    parser.add_argument('--windows-run', required=True)
    args = parser.parse_args()
    if not re.fullmatch(r'[0-9a-f]{40}', args.sha):
        parser.error('Expected full 40-character lowercase commit SHA')
    for run_id, path in [(args.ios_run, '.github/workflows/study-ios.yml'),
                         (args.windows_run, '.github/workflows/study-windows.yml')]:
        validate(fetch(run_id), args.sha, path)
    print(f'Both CI gates passed for {args.sha}')
