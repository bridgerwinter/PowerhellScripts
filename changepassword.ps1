function Main
{
	$username = Read-Host "What is your username? "
	$password = Read-Host -AsSecureString "What is your password? "
	
	$pwd1_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
	
	$valid = Test-ADAuthentication $username $pwd1_text
	
	if ($valid)
	{
		Write-Host "$username you have been validated" -BackgroundColor Green -ForegroundColor Black
		$newpass = Read-Host -AsSecureString "New password "
		$newpassconfirm = Read-Host -AsSecureString "New password confirm "
		
		$pwd2_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newpass))
		$pwd3_text = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($newpassconfirm))
		
		if ($pwd2_text -eq $pwd3_text)
		{
			Set-ADAccountPassword -Identity $username -OldPassword $password -NewPassword $newpass
			$valid = Test-ADAuthentication $username $pwd2_text
			if ($valid)
			{
				Write-Host "Your password has been changed!" -BackgroundColor Green -ForegroundColor Black
				Pause
			}
			else
			{
				Write-Host "Oh no...Something went horribly wrong! Please contact the IT office for more support, also tell Bridger that error code 10 happened."
			}
		}
		else
		{
			Write-Host "They do not match! Can you please start again?" -BackgroundColor Red -ForegroundColor Black
			clearvars $username $password $valid $newpass $newpassconfirm
		}
	}
	else
	{	Write-Host "You could not be validated! Try again" -BackgroundColor Red -ForegroundColor Black
		clearvars $username $password $valid $newpass $newpassconfirm
	}
}

function clearvars ($username, $password, $valid, $newpass, $newpassconfirm)
{
	$username = $null
	$password = $null
	$valid = $null
	$newpass = $null
	$newpassconfirm = $null
	main
}
Function Test-ADAuthentication($username, $password)
{
	Write-Host "Testing user credentials..."
	(new-object directoryservices.directoryentry "", $username, $password).psbase.name -ne $null
}
Main
