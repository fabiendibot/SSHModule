<#
.SYNOPSIS
This module allows to connect SSH Server and do few differents actions.
 
.DESCRIPTION
This module works with Renci.dll a .NET library which allows powershell to pen SSH Sessions.
By default i have put the library to C:Temp, but you can change it by editing the directory in line 52 -> [Reflection.Assembly]::LoadFile('<YOUR DIRECTORY>Renci.SshNet35.dll') | out-null
This module is made, because few modules were present on the web, but not really efficient, and few functions were missing, so i made this one.
Feel free to ping me back if there are bugs or features missing, keep in mind it's a beta version and it will evolve
 
To load this module, do the old but very cool command: Import-Module SSH
 
.LINK
SSH .NET Library: http://sshnet.codeplex.com/
Site: http://pwrshell.net

 
.NOTE
Author: Fabien Dibot (@fdibot)
http://pwrshell.net
Version: 2.0
Copyright: Copyleft
Love to my wife and my son :°)
 
#>
 
$AssemblyFile = 'D:\Powershell\dev\Renci.SshNet.4.0.dll'
if (Test-Path $AssemblyFile) {
    [Reflection.Assembly]::LoadFile($AssemblyFile) | out-null
}
else {
    Throw "Error getting ${AssemblyFile}"
    exit 0
}
 
Function New-SSHSession {
 
<#
.SYNOPSIS
This function creates a SSH Session
 
.DESCRIPTION
This function provide a cmdlet to create a SSH Session, you define few parameters an even use a key instead of password.
If you don't specify a password neither a key, nothing will happened
 
Note that, the connection informations is stored in a Global variable, named $Client.
After you Initiate a connection to SSH Server, you can use this variable in all the script until you use the Remove-SSHSession cmdlet
 
You use SSH Session to execute command
 
.PARAMETER Keyfile
The path leads to the key for authenticated, if you don't use it. Specify a password
 
.PARAMETER Password
The password used for the account to connect to SSH Server
 
.PARAMETER Server
The SSH Server.
 
.PARAMETER UserName
The account use to connect to SSH Server
 
.PARAMETER Port
By default it's, 22. If your SSH Server is listening to another one, please specify it.
 
.PARAMETER Quiet
This is a switch if you don't want the connection informations deployer in the console after the connection to SSH Server
 
.EXAMPLE
C:PS> New-SSHSession -server 127.0.0.1 -UserName root -password Thisisafake
C:PS> New-SSHSession -server 127.0.0.1 -UserName root -KeyFile "C:tempkey.tmp" -Passphrase 'TestThis'
C:PS> New-SSHSession -server 127.0.0.1 -UserName root -password Thisisafake
 
#>
 
param (
    [Parameter(Mandatory=$false)]
    [String]$Key,
    [Parameter(Mandatory=$false)]
    [String]$Password,
    [Parameter(Mandatory=$true)]
    [String]$Server,
    [Parameter(Mandatory=$true)]
    [String]$UserName,
    [Parameter(Mandatory=$false)]
    [Int]$Port = 22,
    [Parameter(Mandatory=$false)]
    [String]$Passphrase
    )
 
    if ($Key) {
        if (Test-Path $Key) {
            $KeyPass = New-Object Renci.SshNet.PrivateKeyFile($Key,$Passphrase)
            $Client = New-Object Renci.SshNet.SshClient($Server, $Port, $UserName, $KeyPass)
        }
        else {
            Throw "${key} does not exists"
        }
    }
    else {
        if (!($Password)) {
            Throw "No password specified"
            Continue
        }
        $Client = New-Object Renci.SshNet.SshClient($Server, $Port, $UserName, $Password)
    }
 
    Try {
        $Client.Connect()
        if ($Client.IsConnected) {
            $Global:Client = $client
            $Client
        }
        else {
            Throw "Error connecting ${Server}"
        }
    }
    Catch {
        Throw "Error connecting ${Server}. $($_.Exception.Message)"
    }
}
 
