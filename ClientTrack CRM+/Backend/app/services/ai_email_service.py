from app.core.config import settings
import httpx

OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"


async def generate_email_draft(
    *,
    purpose: str,
    tone: str,
    language: str,
    client_name: str,
):
    system_prompt = (
        "You write concise, professional CRM emails. "
        "The email must be no more than 3 short paragraphs and under 120 words. "
        "Always return Subject and Body. "
        "Do not mention attachments unless explicitly requested."
    )
    user_prompt = f"Purpose: {purpose}\nTone: {tone}\nLanguage: {language}\nClient: {client_name}"
    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": settings.OPENROUTER_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        "temperature": 0.35,
        "max_tokens": 140,
    }
    async with httpx.AsyncClient(timeout=20) as client:
        res = await client.post(
            OPENROUTER_URL,
            headers=headers,
            json=payload,
        )
    if res.status_code != 200:
        raise Exception(f"OpenRouter error: {res.text}")
    raw_text = res.json()["choices"][0]["message"]["content"]
    text = raw_text.replace("<s>", "").replace("</s>", "").replace("[/s]", "").strip()
    subject = ""
    body = text
    if "Subject:" in text:
        parts = text.split("Body:", 1)
        subject = parts[0].replace("Subject:", "").strip()
        body = parts[1].strip() if len(parts) > 1 else ""
    return {
        "subject": subject,
        "body": body,
        "model": settings.OPENROUTER_MODEL,
    }


async def polish_email_draft(
    *,
    subject: str,
    body: str,
    sender_name: str = "",
):
    system_prompt = (
        "You are a professional email editor. "
        "Polish and improve the given email subject and body. "
        "Fix grammar, spelling, and make it more professional and clear. "
        "Keep the original intent and meaning. "
        "IMPORTANT RULES: "
        "1. NEVER use markdown formatting (no **, no *, no #, etc.). "
        "2. NEVER use placeholders like [Your Name], [Sender], etc. Use the provided sender name instead. "
        "3. Always return in the exact format:\n"
        "Subject: ...\nBody: ..."
    )
    user_prompt = f"Sender Name: {sender_name}\n\nOriginal Subject: {subject}\n\nOriginal Body:\n{body}"
    headers = {
        "Authorization": f"Bearer {settings.OPENROUTER_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "model": settings.OPENROUTER_MODEL,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
        "temperature": 0.35,
        "max_tokens": 300,
    }
    async with httpx.AsyncClient(timeout=20) as client:
        res = await client.post(
            OPENROUTER_URL,
            headers=headers,
            json=payload,
        )
    if res.status_code != 200:
        raise Exception(f"OpenRouter error: {res.text}")
    raw_text = res.json()["choices"][0]["message"]["content"]
    text = raw_text.replace("<s>", "").replace("</s>", "").replace("[/s]", "").strip()
    polished_subject = subject
    polished_body = text
    if "Subject:" in text:
        parts = text.split("Body:", 1)
        polished_subject = parts[0].replace("Subject:", "").strip()
        polished_body = parts[1].strip() if len(parts) > 1 else body
    return {
        "subject": polished_subject,
        "body": polished_body,
        "model": settings.OPENROUTER_MODEL,
    }
