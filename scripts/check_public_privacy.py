"""Read the public HTTPS policy anonymously and compare it with the app's copy."""
from datetime import datetime, timezone
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
URL = 'https://games.norbonics.com/ike-quest/privacy/'

class Policy(HTMLParser):
    def __init__(self):
        super().__init__(); self.inside = False; self.parts = []; self.mains = 0
    def handle_starttag(self, tag, attrs):
        if tag == 'main': self.inside = True; self.mains += 1
        if self.inside and tag in {'br', 'p', 'h1', 'h2'}: self.parts.append(' ')
    def handle_endtag(self, tag):
        if tag == 'main': self.inside = False
        if self.inside: self.parts.append(' ')
    def handle_data(self, data):
        if self.inside: self.parts.append(data)


def validate_policy(html: str, markdown: str) -> None:
    plain = re.sub(r'^#{1,2} ', '', markdown, flags=re.M)
    plain = re.sub(r'^_(Last updated: .*)_$', r'\1', plain, flags=re.M)
    parser = Policy(); parser.feed(html)
    if parser.mains != 1 or ' '.join(''.join(parser.parts).split()) != ' '.join(plain.split()):
        raise ValueError('Public policy body differs from the app policy')
    if re.search(r'<\s*(script|iframe)\b', html, re.I):
        raise ValueError('Standalone policy unexpectedly loads scripts or frames')


def main() -> None:
    request = urllib.request.Request(URL, headers={'User-Agent': 'IkeQuest-Policy-Verification/1.0'})
    # No account/session/cookies or credentials are used. TLS verification stays on.
    with urllib.request.urlopen(request, timeout=30) as response:
        status = response.status; final_url = response.url
        content_type = response.headers.get_content_type()
        data = response.read(1_000_001)
    if status != 200 or final_url != URL or content_type != 'text/html' or len(data) > 1_000_000:
        raise ValueError(f'Public policy is not a direct HTML 200 response: {status} {final_url} {content_type}')
    markdown = (ROOT / 'docs/privacy-policy.md').read_text(encoding='utf-8')
    validate_policy(data.decode('utf-8'), markdown)
    evidence = {'checked_at_utc': datetime.now(timezone.utc).isoformat(), 'url': URL,
        'http_status': status, 'final_url': final_url, 'content_type': content_type,
        'anonymous_request': True, 'policy_body_matches_app': True,
        'html_sha256': hashlib.sha256(data).hexdigest(),
        'app_policy_sha256': hashlib.sha256(markdown.encode()).hexdigest()}
    output = ROOT / 'exports/policy'; output.mkdir(parents=True, exist_ok=True)
    (output / 'public-policy.html').write_bytes(data)
    (output / 'verification.json').write_text(json.dumps(evidence, indent=2) + '\n')
    print(json.dumps(evidence, indent=2))

if __name__ == '__main__': main()