Function Invoke-SSHCommand {
<#
.SYNOPSIS
This function execute a command in a SSH Session
 
.DESCRIPTION
This function use the New-SSHSession return value to execute a command on the connected SSH Server.
The result is print on console, but you can use $SSHCommand object and his properties to get the result in a variable
 
.PARAMETER Client
This is the object returned by the New-SSHSession cmdlet
 
.PARAMETER Password
Command, a string with one or multiple command.
 
.EXAMPLE
C:PS> New-SSHSession -server 127.0.0.1 -UserName root -password Thisisafake | Invoke-SSHCommand -command "uname -a"
C:PS> Invoke-SSHCommand -client $client -command "cd /dir/truc;ls -a"
 
#>
 
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SshClient]$Client,
        [Parameter(Mandatory=$true)]
        [String]$Command
    )
    $Global:SSHCommand = $null
    if ($Client.IsConnected) {
        $SSHCommand = $Client.RunCommand($Command)
    } 
    else {
        Throw "You are not connected to any SSH Server"
        Continue
    }
    if ($SSHCommand.ExitStatus -eq 0) {
        $Global:SSHCommand = $SSHCommand
        $SSHCommand
    }
    else {
        Throw "${SSHCommand.Error}"
    }
}
 
Function New-SFTPSession {
 
<#
.SYNOPSIS
This function creates a SFTP Session
 
.DESCRIPTION
This function provide a cmdlet to create a SFTP Session, you define few parameters an even use a key instead of password.
If you don't specify a password neither a key, nothing will happened
 
Note that, the connection informations is stored in a Global variable, named $Client.
After you Initiate a connection to SFTP Server, you can use this variable in all the script until you use the Remove-SFTPSession cmdlet
 
You use SFTP Session to upload and download files
 
.PARAMETER Keyfile
The path leads to the key for authenticated, if you don't use it. Specify a password
 
.PARAMETER Password
The password used for the account to connect to SSH Server
 
.PARAMETER Server
The SSH Server.
 
.PARAMETER UserName
The account use to connect to SSH Server
 
.PARAMETER Port
By default it's, 22. If your SSH Server is listening to another one, please specify it.
 
.PARAMETER Quiet
This is a switch if you don't want the connection informations deployer in the console after the connection to SSH Server
 
.EXAMPLE
C:PS> New-SFTPSession -server 127.0.0.1 -UserName root -password Thisisafake
C:PS> New-SFTPSession -server 127.0.0.1 -UserName root -KeyFile "C:tempkey.tmp" -Passphrase 'TestThis'
C:PS> New-SFTPSession -server 127.0.0.1 -UserName root -password Thisisafake
 
#>
    param (
        [Parameter(Mandatory=$false)]
        [String]$Key,
        [Parameter(Mandatory=$false)]
        [String]$Password,
        [Parameter(Mandatory=$true)]
        [String]$Server,
        [Parameter(Mandatory=$true)]
        [String]$UserName,
        [Parameter(Mandatory=$false)]
        [Int]$Port = 22,
        [Parameter(Mandatory=$false)]
        [String]$Passphrase
    )
 
    if ($Key) {
        if (Test-Path $Key) {
            $KeyPass = New-Object Renci.SshNet.PrivateKeyFile($Key,$Passphrase)
            $ConnInfo = New-Object Renci.SshNet.PrivateKeyConnectionInfo($Server,$Port,$UserName,$KeyPass)
            $Client = New-Object Renci.SshNet.SftpClient($ConnInfo)
        }
        else {
            Throw "${key} does not exists"
        }
    }
    else {
        if ($Password) {
            $ConnInfo = New-Object Renci.SshNet.PasswordConnectionInfo($Server, $Port, $UserName, $Password)
            $Client = New-Object Renci.SshNet.SftpClient($ConnInfo)
        }
        else {
            Throw "Specify a password."
        }
    }
 
    Try {
        $Client.Connect()
        if ($Client.IsConnected) {
            $Global:Client = $client
        }
        else {
            Throw "Error connecting ${Server}"
        }
    }
    Catch {
        Throw "Error connecting ${Server}. $($_.Exception.Message)"
    }
    Finally {
        $Global:Client
    }
}
 
