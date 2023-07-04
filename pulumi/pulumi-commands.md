Pulumi is a cloud based Infrastructure as Code tool

## Install Pulumi on Windows
choco install pulumi
choco install awscli

## New Project in local empty folder
> pulumi new

Login to pulumi with your browser (or a token) and select a template for what you want to create, make sure it has a -python suffix for a python project.

## Set AWS Profile
Modify file:
> notepad.exe `C:\Users\JoshDean\.aws\credentials`

Add these lines and the access keys:
[pulumi]
aws_access_key_id = 
aws_secret_access_key = 

Set pulumi to use that profile:
> pulumi config set aws:profile pulumi

## View AWS State
Pulumi Will Store the AWS State for us, use this command to view the AWS state 
> pulumi stack

If the state ever changes use the --refresh flag for the stack that you want to re-deploy
> pulumi up --refresh

## Preview Stack Changes / Updates to a file
> pulumi preview

## Spin Up Resources - Create or Update a Stack
> pulumi up 

## Spin Down Resources - Destroy everything!!!
> pulumi destroy    

