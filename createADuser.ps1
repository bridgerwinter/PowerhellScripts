
function Main
{
	CreateADUser
}

function CreateADUser
{
	$userToCopy = Read-Host "What user would you like to copy?"
	$newUserName = Read-Host "What would you like to call the new account?"
	
	$newpass = Read-Host -AsSecureString "Account Password:"
	$newpassconfirm = Read-Host -AsSecureString "Account Password:"
	$decodedpassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newpass))
	$decodedpassword2 = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newpassconfirm))
	
	if ($decodedpassword -ne $decodedpassword2)
	{
		Write-Host "Were not equivalent" -BackgroundColor Red -ForegroundColor Black
		Write-Host "Try Again"
		Exit
	}
	else
	{
		Write-Host "Works!" -BackgroundColor Green -ForegroundColor Black
	}
	$userToCopyADObj = Get-ADUser $userToCopy
	
	$OUDN = $userToCopyADObj.distinguishedName
	$OUDN = $OUDN.Split(",")
	
	if ($OUDN.Length -le 1)
	{
		$OUDN = @()
	}
	else
	{
		$OUDN = $OUDN[1 .. ($OUDN.length - 1)]
	}
	$OUDN = $OUDN -join ","
	
	New-ADUser -Name $newUserName -Instance $userToCopyADObj -Path $OUDN -scriptpath "logon.bat" -HomeDrive "W:" -HomeDirectory "\\foo\tshome\$newUserName"  -ChangePasswordAtLogon $false -CannotChangePassword $false -PasswordNeverExpires $true -AccountPassword $newpass
	
	#copy all member groups
	$dnresult = Get-ADUser -Identity $newUserName | select -expandproperty 'distinguishedname'
	$user = [ADSI] "LDAP://$dnresult"
	$user.psbase.Invokeset("terminalserviceshomedrive", "W:")
	$user.psbase.Invokeset("terminalserviceshomedirectory", "\\foo\tshome\$newUserName")
	$user.setinfo()
	
	Get-ADUser -Identity $userToCopy -Properties memberof | Select-Object -ExpandProperty memberof | Add-ADGroupMember -Members $newUserName -PassThru
	changeSecurity $newUserName
}

function changeSecurity($newUserName)
{
	$fp = "\\foo\boo\USERS\$newUserName"
	
	New-Item $fp -Type directory
	
	
	$colRights = [System.Security.AccessControl.FileSystemRights]"Read, Write, ListDirectory, ReadAndExecute, Modify, Synchronize"
	$objType = [System.Security.AccessControl.AccessControlType]::Allow
	$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]::None
	$PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
	
	$objUser = New-Object System.Security.Principal.NTAccount("PEPPERS\$newUserName")
	$objAce = $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule `
	($objUser, $colRights, $InheritanceFlag, $PropagationFlag, $objType)
	
	$Acl = Get-Acl $fp
	$Acl.SetAccessRule($objAce);
	Set-Acl $fp $Acl
	
	changeSharing $newUserName $fp
}

function changeSharing($newUserName, $fp)
{
	$text = $newUserName
	$text > "H:\USERS\newuser.txt"
	sleep -s 1
	#New-SmbShare -name "P_$newUserName" -Path "\\foo\boo\USERS\$newUserName" -ChangeAccess $newUserName

}
Main