Function Get-SFTPFile {
<#
.SYNOPSIS
This function download a file on SFTP Server
 
.DESCRIPTION
This function use the object created with SFTP-SSHSession cmdlet to download a file from a SSH Server
 
.PARAMETER Client
This is the object returned by the New-SFTPSession cmdlet
 
.PARAMETER File
The file stored on SSH Server. Use Full path.
 
.PARAMETER Destination
The file will be created locally.
 
.EXAMPLE
C:PS> New-SFTPSession -server 127.0.0.1 -UserName root -password Thisisafake -Quiet | Get-SFTPFile -File "/var/www/text/truc" -Destination "C:tempmachin.bidule"
C:PS> Get-SFTPFile -Client $Client -File "/var/www/text/truc" -Destination "C:tempmachin.bidule"
C:PS> $Client | Get-SFTPFile -File "/var/www/text/truc" -Destination "C:tempmachin.bidule"
 
#>
 
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SftpClient]$Client,
        [Parameter(Mandatory=$true)]
        [String]$File,
        [Parameter(Mandatory=$true)]
        [String]$Destination,
        [Parameter(Mandatory=$true)]
        [String]$Location
    )
 
    Try {
        if (Test-Path $Destination) {
            $FileFull = $Destination + $File
            $DestinationFull = $Location + $File
            $FileStream = [System.IO.File]::Create($DestinationFull)
            $Client.DownloadFile($FileFull, $FileStream)
        }
        else {
            Throw "${Destination} does not exists"
        }
    }
    Catch {
        Throw "Error Downloading ${File}. $($_.Exception.Message)"
    }
    Finally {
        $FileStream.Flush()
        $FileStream.Dispose()
    }
}
 
Function Copy-SFTPFile {
<#
.SYNOPSIS
This function upload a file on SFTP Server
 
.DESCRIPTION
This function use the object created with SFTP-SSHSession cmdlet to upload a file from a SSH Server
 
.PARAMETER Client
This is the object returned by the New-SFTPSession cmdlet
 
.PARAMETER File
The file stored locally.
 
.PARAMETER Destination
The file will be created remotly. Use Full path.
 
.EXAMPLE
C:PS> New-SFTPSession -server 127.0.0.1 -UserName root -password Thisisafake -Quiet | Copy-SFTPFile -File "C:tempmachin.bidule" -Destination "/var/www/text/truc"
C:PS> Copy-SFTPFile -Client $Client -File "C:tempmachin.bidule" -Destination "/var/www/text/truc"
C:PS> $Client | Copy-SFTPFile -File "C:tempmachin.bidule" -Destination "/var/www/text/truc"
 
#>
 
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SftpClient]$Client,
        [Parameter(Mandatory=$true)]
        [String]$File,
        [Parameter(Mandatory=$true)]
        [String]$Destination,
        [Parameter(Mandatory=$true)]
        [String]$Location
    )
 
    Try {
        $FullFile = $Location + $File
        if (Test-Path $FullFile) {
            $FileStream = New-Object System.IO.FileStream($FullFile, [System.IO.FileMode]::Open)
            $DestinationFull = $Destination + $File
            $Client.UploadFile($FileStream,$DestinationFull)
        }
        else {
            Throw "${FullFile} does not exists"
        }
     }
    Catch {
        Throw "Error Uploading ${File}. $($_.Exception.Message)"
    }
    Finally {
        $FileStream.Flush()
        $FileStream.Dispose()
    }
}
 
Function Remove-SSHSession {
 
<#
.SYNOPSIS
This function close a SSH Session
 
.DESCRIPTION
This function use the object created with New-SSHSession cmdlet to close it
 
.PARAMETER Client
This is the object returned by the New-SSHSession cmdlet
 
.EXAMPLE
C:PS> Remove-SSHSession -Client $Client
C:PS> $Client | Remove-SSHSession
 
#>
 
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SshClient]$Client
    )
 
    Try {
        $Hostname = $client.ConnectionInfo.Host
        $Global:Client = $null
    }
    Catch {
        Throw "Error deconnecting. $($_.Exception.Message)"
    }
    Finally {
        $Client.Disconnect()
        $Client.Dispose()
    }
}
 
Function Remove-SFTPSession {
 
<#
.SYNOPSIS
This function close a SFTP Session
 
.DESCRIPTION
This function use the object created with New-SFTPSession cmdlet to close it
 
.PARAMETER Client
This is the object returned by the New-SFTPSession cmdlet
 
.EXAMPLE
C:PS> Remove-SFTPSession -Client $Client
C:PS> $Client | Remove-SFTPSession
 
#>
 
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SftpClient]$Client
    )
 
    Try {
        $Hostname = $client.ConnectionInfo.Host
        $Global:Client = $null
    }
    Catch {
        Throw "Error deconnecting. $($_.Exception.Message)"
    }
    Finally {
        $Client.Disconnect()
        $Client.Dispose()
    }
}
 
