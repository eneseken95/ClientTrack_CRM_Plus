from app.core.config import settings


def get_logo_html():
    if getattr(settings, "APP_LOGO_URL", None):
        return f'<img src="{settings.APP_LOGO_URL}" alt="ClientTrack CRM+" style="width: 84px; height: 84px; border-radius: 18px; object-fit: cover;">'
    return ""


def render_verification_email(name: str, otp: str):
    return f"""
    <html>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 40px 20px; text-align: center; background-color: #f9fafb;">
        <div style="max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
          
          <div style="margin-bottom: 12px;">
            {get_logo_html()}
          </div>
          
          <h1 style="margin: 0 0 8px; font-size: 26px; font-weight: 800; color: #111827;">ClientTrack CRM+</h1>
          <div style="height: 4px; width: 200px; background: linear-gradient(90deg, #db2777, #be185d); margin: 0 auto 32px; border-radius: 2px;"></div>

          <h2 style="margin: 0 0 24px; font-size: 20px; font-weight: 700; color: #111827;">Verify Your Email</h2>
          
          <p style="font-size: 16px; font-weight: 600; color: #4f46e5; margin-bottom: 24px;">Hi {name},</p>
          <p style="font-size: 15px; color: #4b5563; margin-bottom: 32px;">Use the verification code below to activate your account.</p>
          
          <div style="background: #f8fafc; border: 2px solid #22c55e; padding: 12px 20px; border-radius: 12px; margin: 0 auto 40px; max-width: 250px;">
            <span style="font-size: 26px; font-weight: 800; color: #334155; letter-spacing: 6px;">{otp}</span>
          </div>
          
          <p style="font-size: 13px; color: #9ca3af; margin: 0 0 8px;">This email was automatically sent by <strong>ClientTrack CRM+</strong></p>
          <div style="height: 2px; width: 160px; background: #fdba74; margin: 0 auto 16px;"></div>
          <p style="font-size: 13px; color: #9ca3af; margin: 0;">Please do not reply to this message.</p>
        </div>
      </body>
    </html>
    """


def render_password_reset_email(name: str, otp: str):
    return f"""
    <html>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 40px 20px; text-align: center; background-color: #f9fafb;">
        <div style="max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
          
          <div style="margin-bottom: 12px;">
            {get_logo_html()}
          </div>
          
          <h1 style="margin: 0 0 8px; font-size: 26px; font-weight: 800; color: #111827;">ClientTrack CRM+</h1>
          <div style="height: 4px; width: 200px; background: linear-gradient(90deg, #db2777, #be185d); margin: 0 auto 32px; border-radius: 2px;"></div>

          <h2 style="margin: 0 0 24px; font-size: 20px; font-weight: 700; color: #111827;">Reset Your Password</h2>
          
          <p style="font-size: 16px; font-weight: 600; color: #4f46e5; margin-bottom: 24px;">Hi {name},</p>
          <p style="font-size: 15px; color: #4b5563; margin-bottom: 32px;">Use the code below to reset your password.</p>
          
          <div style="background: #f8fafc; border: 2px solid #3b82f6; padding: 12px 20px; border-radius: 12px; margin: 0 auto 40px; max-width: 250px;">
            <span style="font-size: 26px; font-weight: 800; color: #334155; letter-spacing: 6px;">{otp}</span>
          </div>
          
          <p style="font-size: 13px; color: #9ca3af; margin: 0 0 8px;">This email was automatically sent by <strong>ClientTrack CRM+</strong></p>
          <div style="height: 2px; width: 160px; background: #fdba74; margin: 0 auto 16px;"></div>
          <p style="font-size: 13px; color: #9ca3af; margin: 0;">Please do not reply to this message.</p>
        </div>
      </body>
    </html>
    """


def render_email_change(name: str, otp: str):
    return f"""
    <html>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 40px 20px; text-align: center; background-color: #f9fafb;">
        <div style="max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
          
          <div style="margin-bottom: 12px;">
            {get_logo_html()}
          </div>
          
          <h1 style="margin: 0 0 8px; font-size: 26px; font-weight: 800; color: #111827;">ClientTrack CRM+</h1>
          <div style="height: 4px; width: 200px; background: linear-gradient(90deg, #db2777, #be185d); margin: 0 auto 32px; border-radius: 2px;"></div>

          <h2 style="margin: 0 0 24px; font-size: 20px; font-weight: 700; color: #111827;">Update Your Email</h2>
          
          <p style="font-size: 16px; font-weight: 600; color: #4f46e5; margin-bottom: 24px;">Hi {name},</p>
          <p style="font-size: 15px; color: #4b5563; margin-bottom: 32px;">Use the code below to confirm your new email address.</p>
          
          <div style="background: #f8fafc; border: 2px solid #8b5cf6; padding: 12px 20px; border-radius: 12px; margin: 0 auto 40px; max-width: 250px;">
            <span style="font-size: 26px; font-weight: 800; color: #334155; letter-spacing: 6px;">{otp}</span>
          </div>
          
          <p style="font-size: 13px; color: #9ca3af; margin: 0 0 8px;">This email was automatically sent by <strong>ClientTrack CRM+</strong></p>
          <div style="height: 2px; width: 160px; background: #fdba74; margin: 0 auto 16px;"></div>
          <p style="font-size: 13px; color: #9ca3af; margin: 0;">Please do not reply to this message.</p>
        </div>
      </body>
    </html>
    """


