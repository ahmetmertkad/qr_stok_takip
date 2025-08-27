# notifications/services.py
from typing import Iterable
from firebase_admin import messaging

BATCH_SIZE = 500

def _chunked(xs: Iterable, n: int):
    it = iter(xs)
    while True:
        chunk = list([x for _, x in zip(range(n), it)])
        if not chunk:
            break
        yield chunk

def send_to_tokens(tokens: list[str], title: str, body: str = "", data: dict | None = None):
    # FCM data string olmalı
    data = {k: str(v) for k, v in (data or {}).items()}
    report = {"success": 0, "failure": 0}

    for chunk in _chunked(tokens, BATCH_SIZE):
        # 1) send_each varsa (yeni API)
        if hasattr(messaging, "send_each"):
            messages = [
                messaging.Message(
                    notification=messaging.Notification(title=title, body=body or None),
                    data=data,
                    token=t,
                ) for t in chunk
            ]
            resp = messaging.send_each(messages)
            # send_each: success_count / failure_count alanları var
            report["success"] += getattr(resp, "success_count", 0)
            report["failure"] += getattr(resp, "failure_count", 0)
            continue

        # 2) send_all varsa (bazı sürümler)
        if hasattr(messaging, "send_all"):
            messages = [
                messaging.Message(
                    notification=messaging.Notification(title=title, body=body or None),
                    data=data,
                    token=t,
                ) for t in chunk
            ]
            resp = messaging.send_all(messages)
            report["success"] += getattr(resp, "success_count", 0)
            report["failure"] += getattr(resp, "failure_count", 0)
            continue

        # 3) send_multicast (daha eski ve yaygın)
        if hasattr(messaging, "send_multicast"):
            multi = messaging.MulticastMessage(
                notification=messaging.Notification(title=title, body=body or None),
                data=data,
                tokens=chunk,
            )
            resp = messaging.send_multicast(multi)
            report["success"] += getattr(resp, "success_count", 0)
            report["failure"] += getattr(resp, "failure_count", 0)
            continue

        # 4) En geriye uyumlu: tek tek gönder
        for t in chunk:
            try:
                messaging.send(messaging.Message(
                    notification=messaging.Notification(title=title, body=body or None),
                    data=data,
                    token=t,
                ))
                report["success"] += 1
            except Exception:
                report["failure"] += 1

    return report
