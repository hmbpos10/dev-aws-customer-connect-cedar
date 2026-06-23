"""Minimal Connect contact-event handler.

Receives Amazon Connect contact events delivered via EventBridge and enqueued on SQS,
and acknowledges them. Real downstream logic (CRM sync, notifications) is added later.
"""

import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event: dict, context: object) -> dict:
    """Log and acknowledge each SQS-batched contact event."""
    records = event.get("Records", [])
    for record in records:
        logger.info("contact event: %s", record.get("body"))
    return {"processed": len(records)}
