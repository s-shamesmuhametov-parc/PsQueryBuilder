function Get-DinamicParam
{
    param
    (
        $ParameterName,
        $arrSet,
        $position = 0
    )

    # Create the dictionary
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
      # Create the collection of attributes
      $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

      # Create and set the parameters' attributes
      $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
      $ParameterAttribute.Mandatory = $true
      $ParameterAttribute.Position = $position

      # Add the attributes to the attributes collection
      $AttributeCollection.Add($ParameterAttribute)

      $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)

      # Add the ValidateSet to the attributes collection
      $AttributeCollection.Add($ValidateSetAttribute)

      # Create and return the dynamic parameter
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