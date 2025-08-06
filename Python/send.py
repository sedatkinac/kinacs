# Form üzerinden toplanan bilgilerin send.py betiği aracılığı ile gönderimini test ettik
# Kullanıcıdan Ad-Soyad ve E-mail adresi bilgilerini alıp bunu belirtilen adrese mail gönderiyoruz.

from flask import Flask, request
import smtplib
from email.mime.text import MIMEText

app = Flask(__name__)

@app.route('/send', methods=['POST'])
def send():
    name = request.form.get('name')
    email_address = request.form.get('email')
    subject = "Mail Test"
    body = f"Ad Soyad: {name}\nE-mail: {email_address}" 
    msg = MIMEText(body)
    msg['Subject'] = subject
    msg['From'] = "e-mail adresini yazın"
    msg['To'] = "e-mail adresini yazın"

    try:
        with smtplib.SMTP_SSL('smtpserver', 465) as server:
            server.login("smtp_user", "Password")
            server.sendmail(msg['From'], [msg['To']], msg.as_string())
        return "E-mail gönderildi."
    except Exception as e:
       return f"Hata: {e}"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)