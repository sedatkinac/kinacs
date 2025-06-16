import requests
from bs4 import BeautifulSoup
import datetime
import os
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException, WebDriverException, NoSuchElementException

import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart # E-posta gövdesini daha esnek hale getirmek için eklendi

def get_bedas_kesinti_info(url):
    """
    BEDAŞ web sayfasından elektrik kesintisi bilgilerini Selenium kullanarak çeker.
    """
    driver = None
    try:
        script_dir = os.path.dirname(__file__)
        driver_path = os.path.join(script_dir, 'chromedriver.exe')

        print(f"ChromeDriver aranıyor: {driver_path}")
        if not os.path.exists(driver_path):
            print(f"HATA: ChromeDriver '{driver_path}' konumunda bulunamadı. Lütfen dosyanın burada olduğundan emin olun.")
            return None

        service = Service(executable_path=driver_path)
        options = webdriver.ChromeOptions()
        options.add_argument('--headless')
        options.add_argument('--disable-gpu')
        options.add_argument('--no-sandbox')
        options.add_argument('--disable-dev-shm-usage')
        
        driver = webdriver.Chrome(service=service, options=options)
        print("WebDriver başlatıldı.")

        driver.get(url)
        print(f"URL'ye gidildi: {url}")

        # Sayfanın tamamen yüklenmesini bekle (body etiketinin görünür olmasını bekle)
        WebDriverWait(driver, 15).until(
            EC.presence_of_element_located((By.TAG_NAME, 'body'))
        )
        print("Sayfa içeriği yüklendi.")

        # --- Çerez Bildirimini Kapatma Girişimi ---
        # Hata mesajına göre, 'lwcn-cookie-notice-button-container' elementi tıklamayı engelliyor.
        # Bu div içinde bir "Kabul Et" veya "Tamam" butonu arayacağız.
        try:
            print("Çerez bildirimini kontrol ediliyor...")
            # Çerez bildirim konteynerini bekle
            cookie_container = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.ID, 'lwcn-cookie-notice-button-container'))
            )
            print("Çerez bildirim konteyneri bulundu.")

            # Konteyner içinde "İsteğe Bağlı Çerezleri Kabul Et" butonunu ID'si ile ara
            accept_button = WebDriverWait(driver, 10).until(
                EC.element_to_be_clickable((By.ID, 'lwcn-cookie-notice-button-2')) # ID ile hedefleme
            )
            print("Çerez kabul butonu bulundu (ID ile).")
            accept_button.click()
            print("Çerez kabul butonuna tıklandı.")

            # Çerez bildiriminin kaybolmasını bekle
            WebDriverWait(driver, 10).until(
                EC.invisibility_of_element_located((By.ID, 'lwcn-cookie-notice-button-container'))
            )
            print("Çerez bildirimi kapatıldı.")

        except TimeoutException:
            print("Çerez bildirimi veya kabul butonu bulunamadı/tıklanamadı (zaman aşımı). Devam ediliyor...")
        except NoSuchElementException:
            print("Çerez kabul butonu bulunamadı (NoSuchElementException). Devam ediliyor...")
        except Exception as e:
            print(f"Çerez bildirimini kapatırken beklenmeyen bir hata oluştu: {e}. Devam ediliyor...")
        # --- Çerez Bildirimi Kapatma Girişimi Sonu ---


        # "Sorgula" butonunu bul ve tıklanabilir olmasını bekle
        # Buton bir <a> etiketi ve id'si "btntmSorgula" olarak güncellendi.
        sorgula_button = WebDriverWait(driver, 15).until(
            EC.element_to_be_clickable((By.ID, 'btntmSorgula'))
        )
        print("Sorgula butonu bulundu ve tıklanabilir durumda.")
        sorgula_button.click()
        print("Sorgula butonuna tıklandı.")

        # Butona tıkladıktan sonra kesinti kartlarının yüklenmesini ve görünür olmasını bekle
        # Yeni HTML yapısına göre ana kart sınıfı 'box-elektrik-kesintisi-sorgulama' olarak güncellendi.
        WebDriverWait(driver, 30).until(
            EC.presence_of_element_located((By.CLASS_NAME, 'box-elektrik-kesintisi-sorgulama'))
        )
        print("Kesinti kartları yüklendi ve görünür durumda.")

        page_source = driver.page_source
        soup = BeautifulSoup(page_source, 'html.parser')

        kesinti_list = []
        
        # Kesinti bilgilerini içeren kartları bul
        # HTML yapısına göre en dıştaki kart sınıfı 'box-elektrik-kesintisi-sorgulama'
        kesinti_cards = soup.find_all('div', class_=lambda x: x and 'box-elektrik-kesintisi-sorgulama' in x) 
        print(f"Bulunan kesinti kartı sayısı: {len(kesinti_cards)}")

        if kesinti_cards:
            for i, card in enumerate(kesinti_cards):
                print(f"\n--- Kart {i+1} İşleniyor ---")

                baslangic_saati = "N/A"
                bitis_saati = "N/A"
                etkilenen_bolgeler = "N/A"
                aciklama = "N/A"

                # Sol sütunu bul (tarih, saat, neden)
                left_col = card.find('div', class_='col-lg-6')
                if left_col:
                    # Tarih ve Saat bilgisi
                    date_span = left_col.find('div', class_='item-elektrik-kesintisi-sorgulama').find('span')
                    time_label = left_col.find('div', class_='item-elektrik-kesintisi-sorgulama').find('label', class_='seperator')
                    
                    if date_span and time_label:
                        date_part = date_span.text.strip()
                        time_range_text = time_label.text.strip() # "00:00:00 - 06:00:00"
                        
                        time_parts = time_range_text.split(' - ') # " - " ile ayır
                        if len(time_parts) == 2:
                            baslangic_saati = f"{date_part} {time_parts[0]}"
                            bitis_saati = f"{date_part} {time_parts[1]}"
                        else:
                            baslangic_saati = f"{date_part} {time_range_text}" # Ayrıştırma başarısız olursa tüm metni al
                            bitis_saati = "N/A"
                    
                    # Kesinti Nedeni (Açıklama)
                    reason_label = left_col.find('label', string='Kesinti Nedeni:')
                    if reason_label:
                        aciklama_span = reason_label.find_next_sibling('span')
                        if aciklama_span:
                            aciklama = aciklama_span.text.strip()
                
                # Sağ sütunu bul (etkilenen cadde/sokak ve detaylı açıklama)
                # İç içe div yapısına dikkat ederek doğru div'i buluyoruz.
                right_col_outer = card.find_all('div', class_='col-lg-6')
                right_col = None
                if len(right_col_outer) > 1: # İkinci col-lg-6'yı al
                    right_col = right_col_outer[1].find('div', class_='item-elektrik-kesintisi-sorgulama uzunAciklama')

                if right_col:
                    etkilenen_span = right_col.find('span', class_='content-daha-fazla-goster')
                    if etkilenen_span:
                        etkilenen_bolgeler = etkilenen_span.text.strip()
                    else:
                        etkilenen_bolgeler = right_col.text.strip() # Eğer span bulunamazsa tüm div metnini al

                kesinti_list.append({
                    'Başlangıç Saati': baslangic_saati,
                    'Bitiş Saati': bitis_saati,
                    'Etkilenen Bölgeler': etkilenen_bolgeler,
                    'Açıklama': aciklama
                })
        else:
            no_kesinti_div = soup.find('div', class_='alert alert-info')
            if no_kesinti_div and "Kayıt bulunamadı" in no_kesinti_div.text:
                print("Sarıyer için mevcut bir elektrik kesintisi kaydı bulunamadı.")
                return []
            else:
                print("Kesinti bilgilerini içeren kartlar bulunamadı veya sayfa yapısı değişmiş olabilir.")

        return kesinti_list

    except TimeoutException:
        print("Sayfa yüklenirken veya elementler aranırken zaman aşımı oluştu. İnternet bağlantınızı veya element seçicileri kontrol edin.")
        print("Olası nedenler: Buton veya kartlar beklenenden daha uzun sürede yükleniyor, element seçicileri yanlış veya sayfa yapısı değişmiş.")
        return None
    except WebDriverException as e:
        print(f"WebDriver hatası oluştu: {e}. ChromeDriver'ın doğru sürüme sahip olduğundan ve PATH'te olduğundan emin olun.")
        return None
    except Exception as e:
        print(f"Beklenmeyen bir hata oluştu: {e}")
        return None
    finally:
        if driver:
            driver.quit()
            print("WebDriver kapatıldı.")

