#skript na zalohu *.fbk suborov Engineering Base (exporty databazy)
#Administrator Engineering Base do adresara $srcDir rucne generuje zalohy z EB v tvare *.fbk
#odtial sa len doteraz neskopirovane subory kopiruju do $dstDir
#kopiruje sa na zaklade suboru $copyListTxt - parameter, kde su zapisane uz skopirovane subory

#Cielom tohto skriptu je kopirovat len novovytvorene zalohy z EB a nekopirovat uz existujuce zalohy


#-------------------------------------------------------------------------------------------------------------------------
#PARAMETRE - mozes menit podla potreby

#zdrojovy adresar - odtialto sa budu nove subory kopirovat
$srcDir = "D:\EB Backup_Files\"

#cielovy adresar - sem sa kopiruju subory
$dstDir = "\\storage\Zalohy2\EB_Backup\"

#nazov suboru v cielovom adresari, kde je zoznam uz kopirovanych suborov. Ak neexistuje, tak sa vytvori pri prvom kopirovani suboru
$copyListTxt = "_copyList.txt"

#email, kde sa posle zaznam o kopirovani
$email = "it@noving.sk"
#$email = "jozef.durina@noving.sk"

#KONIEC PARAMETRE
#-------------------------------------------------------------------------------------------------------------------------

$subject = "EB Backup status"

$date = Get-Date 
#telo emailu, ktory sa odosle po vykonani ulohy
$body = "Kopirovanie exportovanych databaz z Engineering Base do zalohy - $($date.ToString('yyyy-MM-dd HH:mm:ss'))`n"
$body += "Skript bezi na: $env:COMPUTERNAME`n"
$body += "Cesta k skriptu: $($MyInvocation.MyCommand.Path)`n"
$body += "Zdrojovy adresar: $srcDir`n"
$body += "Cielovy adresar: $dstDir`n"

$body += "`n"

$pathError = $FALSE    #

if (-NOT(Test-Path $srcDir)) {
    $body += "CHYBA: Zdrojovy adresar neexistuje alebo je nedostupny!!!`n"
    $pathError= $TRUE
}

if (-NOT(Test-Path $dstDir)) {
    $body += "CHYBA: Cielovy adresar neexistuje alebo je nedostupny!!!`n"
    $pathError= $TRUE
}

if ($pathError) {
    $subject = "ERROR!!! - " + $subject

} else {

    #Ziskam zoznam suborov v lokalnom adresari
    $srcFiles = Get-ChildItem -Path $srcDir -Filter *.fbk

    <#
    #vypis zoznamu suborov v lokalnom adresari
    Write-Host "---srcDirFiles---"
    foreach ( $srcFile in $srcFiles ) {
        $srcFile.Name
    }
    #>

    # $copyList - tu bude zoznam uz nakopirovanych suborov nacitanych zo suboru copyList.txt
    $copyList = @()  #prazdny array 

    if ( Test-Path $dstDir\$copyListTxt ) {
        foreach ( $line in Get-Content $dstDir\$copyListTxt ) {    
            $copyList += $line
        }
    }

    <#
    ""
    "---copyList---"
    $copyList
    ""
    #>

    #priznak, ci sa nieco kopirovalo
    $somethingToCopy = $FALSE

    #priznak, ci nejake kopirovanie zlyhalo
    $someCopyFailed = $FALSE

    foreach ($srcFile in $srcFiles) {
    
        $exist = $FALSE
        foreach ( $line in $copyList) {    # kazdy lokalny subor porovnam s nazvami uz nakopirovanych suborov
            if  ($line -eq $srcFile.Name) {
                $exist = $TRUE
                break
            }
        }

        #tu sa vlastne robi mnozinovy rozdiel $srcFiles - $copyList
        #cize sa hladaju subory, ktore su v $srcFiles a nie su v $copyList

        #a ak este nebol kopirovany - tak ho skopirujem
        if (-NOT($exist)) { #ak sa subor z localDir nenasiel v zozname uz nakopirovanych suborov copyList.txt
        
            $somethingToCopy = $TRUE

            $dstFilePath = $dstDir + $srcFile.Name
        
            $bodyline = "Kopirujem  $($srcFile.FullName)  ...`n  ... do  $dstFilePath  ...  "
            Write-Host -NoNewline "$bodyline"
            $body += $bodyline

            #samotne kopirovanie - moze byt casovo narocne
            Copy-Item $srcFile.FullName -Destination $dstDir
        
            #a overim, ci sa subor skopiroval spravne
            $copyOK = $FALSE
            if (Test-Path $dstFilePath) {
                $dstFile = Get-Item $dstFilePath
                if ($dstFile.Length -eq $srcFile.Length) {
                    $copyOK = $TRUE
                }
            } 
        
            if ($copyOK) {            
                Add-Content $dstDir\$copyListTxt $srcFile.Name
                Write-Host "OK"
                $body += "OK`n`n"

            } else {
                Write-Host "zlyhalo."
                $body += "zlyhalo.`n`n"
                $someCopyFailed = $TRUE
            }

        }
    }

    if (-NOT($somethingToCopy)) {
        $nic = "Nenaslo sa nic nove na kopirovanie"
        Write-Host $nic
        $body += $nic
    }


    if ($someCopyFailed) {
        $subject = "WARNING!!! - " + $subject
        $body += "Skontroluj, ci je cielovy adresar $dstDir dostupny a ci je na nom dostatok volneho miesta. `n"
    } 
}


#nakoniec poslem mail so zaznamom priebehu
Send-MailMessage `
    -From EB_backup_script@noving.sk `
    -To $email `
    -Subject $subject `
    -Body $body `
    -SmtpServer 'mail.noving.sk'



