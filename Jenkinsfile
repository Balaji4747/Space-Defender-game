pipeline {
    agent any
    
    environment {
        // Docker configuration
        DOCKER_IMAGE = 'space-defender-game'
        DOCKER_TAG = "${BUILD_NUMBER}"
        DOCKER_REGISTRY = 'your-registry.com' // Replace with your registry
        
        // Kubernetes configuration
        KUBECONFIG = credentials('kubeconfig')
        NAMESPACE = 'space-defender'
        
        // AWS configuration (if using AWS)
        AWS_REGION = 'us-west-2'
        AWS_ACCOUNT_ID = credentials('aws-account-id')
        
        // Notification settings
        SLACK_CHANNEL = '#devops-alerts'
        EMAIL_RECIPIENTS = 'devops@yourcompany.com'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '🚀 Starting Space Defender Game CI/CD Pipeline'
                checkout scm
                
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()
                    env.BUILD_VERSION = "${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Code Quality & Security') {
            parallel {
                stage('Lint Code') {
                    steps {
                        echo '🔍 Running code linting...'
                        sh '''
                            # Install dependencies if needed
                            npm install --only=dev
                            
                            # Run linting (you can add ESLint, Prettier, etc.)
                            echo "Linting HTML, CSS, and JavaScript files..."
                            
                            # Check for common issues
                            find . -name "*.html" -exec echo "Checking {}" \\;
                            find . -name "*.css" -exec echo "Checking {}" \\;
                            find . -name "*.js" -exec echo "Checking {}" \\;
                        '''
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        echo '🔒 Running security scans...'
                        sh '''
                            # Scan for vulnerabilities in dependencies
                            npm audit --audit-level moderate
                            
                            # Scan Docker image for vulnerabilities (using Trivy)
                            if command -v trivy &> /dev/null; then
                                echo "Running Trivy security scan..."
                                trivy fs .
                            else
                                echo "Trivy not installed, skipping container scan"
                            fi
                        '''
                    }
                }
                
                stage('Unit Tests') {
                    steps {
                        echo '🧪 Running unit tests...'
                        sh '''
                            # Run tests (add your test framework here)
                            echo "Running JavaScript unit tests..."
                            # npm test
                            
                            # For now, just validate files exist
                            test -f index.html
                            test -f styles.css
                            test -f game.js
                            test -f Dockerfile
                            
                            echo "All required files present ✅"
                        '''
                    }
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                script {
                    def image = docker.build("${DOCKER_IMAGE}:${BUILD_VERSION}")
                    env.DOCKER_IMAGE_FULL = "${DOCKER_IMAGE}:${BUILD_VERSION}"
                    
                    // Tag as latest
                    sh "docker tag ${DOCKER_IMAGE}:${BUILD_VERSION} ${DOCKER_IMAGE}:latest"
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo '🧪 Testing Docker image...'
                sh '''
                    # Run container in background
                    docker run -d --name test-container -p 8081:8080 ${DOCKER_IMAGE}:${BUILD_VERSION}
                    
                    # Wait for container to start
                    sleep 10
                    
                    # Test health endpoint
                    curl -f http://localhost:8081/health || exit 1
                    
                    # Test main page
                    curl -f http://localhost:8081/ || exit 1
                    
                    # Cleanup
                    docker stop test-container
                    docker rm test-container
                    
                    echo "Docker image tests passed ✅"
                '''
            }
        }
        
        stage('Push to Registry') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                echo '📦 Pushing to Docker registry...'
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        def image = docker.image("${DOCKER_IMAGE}:${BUILD_VERSION}")
                        image.push()
                        image.push("latest")
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                echo '🚀 Deploying to staging environment...'
                sh '''
                    # Update Kubernetes manifests with new image
                    sed -i "s|image: space-defender-game:.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${BUILD_VERSION}|g" k8s/deployment.yaml
                    
                    # Apply to staging namespace
                    kubectl apply -f k8s/ -n space-defender-staging
                    
                    # Wait for rollout
                    kubectl rollout status deployment/space-defender-game -n space-defender-staging --timeout=300s
                    
                    # Run smoke tests
                    echo "Running staging smoke tests..."
                    # Add your staging tests here
                '''
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                echo '🎯 Deploying to production...'
                
                // Manual approval for production
                input message: 'Deploy to production?', ok: 'Deploy',
                      submitterParameter: 'DEPLOYER'
                
                sh '''
                    # Update Kubernetes manifests
                    sed -i "s|image: space-defender-game:.*|image: ${DOCKER_REGISTRY}/${DOCKER_IMAGE}:${BUILD_VERSION}|g" k8s/deployment.yaml
                    
                    # Apply to production namespace
                    kubectl apply -f k8s/ -n space-defender-prod
                    
                    # Rolling update
                    kubectl rollout status deployment/space-defender-game -n space-defender-prod --timeout=600s
                    
                    # Verify deployment
                    kubectl get pods -n space-defender-prod
                '''
            }
        }
        
        stage('Integration Tests') {
            parallel {
                stage('API Tests') {
                    steps {
                        echo '🔧 Running API integration tests...'
                        sh '''
                            # Test health endpoint
                            kubectl port-forward service/space-defender-game 8082:80 -n space-defender-prod &
                            PF_PID=$!
                            sleep 5
                            
                            curl -f http://localhost:8082/health
                            
                            kill $PF_PID
                        '''
                    }
                }
                
                stage('Performance Tests') {
                    steps {
                        echo '⚡ Running performance tests...'
                        sh '''
                            # Basic load test (you can use tools like k6, JMeter, etc.)
                            echo "Running basic performance tests..."
                            
                            # Example with curl (replace with proper load testing tool)
                            for i in {1..10}; do
                                curl -s -o /dev/null -w "%{http_code}\\n" http://localhost:8082/ || true
                            done
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            echo '🧹 Cleaning up...'
            sh '''
                # Clean up test containers
                docker container prune -f
                
                # Clean up old images (keep last 5)
                docker images ${DOCKER_IMAGE} --format "table {{.Repository}}:{{.Tag}}\\t{{.CreatedAt}}" | tail -n +6 | awk '{print $1}' | xargs -r docker rmi || true
            '''
        }
        
        success {
            echo '✅ Pipeline completed successfully!'
            
            // Slack notification
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'good',
                message: "✅ Space Defender Game deployed successfully!\nVersion: ${env.BUILD_VERSION}\nDeployed by: ${env.DEPLOYER ?: 'Jenkins'}"
            )
            
            // Email notification
            emailext(
                subject: "✅ Space Defender Game - Deployment Success",
                body: """
                    Space Defender Game has been successfully deployed!
                    
                    Build: ${env.BUILD_NUMBER}
                    Version: ${env.BUILD_VERSION}
                    Branch: ${env.BRANCH_NAME}
                    Deployed by: ${env.DEPLOYER ?: 'Jenkins'}
                    
                    View the game: https://your-domain.com
                """,
                to: env.EMAIL_RECIPIENTS
            )
        }
        
        failure {
            echo '❌ Pipeline failed!'
            
            // Slack notification
            slackSend(
                channel: env.SLACK_CHANNEL,
                color: 'danger',
                message: "❌ Space Defender Game deployment failed!\nBuild: ${env.BUILD_NUMBER}\nBranch: ${env.BRANCH_NAME}"
            )
            
            // Email notification
            emailext(
                subject: "❌ Space Defender Game - Deployment Failed",
                body: """
                    Space Defender Game deployment has failed!
                    
                    Build: ${env.BUILD_NUMBER}
                    Branch: ${env.BRANCH_NAME}
                    
                    Please check the Jenkins logs for details.
                """,
                to: env.EMAIL_RECIPIENTS
            )
        }
        
        unstable {
            echo '⚠️ Pipeline completed with warnings!'
        }
    }
}