def send_email(recipient_email, subject, body, sender_email, sender_password, smtp_server, smtp_port):
    """
    Belirtilen e-posta adresine e-posta gönderir.
    SSL (port 465) ve STARTTLS (port 587) yöntemlerini dener.
    """
    msg = MIMEMultipart()
    msg['Subject'] = subject
    msg['From'] = sender_email
    msg['To'] = recipient_email
    msg.attach(MIMEText(body, 'plain', 'utf-8'))

    try:
        print(f"E-posta gönderme denemesi (SSL - Port {smtp_port})...")
        with smtplib.SMTP_SSL(smtp_server, smtp_port) as server:
            server.login(sender_email, sender_password)
            server.send_message(msg)
        print(f"E-posta '{recipient_email}' adresine başarıyla gönderildi (SSL).")
        return True
    except smtplib.SMTPAuthenticationError as e:
        print(f"E-posta kimlik doğrulama hatası (SSL): {e}. Şifrenizi veya uygulama şifrenizi kontrol edin.")
        return False
    except Exception as e:
        print(f"SSL ile e-posta gönderilirken hata oluştu: {e}. STARTTLS denemesi yapılıyor...")
        
        try:
            # SSL başarısız olursa, STARTTLS (genellikle port 587) ile dene
            print(f"E-posta gönderme denemesi (STARTTLS - Port 587)...")
            with smtplib.SMTP(smtp_server, 587) as server: # Portu 587 olarak ayarla
                server.starttls() # STARTTLS'yi başlat
                server.login(sender_email, sender_password)
                server.send_message(msg)
            print(f"E-posta '{recipient_email}' adresine başarıyla gönderildi (STARTTLS).")
            return True
        except smtplib.SMTPAuthenticationError as e:
            print(f"E-posta kimlik doğrulama hatası (STARTTLS): {e}. Şifrenizi veya uygulama şifrenizi kontrol edin.")
            return False
        except Exception as e:
            print(f"STARTTLS ile e-posta gönderilirken de hata oluştu: {e}")
            return False

