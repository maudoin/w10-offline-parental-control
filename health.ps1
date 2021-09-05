param (
  [int] $creditMinutes=30,
  $maxDate="20:00",
  [int] $shutSeconds=900,
  [bool] $startup=0
  )
#run on at startup with C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden  -executionpolicy bypass  -command "& .\health.ps1" -creditMinutes 90 -maxDate "20:00" -start 0
#run periodically with C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden  -executionpolicy bypass  -command "& .\health.ps1" -creditMinutes 90 -maxDate "20:00" -start 1


function Show-Notification {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle,
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText
    )

    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    $Template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)

    $RawXml = [xml] $Template.GetXml()
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "1"}).AppendChild($RawXml.CreateTextNode($ToastTitle)) > $null
    ($RawXml.toast.visual.binding.text|where {$_.id -eq "2"}).AppendChild($RawXml.CreateTextNode($ToastText)) > $null

    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "Parental Control"
    $Toast.Group = "Parental Control"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Parental Control")
    $Notifier.Show($Toast);
}

$todayMinutesFile = (Get-Date -Format "yyyy-MM-dd")+'.cnt'
if (Test-Path $todayMinutesFile -PathType leaf)
{
  #get previous time from file
  $previousCount = Get-Content $todayMinutesFile
  #add time from previous file creation
  if($startup)
  {
  
    #ignore time elapsed from previous count
    $todayElapsedMinutes = $previousCount
    [bool] $greet = 1
  }
  else
  {
    #command tick, update ellapsed time from previous time dump
    $elapsedSinceFile = (New-TimeSpan -start (Get-Item $todayMinutesFile).LastWriteTime).totalminutes
    $todayElapsedMinutes = $elapsedSinceFile + $previousCount
  }
}
else
{
  #first time of day
  [bool] $greet = 1
  $todayElapsedMinutes=0
}
#set current time modification and remaining credit
Write $todayElapsedMinutes > $todayMinutesFile

#check $creditMinutes
$remainingMinutes=$creditMinutes - $todayElapsedMinutes

#check $maxDate 
$minutesToMaxDate = (new-timespan -end (get-date $maxDate ) ).totalminutes
$cappedRemainingMinutes =  [math]::Min($minutesToMaxDate, $remainingMinutes)

if( $greet )
{
  Show-Notification "Controle parental" "Bienvenue, $cappedRemainingMinutes minutes avant $maxDate pour aujourd'hui"
}

if ( ($cappedRemainingMinutes -le 0) )
{
  [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
  [System.Windows.Forms.MessageBox]::Show("Fini", "PC")
  & shutdown /s /t $shutSeconds
}
