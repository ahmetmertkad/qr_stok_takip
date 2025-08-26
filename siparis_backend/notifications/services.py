from typing import Iterable
from firebase_admin import messaging

BATCH_SIZE = 500

def _chunked(xs: Iterable, n: int):
    it = iter(xs)
    while True:
        chunk = list([x for _, x in zip(range(n), it)])
        if not chunk: break
        yield chunk

def send_to_tokens(tokens: list[str], title: str, body: str = "", data: dict | None = None):
    data = {k: str(v) for k, v in (data or {}).items()}
    report = {"success": 0, "failure": 0}
    for chunk in _chunked(tokens, BATCH_SIZE):
        messages = [
            messaging.Message(
                notification=messaging.Notification(title=title, body=body or None),
                data=data,
                token=t
            ) for t in chunk
        ]
        resp = messaging.send_each(messages)
        report["success"] += resp.success_count
        report["failure"] += resp.failure_count
    return report
