param vnetID string
param privateDNSname string //https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-dns

@description('DNS Zone Creation')
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDNSname
  location: 'global'
}

@description('Connecting DNS with Vnet')
resource privateDNSZoneNetworkLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDNSZone
  name: 'CoreVnetLink'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetID
    }
  }
}
