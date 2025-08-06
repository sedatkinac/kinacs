# Betiğin amacı Azure üzerince yer alan App Registrations Sertifika/Secret'ların sürelerini takip etmek.
# Konuyla ilgili https://www.mshowto.org/microsoft-azure-app-registrations-sertifika-secret-sure-takibi.html buradaki yazımı inceleyebilirsiniz.

import msal
import requests
import datetime
import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from dateutil import parser 
from email.utils import formataddr

# Azure App bilgileri
client_id = "ID"
client_secret = "Secret ID"
tenant_id = "Tenant ID"

# SMTP bilgileri
smtp_server = "smtp.outlook.com"
smtp_port = 587
smtp_user = "kinacs@sedatkinac.com"
smtp_password = "Password"  # Güvenli şekilde alman önerilir



days_until_expiration = 30 # Süre kişiselleştirilebilir.
include_already_expired = True

# Token alma (MSAL ile client credentials flow)
authority = f"https://login.microsoftonline.com/{tenant_id}"
scope = ["https://graph.microsoft.com/.default"]

app = msal.ConfidentialClientApplication(client_id, authority=authority, client_credential=client_secret)
result = app.acquire_token_for_client(scopes=scope)

if "access_token" not in result:
    raise Exception("Token alınamadı: " + str(result.get("error_description")))

access_token = result['access_token']
headers = {
    "Authorization": f"Bearer {access_token}",
    "Content-Type": "application/json"
}

url_apps = "https://graph.microsoft.com/v1.0/applications"
now = datetime.datetime.now(datetime.timezone.utc)

apps = []
next_url = url_apps
while next_url:
    resp = requests.get(next_url, headers=headers)
    resp.raise_for_status()
    data = resp.json()
    apps.extend(data.get('value', []))
    next_url = data.get('@odata.nextLink')

logs = []

def get_owners(app_id):
    owners_url = f"https://graph.microsoft.com/v1.0/applications/{app_id}/owners"
    resp = requests.get(owners_url, headers=headers)
    resp.raise_for_status()
    return resp.json().get('value', [])

for app in apps:
    app_name = app.get('displayName')
    app_id = app.get('id')
    app_appid = app.get('appId')

    secrets = app.get('passwordCredentials', [])
    certs = app.get('keyCredentials', [])

    owners = get_owners(app_id)

    if owners:
        usernames = []
        owner_ids = []
        for owner in owners:
            upn = owner.get('userPrincipalName')
            display_name = owner.get('displayName')
            owner_id = owner.get('id')
            if upn:
                usernames.append(upn)
            elif display_name:
                usernames.append(f"{display_name} **<This is an Application>**")
            else:
                usernames.append("<<No Owner>>")
            owner_ids.append(owner_id)
        owner_str = ';'.join(usernames)
        owner_id_str = ';'.join(owner_ids)
    else:
        owner_str = "<<No Owner>>"
        owner_id_str = ""

    for secret in secrets:
        start_date = parser.isoparse(secret['startDateTime']) 
        end_date = parser.isoparse(secret['endDateTime'])      
        secret_name = secret.get('displayName', '')
        remaining_days = (end_date - now).days

        if remaining_days <= days_until_expiration or (include_already_expired and remaining_days < 0):
            logs.append({
                'ApplicationName': app_name,
                'ApplicationID': app_appid,
                'Secret Name': secret_name,
                'Secret Start Date': start_date.strftime("%Y-%m-%d"),
                'Secret End Date': end_date.strftime("%Y-%m-%d"),
                'Certificate Name': None,
                'Certificate Start Date': None,
                'Certificate End Date': None,
                'Owner': owner_str,
                'Owner_ObjectID': owner_id_str
            })

    for cert in certs:
        start_date = parser.isoparse(cert['startDateTime'])   
        end_date = parser.isoparse(cert['endDateTime'])      
        cert_name = cert.get('displayName', '')
        remaining_days = (end_date - now).days

        if remaining_days <= days_until_expiration or (include_already_expired and remaining_days < 0):
            logs.append({
                'ApplicationName': app_name,
                'ApplicationID': app_appid,
                'Secret Name': None,
                'Secret Start Date': None,
                'Secret End Date': None,
                'Certificate Name': cert_name,
                'Certificate Start Date': start_date.strftime("%Y-%m-%d"),
                'Certificate End Date': end_date.strftime("%Y-%m-%d"),
                'Owner': owner_str,
                'Owner_ObjectID': owner_id_str
            })

def generate_html_table(data):
    if not data:
        return "<p>Son 30 gün içinde süresi dolan veya dolmak üzere olan kayıt yok.</p>"
    headers = ['ApplicationName', 'ApplicationID', 'Secret Name', 'Secret Start Date', 'Secret End Date',
               'Certificate Name', 'Certificate Start Date', 'Certificate End Date', 'Owner', 'Owner_ObjectID']
    html = '<table border="1" cellpadding="5" cellspacing="0" style="border-collapse: collapse;">'
    html += '<tr>' + ''.join(f'<th>{h}</th>' for h in headers) + '</tr>'
    for entry in data:
        html += '<tr>' + ''.join(f'<td>{entry.get(h) if entry.get(h) is not None else ""}</td>' for h in headers) + '</tr>'
    html += '</table>'
    return html

html_table = generate_html_table(logs)

body = f"""
<h2>Azure App Secret/Certificate Expiry Report</h2>
<p>Son 30 gün içinde süresi dolan veya dolmak üzere olan tüm kayıtlar aşağıdadır:</p>
{html_table}
"""

msg = MIMEMultipart('alternative')
msg['Subject'] = f"Secret ve Sertifika Bitiş Raporu - {datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%d')}"
msg['From'] = formataddr(('Info', smtp_user))
msg['To'] = "recipient email address"

part = MIMEText(body, 'html')
msg.attach(part)

try:
    server = smtplib.SMTP(smtp_server, smtp_port)
    server.starttls()
    server.login(smtp_user, smtp_password)
    server.sendmail(smtp_user, [msg['To']], msg.as_string())
    server.quit()
    print("Mail gönderildi.")
except Exception as e:
    print(f"Hata oluştu: {e}")
