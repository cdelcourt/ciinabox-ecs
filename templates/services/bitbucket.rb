require 'cfndsl'

if !defined? timezone
  timezone = 'GMT'
end

CloudFormation {

  AWSTemplateFormatVersion "2010-09-09"
  Description "ciinabox - ECS Service Bitbucket v#{ciinabox_version}"

  Parameter("ECSCluster"){ Type 'String' }
  Parameter("ECSRole"){ Type 'String' }
  Parameter("ServiceELB"){ Type 'String' }

  Resource('BitbucketTask') {
    Type "AWS::ECS::TaskDefinition"
    Property('ContainerDefinitions', [
      {
        Name: 'bitbucket',
        Memory: 2024,
        Cpu: 300,
        Image: 'atlassian/bitbucket-server',
        PortMappings: [{
          HostPort: 7999,
          ContainerPort: 7999
        }],
        Environment: [
          {
            Name: 'VIRTUAL_HOST',
            Value: "bitbucket.#{dns_domain}"
          },
          {
            Name: 'VIRTUAL_PORT',
            Value: '7990'
          }
        ],
        Essential: true,
        MountPoints: [
          {
            ContainerPath: '/var/atlassian/application-data/bitbucket',
            SourceVolume: 'bitbucket_data',
            ReadOnly: false
          }
        ]
      }
    ])
    Property('Volumes', [
      {
        Name: 'bitbucket_data',
        Host: {
          SourcePath: '/data/bitbucket'
        }
      }
    ])
  }

  Resource('BitbucketService') {
    Type 'AWS::ECS::Service'
    Property('Cluster', Ref('ECSCluster'))
    Property('DesiredCount', 1)
    Property('TaskDefinition', Ref('BitbucketTask'))
    Property('Role', Ref('ECSRole'))
    Property('LoadBalancers', [
      { ContainerName: 'bitbucket', ContainerPort: '7999', LoadBalancerName: Ref('ServiceELB') }
    ])
  }
}