def render_delete_account_email(name: str, otp: str):
    return f"""
    <html>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 40px 20px; text-align: center; background-color: #f9fafb;">
        <div style="max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
          
          <div style="margin-bottom: 12px;">
            {get_logo_html()}
          </div>
          
          <h1 style="margin: 0 0 8px; font-size: 26px; font-weight: 800; color: #111827;">ClientTrack CRM+</h1>
          <div style="height: 4px; width: 200px; background: linear-gradient(90deg, #db2777, #be185d); margin: 0 auto 32px; border-radius: 2px;"></div>

          <h2 style="margin: 0 0 24px; font-size: 20px; font-weight: 700; color: #111827;">Delete Account Request</h2>
          
          <p style="font-size: 16px; font-weight: 600; color: #4f46e5; margin-bottom: 24px;">Hi {name},</p>
          <p style="font-size: 15px; color: #4b5563; margin-bottom: 32px;">Use the code below to permanently delete your account.</p>
          
          <div style="background: #fef2f2; border: 2px solid #ef4444; padding: 12px 20px; border-radius: 12px; margin: 0 auto 16px; max-width: 250px;">
            <span style="font-size: 26px; font-weight: 800; color: #991b1b; letter-spacing: 6px;">{otp}</span>
          </div>
          <p style="font-size: 14px; font-weight: 600; color: #ef4444; margin-bottom: 40px;">Warning: This action is irreversible.</p>
          
          <p style="font-size: 13px; color: #9ca3af; margin: 0 0 8px;">This email was automatically sent by <strong>ClientTrack CRM+</strong></p>
          <div style="height: 2px; width: 160px; background: #fdba74; margin: 0 auto 16px;"></div>
          <p style="font-size: 13px; color: #9ca3af; margin: 0;">Please do not reply to this message.</p>
        </div>
      </body>
    </html>
    """


def render_client_email(
    *,
    client_name: str,
    sender_name: str,
    sender_email: str,
    body_text: str,
):
    body_html = body_text.replace("\\n", "<br>")
    return f"""
    <html>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 40px 20px; text-align: center; background-color: #f9fafb;">
        <div style="max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
          
          <div style="margin-bottom: 12px;">
            {get_logo_html()}
          </div>
          
          <h1 style="margin: 0 0 8px; font-size: 26px; font-weight: 800; color: #111827;">ClientTrack CRM+</h1>
          <div style="height: 4px; width: 200px; background: linear-gradient(90deg, #3b82f6, #0ea5e9); margin: 0 auto 32px; border-radius: 2px;"></div>

          <p style="font-size: 16px; font-weight: 600; color: #4f46e5; margin-bottom: 24px;">Hi {client_name},</p>
          
          <div style="font-size: 15px; color: #4b5563; margin-bottom: 40px; text-align: center; line-height: 1.8;">
            {body_html}
          </div>
          
          <p style="font-size: 14px; color: #6b7280; margin: 0 0 4px;">Kind regards,</p>
          <p style="font-size: 15px; font-weight: 700; color: #111827; margin: 0 0 4px;">{sender_name}</p>
          <a href="mailto:{sender_email}" style="font-size: 14px; color: #2563eb; text-decoration: none;">{sender_email}</a>
          
          <div style="margin-top: 40px;">
            <p style="font-size: 13px; color: #9ca3af; margin: 0 0 8px;">This email was sent via <strong>ClientTrack CRM+</strong></p>
            <div style="height: 2px; width: 160px; background: #fdba74; margin: 0 auto 16px;"></div>
            <p style="font-size: 13px; color: #9ca3af; margin: 0;">Replies will be delivered directly to the sender.</p>
          </div>
        </div>
      </body>
    </html>
    """


def render_task_deadline_email(task_title: str, due_date: str, user_name: str):
    return f"""
    <html>
      <body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 40px 20px; text-align: center; background-color: #f9fafb;">
        <div style="max-width: 500px; margin: 0 auto; background: #ffffff; border-radius: 16px; padding: 40px 30px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);">
          
          <div style="margin-bottom: 12px;">
            {get_logo_html()}
          </div>
          
          <h1 style="margin: 0 0 8px; font-size: 26px; font-weight: 800; color: #111827;">ClientTrack CRM+</h1>
          <div style="height: 4px; width: 200px; background: linear-gradient(90deg, #f59e0b, #f59e0b, #f59e0b); margin: 0 auto 32px; border-radius: 2px;"></div>

          <h2 style="margin: 0 0 24px; font-size: 20px; font-weight: 700; color: #111827;">Task Reminder</h2>
          
          <p style="font-size: 16px; font-weight: 600; color: #4f46e5; margin-bottom: 24px;">Hi {user_name},</p>
          <p style="font-size: 15px; color: #4b5563; margin-bottom: 24px;">This is a quick reminder about your upcoming task.</p>
          
          <div style="background: #fffbeb; border: 2px solid #fcd34d; padding: 20px; border-radius: 12px; margin-bottom: 40px; text-align: left;">
            <p style="margin: 0 0 8px; font-size: 16px; font-weight: 700; color: #b45309;">{task_title}</p>
            <p style="margin: 0; font-size: 14px; color: #d97706;"><span style="font-weight: 600;">Due:</span> {due_date}</p>
          </div>
          
          <p style="font-size: 13px; color: #9ca3af; margin: 0 0 8px;">This email was automatically sent by <strong>ClientTrack CRM+</strong></p>
          <div style="height: 2px; width: 160px; background: #fdba74; margin: 0 auto 16px;"></div>
          <p style="font-size: 13px; color: #9ca3af; margin: 0;">Please do not reply to this message.</p>
        </div>
      </body>
    </html>
    """
