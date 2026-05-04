# Module 15 Assignment Report

## Title

Deploy Application Using AWS ECR and ECS Fargate with Auto Scaling

## Objective

Containerize an application, push the image to AWS ECR, deploy it on AWS ECS Fargate, and enable Auto Scaling.

## AWS Account and Region

- Account ID: `366403523501`
- Region: `us-east-1`
- AWS profile used: `mizan-ostad`

## Application Used

A simple Node.js Express web app was created for this assignment.

- App path: `module15-ecs-fargate-app`
- Endpoints:
  - `/` -> text response
  - `/health` -> JSON health response

Files created:

- `module15-ecs-fargate-app/app.js`
- `module15-ecs-fargate-app/package.json`
- `module15-ecs-fargate-app/Dockerfile`
- `module15-ecs-fargate-app/task-definition.json`

## Step-by-Step Implementation

### 1) Dockerize the Application

- Docker image built locally from `module15-ecs-fargate-app/Dockerfile`
- Local image tag: `module15-ecs-fargate-app:latest`

### 2) Push Image to AWS ECR

- ECR repository created: `module15-ecs-fargate-app`
- Repository URI: `366403523501.dkr.ecr.us-east-1.amazonaws.com/module15-ecs-fargate-app`
- Docker login to ECR completed
- Image tagged and pushed successfully as `latest`

### 3) Deploy on ECS Fargate

- ECS cluster created: `module15-fargate-cluster`
- Task definition family: `module15-fargate-task`
- Service created: `module15-fargate-service`
- Launch type: `FARGATE`
- Desired count: `1`
- Network mode: `awsvpc`
- Container port: `8080`

### 4) Enable Auto Scaling

- Scalable target configured for ECS service desired count
- Min capacity: `1`
- Max capacity: `3`
- Scaling policy type: `TargetTrackingScaling`
- Metric: `ECSServiceAverageCPUUtilization`
- Target value: `50%`

### 5) Test Deployment

- Service reached stable state
- Running task public endpoint verified:
  - `http://3.237.51.194:8080/`
  - `http://3.237.51.194:8080/health`

## Required Screenshot Checklist

Include these screenshots in your Google Doc submission:

1. Local Docker build success (terminal output of `docker build`)
2. ECR repository with uploaded image (`latest`)
3. ECS Task Definition details (`module15-fargate-task`)
4. ECS Service page showing running service + Auto Scaling settings
5. Browser showing app running at the public endpoint

## Bonus Coverage

- Auto Scaling policy configured based on CPU utilization (scale out/in)

## Submission Instructions

1. Create a Google Doc.
2. Add a short explanation and screenshot for each required step.
3. Add this repository link: `https://github.com/mizan23/3-tier-app-terraform-jenkins`
4. Set sharing to: **Anyone with the link can view**.
5. Submit the Google Docs link.

## Notes

- ECS task public IP can change if a task is replaced.
- If IP changes, get latest task ENI public IP from ECS/EC2 console and retest.