function Get-SSHList {
 
<#
.SYNOPSIS
This function return a list of file in a directory on SSH Server
 
.DESCRIPTION
This function create a custom object with a parsing of string result.
It uses the $Client object to get SSH Connecion informations
 
.PARAMETER Client
This is the object returned by the New-SSHSession cmdlet
 
.PARAMETER Directory
The Directory you wan to lit content.
 
.EXAMPLE
C:PS> New-SSHSession -server 10.1.114.45 -UserName root -password 12345 | Get-SSHList -Directory "/root/"
C:PS> $Client | Get-SSHList -Directory "/var/www/scripts/"
C:PS> Get-SSHList -Client $Client -Directory "/var/www/scripts/"
 
#>
 
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SshClient]$Client,
        [Parameter(Position=1,Mandatory=$true)]
        [String]$Directory
    )
 
    $Resultat = Invoke-SSHCommand -Client $Client -Command "cd $Directory;ls -l --full-time "
    $ListOfFiles = $Resultat.result.split("`r`n")
    $FilesList = @()
 
    Try {
        $ListOfFiles | % {
            $SplitFile = $_.split(" ")
            [String]$SplitTimeString = $SplitFile[6]
            $SplitTime = $SplitTimeString.split(".")
            if ( $SplitFile[0] -ne "Total") {
                $FilesList += New-Object PSObject -property @{
                'Chmod' = $SplitFile[0];
                'CreateDate' = $SplitFile[5];
                'CreateTime' = $SplitTime[0];
                'Name' = $SplitFile[8];
                'FullName' = $SnapshotDir + $SplitFile[8]
                }
            }
        }
    }
    Catch {
        Throw "Unable to create a custom object with list of files. $($_.Exception.Message)"
    }
    Finally {
        $FilesList
    }
}
 
function Get-SftpList {
<#
.SYNOPSIS
This function return a list of file in a directory on SSH Server
 
.DESCRIPTION
This function create a custom object with a parsing of string result.
It uses the $Client object to get SSH Connecion informations
 
.PARAMETER Client
This is the object returned by the New-SFTPSession cmdlet
 
.PARAMETER Directory
The Directory you wan to lit content.
 
.EXAMPLE
C:PS> New-SFTPSession -server 10.1.114.45 -UserName root -password 12345 | Get-SftpList -Directory "/root/"
C:PS> $Client | Get-SftpList -Directory "/var/www/scripts/"
C:PS> Get-SftpList -Client $Client -Directory "/var/www/scripts/"
 
#>
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SftpClient]$Client,
        [Parameter(Position=1,Mandatory=$true)]
        [String]$Directory
    )
 
    try {
        $FileList = $Client.ListDirectory($Directory)
    }
    Catch {
        Throw "Unable to create a custom object with list of files."
    }
    Finally {
        $FileList
    }
}
 
Function Remove-SFTPItem {
<#
.SYNOPSIS
This function rdelete an item on a sftp server
 
.DESCRIPTION
This function use Renci.SshNet.SftpClient class to remove an item file/directory
 
.PARAMETER Client
This is the object returned by the New-SFTPSession cmdlet
 
.PARAMETER Type
File or directory depends of what you want to delete
 
.PARAMETER Name
The path to the item you want to delete
 
.EXAMPLE
C:PS> New-SFTPSession -server 10.1.114.45 -UserName root -password 12345 | Remove-SFTPItem -Type File -Name "/home/fabien/truc.txt"
C:PS> $Client | Remove-SFTPItem -Type File -Name "/home/fabien/machin.pdf"
C:PS> Remove-SFTPItem -Client $Client -Type Directory -Name "/home/fabien/fab"
 
#>
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SftpClient]$Client,
        [Parameter(Mandatory=$true)]
        [ValidateSet("File","Directory")]
        [String]$Type,
        [Parameter(Mandatory=$true)]
        [String]$Name
    )
    Try {
        if ($Type -eq 'file') {
            $Client.DeleteFile($Name)
        }
        elseif ($type -eq 'Directory') {
            $Client.DeleteDirectory($Name)
        }
    }
    Catch {
        Throw "Error removing $Name. $($_.Exception.Message)"
    }
}
 
Function Get-SFTPConnectionInfo {
<#
.SYNOPSIS
Get informations about a sftp connection
 
.DESCRIPTION
Get informations about a sftp connection
 
.PARAMETER Client
This is the object returned by the New-SFTPSession cmdlet
 
.EXAMPLE
C:PS> New-SFTPSession -server 10.1.114.45 -UserName root -password 12345 | Get-SFTPConnectionInfo
C:PS> $Client | Get-SFTPConnectionInfo
C:PS> Get-SFTPConnectionInfo -Client $Client
 
#>
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SftpClient]$Client
    )
    $Client.ConnectionInfo
}
 
