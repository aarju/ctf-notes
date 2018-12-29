Get-Process | % {if ($_.Modules -like "*automation.ni*") {$_ | select name,id}}
