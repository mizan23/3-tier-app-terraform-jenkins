# SonarQube Assignment Documentation

This project now fulfills the assignment requirement to integrate SonarQube with GitHub Actions and run code quality analysis automatically.

## Files Added

- `.github/workflows/sonarqube.yml`
- `sonar-project.properties`
- `backend/test/calculations.test.js`

## Infrastructure Provisioned on AWS

- SonarQube server deployed with Terraform in `terraform/sonarqube`
- Runtime URL: `http://13.218.159.5:9000`
- EC2 + Security Group + route table association created
- SonarQube and PostgreSQL run in Docker containers through EC2 user-data

## GitHub Secrets

Configured in repository Actions secrets:

- `SONAR_TOKEN`
- `SONAR_HOST_URL`

## SonarQube Project Setup Completed

1. SonarQube project key created: `bmi-health-tracker`
2. Project name: `BMI Health Tracker`
3. Token generated for GitHub Actions and stored as secret

## Workflow Behavior

The workflow does the following:

1. Checks out repository code
2. Sets up Node.js
3. Installs backend dependencies
4. Runs backend unit test with coverage (`c8`)
5. Sends analysis to SonarQube

## Trigger Analysis

Analysis runs automatically on:

- push to `main`
- pull request events

Manual trigger flow:

```bash
git add .
git commit -m "Add SonarQube integration"
git push origin main
```

Then open SonarQube dashboard to view:

- Bugs
- Code Smells
- Coverage
- Maintainability

## Assignment Completion Checklist

- Environment prepared (AWS SonarQube + token)
- Sample project used (JavaScript app with backend/frontend)
- SonarQube project configured
- `sonar-project.properties` added
- GitHub Actions workflow created in `.github/workflows/sonarqube.yml`
- Workflow ready to run on push and pull request
- SonarQube report available in dashboard after workflow success

## Submission Artifacts

- GitHub repository: `git@github.com:mizan23/3-tier-app-terraform-jenkins.git`
- Sonar dashboard URL: `http://13.218.159.5:9000/dashboard?id=bmi-health-tracker`
- Take one screenshot from dashboard after the latest workflow run finishes successfully
