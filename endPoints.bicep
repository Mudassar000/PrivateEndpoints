param location string
param privateDnsRG string

@secure()
param privateEndpintName string

@secure()
param privateDnsName object

// var targetSubResource = [ //https://docs.microsoft.com/en-us/azure/private-link/private-endpoint-overview
//   'blob'
//   'file'
//   'queue'
//   'table'
// ]

@secure()
param subnetID string

@description('Priave End Point Creation')
resource PrivateEndPoint 'Microsoft.Network/privateEndpoints@2021-05-01' = [for item in items(privateDnsName): {
  name: '${privateEndpintName}-${item.key}'
  location: location
  properties: {
    subnet: {
      id: subnetID
    }
    // customNetworkInterfaceName: '${privateEndpintName}.nic'
    privateLinkServiceConnections: [
      {
        name: '${privateEndpintName}-${item.key}'
        properties: {
          privateLinkServiceId: StorageAccount.id
          groupIds: [
            item.key
          ]
          requestMessage: ''
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Approved'
          }
        }
      }
    ]

  }
}]

param storagesName string
param storagesRG string

@description('Storage Account Reference')
resource StorageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storagesName
  scope: resourceGroup(storagesRG)
}

@description('To use the existing Reference')
resource privateDNSZoneRef 'Microsoft.Network/privateDnsZones@2020-06-01' existing = [for item in items(privateDnsName): {
  name: item.value
  scope: resourceGroup(privateDnsRG)
}]

@description('Private Dns Zone Config')
resource DnsConfig 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-03-01' = [for item in range(0, length(privateDnsName)): {
  parent: PrivateEndPoint[item]
  name: PrivateEndPoint[item].name
  properties: {
    privateDnsZoneConfigs: [
      {
        name: PrivateEndPoint[item].properties.privateLinkServiceConnections[0].properties.groupIds[0]
        properties: {
          privateDnsZoneId: privateDNSZoneRef[item].id
        }
      }
    ]
  }
  dependsOn: [
    PrivateEndPoint
  ]
}]