def write_to_log(data, log_file="bedas_kesinti_log.txt"):
    """
    Çekilen verileri veya kesinti olmadığı bilgisini bir log dosyasına yazar.
    Dosya her çalıştırıldığında yeniden oluşturulur.
    """
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    
    # Dosyayı 'w' (write) modunda açarak her seferinde yeniden oluştur
    with open(log_file, "w", encoding="utf-8") as f: 
        f.write(f"--- Kesinti Sorgulama Tarihi: {timestamp} ---\n")
        if data:
            for item in data:
                f.write(f"Başlangıç: {item['Başlangıç Saati']}\n")
                f.write(f"Bitiş: {item['Bitiş Saati']}\n")
                f.write(f"Etkilenen Bölgeler: {item['Etkilenen Bölgeler']}\n")
                f.write(f"Açıklama: {item['Açıklama']}\n")
                f.write("-" * 30 + "\n")
        else:
            f.write("Sarıyer için mevcut bir elektrik kesintisi bulunamadı.\n")
        f.write("\n")

if __name__ == "__main__":
    url = "https://www.bedas.com.tr/elektrik-kesintisi-sorgulama?il=%C4%B0STANBUL&ilce=SARIYER" #farklı ilçe seçilebilir.
    log_file_name = "bedas_kesinti_log.txt"

    # E-posta yapılandırma bilgileri - Lütfen bunları kendi bilgilerinizle güncelleyin!
    SENDER_EMAIL = "your_email"  # Gönderici e-posta adresi
    SENDER_PASSWORD = "your password" # Gönderici e-posta şifresi veya uygulama şifresi
    # Gmail için: smtp.gmail.com, 465 (SSL) veya 587 (TLS)
    # Outlook/Hotmail için: smtp.office365.com, 587 (TLS)
    SMTP_SERVER = "outlook.office365.com"      # SMTP sunucusu adresi
    SMTP_PORT = 587                    # SMTP portu (SSL için 465, TLS için 587)
    RECIPIENT_EMAIL = "your mail @gmail.com" # Alıcı e-posta adresi
    EMAIL_SUBJECT = "BEDAŞ Elektrik Kesintisi Raporu"

    # Aranacak kelimeyi burada belirtin
    KEYWORD_TO_SEARCH = "Kesinti için aranacak kelime örn sokak cadde mahalle vs." 

    # E-posta yapılandırma bilgilerinin doldurulup doldurulmadığını kontrol et
    if SENDER_EMAIL == "your_email@example.com" or SENDER_PASSWORD == "your_email_password":
        print("HATA: Lütfen SENDER_EMAIL ve SENDER_PASSWORD değişkenlerini kendi bilgilerinizle güncelleyin.")
        print("E-posta gönderme işlemi atlandı.")
    else:
        print("BEDAŞ elektrik kesintisi bilgileri çekiliyor...")
        kesinti_data = get_bedas_kesinti_info(url)

        if kesinti_data is not None:
            if kesinti_data:
                print("Kesinti bilgileri başarıyla çekildi. Log dosyasına yazılıyor...")
                write_to_log(kesinti_data, log_file_name)
                print("İşlem tamamlandı. 'bedas_kesinti_log.txt' dosyasını kontrol edin.")
            else:
                print("Sarıyer için aktif bir elektrik kesintisi bulunamadı. Log dosyasına kaydediliyor...")
                write_to_log(kesinti_data, log_file_name)
            
            # Log dosyasının içeriğini oku ve belirli kelimeyi içeren satırları filtrele
            filtered_log_content = ""
            try:
                with open(log_file_name, "r", encoding="utf-8") as f:
                    for line in f:
                        if KEYWORD_TO_SEARCH.lower() in line.lower():
                            filtered_log_content += line
                
                # Filtrelenmiş içerik varsa e-posta gönder
                if filtered_log_content:
                    print(f"'{KEYWORD_TO_SEARCH}' kelimesi log dosyasında bulundu. İlgili satırlar e-posta olarak gönderiliyor...")
                    send_email(RECIPIENT_EMAIL, EMAIL_SUBJECT, filtered_log_content, SENDER_EMAIL, SENDER_PASSWORD, SMTP_SERVER, SMTP_PORT)
                else:
                    print(f"'{KEYWORD_TO_SEARCH}' kelimesi log dosyasında bulunamadı veya ilgili satırlar boş. E-posta gönderilmedi.")

            except FileNotFoundError:
                print(f"HATA: Log dosyası '{log_file_name}' bulunamadı. E-posta gönderilemedi.")
            except Exception as e:
                print(f"Log dosyasını okuma veya e-posta gönderme sırasında bir hata oluştu: {e}")

        else:
            print("Veri çekme veya işleme sırasında bir sorun oluştu. Log dosyası oluşturulmadı ve e-posta gönderilemedi.")
