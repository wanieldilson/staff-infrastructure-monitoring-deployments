{{ define "cloudwatchMetrics.default" }}
discovery:
  exportedTagsOnMetrics:
    ec2:
      - Name
      - type
    ecs:
      - ClusterName
      - ServiceName
    s3:
      - BucketName
      - StorageType
  jobs:
    - regions: [eu-west-2]
      roleArns: [{{ .Values.cloudwatchExporter.accessRoleArns }}]
      type: AWS/EC2
      length: 300
      metrics:
        - name: CPUUtilization
          statistics: [Average]
          nilToZero: true
    - regions: [eu-west-2]
      roleArns: [{{ .Values.cloudwatchExporter.accessRoleArns }}]
      type: AWS/ECS
      length: 300
      metrics:
        - name: CPUUtilization
          statistics: [Average, Minimum, Maximum]
          nilToZero: true
        - name: MemoryUtilization
          statistics: [Average]
          nilToZero: true
    - regions: [eu-west-2]
      roleArns: [{{ .Values.cloudwatchExporter.accessRoleArns }}]
      type: AWS/RDS
      length: 300
      metrics:
        - name: FreeStorageSpace
          statistics: [Average]
          nilToZero: true
    - regions: [eu-west-2]
      roleArns: [{{ .Values.cloudwatchExporter.accessRoleArns }}]
      type: AWS/S3
      length: 300
      metrics:
        - name: BucketSizeBytes
          statistics: [Average]
          nilToZero: true
{{ end }}