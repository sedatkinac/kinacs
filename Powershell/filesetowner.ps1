takeown /F "Dosya yolunu buraya yazın" /R /D Y /A
icacls "C:\ProgramData\docker" /setowner "kullanıcı adı" /T /C

<#
 takeown /F → Dosya/klasör sahipliğini alır

 /R → Alt klasörler ve dosyalar dahil

 /A → Sahipliği yöneticilere verir (önce)

 icacls /setowner → Sahipliği doğrudan istenilen kullanıcısına atar

/T /C → Alt klasörler dahil, hataları atlayarak devam
#>


