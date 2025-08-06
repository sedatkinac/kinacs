#AD Grubu içerisinde yer alan üyeleri belirtilen dizine export edilmesi sağlanması amacıyla aşağıdaki betik oluşturuldu.
#Export edilecek path belirtilir.

Get-ADGroupMember -Identity "GroupName" | 
Get-ADUser -Properties Mail | 
Select-Object Name, SamAccountName, Mail | 
Export-Csv -Path "C:\GroupMembers.csv" -NoTypeInformation -Encoding UTF8