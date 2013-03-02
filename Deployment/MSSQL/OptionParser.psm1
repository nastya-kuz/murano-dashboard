function New-Option ([string]$Name, [switch]$Switch, [switch]$Boolean, [switch]$String, [switch]$List, $Constraints=$null) {
    <#
    .SYNOPSIS
    ToDo: Describe

    .DESCRIPTION
    ToDo: Describe
    #>

    $Option = New-Object -TypeName PSObject

    # Fields
    $Option | Add-Member NoteProperty Type -value $null
    $Option | Add-Member NoteProperty Name -value $null
    $Option | Add-Member NoteProperty AllowedValues -value $null

    # Init

    $Option | Add-Member ScriptMethod __init__ {
        param([string]$Name, $Switch, $Boolean, $String, $List)

        $this.Name = $Name
                       
        # With respect for our developers we do not check for double type selected
        if ($Switch) {
            AugmentOptionSwitch($this)
        } elseif ($Boolean) {
            AugmentOptionBoolean($this)
        } elseif ($String) {
            AugmentOptionString($this)
        } elseif ($List) {
            AugmentOptionList($this)
        } else {
            throw "Switch, Boolean, String or List option type must be provided for option '$Name'"
        }
    }

    $Option | Add-Member ScriptMethod __post_init__ {
        param($Constraints=$null)
        if ($Constraints -ne $null) {
            $this.AllowedValues = @()
            $this.AllowedValues = $this.AllowedValues + $Constraints
        } else {
            $Constraints = $null
        }
    }

    # Methods

    $Option | Add-Member -Force ScriptMethod Validate {
        if ($this.AllowedValues -ne $null) {
            if (-not($this.AllowedValues -contains $this.Value)) {
                $Cts = $this.AllowedValues -join ','
                throw "Option '$($this.Name)' may have values ($Cts) but not '$($this.Value)'"
            }
        }
    }

    $Option | Add-Member -Force ScriptMethod ToString {
        return "/$($this.Name)"
    }

    # invoke constructor

    $Option.__init__($Name, $Switch, $Boolean, $String, $List)
    $Option.__post_init__($Constraints)

    return $Option
}

function AugmentOptionSwitch($Option) {
}

function AugmentOptionBoolean($Option) {
    # Fields
    $Option | Add-Member NoteProperty Value -value $false

    # Methods

    $Option | Add-Member -Force ScriptMethod ToString {
        if ($this.Value) {
            return "/$($this.Name)=1"
        } else {
            return "/$($this.Name)=0"
        }
    }
}

function AugmentOptionString($Option) {
    # Fields
    $Option | Add-Member NoteProperty Value -value ""

    # Methods

    $Option | Add-Member -Force ScriptMethod ToString {
        $v = "$($this.Value)"
        if ($v -match '.* .*') {
            # TODO: Escape double quote characters if possible
            return "/$($this.Name)=`"$v`""
        } else {
            return "/$($this.Name)=$v"
        }
    }
}

function AugmentOptionList($Option) {
    # Fields
    $Option | Add-Member NoteProperty Value -value @()

    # Methods

    $Option | Add-Member -Force ScriptMethod Validate {
        if ($this.AllowedValues -ne $null) {
            foreach ($V in $this.Value) {
                if (-not($this.AllowedValues -contains $V)) {
                    $Cts = $this.AllowedValues -join ','
                    throw "Option '$($this.Name)' may have values ($Cts) but not '$V'"
                }
            }
        }
    }

    $Option | Add-Member -Force ScriptMethod ToString {
        return "/$($this.Name)=$($this.Value -join ',')"
    }
}

function New-OptionParser() {
    <#
    .SYNOPSIS
    ToDo: Describe

    .DESCRIPTION
    ToDo: Describe
    #>

    $OptionParser = New-Object -TypeName PSObject

    # Fields
    $OptionParser | Add-Member NoteProperty Options -value @{}

    # Methods

    $OptionParser | Add-Member ScriptMethod AddOption {
        param($Option)
        $this.Options.Add($Option.Name, $Option)
    }

    $OptionParser | Add-Member ScriptMethod Parse {
        param([hashtable]$Options)

        $CommandLine = @()
        foreach($OptionName in $($Options.keys)) {
            $Option = $this.Options.Get_Item($OptionName)
            if ($Option -eq $null) {
                throw "Option '$OptionName' is not allowed"
            }
            $Option.Value = $Options.Get_Item($OptionName)
            $Option.Validate()
            $CommandLine = $CommandLine + $Option.ToString()
        }
        return $CommandLine -join ' '
    }

    return $OptionParser
}

Export-ModuleMember -Function New-OptionParser
Export-ModuleMember -Function New-Option