Function Get-SSHConnectionInfo {
<#
.SYNOPSIS
Get informations about a ssh connection
 
.DESCRIPTION
Get informations about a ssh connection
 
.PARAMETER Client
This is the object returned by the New-SSHSession cmdlet
 
.EXAMPLE
C:PS> New-SSHSession -server 10.1.114.45 -UserName root -password 12345 | Get-SSHConnectionInfo
C:PS> $Client | Get-SSHConnectionInfo
C:PS> Get-SSHConnectionInfo -Client $Client
 
#>
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SshClient]$Client
    )
    $Client.ConnectionInfo
}
 
Function New-SSHForwardPort {
<#
.SYNOPSIS
This cmdlet create a forward port object
 
.DESCRIPTION
The object returned will be typed as Renci.SshNet.ForwardedPortRemote and contain all informations described in parameters
 
.PARAMETER BoundHost
The bouned host where you will connect
 
.PARAMETER BoundPort
The port of the bounded host where you will connect
 
.PARAMETER Host
The remote Host
 
.PARAMETER Port
The port of the remote host
 
.EXAMPLE
C:PS> New-SSHForwardPort -BoundHost localhost -BoundPort 8081 -Host some.remote.host.net -Port 80
 
#>
    param (
        [Parameter(Mandatory=$true)]
        [String]$BoundHost,
        [Parameter(Mandatory=$true)]
        [String]$BoundPort,
        [Parameter(Mandatory=$true)]
        [String]$Host,
        [Parameter(Mandatory=$true)]
        [String]$Port
    )
    Try {
        $Global:ForwardPort = New-Object Renci.SshNet.ForwardedPortRemote($BoundHost, $BoundPort, $Host, $Port)
    }
    Catch {
        Throw "Error create Forwarded port object. $($_.Exception.Message)"
    }
    Finally {
        $Global:ForwardPort
    }
}
 
Function Add-SSHForwardPort {
<#
.SYNOPSIS
This cmdlet add a forward port object
 
.DESCRIPTION
Add the port created by New-SSHForwardPort cmdlet fo a SSH Session object
 
.PARAMETER Client
the ssh session object
 
.PARAMETER ForwardPort
the forward port object
 
.EXAMPLE
C:PS> $Client | Add-SSHForwardPort -ForwardPort $ForwardPort
C:PS> Add-SSHForwardPort -Client $Client -ForwardPort $ForwardPort
 
#>
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SshClient]$Client,
        [Parameter(Position=1,Mandatory=$true)]
        [Renci.SshNet.ForwardedPortRemote]$ForwardPort
    )
    if ($Client.IsConnected) {
        if ($ForwardPort) {
            Try {
                $Client.AddForwardedPort($ForwardPort)
            }
            Catch {
            Throw "Error adding Forwarded port object. $($_.Exception.Message)"
            }
        }
        else {
        Throw "Use New-SSHForwardPort cmdlet to create the ForwardPort object"
        }
    }
    else {
        Throw "Not connected to any SSH shell. Use New-SSHSession cmdlet"
    }
}
 
