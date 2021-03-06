# Author Jasen C
# Date 2/20/2022
# Description: Audit members of the local administrators group as well as local user accounts on servers and/or workstations

#region Code Blocks for remote scripts

    $CODE = {
        $LocalUsers = Get-LocalUser | Where-Object {$_.Name -notlike '*admin*'} #filter out known local admin accounts like Administrator or admin
        
        foreach($User in $LocalUsers)
        {
            $object = new-object psobject -Property @{
                Servername = $env:computername
                UserName = $User.name
                Enabled = $User.Enabled
                }
                write-output $object 
        }
    }    

    $CODE2 = {
        $LocalAdmins = Get-LocalGroupMember -Name Administrators | Where-Object {$_.Name -notlike '*admin*'} #filter out known local admin accounts like Administrator or admin
        
        foreach($Member in $LocalAdmins)
        {
            $object1 = new-object psobject -Property @{
                Servername = $env:computername
                UserName = $Member.name
                ObjectClass = $Member.ObjectClass
                PrincipalSource = $Member.PrincipalSource
                }
                write-output $object1
        }
    }
#endregion

#region Get Server Local users and Local adminitrator report

    # Prompt for server admin credentials
    $ServerCred = $host.ui.PromptForCredential("Need Server Admin credentials", "Please enter your user name and password.", "", "NetBiosUserName")

    #Get list of windows servers from AD, filter for enabled only, select, sort and store dnshostname
    $Servers = Get-ADComputer -Filter {(OperatingSystem -Like '*Windows Server*') -and (Enabled -eq $true)} | Select-Object dnshostname | Sort-Object dnshostname 


    $ServerAccounts = ""
    $ServerAdmins = ""


    # Test our credentials and connections to each server, initialize a powershell remoting session
    Invoke-Command -ComputerName $Servers.dnshostname -Credential $ServerCred -ScriptBlock {$env:COMPUTERNAME} -erroraction SilentlyContinue

    # Run first code block to get local accounts on all servers
    $ServerAccounts = Invoke-Command -ComputerName $Servers.dnshostname -Credential $ServerCred -ScriptBlock $CODE -erroraction SilentlyContinue

    # Run second code block to get local admins on all servers
    $ServerAdmins = Invoke-Command -ComputerName $Servers.dnshostname -Credential $ServerCred -ScriptBlock $CODE2 -erroraction SilentlyContinue

    # Export each report to csv for review
    $ServerAccounts | export-csv "C:\temp\Server-LocalAccounts.csv" -NoTypeInformation
    $ServerAdmins | export-csv "C:\temp\Server-LocalAdmins.csv" -NoTypeInformation 

#endregion


#region Get workstation Local users and Local adminitrator report

    # Prompt for workstation admin credentials
    $WorkstationCred = $host.ui.PromptForCredential("Need Workstation Admin credentials", "Please enter your user name and password.", "", "NetBiosUserName")

    #Get list of windows servers from AD, filter for enabled only, select, sort and store dnshostname
    $Computers = Get-ADComputer -Filter {(OperatingSystem -Like '*Windows 10*') -and (Enabled -eq $true)} | Select-Object dnshostname | Sort-Object dnshostname 

    $WorkstationAccounts = ""
    $WorkstationAdmins = ""


    # Test our credentials and connections to each workstation, initialize a powershell remoting session
    Invoke-Command -ComputerName $Computers.dnshostname -Credential $WorkstationCred -ScriptBlock {$env:COMPUTERNAME} -erroraction SilentlyContinue

    # Run first code block to get local accounts on all workstations
    $WorkstationAccounts = Invoke-Command -ComputerName $Computers.dnshostname -Credential $WorkstationCred -ScriptBlock $CODE -erroraction SilentlyContinue

    # Run second code block to get local admins on all workstations
    $WorkstationAdmins = Invoke-Command -ComputerName $Computers.dnshostname -Credential $WorkstationCred -ScriptBlock $CODE2 -erroraction SilentlyContinue

    # Export each report to csv for review
    $WorkstationAccounts | export-csv "C:\temp\WorkStation-LocalAccounts.csv" -NoTypeInformation
    $WorkstationAdmins | export-csv "C:\temp\Workstation-LocalAdmins.csv" -NoTypeInformation 

#endregion 

# Clear our credentials when done
$ServerCred = ""
$WorkstationCred = ""