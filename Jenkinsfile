pipeline {
    agent any

    stages {
        stage('Clone Repo') {
            steps {
                git branch: 'main', url: 'https://github.com/srinirajuk20/devops-pipeline-project.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t devops-flask-app:ci -f app/Dockerfile app'
            }
        }
    }
}