Function Remove-SSHForwardPort {
<#
.SYNOPSIS
This cmdlet remove a forward port object
 
.DESCRIPTION
remove the port created by New-SSHForwardPort cmdlet fo a SSH Session object
 
.PARAMETER Client
the ssh session object
 
.PARAMETER ForwardPort
the forward port object
 
.EXAMPLE
C:PS> $Client | Remove-SSHForwardPort -ForwardPort $ForwardPort
C:PS> Remove-SSHForwardPort -Client $Client -ForwardPort $ForwardPort
 
#>
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SshClient]$Client,
        [Parameter(Position=1,Mandatory=$true)]
        [Renci.SshNet.ForwardedPortRemote]$ForwardPort
    )
    if ($Client.IsConnected) {
        if ($ForwardPort) {
            Try {
                $Client.RemoveForwardedPort($ForwardPort)
            }
            Catch {
                Throw "Error adding Forwarded port object. $($_.Exception.Message)"
            }
        }
        else {
            Throw "Use New-SSHForwardPort cmdlet to create the ForwardPort object"
        }
    }
    else {
        Throw "Not connected to any SSH shell. Use New-SSHSession cmdlet"
    }
}
Function Start-SSHPortForwarding {
<#
.SYNOPSIS
This cmdlet starts the forwarding
 
.DESCRIPTION
This cmdlet starts the forwarding for a ssh session with a forwarder port
 
.PARAMETER Client
the ssh session object
 
.PARAMETER ForwardPort
the forward port object
 
.EXAMPLE
C:PS> $Client | Start-SSHPortForwarding -ForwardPort $ForwardPort
C:PS> Start-SSHPortForwarding -Client $Client -ForwardPort $ForwardPort
 
#>
    param (
    [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
    [Renci.SshNet.SshClient]$Client,
    [Parameter(Position=1,Mandatory=$true)]
    [Renci.SshNet.ForwardedPortRemote]$ForwardPort
    )
    if ($Client.ForwardedPorts) {
        if (!($ForwardPort.IsStarted)) {
            Try {
                $ForwardPort.Start()
            }
            Catch {
                Throw "Enable starting forward. $($_.Exception.Message)"
            }
        }
        else {
            Throw "Port forwarding already started."
        }
    }
    else {
        Throw "Use Add-SSHForwardPort cmdlet to add it to ssh session properties"
    }
}
 
Function Stop-SSHPortForwarding {
<#
.SYNOPSIS
This cmdlet stops the forwarding
 
.DESCRIPTION
This cmdlet stops the forwarding for a ssh session with a forwarder port
 
.PARAMETER Client
the ssh session object
 
.PARAMETER ForwardPort
the forward port object
 
.EXAMPLE
C:PS> $Client | Stop-SSHPortForwarding -ForwardPort $ForwardPort
C:PS> Stop-SSHPortForwarding -Client $Client -ForwardPort $ForwardPort
 
#>
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SshClient]$Client,
        [Parameter(Position=1,Mandatory=$true)]
        [Renci.SshNet.ForwardedPortRemote]$ForwardPort
    )
    if ($Client.ForwardedPorts) {
        if ($ForwardPort.IsStarted) {
            Try {
                $ForwardPort.Stop()
            }
            Catch {
                Throw "Enable starting forward. $($_.Exception.Message)"
            }
        }
        else {
            Throw "Port forwarding already stopped."
        }
    }
    else {
        Throw "Use Add-SSHForwardPort cmdlet to add it to ssh session properties"
    }
}
 
Function Get-SSHForwardPort {
<#
.SYNOPSIS
This cmdlet gather the forwarderports information
 
.DESCRIPTION
This cmdlet gather the forwarderports information
 
.PARAMETER Client
the ssh session object
 
.EXAMPLE
C:PS> $Client | Get-SSHForwardPort
C:PS> Get-SSHForwardPort -Client $Client
 
#>
    param (
        [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
        [Renci.SshNet.SshClient]$Client
    )
    $Client.ForwardedPorts
}
 
# Set aliases
Set-Alias -Scope Global -name nss -value New-SSHSession -Description "SSH Alias"
Set-Alias -Scope Global -name nsf -value New-SFTPSession -Description "SSH Alias"
Set-Alias -Scope Global -name ssrun -value Invoke-SSHCommand -Description "SSH Alias"
Set-Alias -Scope Global -name sfget -value Get-SFTPFile -Description "SSH Alias"
Set-Alias -Scope Global -name sfput -value Copy-SFTPFile -Description "SSH Alias"
Set-Alias -Scope Global -name ssext -value Remove-SSHSession -Description "SSH Alias"
Set-Alias -Scope Global -name sfext -value Remove-SFTPSession -Description "SSH Alias"
Set-Alias -Scope Global -name ssls -value Get-SSHList -Description "SSH Alias"
Set-Alias -Scope Global -name sfdel -value Remove-SFTPItem -Description "SSH Alias"
Set-Alias -Scope Global -name sfls -value Get-SftpList -Description "SSH Alias"
Set-Alias -Scope Global -name sfinfo -value Get-SFTPConnectionInfo -Description "SSH Alias"
Set-Alias -Scope Global -name ssinfo -value Get-SSHConnectionInfo -Description "SSH Alias"
 
#Export Members
Export-ModuleMember -Alias * -Function New-SSHSession,Invoke-SSHCommand,New-SFTPSession,Get-SFTPFile,Copy-SFTPFile,Remove-SSHSession,Remove-SFTPSession,Get-SSHList,Get-SftpList,Remove-SFTPItem,Get-SFTPConnectionInfo,Get-SSHConnectionInfo,New-SSHForwardPort,Add-SSHForwardPort,Remove-SSHForwardPort,Start-SSHPortForwarding,Stop-SSHPortForwarding,Get-SSHForwardPort