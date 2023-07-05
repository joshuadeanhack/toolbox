from pulumi import Config, Output, export
import pulumi_aws as aws
import pulumi_awsx as awsx

config = Config()
container_port = config.get_int("containerPort", 80)
cpu = config.get_int("cpu", 512)
memory = config.get_int("memory", 256)

# An ECS cluster to deploy into, public VPC
cluster = aws.ecs.Cluster("cluster")

# An ALB to serve the container endpoint to the internet
loadbalancer = awsx.lb.ApplicationLoadBalancer("cogito-loadbalancer")

# An ECR repository to store our application's container image
repo = awsx.ecr.Repository("cogito-repo")

# Build and publish our application's container image from ../web to the ECR repository
image = awsx.ecr.Image(
    "image",
    repository_url=repo.url,
    path="../web")

# Deploy an ECS Service on Fargate to host the application container
service = awsx.ecs.FargateService(
    "service",
    cluster=cluster.arn,
    task_definition_args=awsx.ecs.FargateServiceTaskDefinitionArgs(
        container=awsx.ecs.TaskDefinitionContainerDefinitionArgs(
            image=image.image_uri,
            cpu=cpu,
            memory=memory,
            essential=True,
            port_mappings=[awsx.ecs.TaskDefinitionPortMappingArgs(
                container_port=container_port,
                target_group=loadbalancer.default_target_group,
            )],
        ),
    ))

#Code Commit Repo
codecommit_repo = aws.codecommit.Repository("webcode",
    description="This is the Web Code Repository",
    repository_name="webcode")      


#Code Pipeline Dependancies

codepipeline_bucket = aws.s3.Bucket("codepipelineBucket",
    acl="private"
    )

codepipeline_role = aws.iam.Role("codepipelineRole", assume_role_policy="""{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
""")

codepipeline_policy = aws.iam.RolePolicy("codepipelinePolicy",
    role=codepipeline_role.id,
    policy=Output.all(codepipeline_bucket.arn, codepipeline_bucket.arn) \
      .apply(lambda arns: f"""{{
  "Version": "2012-10-17",
  "Statement": [
    {{
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObjectAcl",
        "s3:PutObject"
      ],
      "Resource": [
        "{arns[0]}",
        "{arns[1]}/*"
      ]
    }},
    {{
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild",
        "codecommit:*"
      ],
      "Resource": "*"
    }}
  ]
}}
"""))


#CodeBuild Project

codebuild_role = aws.iam.Role("codeBuildRole", assume_role_policy="""{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
""")

codebuild_policy = aws.iam.RolePolicy("codeBuildPolicy",
    role=codebuild_role.id,
    policy=Output.all(codepipeline_bucket.arn).apply(lambda codePipelineBucket: f"""{{
  "Version": "2012-10-17",
  "Statement": [
    {{
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }},
    {{
      "Effect": "Allow",
      "Resource": [
          "*"
      ],
      "Action": [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetBucketAcl",
          "s3:GetBucketLocation"
      ]
    }},
    {{
      "Effect": "Allow",
      "Resource": [
          "*"
      ],
      "Action": [
          "codecommit:GitPull"
      ]
    }}, 
    {{
        "Effect": "Allow",
        "Action": [
            "codebuild:CreateReportGroup",
            "codebuild:CreateReport",
            "codebuild:UpdateReport",
            "codebuild:BatchPutTestCases",
            "codebuild:BatchPutCodeCoverages"
        ],
        "Resource": [
            "*"
        ]
    }},
    {{
      "Effect": "Allow",
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeDhcpOptions",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface",
        "ec2:DescribeSubnets",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeVpcs"
      ],
      "Resource": "*"
    }},
    {{
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "{codePipelineBucket}",
        "{codePipelineBucket}/*"
      ]
    }}
  ]
}}
"""))

codebuild_project = aws.codebuild.Project("build-nginx-docker-image",
    description="Builds the Nginx Docker Image",
    build_timeout=5,
    service_role=codebuild_role.arn,
    artifacts=aws.codebuild.ProjectArtifactsArgs(
        type="NO_ARTIFACTS",
    ),
    cache=aws.codebuild.ProjectCacheArgs(
        type="S3",
        location=codepipeline_bucket.bucket,
    ),
    environment=aws.codebuild.ProjectEnvironmentArgs(
        compute_type="BUILD_GENERAL1_SMALL",
        image="aws/codebuild/standard:4.0",
        type="LINUX_CONTAINER",
        image_pull_credentials_type="CODEBUILD",
    ),
    logs_config=aws.codebuild.ProjectLogsConfigArgs(
        cloudwatch_logs=aws.codebuild.ProjectLogsConfigCloudwatchLogsArgs(
            group_name="log-group",
            stream_name="log-stream",
        ),
        s3_logs=aws.codebuild.ProjectLogsConfigS3LogsArgs(
            status="ENABLED",
            location=codepipeline_bucket.id.apply(lambda id: f"{id}/build-log"),
        ),
    ),
    source=aws.codebuild.ProjectSourceArgs(
        type="CODECOMMIT",
        location="https://git-codecommit.eu-west-1.amazonaws.com/v1/repos/webcode",
        git_clone_depth=1,
        git_submodules_config=aws.codebuild.ProjectSourceGitSubmodulesConfigArgs(
            fetch_submodules=True,
        ),
    ),
    source_version="master"
    )


#CodePipeline - Source Files from CodeCommit and Deploy to ECS Fargate Service

codepipeline = aws.codepipeline.Pipeline("codepipeline",
    role_arn=codepipeline_role.arn,
    artifact_stores=[aws.codepipeline.PipelineArtifactStoreArgs(
        location=codepipeline_bucket.bucket,
        type="S3"
    )],
    stages=[
        #https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-S3.html
        aws.codepipeline.PipelineStageArgs(
            name="Source",
            actions=[aws.codepipeline.PipelineStageActionArgs(
                name="Source",
                category="Source",
                owner="AWS",
                provider="CodeCommit",
                version="1",
                output_artifacts=["source_output"],
                configuration={
                    "RepositoryName": codecommit_repo.repository_name,
                    "BranchName": "master",
                    "PollForSourceChanges": "true",
                },
            )],
        ),
        #https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodeBuild.html
        aws.codepipeline.PipelineStageArgs(
            name="Build",
            actions=[aws.codepipeline.PipelineStageActionArgs(
                name="Build",
                category="Build",
                owner="AWS",
                provider="CodeBuild",
                input_artifacts=["source_output"],
                output_artifacts=["build_output"],
                version="1",
                configuration={
                    "ProjectName": codebuild_project.name,
                },
            )],
        ),
        #https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-ECS.html
        aws.codepipeline.PipelineStageArgs(
            name="Deploy",
            actions=[aws.codepipeline.PipelineStageActionArgs(
                name="Deploy",
                category="Deploy",
                owner="AWS",
                provider="ECS",
                input_artifacts=["build_output"],
                version="1",
                configuration={
                    "ServiceName": service.service,
                    "ClusterName": cluster.name,
                    "DeploymentTimeout": "10",
                },
            )],
        ),
    ])

# The URL at which the container's HTTP endpoint will be available
export("url", Output.concat("http://", loadbalancer.load_balancer.dns_name))