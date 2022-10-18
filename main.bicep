targetScope = 'subscription'

var sVar = json(loadTextContent('Storages.json'))

// az deployment sub create --location 'eastus' --template-file './main.bicep'

param location string = deployment().location
param VnetName string = 'vnet1'
param vnetRG string = 'RG1'
param subnetName string = 'default'
param privateDnsRG string = 'RG1'

@description('Object Key is the Resource Group and Storage is the storage name')
var Storages = sVar.PersonalStorage

// param location string = deployment().location
// param VnetName string = 'slx-use-qa96-vn01'
// param vnetRG string = 'SLX-USE-QA96-RG02'
// param privateDnsRG string = 'slx-use-qa96-rg02'
// param subnetName string = 'dev-private-endpoint'

// @description('Object Key is the Resource Group and Storage is the storage name')
// var Storages = sVar.storages

@description('Private DNS Lists')
var PrivateDNSTypes = {
  blob: 'privatelink.blob.${environment().suffixes.storage}'
  file: 'privatelink.file.${environment().suffixes.storage}'
  queue: 'privatelink.queue.${az.environment().suffixes.storage}'
  table: 'privatelink.table.${az.environment().suffixes.storage}'
}

@description('Vnet Reference')
resource Vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: VnetName
  scope: resourceGroup(vnetRG)
}

@description('Subnet Reference')
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-05-01' existing = {
  name: subnetName
  parent: Vnet
}

@description('Private DNS Creation')
module PrivateDNS 'privateDns.bicep' = [for item in items(PrivateDNSTypes): {
  name: 'Private-DNS-${item.value}'
  params: {
    privateDNSname: item.value
    vnetID: Vnet.id
  }
  scope: resourceGroup(privateDnsRG)
}]

@description('Private Endpoints Creation')
module PrivateEndPoints 'endPoints.bicep' = [for item in items(Storages): {
  name: 'pep-${item.key}'
  params: {
    privateDnsRG: privateDnsRG
    privateDnsName: PrivateDNSTypes //Dns We Created earlier
    subnetID: subnet.id
    location: location
    privateEndpintName: 'pep-${item.key}' //Name of the endPoint
    storagesName: item.key
    storagesRG: item.value
  }
  scope: resourceGroup(item.value)
  dependsOn: [
    PrivateDNS
  ]
}]
