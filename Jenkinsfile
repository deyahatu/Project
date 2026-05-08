pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        COMPOSE_PROJECT_NAME = 'recommendation-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Build') {
            steps {
                sh 'docker compose build'
            }
        }

        stage('Deploy') {
            steps {
                sh 'docker compose down --remove-orphans || true'
                sh 'docker compose up -d'
            }
        }

        stage('Smoke test') {
            steps {
                sh '''
                    for i in $(seq 1 30); do
                        if curl -sf http://localhost:8081 > /dev/null; then
                            echo "App is up."
                            exit 0
                        fi
                        echo "Waiting for app... ($i/30)"
                        sleep 2
                    done
                    echo "App did not become ready in time."
                    docker compose logs --tail=80
                    exit 1
                '''
            }
        }
    }

    post {
        success {
            echo "Deployed successfully on http://localhost:8081"
        }
        failure {
            sh 'docker compose logs --tail=120 || true'
        }
    }
}
