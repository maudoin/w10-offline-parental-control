param (
  [int] $creditMinutes=30,
  $maxDate="20:00",
  [int] $shutSeconds=900,
  [bool] $startup=0
  )
#run on at startup with C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden  -executionpolicy bypass  -command "& .\health.ps1" -creditMinutes 90 -maxDate "21:00" -start 1
#run periodically with C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -WindowStyle Hidden  -executionpolicy bypass  -command "& .\health.ps1" -creditMinutes 90 -maxDate "21:00"


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
    $Toast.Tag = $ToastTitle
    $Toast.Group = $ToastTitle
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    $Notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($ToastTitle)
    $Notifier.Show($Toast);
}
function Show-Notification-And-Popup {
    [cmdletbinding()]
    Param (
        [string]
        $ToastTitle,
        [string]
        [parameter(ValueFromPipeline)]
        $ToastText
    )
    Show-Notification $ToastTitle $ToastText

    [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
    [System.Windows.Forms.MessageBox]::Show($ToastText, $ToastTitle)
}

#Import-LocalizedData -BindingVariable LocalText
$LocalText = Data {
#culture="fr-FR"
ConvertFrom-StringData -StringData @'
    title = Controle parental
    expiredMaxdate = L'heure limite {0} est atteinte
    expiredDuration = {0:hh}:{0:mm} dépasse la duree maximale de {1:hh}:{1:mm}
    welcome = Bienvenue, Il reste {0:hh}:{0:mm} avant {1}
'@
}

$todayMinutesFile = (Get-Date -Format "yyyy-MM-dd")+'.cnt'
if (Test-Path $todayMinutesFile -PathType leaf)
{
  #get previous time from file
  [int] $previousCount = Get-Content $todayMinutesFile
  #add time from previous file creation
  if($startup)
  {
  
    #ignore time elapsed from previous count
    [int] $todayElapsedMinutes = [math]::round($previousCount)
    [bool] $greet = 1
  }
  else
  {
    #command tick, update ellapsed time from previous time dump
    [int] $elapsedMinutesSinceFileWritten = [math]::round((New-TimeSpan -start (Get-Item $todayMinutesFile).LastWriteTime).totalminutes)
    [int] $todayElapsedMinutes = $elapsedMinutesSinceFileWritten + $previousCount
  }
}
else
{
  #first time of day
  [bool] $greet = 1
  #initialize elapsed duration to 0
  [int] $todayElapsedMinutes=0
}


#set current time modification and remaining credit
Write $todayElapsedMinutes > $todayMinutesFile

#check $creditMinutes
[int] $remainingMinutes=$creditMinutes - $todayElapsedMinutes
[bool] $expiredFromDuration = $remainingMinutes -le 0;

#check $maxDate 
[int] $minutesToMaxDate = (new-timespan -end (get-date $maxDate ) ).totalminutes
[bool] $expiredFromMaxDate = $minutesToMaxDate -le 0;


#actual shutdown
if ( $expiredFromMaxDate -or $expiredFromDuration )
{
  & shutdown /s /t $shutSeconds
}

#notification messages
if ( $expiredFromMaxDate )
{
  Show-Notification-And-Popup -ToastTitle $LocalText.title -ToastText ($LocalText.expiredMaxDate -f $maxDate)
}
elseif ( $expiredFromDuration )
{
  [TimeSpan] $todayElapsedTime = new-timespan -minutes $todayElapsedMinutes
  [TimeSpan] $maxTimeDuration = new-timespan -minutes $creditMinutes
  Show-Notification-And-Popup -ToastTitle $LocalText.title -ToastText ($LocalText.expiredDuration -f $todayElapsedTime, $maxTimeDuration)
}
elseif( $greet )
{
  [TimeSpan] $remainingTime = new-timespan -minutes $remainingMinutes
  Show-Notification -ToastTitle $LocalText.title -ToastText ($LocalText.welcome -f $remainingTime,$maxDate)
}

