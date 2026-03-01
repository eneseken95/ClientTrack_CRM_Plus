from app.core.config import settings
from sendgrid import SendGridAPIClient
from sendgrid.helpers.mail import Mail, ReplyTo
import ssl

ssl._create_default_https_context = ssl._create_unverified_context


def sendMailUsingSendGrid(
    *,
    to_email: str,
    subject: str,
    html_content: str,
    reply_to: str,
):
    API = settings.SENDGRID_API_KEY
    from_email = settings.SENDGRID_SENDER
    if not API or not from_email:
        raise RuntimeError("SENDGRID ERROR: API KEY or SENDER is missing.")
    message = Mail(
        from_email=from_email,
        to_emails=to_email,
        subject=subject,
        html_content=html_content,
    )
    message.reply_to = ReplyTo(reply_to)
    try:
        sg = SendGridAPIClient(API)
        response = sg.send(message)
        return response.status_code
    except Exception as e:
        raise
