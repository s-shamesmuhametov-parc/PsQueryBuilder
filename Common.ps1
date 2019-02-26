function Get-DinamicParam
{
    param
    (
        $ParameterName,
        $arrSet,
        $position = 0
    )

    $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

    $RuntimeParameter = Get-StringAutocomletionParam $ParameterName $arrSet $position

    $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
    return $RuntimeParameterDictionary
}

function Get-StringAutocomletionParam {
    param
    (
        $ParameterName,
        $arrSet,
        $position = 0
    )
    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $true
    $ParameterAttribute.Position = $position

    $AttributeCollection.Add($ParameterAttribute)

    if ($arrSet -ne $null) {
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
    }

      return New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
}

function Get-SwitchParam
{
    param
    (
        $ParameterName,
        $position = 0
    )
    # Create the collection of attributes
    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

    # Create and set the parameters' attributes
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $false
    $ParameterAttribute.Position = $position

    # Add the attributes to the attributes collection
    $AttributeCollection.Add($ParameterAttribute)

    # Create and return the dynamic parameter
    $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [switch], $AttributeCollection)
    return $RuntimeParameter
}