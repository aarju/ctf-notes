

function Invoke-WMIPersistCheck { 
    <#
        .Synopsis
        Queries WMI event subscriber classes commonly used by malware for persistence. 

        PowerShell Function: Invoke-WMIPersistCheck
        Author: Aaron Jewitt
                
        .Description
        Queries WMI event subscriber classes commonly used by malware for persistence. Queries the root\Subscription namespace looking for __FilterToConsumerBinding entries then finds the associated consumer and filter for the binding. Returns the subscription event as a single object
        
        .PARAMETER Computer
        IP address or hostname of the machine to query. Default will run the query against the local system. Can be passed in via the pipeline.
    #>
    
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [String]$Computer = $env:COMPUTERNAME

    )

    $bindings = Get-WMIObject -Namespace root\Subscription -Class __FilterToConsumerBinding -ComputerName $computer
    $wmiEvents = @()

    foreach ($binding in $bindings){
        # start a for loop looking at each binding
        #$binding is the filterconsumerbinding associated with the eventfilter
        #$eventFilter is an eventfilter in the subscriptions namespace
        #$consumer is the consumer bound to the event

        # find the matching Filter and consumer
        $eventFilter = Get-WMIObject -Namespace root\Subscription -Class __EventFilter -ComputerName $computer | where {($_.Name).contains($binding.Filter.Split('"')[1])}
        $consumer = Get-WMIObject -Namespace root\Subscription -Class __EventConsumer -ComputerName $computer | where {($_.Name).contains($binding.Consumer.Split('"')[1])}

        $WMIproperties = @{}
        $WMIproperties.Host=$computer
        $WMIproperties.EventFilterName=$eventFilter.Name
        $WMIproperties.EventFilterQuery=$eventFilter.Query
        $WMIproperties.EventConsumerName=$consumer.Name
        $WMIproperties.EventConsumerSourceName=$consumer.SourceName
        $WMIproperties.EventConsumerExecutablePath=$consumer.ExecutablePath
        $WMIproperties.EventConsumerScriptFileName=$consumer.ScriptFileName
        $WMIproperties.EventConsumerScriptingEngine=$consumer.ScriptingEngine
        $WMIproperties.EventConsumerScriptText=$consumer.ScriptText
        $WMIproperties.EventConsumerCommandLineTemplate=$consumer.CommandLineTemplate
        $WMIproperties.EventConsumerWorkingDirectory=$consumer.WorkingDirectory
        $wmiEvents += $WMIproperties
        
    }
    $wmiEvents
}

# These two consumers are very common and confirmed to be benign unless they have been modified


function Invoke-WMIUnkownPersistCheck {
        [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [String]$Computer = $env:COMPUTERNAME

    )
    <#
        .synopsis
        Executes Invoke-WMIPersistCheck and checks the results against known good. Only displays the unknown entries.

        PowerShell Function: Invoke-WMIUnkownPersistCheck
        Author: Aaron Jewitt

        .Description
        Executes the Invoke-WMIPersistCheck function and checks the results against a list of known good Consumers. 
    #>

    $knowngood = @(
               "BVTConsumer",
               "SCM Event Log Consumer"
               )

    $wmiSubscriptions = Invoke-WMIPersistCheck -Computer $Computer
    foreach ($wmi in $wmiSubscriptions){
        if ($knowngood -match $wmi.EventConsumerName){
        # comment out the following line to only report unknowns.
        "[+] " +$wmi.Host + ":" + $wmi.EventConsumerName 
        }
        else{
        "[-] UNKNOWN: " + $wmi.Host
        "[-] UNKNOWN: " + $wmi.EventFilterName
        "[-] UNKNOWN: " + $wmi.EventConsumerName
        "[-] UNKNOWN: " + $wmi.EventFilterQuery
        "[-] UNKNOWN: " + $wmi.EventConsumerScriptFileName
        "[-] UNKNOWN: " + $wmi.EventConsumerScriptText
        "[-] UNKNOWN: " + $wmi.EventConsumerScriptingEngine
        "[-] UNKNOWN: " + $wmi.EventConsumerWorkingDirectory
        "[-] UNKNOWN: " + $wmi.EventConsumerCommandLineTemplate
        }
    }
}




